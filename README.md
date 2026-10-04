# OVERWATCH

A Half-Life 2 Combine desktop for Linux: a full shell for Hyprland written in Quickshell,
plus a matching boot menu, boot splash, login screen and lock screen.

**Demo video:** <!-- paste the YouTube link here -->

It does not ship any Valve content. Art, sounds, fonts and the soundtrack are copied out of
**your own** Half-Life 2 install, on your machine, by a script.

## What you get

- **Top bar**: workspaces ("sectors"), focused window, tray, CPU / memory / GPU telemetry
  with hover cards, network, volume, battery, clock
- **Launcher** with search, plus clipboard history and emoji picker in the same panel
- **Floating windows** with title bars, snap to halves and quarters, minimize, maximize, a
  taskbar, and a window switcher that shows live previews
- **Control panel**: volume, brightness, Wi-Fi, Bluetooth, do not disturb, stay awake,
  power profile, and a radio that plays the game soundtrack
- **Notifications** with a history panel; critical ones get the alert siren
- **Lock screen** (PAM), an idle "broadcast" screen before it locks, and a session menu
- **Game sounds** for nearly everything, with Overwatch dispatch voice lines (three levels:
  all, effects only, silent)
- **Stealth mode** (`SUPER+B`): the whole desktop turns into a plain, silent, ordinary-looking
  shell for work, and back
- **Boot menu, boot splash, login screen** in the same style (optional, needs root)

## Requirements

- Linux with **Hyprland 0.56 or newer using the Lua config** (`~/.config/hypr/hyprland.lua`)
- **Quickshell** 0.3 or newer
- **Half-Life 2** installed through Steam (the 20th-anniversary build, which includes both
  episodes). Entropy Zero 2 (free on Steam) is optional and adds the Combine-alphabet font.

Built and tested on one machine: CachyOS (Arch), Hyprland 0.56.2, Quickshell 0.3.1, a
2560x1600 laptop panel. Other setups may need adjusting.

## Install

    git clone https://github.com/nateabowman/overwatch-shell
    cd overwatch-shell
    ./install.sh --wire

Then log out and back in. Full walkthrough, package list, keybinds and troubleshooting:
**[TUTORIAL.md](TUTORIAL.md)**.

## Remove

    sudo ~/.config/quickshell/overwatch/boot/uninstall-system.sh   # only if you installed the boot/login pieces
    ./uninstall.sh

## Licence and credits

Code: MIT (see [LICENSE](LICENSE)). Half-Life, the Combine and all game content belong to
Valve; this is an unofficial fan project. The emblem is the Combine "claw", redrawn from the
in-game propaganda posters.
