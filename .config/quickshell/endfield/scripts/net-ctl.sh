#!/bin/bash

# Wi-Fi band and DNS provider for the shell's network page. Both are per-profile
# NetworkManager settings that no Quickshell binding exposes, and the band has to
# be checked against the bands the access point actually answers on: pinning one
# it does not serve drops the connection with nothing to reassociate to.

set -euo pipefail

# nmcli translates state words, so a non-English session would stop matching;
# -e no keeps ':' and '\' unescaped in values such as an SSID.
nm() { LC_ALL=C nmcli -e no "$@" 2>/dev/null; }

device() {
  nm -g DEVICE,TYPE,STATE device status |
    awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }'
}

profile() { nm -g GENERAL.CONNECTION device show "$1"; }

band_for_freq() {
  local mhz=${1%%[!0-9]*}
  [[ -n $mhz ]] || return 1
  if ((mhz >= 2400 && mhz < 2500)); then echo 2.4
  elif ((mhz >= 4900 && mhz < 5925)); then echo 5
  elif ((mhz >= 5925 && mhz < 7125)); then echo 6
  else return 1
  fi
}

nm_band() {
  case "$1" in
    2.4) echo bg ;;
    5) echo a ;;
    6) echo 6GHz ;;
    *) return 1 ;;
  esac
}

from_nm_band() {
  case "$1" in
    bg) echo 2.4 ;;
    a) echo 5 ;;
    6GHz) echo 6 ;;
    *) echo auto ;;
  esac
}

# --rescan no reads NetworkManager's cache, kept warm by the panel's own
# scanner; forcing a scan here would stall every poll. The band in use is always
# included — a weak radio gets missed by plenty of scans, and the band we sit on
# must never be absent from its own list of options.
available_bands() {
  local dev=$1 ssid=$2 current=$3
  {
    [[ -n $current ]] && echo "$current"
    nm -g FREQ,SSID dev wifi list ifname "$dev" --rescan no |
      want="$ssid" awk -F: '
        BEGIN { want = ENVIRON["want"] }
        { name = $2; for (i = 3; i <= NF; i++) name = name ":" $i
          if (name == want) print $1 }' |
      while read -r freq; do band_for_freq "$freq" || true; done
  } | sort -u -g | tr '\n' ' ' | sed 's/ *$//'
}

# Providers are matched on their first server so a profile set outside the panel
# still lights up the right pill.
dns_servers() {
  case "$1" in
    cloudflare) echo "1.1.1.1 1.0.0.1" ;;
    google) echo "8.8.8.8 8.8.4.4" ;;
    quad9) echo "9.9.9.9 149.112.112.112" ;;
    *) echo "" ;;
  esac
}

dns_provider_of() {
  case "${1%%,*}" in
    1.1.1.1) echo cloudflare ;;
    8.8.8.8) echo google ;;
    9.9.9.9) echo quad9 ;;
    "") echo dhcp ;;
    *) echo custom ;;
  esac
}

status() {
  local dev prof ssid freq band
  dev=$(device) || true
  [[ -n ${dev:-} ]] || return 0
  prof=$(profile "$dev")
  [[ -n $prof ]] || return 0

  printf 'dns\t%s\n' "$(dns_provider_of "$(nm -g ipv4.dns connection show "$prof")")"
  printf 'selected\t%s\n' "$(from_nm_band "$(nm -g 802-11-wireless.band connection show "$prof")")"

  ssid=$(iw dev "$dev" link 2>/dev/null | awk '/SSID:/ { sub(/.*SSID: /, ""); print; exit }')
  freq=$(iw dev "$dev" link 2>/dev/null | awk '/freq:/ { print $2; exit }')
  [[ -n $ssid ]] || return 0
  band=$(band_for_freq "$freq" || true)
  printf 'band\t%s\n' "$band"
  printf 'available\t%s\n' "$(available_bands "$dev" "$ssid" "$band")"
}

set_dns() {
  local prof servers
  prof=$(profile "$(device)")
  [[ -n $prof ]] || { echo "no active connection" >&2; exit 1; }
  servers=$(dns_servers "$1")

  # Reactivating costs the connection a few seconds, so clicking the pill that
  # is already lit must do nothing.
  [[ $(dns_provider_of "$(nm -g ipv4.dns connection show "$prof")") == "$1" ]] && exit 0

  if [[ -z $servers ]]; then
    nmcli connection modify "$prof" ipv4.dns "" ipv4.ignore-auto-dns no
  else
    nmcli connection modify "$prof" ipv4.dns "${servers// /,}" ipv4.ignore-auto-dns yes
  fi
  nmcli connection up "$prof" >/dev/null
}

# A band change only takes effect on reassociation. If the radio cannot come back
# up on the requested band, restore the previous setting rather than leaving the
# machine stranded offline.
set_band() {
  local target=$1 dev prof previous desired ssid freq
  dev=$(device) || true
  [[ -n ${dev:-} ]] || { echo "no connected Wi-Fi device" >&2; exit 1; }
  prof=$(profile "$dev")
  [[ -n $prof ]] || { echo "no active connection" >&2; exit 1; }

  if [[ $target == auto ]]; then
    desired=""
  else
    ssid=$(iw dev "$dev" link | awk '/SSID:/ { sub(/.*SSID: /, ""); print; exit }')
    freq=$(iw dev "$dev" link | awk '/freq:/ { print $2; exit }')
    if [[ " $(available_bands "$dev" "$ssid" "$(band_for_freq "$freq" || true)") " != *" $target "* ]]; then
      echo "${target}GHz is not available on this network" >&2
      exit 1
    fi
    desired=$(nm_band "$target")
  fi

  previous=$(nm -g 802-11-wireless.band connection show "$prof")
  [[ $previous == "$desired" ]] && exit 0

  nmcli connection modify "$prof" 802-11-wireless.band "$desired" >/dev/null
  if ! nmcli connection up "$prof" >/dev/null 2>&1; then
    nmcli connection modify "$prof" 802-11-wireless.band "$previous" >/dev/null
    nmcli connection up "$prof" >/dev/null 2>&1 || true
    echo "could not connect on ${target}; reverted" >&2
    exit 1
  fi
}

case "${1:-status}" in
  status) status ;;
  dns) set_dns "${2:?provider required}" ;;
  band) set_band "${2:?band required}" ;;
  *) echo "usage: net-ctl.sh [status | dns <provider> | band <auto|2.4|5|6>]" >&2; exit 1 ;;
esac
