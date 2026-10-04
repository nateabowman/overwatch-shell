-- OVERWATCH look and feel. Loaded last so it overrides the CachyOS defaults in
-- decorations.lua / animations.lua. Remove the require in hyprland.lua to go back.

OW_TEAL   = "rgba(5fd7e8ff)"
OW_TEALDK = "rgba(1f6f7dff)"
OW_WHITE  = "rgba(e6f6faff)"
OW_STEEL  = "rgba(26323dcc)"
OW_VOID   = "rgba(0a0f14ff)"
OW_AMBER  = "rgba(ffb347ff)"

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = {
                colors = { OW_WHITE, OW_TEAL, OW_TEALDK },
                angle = 90,
            },
            inactive_border = OW_STEEL,
        },
    },
    group = {
        col = {
            border_active = OW_TEAL,
            border_inactive = OW_STEEL,
            border_locked_active = OW_AMBER,
            border_locked_inactive = OW_STEEL,
        },
        groupbar = {
            col = {
                active = OW_TEAL,
                inactive = OW_STEEL,
                locked_active = OW_AMBER,
                locked_inactive = OW_STEEL,
            },
        },
    },
    decoration = {
        rounding = 0,
        active_opacity = 0.96,
        inactive_opacity = 0.93,
        fullscreen_opacity = 1,
        dim_inactive = true,
        dim_strength = 0.08,
        dim_special = 0.4,
        blur = {
            size = 7,
            passes = 3,
            noise = 0.04,
            contrast = 1.1,
            brightness = 0.75,
            vibrancy = 0.25,
            special = true,
        },
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(5fd7e838)",
            color_inactive = "rgba(00000000)",
        },
    },
    misc = {
        col = {
            splash = OW_TEAL,
        },
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = OW_VOID,
    },
})

-- Snap-in motion: quick, hard stops, no bounce.
hl.curve("owSnap",   { type = "bezier", points = { {0.16, 1},   {0.3, 1}   } })
hl.curve("owCut",    { type = "bezier", points = { {0.7, 0},    {0.84, 0}  } })
hl.curve("owLinear", { type = "bezier", points = { {0, 0},      {1, 1}     } })

hl.animation({ leaf = "global",              enabled = true, speed = 2,   bezier = "owSnap" })
hl.animation({ leaf = "windowsIn",           enabled = true, speed = 2.5, bezier = "owSnap", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 1.5, bezier = "owCut",  style = "popin 96%" })
hl.animation({ leaf = "windowsMove",         enabled = true, speed = 2.5, bezier = "owSnap", style = "slide" })
hl.animation({ leaf = "fade",                enabled = true, speed = 2,   bezier = "owSnap" })
hl.animation({ leaf = "border",              enabled = true, speed = 4,   bezier = "owLinear" })
hl.animation({ leaf = "borderangle",         enabled = false })
hl.animation({ leaf = "layers",              enabled = true, speed = 2,   bezier = "owSnap", style = "fade" })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 3,   bezier = "owSnap", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2,   bezier = "owSnap", style = "slidefadevert -12%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2,   bezier = "owCut",  style = "slidefadevert -12%" })

-- Shell surfaces. The shell animates its own panels, so Hyprland stays out of the way.
hl.layer_rule({
    name = "overwatch-blur",
    match = { namespace = "^overwatch-(bar|panel|notify|osd)$" },
    no_anim = true,
    ignore_alpha = 0.35,
    blur = true,
    blur_popups = true,
})
hl.layer_rule({
    name = "overwatch-passive",
    match = { namespace = "^overwatch-(overlay|wallpaper)$" },
    no_anim = true,
})

-- Stealth (work) look: plain borders, no glow, no dimming. Applied when the marker
-- file exists; `owctl stealth` creates/removes it. Leaving stealth is a config reload.
function OW_stealth()
    hl.config({
        general = {
            gaps_in = 4,
            gaps_out = 8,
            col = {
                active_border = "rgba(6ea8dcff)",
                inactive_border = "rgba(3b424bff)",
            },
        },
        decoration = {
            rounding = 6,
            active_opacity = 1,
            inactive_opacity = 1,
            dim_inactive = false,
            shadow = { range = 10, render_power = 3, color = "rgba(00000066)", color_inactive = "rgba(00000033)" },
        },
    })
end
local owMarker = io.open(os.getenv("HOME") .. "/.local/state/overwatch/stealth", "r")
if owMarker then owMarker:close(); OW_stealth() end
