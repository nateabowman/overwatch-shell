-- OVERWATCH for Hyprland (Lua config, Hyprland 0.56+). Add ONE line at the very end of
-- ~/.config/hypr/hyprland.lua:
--
--     require("overwatch")
--
-- Comment out any part you do not want.
require("overwatch.autostart")   -- start the shell
require("overwatch.binds")       -- keybinds for the shell's panels
require("overwatch.look")        -- borders, blur, animations, stealth look (keep after your own look settings)
require("overwatch.stacking")    -- floating windows with snap / minimize / maximize; remove to keep tiling
require("overwatch.titlebars")   -- title bars; does nothing unless the hyprbars plugin is installed
