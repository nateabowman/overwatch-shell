#!/usr/bin/env bash
# Removes everything install-system.sh put in place. Run with sudo.
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }
systemctl disable --now overwatch-backdrop.service 2>/dev/null
rm -f /etc/systemd/system/overwatch-backdrop.service; systemctl daemon-reload
g=/var/lib/noctalia-greeter
if [ -f "$g/greeter.toml.pre-overwatch" ]; then mv "$g/greeter.toml.pre-overwatch" "$g/greeter.toml"; else rm -f "$g/greeter.toml"; fi
# Only the appearance lines go back: a whole-file backup would carry stale kernel hashes.
"$(dirname "$(readlink -f "$0")")/limine/apply-limine-theme" --revert 2>/dev/null || true
plymouth-set-default-theme -R cachyos
rm -rf /usr/share/plymouth/themes/overwatch /usr/share/overwatch /usr/share/fonts/overwatch /usr/share/icons/HL2
fc-cache -f
echo "OVERWATCH system pieces removed."
