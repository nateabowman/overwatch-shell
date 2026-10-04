-- Stacking (floating) window management for OVERWATCH: windows overlap, can be
-- minimized, maximized and snapped. Remove the require in hyprland.lua to return to tiling.

local mainMod = "SUPER"
local win = "~/.config/quickshell/overwatch/scripts/owwin "

-- Every new window opens floating, centred on screen
hl.window_rule({ name = "ow-float-all", match = { class = ".*" }, float = true, center = true })

hl.config({
    input = {
        follow_mouse = 2,        -- click a window to focus it; hovering does not steal focus
    },
})

-- Minimize / restore / maximize
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd(win .. "minimize"))
hl.bind(mainMod .. " + SHIFT + N",   hl.dsp.exec_cmd(win .. "restore"))
hl.bind(mainMod .. " + ALT + Down",  hl.dsp.exec_cmd(win .. "minimize"))
hl.bind(mainMod .. " + ALT + Up",    hl.dsp.exec_cmd(win .. "maximize"))

-- Snap to halves and centre
hl.bind(mainMod .. " + ALT + Left",   hl.dsp.exec_cmd(win .. "snap left"))
hl.bind(mainMod .. " + ALT + Right",  hl.dsp.exec_cmd(win .. "snap right"))
hl.bind(mainMod .. " + ALT + Return", hl.dsp.exec_cmd(win .. "snap center"))

-- Alt+Tab also raises the window it lands on
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top())

-- Backdrops: SUPER+SHIFT+W is next (already bound in binds.lua); this one goes back
hl.bind(mainMod .. " + CONTROL + SHIFT + W", hl.dsp.exec_cmd("~/.config/quickshell/overwatch/scripts/owctl wallpaper-prev"))

-- Stealth: flip the whole desktop to a plain, silent work look and back
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/quickshell/overwatch/scripts/owctl stealth"))

-- Windows stick lightly to screen edges and to each other while being dragged
hl.config({
    general = {
        snap = { enabled = true, window_gap = 12, monitor_gap = 12 },
    },
})

-- Drag-to-edge snapping. On left-button press, remember where every window is; on
-- release, if the focused floating window has moved and the cursor is at a screen
-- edge, snap it: left/right = half, top = maximize, corners = quarter.
local owBefore = {}
local OW_EDGE = 12        -- px from a side edge
local OW_TOP = 46         -- px from the top (the shell bar is 34px tall)
local OW_BOTTOM = 50      -- px from the bottom (the taskbar is 38px tall)

local function owSnapPress()
    owBefore = {}
    for _, w in ipairs(hl.get_windows()) do
        owBefore[tostring(w.address)] = { x = w.at.x, y = w.at.y }
    end
end

function OW_snap_zone(cx, cy, mon)
    local mx, my = mon.x, mon.y
    local mw, mh = mon.width / mon.scale, mon.height / mon.scale
    local left   = cx <= mx + OW_EDGE
    local right  = cx >= mx + mw - OW_EDGE - 1
    local top    = cy <= my + OW_TOP
    local bottom = cy >= my + mh - OW_BOTTOM
    if top and left then return "tl" end
    if top and right then return "tr" end
    if bottom and left then return "bl" end
    if bottom and right then return "br" end
    if left then return "left" end
    if right then return "right" end
    if top then return "max" end
    return nil
end

local function owSnapRelease()
    local w = hl.get_active_window()
    if not w or not w.floating then return end
    local addr = tostring(w.address)
    local was = owBefore[addr]
    owBefore = {}
    if not was or (was.x == w.at.x and was.y == w.at.y) then return end   -- not dragged
    local c = hl.get_cursor_pos()
    local zone = OW_snap_zone(c.x, c.y, hl.get_active_monitor())
    if not zone then return end
    if zone == "max" then hl.exec_cmd(win .. "maximize " .. addr)
    else hl.exec_cmd(win .. "snap " .. zone .. " " .. addr) end
end

hl.bind("mouse:272", owSnapPress,   { non_consuming = true })
hl.bind("mouse:272", owSnapRelease, { non_consuming = true, release = true })

-- Stay awake: no dimming, locking or sleeping while on
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("~/.config/quickshell/overwatch/scripts/owctl caffeine"))
