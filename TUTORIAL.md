# Setting up OVERWATCH, step by step

This takes about fifteen minutes. Steps 1 to 4 need no root and are easy to undo. Step 6
changes your boot menu, boot splash and login screen and is optional.

Tested on CachyOS with Hyprland 0.56.2 only. Package names below are for Arch-based
systems; on other distros install the same programs by their own names.

## 1. Check the basics

    hyprctl version          # 0.56 or newer
    ls ~/.config/hypr/hyprland.lua    # the Lua config must exist
    qs --version             # Quickshell 0.3 or newer
    ls ~/.local/share/Steam/steamapps/common/"Half-Life 2"/hl2

If your Hyprland still uses `hyprland.conf`, this will not work as it stands: the Hyprland
side is written for the Lua config.

Half-Life 2 has to be in the default Steam library (`~/.local/share/Steam`). If yours is
elsewhere, symlink it there or edit the paths at the top of `shell/scripts/extract-assets`,
`build-assets.py` and `convert-textures.py`.

## 2. Packages

Required:

    sudo pacman -S quickshell jq pipewire wireplumber wl-clipboard cliphist grim slurp \
        brightnessctl networkmanager imagemagick ffmpeg python python-virtualenv hyprcursor \
        kitty ttf-meslo-nerd

Used by parts of the shell (it runs without them, minus that feature):

| Package | For |
| --- | --- |
| `bluez-utils` | Bluetooth switch and device list |
| `power-profiles-daemon` | power profile buttons |
| `swash` | screenshot editor after a capture |
| `btop` | opens when you click the CPU / MEM / GPU readouts |
| `fastfetch` | the themed terminal readout |
| `hyprland-plugin-hyprbars` (AUR) | window title bars; without it the buttons sit in the top bar |
| `hyprpolkitagent` | password prompts for apps |
| `noctalia` | the emoji list (`/usr/share/noctalia/assets/emoji.json`) and `scripts/apply-system-theme`, which recolours GTK and Qt apps to match |

Fonts: the game's own menu font (GorDIN) is copied from your install in step 3. The shell
also uses **Share Tech Mono** for numbers and falls back to **Rajdhani** for labels; both are
free on Google Fonts. Drop the `.ttf` files in `~/.local/share/fonts` and run `fc-cache -f`.

## 3. Install the shell

    git clone https://github.com/nateabowman/overwatch-shell
    cd overwatch-shell
    ./install.sh

What it does:

1. copies `shell/` to `~/.config/quickshell/overwatch`
2. copies `hypr/` to `~/.config/hypr/overwatch`
3. installs the fastfetch look (your old config is kept as `config.jsonc.pre-overwatch`)
4. runs `scripts/extract-assets`, which reads your Half-Life 2 files and writes:
   - sounds, interface art and fonts to `~/.local/share/overwatch`
   - the chapter art to `~/Pictures/Wallpapers/hl2` (the City 17 ones go into the backdrop rotation)
   - a cursor theme called `HL2` to `~/.local/share/icons`
   - the soundtrack to `~/Music/Half-Life 2` (for the radio)
   - the emblem (`assets/claw.svg`, the boot splash logo, the terminal art)

The asset step takes a couple of minutes the first time (it sets up a small Python
environment and converts textures).

Try it before wiring it in:

    qs -c overwatch

A bar should appear at the top and a taskbar at the bottom. `Ctrl+C` stops it.

## 4. Wire it into Hyprland

Add one line at the **end** of `~/.config/hypr/hyprland.lua` (or run `./install.sh --wire`,
which does exactly this and keeps a backup):

    require("overwatch")

That loads `~/.config/hypr/overwatch/init.lua`, which pulls in five parts. Open it and
comment out what you do not want:

| Part | What it does |
| --- | --- |
| `autostart` | starts the shell with Hyprland |
| `binds` | keybinds for the shell's panels |
| `look` | borders, blur, shadows, animations, and the stealth look |
| `stacking` | every window floats; snap, minimize, maximize; drag to an edge to snap |
| `titlebars` | title bars with close / maximize / minimize (needs the hyprbars plugin) |

Two things to do by hand:

- **Stop your old bar and notification daemon** (waybar, mako, dunst, another shell).
  Remove them from your autostart or you get two bars and two sets of notifications.
- **Remove your own binds for the same keys.** Hyprland runs every bind on a key, so if
  `SUPER+Space` already opens another launcher, both will open.

Then reload: `hyprctl reload`, or log out and back in.

To use the game cursor: `hyprctl setcursor HL2 32` (add `hl.env("HYPRCURSOR_THEME", "HL2")`
and `hl.env("HYPRCURSOR_SIZE", "32")` to your config to keep it).

