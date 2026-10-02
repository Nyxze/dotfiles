local scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- hyprpaper --config " .. os.getenv("HOME") .. "/.config/hypr/hyprpaper.conf")
    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd("uwsm app -- qs -c endfield")
    hl.exec_cmd(scripts .. "displays.py apply")
    hl.exec_cmd(scripts .. "displays.py watch")
end)

hl.on("config.reloaded", function()
    -- Initial parsing also emits this event, before any monitor exists.
    if not hl.get_active_monitor() then
        return
    end
    hl.exec_cmd(scripts .. "displays.py apply")
end)
