#!/bin/bash

# Print "<pipewire node name>\t0|1" per output. PipeWire keeps a sink in the
# graph whether or not anything is plugged into its port, so the headphone jack
# and an idle HDMI output stay selectable and silently swallow the sound. Only
# pactl knows a port is unavailable; a sink with no ports at all (a virtual one)
# counts as available.

pactl list sinks 2>/dev/null | awk '
  function emit() {
    if (name == "") return
    print name "\t" ((ports == 0 || available) ? 1 : 0)
  }
  /^Sink #/          { emit(); name = ""; in_ports = 0; ports = 0; available = 0; next }
  /^[[:space:]]*Name:/  { name = $2; next }
  /^[[:space:]]*Ports:$/ { in_ports = 1; next }
  in_ports && /^\tActive Port:/ { in_ports = 0; next }
  in_ports && /^\t\t/ { ports++; if ($0 !~ /not available/) available = 1; next }
  END { emit() }
'
