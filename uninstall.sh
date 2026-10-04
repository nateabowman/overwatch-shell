#!/usr/bin/env bash
# Removes what install.sh put in place and restores the backups it made.
# The system pieces (boot menu, splash, login) are removed separately:
#   sudo ~/.config/quickshell/overwatch/boot/uninstall-system.sh     (run that FIRST)
set -uo pipefail
conf="${XDG_CONFIG_HOME:-$HOME/.config}"; data="${XDG_DATA_HOME:-$HOME/.local/share}"
qs -c overwatch kill 2>/dev/null
main="$conf/hypr/hyprland.lua"
[ -f "$main" ] && sed -i '/^-- OVERWATCH (remove this line to turn it all off)$/d; /^require("overwatch")$/d' "$main"
rm -rf "$conf/hypr/overwatch" "$conf/quickshell/overwatch"
[ -d "$conf/quickshell/overwatch.pre-overwatch" ] && mv "$conf/quickshell/overwatch.pre-overwatch" "$conf/quickshell/overwatch"
if [ -e "$conf/fastfetch/config.jsonc.pre-overwatch" ]; then mv "$conf/fastfetch/config.jsonc.pre-overwatch" "$conf/fastfetch/config.jsonc"
else rm -f "$conf/fastfetch/config.jsonc"; fi
rm -f "$conf/fastfetch/emblem.txt"
echo "Removed. Extracted game assets are still in $data/overwatch, ~/Music/Half-Life 2 and"
echo "~/Pictures/Wallpapers/hl2; delete those by hand if you want them gone. Reload Hyprland (hyprctl reload)."
