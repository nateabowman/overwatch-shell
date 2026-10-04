# OVERWATCH demo reel

`owdemo` records the theme with OBS, one segment at a time, and `owdemo build` cuts the
segments into one captioned video. Everything lands in `~/Videos/overwatch-demo/`.

    owdemo check                  what is ready
    owdemo boot | login | desktop | lock | stealth | all
    owdemo build [--scale 1920] [--only 03-desktop,04-lock] [--no-captions]

Each segment can be re-recorded on its own. `raw/<segment>.tl` holds its cut points and
captions as plain text; edit it and build again to move a cut or reword a caption.

## How each part is captured

- **Boot menu and splash**: the machine's real Limine binary, `limine.conf`, kernel and
  initramfs, booted in a QEMU window with no disk attached. What plays is the real menu and
  the real Plymouth theme; the wait between them (kernel load, Plymouth's device timeout)
  is cut out.
- **Login screen**: the real `noctalia-greeter` with `boot/greeter.toml`, in a nested
  window. `fake-greetd.py` answers in place of greetd so the greeter runs outside a real
  login; it accepts anything and starts nothing.
- **Desktop, lock, stealth**: the live session, driven through the shell's IPC.

The lock segment uses the trial lock (releases itself after 30s). The "wrong credential"
moment is the shell's `lockDenyPreview` IPC call, which plays the rejection without asking
PAM, so nothing counts toward faillock.

The taskbar and switcher list windows from every workspace, so while a take records,
windows that were already open are left out of both (`$XDG_RUNTIME_DIR/overwatch-hidden`,
read by `services/Windows.qml`). A notification arriving mid-take still shows. The tour clears the
notification history when it starts and puts back volume, brightness profile, backdrop,
sound level and the other settings it touches when it ends.

Keys go in two ways: `wtype` for the shell's own panels, and Hyprland's `send_shortcut`
for the nested login screen (a nested compositor cannot read wtype's private keymap).

## Boot menu theme

`boot/limine/apply-limine-theme` (run by `boot/install-system.sh`) replaces only the
appearance lines at the top of `/boot/limine.conf`; `--revert` puts the old ones back.
`boot/limine/make-wallpaper` rebuilds the wallpaper. Try changes with `--dir` on a copy
and boot that copy in the VM before applying them to `/boot`.

## Boot image

`vm/esp.img` is a FAT image of the boot files. `/boot` is root-only, so rebuilding it
after a kernel or theme update takes one privileged copy:

    d=~/Videos/overwatch-demo/vm; m=$(cat /etc/machine-id); mkdir -p $d/esp/EFI/BOOT $d/esp/$m/linux-cachyos
    pkexec sh -c "cp /boot/EFI/BOOT/BOOTX64.EFI $d/esp/EFI/BOOT/ && cp /boot/limine.conf /boot/limine-splash.png $d/esp/ \
        && cp /boot/$m/linux-cachyos/vmlinuz /boot/$m/linux-cachyos/initramfs $d/esp/$m/linux-cachyos/ && chown -R $USER: $d"
    truncate -s 400M $d/esp.img && mformat -i $d/esp.img -F :: && mcopy -s -i $d/esp.img $d/esp/* :: && rm -r $d/esp

## OBS

Profile and scene collection are both named `Overwatch`: 2560x1600, 60 fps, NVENC, desktop
audio, no microphone. `obsctl.py` drives OBS over obs-websocket using the password in OBS's
own config. The screen source has to be picked once from the OBS window (a source added
over the websocket never opens the picker).

## What a take changes on screen

Only while a segment records (all undone when it ends, or on Ctrl+C):
- windows that were already open are left out of the taskbar and switcher
- Wi-Fi and Bluetooth names show as `C17-...` / `UNIT-..` stand-ins (`$XDG_RUNTIME_DIR/overwatch-demo-mask`)
- the login screen and the fastfetch window show `CP-UNIT-17` (set `OWDEMO_LOGIN_NAME` for another)
- btop runs without its process list, whose user column shows the login name; its network
  panel still shows the machine's LAN address
- lock and stealth run on an empty workspace with the demo's own windows

The title cards carry the claw from `assets/claw.svg`; `--title` / `--outro` change the text.
