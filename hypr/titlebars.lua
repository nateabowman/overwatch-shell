-- Title bars (hyprbars plugin) for windows that do not draw their own.
-- Install / rebuild after a Hyprland update:  paru -S hyprland-plugin-hyprbars
-- Without the plugin this file does nothing and the shell shows window buttons in its top bar.

local home = os.getenv("HOME")
local plugin = "/usr/lib/libhyprbars.so"
local marker = home .. "/.local/state/overwatch/titlebars"   -- tells the shell a bar exists, and its height
local BAR = 26

local f = io.open(plugin, "r")
if not f then os.remove(marker); return end
f:close()

-- Never load the plugin from inside the config: loading re-reads the config while it is
-- still being read, which crashes Hyprland. Load it once the compositor is up; that
-- triggers a reload, and on that second pass the plugin is present and gets configured.
if not hl.plugin.hyprbars then
    os.remove(marker)
    hl.on("hyprland.start", function() hl.exec_cmd("hyprctl plugin load " .. plugin) end)
    return
end

local win = "~/.config/quickshell/overwatch/scripts/owwin "

local function look(stealth)
    hl.config({
        plugin = {
            hyprbars = {
                enabled = true,
                bar_height = BAR,
                bar_color = stealth and "rgba(2a3038ff)" or "rgba(0d141bf2)",
                col = { text = stealth and "rgba(d9dde2ff)" or "rgba(9be8f2ff)" },
                bar_text_font = stealth and "Adwaita Sans" or "GorDIN",
                bar_text_size = 11,
                bar_text_align = "left",
                bar_buttons_alignment = "right",
                bar_part_of_window = true,
                bar_precedence_over_border = true,
                bar_padding = 10,
                bar_button_padding = 6,
                on_double_click = win .. "maximize",
            },
        },
    })
end
look(false)

-- Buttons, right to left: close, maximize, minimize
if hl.plugin.hyprbars.add_button then
    hl.plugin.hyprbars.add_button({ bg_color = "rgba(ff5a4f40)", fg_color = "rgba(ffffffff)", size = 15, icon = "✕", action = win .. "close" })
    hl.plugin.hyprbars.add_button({ bg_color = "rgba(ffffff14)", fg_color = "rgba(e6f6faff)", size = 15, icon = "□", action = win .. "maximize" })
    hl.plugin.hyprbars.add_button({ bg_color = "rgba(ffffff14)", fg_color = "rgba(e6f6faff)", size = 15, icon = "–", action = win .. "minimize" })
end

-- Apps that draw their own title bar get none from us. One regex, shared with the shell.
local nf = io.open(home .. "/.config/quickshell/overwatch/nobar.txt", "r")
local nobar = nf and nf:read("l") or "^$"
if nf then nf:close() end
hl.window_rule({ name = "ow-nobar-apps", match = { class = nobar }, ["hyprbars:no_bar"] = true })
hl.window_rule({ name = "ow-nobar-unnamed", match = { class = "^$" }, ["hyprbars:no_bar"] = true })

local mf = io.open(marker, "w")
if mf then mf:write(tostring(BAR)); mf:close() end

-- Stealth also restyles the bars
local base = OW_stealth
function OW_stealth() base(); look(true) end
local sm = io.open(home .. "/.local/state/overwatch/stealth", "r")
if sm then sm:close(); look(true) end