## 5. Keys

| Key | Action |
| --- | --- |
| `SUPER+Space` | launcher |
| `SUPER+Tab` | window switcher |
| `SUPER+X` | control panel |
| `SUPER+A` | notification history |
| `SUPER+V` / `SUPER+.` | clipboard history / emoji |
| `SUPER+L` | lock |
| `SUPER+SHIFT+L` | trial lock: unlocks by itself after 30 seconds, for testing |
| `SUPER+ALT+C` | session menu (lock, log out, suspend, reboot, shut down) |
| `SUPER+B` | stealth mode on / off |
| `SUPER+SHIFT+W` / `SUPER+CTRL+SHIFT+W` | next / previous backdrop |
| `SUPER+SHIFT+O` | scanlines on / off |
| `SUPER+SHIFT+M` | sounds: all, effects only, silent |
| `SUPER+SHIFT+C` | stay awake |
| `SUPER+N` / `SUPER+SHIFT+N` | minimize / restore |
| `SUPER+ALT+Up` | maximize |
| `SUPER+ALT+Left` / `Right` / `Return` | snap left / right / centre |
| `Print` / `SUPER+Print` | screenshot region / full screen |

**Test the lock with `SUPER+SHIFT+L` first.** It is the same lock screen with a 30-second
escape hatch, so a problem with your PAM setup cannot lock you out.

## 6. Boot menu, splash and login screen (optional, root)

    sudo ~/.config/quickshell/overwatch/boot/install-system.sh

This is the part most tied to one distro. It expects:

- **Limine** as the boot loader, with its config at `/boot/limine.conf`
- **Plymouth** for the boot splash (it rebuilds your initramfs)
- **greetd with noctalia-greeter** for the login screen

What it changes, and how to undo each:

| Piece | Change | Undo |
| --- | --- | --- |
| Boot menu | replaces only the appearance lines at the top of `/boot/limine.conf`; your boot entries are not touched; a full copy is saved as `limine.conf.pre-overwatch-theme` | `sudo boot/limine/apply-limine-theme --revert` |
| Boot splash | installs a Plymouth theme and makes it the default | `sudo plymouth-set-default-theme -R <your old theme>` |
| Login screen | writes `/var/lib/noctalia-greeter/greeter.toml` (old one kept as `.pre-overwatch`) | restore that file |
| Login backdrop | a small service picks a random City 17 image each boot | `sudo systemctl disable --now overwatch-backdrop.service` |

`sudo boot/uninstall-system.sh` undoes all four.

If you do not use one of those three programs, skip this step or run only the piece you
have: the boot menu part is `boot/limine/apply-limine-theme` on its own.

**Before you reboot**, make sure you have a way back in if the boot menu misbehaves (a live
USB, or a snapshot entry). The change is small, but it is your boot loader.

## 7. Making it yours

- **Colours, fonts, sizes**: `core/Theme.qml`. The shell reloads as soon as you save.
- **Backdrops**: the rotation is `~/.local/share/overwatch/wallpapers.txt`, one image path
  per line. The control panel's BACKDROP chip switches between random, rotate and fixed.
- **Which sound plays for what**: the `SOUNDS` table in `scripts/build-assets.py`, then
  `scripts/extract-assets sounds`.
- **Apps that should not get a title bar**: `nobar.txt` (one regular expression).
- **Idle times** (dim, lock, screen off, sleep): top of `services/Idle.qml`.
- **Keyboard backlight**: `scripts/owkbd` drives one specific laptop keyboard (Gigabyte
  AERO X16). On anything else it does nothing; ignore or delete it.

## Troubleshooting

- **No bar appears**: run `qs -c overwatch` in a terminal and read the errors. A missing
  QML module means Quickshell is too old.
- **No art, no sounds, a blank square for the emblem**: the asset step did not finish. Run
  `~/.config/quickshell/overwatch/scripts/extract-assets` and read
  `~/.local/share/overwatch/textures.log`.
- **No title bars**: install `hyprland-plugin-hyprbars`, built for your exact Hyprland
  version. After every Hyprland update it has to be rebuilt.
- **Hyprland crashes on start after an edit**: never load a plugin from inside the Lua
  config; `titlebars.lua` loads it from a start hook for that reason.
- **Text looks plain**: the fonts are missing. `fc-list | grep -i -E "gordin|share tech"`.
- **Everything is too big or small**: the layout assumes a HiDPI panel at about 1.6x scale.
  Change your monitor scale, or the sizes in `core/Theme.qml`.
- **Turn it all off**: remove `require("overwatch")` from `hyprland.lua` and reload.
