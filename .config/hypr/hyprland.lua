require("env")
local colors = require("settings").colors
require("displays")
require("workspaces")

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 2,
        col = { active_border = colors.borderActive, inactive_border = colors.borderInactive },
        allow_tearing = false,
        layout = "dwindle",
    },
    group = {
        col = { border_active = colors.borderActive, border_inactive = colors.borderInactive },
        -- Quickshell paints tabs; Hyprland still reserves their space and owns grouping.
        groupbar = {
            height = 24,
            indicator_height = 0,
            indicator_gap = 0,
            gaps_in = 0,
            gaps_out = 0,
            keep_upper_gap = false,
            render_titles = true,
            gradients = false,
            rounding = 0,
            gradient_rounding = 0,
            text_color = "rgba(00000000)",
            text_color_inactive = "rgba(00000000)",
            text_color_locked_active = "rgba(00000000)",
            text_color_locked_inactive = "rgba(00000000)",
            col = {
                active = "rgba(00000000)",
                inactive = "rgba(00000000)",
                locked_active = "rgba(00000000)",
                locked_inactive = "rgba(00000000)",
            },
        },
    },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        -- A restarted shell must be able to adopt the compositor's existing lock.
        allow_session_lock_restore = true,
    },
    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        kb_model = "",
        kb_options = "caps:ctrl_modifier",
        kb_rules = "",
        follow_mouse = 0,
        repeat_delay = 200,
        repeat_rate = 50,
        sensitivity = 0,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            scroll_factor = 0.5,
            clickfinger_behavior = true,
            middle_button_emulation = false,
            tap_to_click = true,
            drag_lock = false,
        },
    },
    xwayland = { force_zero_scaling = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

hl.window_rule({ name = "windowrule-1", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "moonlight-external-monitor",
    match = { class = [[^(com\.moonlight_stream\.Moonlight)$]] },
    monitor = "HDMI-A-1",
})
hl.window_rule({
    name = "windowrule-2",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

require("keybinds")
require("init")
