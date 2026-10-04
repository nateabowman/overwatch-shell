#!/usr/bin/env bash
# Installs the OVERWATCH shell for the current user. Nothing here needs root.
#   ./install.sh            copy the shell, the Hyprland snippets and the fastfetch look, then
#                           pull the game assets out of your Steam install
#   ./install.sh --wire     also add  require("overwatch")  to ~/.config/hypr/hyprland.lua
#   ./install.sh --no-assets   skip the game-asset step (run scripts/extract-assets later)
# Existing files are backed up next to themselves with a .pre-overwatch suffix.
set -euo pipefail
here="$(dirname "$(readlink -f "$0")")"
conf="${XDG_CONFIG_HOME:-$HOME/.config}"
wire=0; assets=1
for a in "$@"; do case "$a" in --wire) wire=1 ;; --no-assets) assets=0 ;; *) sed -n '2,8p' "$0"; exit 1 ;; esac; done

say() { printf '\033[36m== %s\033[0m\n' "$*"; }
keep() { [ -e "$1" ] && [ ! -e "$1.pre-overwatch" ] && cp -a "$1" "$1.pre-overwatch" && echo "   backed up $1"; return 0; }

say "checking what is installed"
missing=()
for t in qs hyprctl jq pw-play wl-copy cliphist grim slurp brightnessctl nmcli magick ffmpeg python3; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
[ ${#missing[@]} -eq 0 ] || echo "   not found: ${missing[*]}  (see TUTORIAL.md, 'Packages'; the shell runs without some of these, with features missing)"
command -v qs >/dev/null 2>&1 || { echo "Quickshell (qs) is required."; exit 1; }

say "shell -> $conf/quickshell/overwatch"
if [ -d "$conf/quickshell/overwatch" ] && [ ! -d "$conf/quickshell/overwatch.pre-overwatch" ]; then
    cp -a "$conf/quickshell/overwatch" "$conf/quickshell/overwatch.pre-overwatch"; echo "   backed up the existing one"
fi
mkdir -p "$conf/quickshell/overwatch"
cp -a "$here/shell/." "$conf/quickshell/overwatch/"

say "Hyprland snippets -> $conf/hypr/overwatch"
mkdir -p "$conf/hypr/overwatch"
cp -a "$here/hypr/." "$conf/hypr/overwatch/"
main="$conf/hypr/hyprland.lua"
if [ "$wire" = 1 ]; then
    [ -f "$main" ] || { echo "   $main not found: this needs Hyprland's Lua config (0.56+)."; exit 1; }
    if grep -q 'require("overwatch")' "$main"; then echo "   already wired"
    else keep "$main"; printf '\n-- OVERWATCH (remove this line to turn it all off)\nrequire("overwatch")\n' >> "$main"; echo "   added require(\"overwatch\") to $main"; fi
else
    echo "   not wired in. Add this line at the end of $main, or re-run with --wire:"
    echo '       require("overwatch")'
fi

say "terminal readout -> $conf/fastfetch"
mkdir -p "$conf/fastfetch"; keep "$conf/fastfetch/config.jsonc"
cp -a "$here/fastfetch/config.jsonc" "$conf/fastfetch/config.jsonc"

if [ "$assets" = 1 ]; then
    say "game assets (from your own Half-Life 2 install)"
    "$conf/quickshell/overwatch/scripts/extract-assets" || echo "   asset step failed: the shell still runs, without game art, sounds or the emblem. Fix the cause and run scripts/extract-assets."
fi

say "done"
echo "   start it now:      qs -c overwatch -d        (or log out and back in if you used --wire)"
echo "   boot + login look: sudo $conf/quickshell/overwatch/boot/install-system.sh   (optional, see TUTORIAL.md)"
