-- OVERWATCH keybinds. Every one calls scripts/owctl, which talks to the running shell.
-- If your own config already binds one of these keys, remove that bind or change this one:
-- Hyprland runs both.
local mainMod = "SUPER"
local ow = "~/.config/quickshell/overwatch/scripts/owctl "
local function sh(action, opts) return hl.dsp.exec_cmd(ow .. action), opts end

hl.bind(mainMod .. " + Space",       sh("launcher"))          -- application index
hl.bind(mainMod .. " + Tab",         sh("switcher"))          -- surveillance feeds (window switcher)
hl.bind(mainMod .. " + X",           sh("control"))           -- control interface (quick settings)
hl.bind(mainMod .. " + A",           sh("notifications"))     -- dispatch log
hl.bind(mainMod .. " + V",           sh("clipboard"))         -- clipboard records
hl.bind(mainMod .. " + period",      sh("emoji"))             -- glyph index
hl.bind(mainMod .. " + L",           sh("lock"))              -- seal sector
hl.bind(mainMod .. " + SHIFT + L",   sh("lock-test"))         -- trial lock, releases itself after 30s
hl.bind(mainMod .. " + ALT + C",     sh("session"))           -- lock / log out / suspend / reboot / shut down
hl.bind(mainMod .. " + SHIFT + W",   sh("wallpaper"))         -- next backdrop (previous: SUPER+CTRL+SHIFT+W, in stacking.lua)
hl.bind(mainMod .. " + SHIFT + O",   sh("scanlines"))
hl.bind(mainMod .. " + SHIFT + M",   sh("sounds"))            -- all sounds / effects only / silent
hl.bind("Print",                     sh("screenshot-region"))
hl.bind(mainMod .. " + Print",       sh("screenshot-full"))

hl.bind("XF86AudioRaiseVolume",  sh("volume-up",       { locked = true, repeating = true }))
hl.bind("XF86AudioLowerVolume",  sh("volume-down",     { locked = true, repeating = true }))
hl.bind("XF86AudioMute",         sh("volume-mute",     { locked = true }))
hl.bind("XF86AudioMicMute",      sh("mic-mute",        { locked = true }))
hl.bind("XF86AudioPlay",         sh("media toggle",    { locked = true }))
hl.bind("XF86AudioPause",        sh("media toggle",    { locked = true }))
hl.bind("XF86AudioNext",         sh("media next",      { locked = true }))
hl.bind("XF86AudioPrev",         sh("media previous",  { locked = true }))
hl.bind("XF86MonBrightnessUp",   sh("brightness-up",   { locked = true, repeating = true }))
hl.bind("XF86MonBrightnessDown", sh("brightness-down", { locked = true, repeating = true }))
