-- Load monitor config from ~/.config/hypr/monitors.lua
-- Create this file with hl.monitor({}) calls for your setup
pcall(require, "monitors")

local hs = require("hyprsplit")
local mod = "SUPER"

hl.config({
    general = {
        layout = "scrolling",
        border_size = 0,
        gaps_in = 1,
        gaps_out = 0,
        ["col.active_border"] = "rgb(101415)",
        ["col.inactive_border"] = "rgb(101415)",
    },
    decoration = {
        rounding = 0,
    },
    animations = {
        enabled = true,
    },
    input = {
        sensitivity = 0,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = false,
            disable_while_typing = false,
            scroll_factor = 0.5,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        middle_click_paste = false,
        enable_swallow = true,
        swallow_regex = "^(kitty|foot*)$",
    },
    dwindle = {
        smart_split = true,
    },
    debug = {
        disable_logs = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})


-- Bezier curves (https://github.com/vyrx-dev/dotfiles)
hl.curve("water",        { type = "bezier", points = { {0.22, 0.9},  {0.36, 1.0}  } })
hl.curve("flow",         { type = "bezier", points = { {0.25, 0.1},  {0.25, 1.0}  } })
hl.curve("ripple",       { type = "bezier", points = { {0.33, 0.0},  {0.2,  1.0}  } })
hl.curve("stream",       { type = "bezier", points = { {0.4,  0.0},  {0.4,  1.0}  } })
hl.curve("cascade",      { type = "bezier", points = { {0.19, 1.0},  {0.22, 1.0}  } })
hl.curve("md3_standard", { type = "bezier", points = { {0.2,  0},    {0,    1}    } })
hl.curve("md3_accel",    { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
hl.curve("overshot",     { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })

hl.animation({ leaf = "windows",          enabled = true, speed = 3.0, bezier = "water"                       })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 2.5, bezier = "cascade",    style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.4, bezier = "stream",     style = "slide" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 1.6, bezier = "flow"                        })
hl.animation({ leaf = "fade",             enabled = true, speed = 2.4, bezier = "water"                       })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2.0, bezier = "cascade"                     })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 1.8, bezier = "ripple"                      })
hl.animation({ leaf = "fadeDim",          enabled = true, speed = 2.0, bezier = "water"                       })
hl.animation({ leaf = "fadeSwitch",       enabled = true, speed = 1.4, bezier = "flow"                        })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 1.5, bezier = "overshot",   style = "popin 80%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.3, bezier = "md3_accel",  style = "popin 90%" })
hl.animation({ leaf = "layers",           enabled = true, speed = 1.5, bezier = "md3_standard"                })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 1.5, bezier = "flow"                        })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.5, bezier = "water"                       })
hl.animation({ leaf = "border",           enabled = true, speed = 2.9, bezier = "water"                       })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 3.5, bezier = "flow"                        })

hl.device({
    name = "img4100:00-4d49:4150-touchpad",
    sensitivity = 0,
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.on("hyprland.start", function()
    hl.exec_cmd("playerctld")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("1password --silent")
end)

-- Mouse binds
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Window management
hl.bind(mod .. " + P",         hl.dsp.window.float())
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + E",         hl.dsp.window.fullscreen())
hl.bind(mod .. " + C",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pin())
hl.bind(mod .. " + Z",         hl.dsp.layout("focus"))
hl.bind(mod .. " + G",         hl.dsp.layout("promote"))

-- Apps
hl.bind(mod .. " + I",      hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + T",      hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + period", hl.dsp.exec_cmd("wofi-emoji"))

-- Session / lock
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("caelestia shell drawers toggle session"))
hl.bind(mod .. " + L",         hl.dsp.exec_cmd("loginctl lock-session"))

-- Screenshots
hl.bind("Print",                     hl.dsp.exec_cmd("caelestia screenshot"))
hl.bind("CTRL + Print",              hl.dsp.exec_cmd("caelestia screenshot -fr"))
hl.bind(mod .. " + SHIFT + S",       hl.dsp.exec_cmd("screenshot"))
hl.bind(mod .. " + SHIFT + ALT + S", hl.dsp.exec_cmd("caelestia screenshot region"))
hl.bind(mod .. " + SHIFT + Print",   hl.dsp.exec_cmd("caelestia record -rs"))
hl.bind("SHIFT + Print",             hl.dsp.exec_cmd("caelestia record -r"))

-- Color picker
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -f hex -a"))
hl.bind(mod .. " + ALT + C",   hl.dsp.exec_cmd("hyprpicker -f hex -a -r"))

-- Alt+Tab
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Scrolling layout: column movement
hl.bind(mod .. " + SHIFT + W", hl.dsp.layout("move -col"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.layout("move +col"))
hl.bind(mod .. " + SHIFT + H", hl.dsp.layout("swapcol l once"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.layout("swapcol r once"))
hl.bind(mod .. " + CTRL + H",  hl.dsp.layout("move -col"))
hl.bind(mod .. " + CTRL + L",  hl.dsp.layout("move +col"))

-- Launchers
hl.bind(mod .. " + SPACE",         hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"))
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("wofi -S drun -I"))
hl.bind(mod .. " + R",             hl.dsp.exec_cmd("kickoff"))
hl.bind(mod .. " + ALT + SPACE",   hl.dsp.exec_cmd("1password --quick-access"))

-- Clipboard
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi -dmenu | cliphist decode | wl-copy"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("cliphist list | wofi -dmenu | cliphist delete"))

-- Hyprexpo plugin
hl.bind(mod .. " + TAB", hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle"))

-- Window swallowing
hl.bind(mod .. " + CTRL + SHIFT + S", hl.dsp.window.toggle_swallow())

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true, locked = true })

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"),       { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("caelestia shell brightness set +0.1"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("caelestia shell brightness set 0.1-"), { locked = true })

-- Lid switch
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("clamshell close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("clamshell open"),  { locked = true })

-- Workspaces 1-10 (hyprsplit: per-monitor workspace tracks)
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mod .. " + " .. key,         hs.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hs.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. key,   hs.dsp.window.move({ workspace = i, follow = false }))
end

-- Resize submap
hl.bind(mod .. " + S", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Dwindle preselect submap
hl.bind(mod .. " + A", hl.dsp.submap("dwindle"))
hl.define_submap("dwindle", function()
    hl.bind("H", function()
        hl.dispatch(hl.dsp.layout("preselect l"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("J", function()
        hl.dispatch(hl.dsp.layout("preselect d"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("K", function()
        hl.dispatch(hl.dsp.layout("preselect u"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("L", function()
        hl.dispatch(hl.dsp.layout("preselect r"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Window rules (tag-setters first, then tag-consumers)
hl.window_rule({
    match = { class = "(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)" },
    tag = "+floating-window",
})

hl.window_rule({
    match = {
        class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)",
    },
    tag = "+floating-window",
})

hl.window_rule({
    match = {
        class = "(org.kde.dolphin)",
        initial_title = "^(Moving \u{2014} Dolphin)",
    },
    tag = "+floating-window",
})

hl.window_rule({
    match = { tag = "floating-window" },
    float = true,
    center = true,
    size = {800, 600},
})

hl.window_rule({
    match = { class = "(xdg-desktop-portal-gtk)" },
    float = true,
})

hl.window_rule({
    match = { class = "(code|org.gnome.Nautilus|org.kde.dolphin)" },
    opacity = "0.9 override 0.9 override",
})

hl.window_rule({
    match = {
        title = "^(Footprint Chooser.*)",
        class = "kicad",
        float = true,
    },
    size = {1411, 854},
    center = true,
})
