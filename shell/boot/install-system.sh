#!/usr/bin/env bash
# OVERWATCH system-wide pieces: login screen, boot splash, boot menu colours.
# Run with sudo. Undo with uninstall-system.sh. Safe to run again.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }
here="$(dirname "$(readlink -f "$0")")"
user="${SUDO_USER:-$(logname)}"; home="$(getent passwd "$user" | cut -d: -f6)"
data="$home/.local/share/overwatch"
[ -d "$data/textures/chapters" ] || { echo "Game assets not extracted yet: run scripts/extract-assets as $user first."; exit 1; }

echo "== Fonts, cursor theme and wallpapers for the login screen"
install -d /usr/share/fonts/overwatch /usr/share/overwatch/wallpapers
install -m644 "$data"/fonts/gordin-*.ttf "$data/fonts/UniversalUnion.ttf" /usr/share/fonts/overwatch/
fc-cache -f /usr/share/fonts/overwatch
rm -rf /usr/share/icons/HL2; cp -r "$home/.local/share/icons/HL2" /usr/share/icons/HL2; chown -R root:root /usr/share/icons/HL2
# the same curated City 17 / Combine set the desktop rotates through
find /usr/share/overwatch/wallpapers -maxdepth 1 -type f -name '*.png' -delete
while IFS= read -r f; do
    [ -f "$f" ] || continue
    out="/usr/share/overwatch/wallpapers/$(basename "${f%.*}").png"
    magick "$f" -resize 2560x1600^ -gravity center -extent 2560x1600 -fill '#0a0f14' -colorize 35% -strip "$out"
done < "$data/wallpapers.txt"
chmod -R a+rX /usr/share/overwatch

echo "== Random login backdrop each boot"
install -m644 "$here/overwatch-backdrop.service" /etc/systemd/system/overwatch-backdrop.service
systemctl daemon-reload
systemctl enable --now overwatch-backdrop.service

echo "== Login screen"
g=/var/lib/noctalia-greeter
owner=$(stat -c %U:%G "$g")
[ -f "$g/greeter.toml" ] && [ ! -f "$g/greeter.toml.pre-overwatch" ] && cp -a "$g/greeter.toml" "$g/greeter.toml.pre-overwatch"
install -m644 "$here/greeter.toml" "$g/greeter.toml"; chown "$owner" "$g/greeter.toml"

echo "== Boot splash"
install -d /usr/share/plymouth/themes/overwatch
install -m644 "$here"/plymouth/overwatch/* /usr/share/plymouth/themes/overwatch/
plymouth-set-default-theme -R overwatch

echo "== Boot menu"
if [ -f /boot/limine.conf ]; then
    [ -f "$here/limine/overwatch-limine.png" ] || "$here/limine/make-wallpaper" >/dev/null
    "$here/limine/apply-limine-theme"
else echo "   /boot/limine.conf not found, skipped"; fi

echo "Done. Reboot to see the boot menu, splash and login screen."
