local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"
local mod = "SUPER"

hl.bind(mod .. " + R", hl.dsp.exec_cmd(scripts .. "/refresh.sh"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm app -- ghostty"))
hl.bind(mod .. " + F4", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + F4", hl.dsp.exec_cmd(scripts .. "/kill-current.sh"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("qs -c endfield ipc call lock lock || uwsm app -- hyprlock"))

hl.bind(mod .. " + E", hl.dsp.exec_cmd("uwsm app -- nautilus"))
hl.bind(mod .. " + F", hl.dsp.exec_cmd("uwsm app -- rofi -show drun"))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + B", hl.dsp.exec_cmd("uwsm app -- brave --enable-features=UseOzonePlatform --ozone-platform=wayland"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("uwsm app -- code"))

for key, direction in pairs({ left = "left", right = "right", up = "up", down = "down", k = "up", j = "down" }) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end
hl.bind(mod .. " + H", hl.dsp.group.prev())
hl.bind(mod .. " + L", hl.dsp.group.next())

for i = 1, 5 do
    hl.bind(mod .. " + " .. i, hl.dsp.exec_cmd(scripts .. "/workspace-cycle.sh " .. i))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = "name:Laptop" }))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(scripts .. "/workspace-layout.sh"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd(scripts .. "/workspace-group.sh"))

hl.bind(mod .. " + Tab", hl.dsp.exec_cmd("qs -c endfield ipc call overview next"))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.exec_cmd("qs -c endfield ipc call overview previous"))
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd("qs -c endfield ipc call overview accept"), { release = true, transparent = true })
hl.bind(mod .. " + Super_R", hl.dsp.exec_cmd("qs -c endfield ipc call overview accept"), { release = true, transparent = true })

hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd(scripts .. "/move-to-workspace.sh"))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.exec_cmd(scripts .. "/move-workspace.sh"))

hl.bind(mod .. " + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy --type image/png'))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind("Print", hl.dsp.exec_cmd("grim ~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png"))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mod .. " + C", hl.dsp.exec_cmd('hyprpicker | wl-copy && notify-send "Color picker" "$(wl-paste)"'))
hl.bind(mod .. " + ALT + S", hl.dsp.exec_cmd("pkill -x orca || uwsm app -- orca"))

hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar toggle"))
hl.bind(mod .. " + CTRL + C", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar toggle"))
hl.bind(mod .. " + CTRL + V", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page clipboard"))
hl.bind(mod .. " + CTRL + A", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page output"))
hl.bind(mod .. " + CTRL + M", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page input"))
hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page network"))
hl.bind(mod .. " + CTRL + B", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page bluetooth"))
hl.bind(mod .. " + CTRL + D", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page calendar"))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("qs -c endfield ipc call sidebar page power"))
