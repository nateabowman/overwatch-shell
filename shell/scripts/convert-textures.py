#!/usr/bin/env python3
"""Converts selected Source-engine textures (VTF) from the user's own game
installs to PNG under ~/.local/share/overwatch/textures/<group>/.
Run through the private venv: ~/.local/share/overwatch/venv/bin/python convert-textures.py
"""
import io, os, re, sys, warnings
warnings.simplefilter("ignore")
import vpk
from srctools.vtf import VTF

STEAM = os.path.expanduser("~/.local/share/Steam/steamapps/common/")
DATA = os.path.expanduser("~/.local/share/overwatch/textures/")
PACKS = [
    ("hl2",  "Half-Life 2/hl2/hl2_textures_dir.vpk"),
    ("hl2",  "Half-Life 2/hl2/hl2_misc_dir.vpk"),
    ("ep1",  "Half-Life 2/episodic/ep1_pak_dir.vpk"),
    ("ep2",  "Half-Life 2/ep2/ep2_pak_dir.vpk"),
    ("anniv", "Half-Life 2/hl2_complete/hl2_complete_misc_dir.vpk"),
    ("ez2",  "EntropyZero2/entropyzero2/ez2/ez2_dir.vpk"),
]
# group -> (regex on the path inside the pack, max frames to keep)
GROUPS = {
    "backgrounds": (r"^materials/console/.*(background|bg_).*\.vtf$", 1),
    "chapters":    (r"^materials/gamepadui/(hl2|episodic|ep2|lostcoast)/chapter\w+\.vtf$", 1),
    "displays":    (r"^materials/(effects/combinedisplay|effects/c17_07camera|props/combine_display|scripted/breen_fakemonitor|models/props_combine/(combine_interface_disp|masterinterface_(disp|alert)|combine_monitorbay_disp|combine_intmonitor001_disp)|models/combine_room/combine_monitor00[12]\.)", 4),
    "static":      (r"^materials/effects/(breenscreen_static|tvscreen_noise|security_noise)", 4),
    "cursors":     (r"^materials/vgui/cursors/", 1),
    "hud":         (r"^materials/(sprites/(640hud\d|640_logo|w_icons\d|a_icons1|hud1)\.|vgui/hud/(800corner\d?|icon_)|sprites/hud/800corner|effects/combine_binocoverlay|vgui/hud/hackicon)", 1),
    "posters":     (r"^materials/(decals/(decal_poster|lambdaspray|decal_combine)|props/paperposter|vgui/logos/spray)", 1),
    "menu":        (r"^materials/(vgui/(appchooser/(hl2|episodic|ep2|background_hl2)|gamepadui/[^/]*(logo|title|hl2)[^/]*|[^/]*(logo|title)[^/]*)|console/(startup_loading|loading|intro))", 1),
}
only = set(sys.argv[1:])
for group, (pat, maxframes) in GROUPS.items():
    if only and group not in only:
        continue
    out = os.path.join(DATA, group); os.makedirs(out, exist_ok=True)
    rx = re.compile(pat)
    for tag, rel in PACKS:
        path = STEAM + rel
        if not os.path.exists(path):
            continue
        pack = vpk.open(path)
        for name in sorted(pack):
            if not name.endswith(".vtf") or not rx.search(name):
                continue
            base = tag + "_" + (name.split("/")[-2] + "_" if group == "chapters" else "") + os.path.basename(name)[:-4]
            try:
                tex = VTF.read(io.BytesIO(pack[name].read()))
                frames = min(tex.frame_count, maxframes)
                step = max(1, tex.frame_count // frames)
                for i in range(frames):
                    f = tex.get(frame=i * step)
                    f.load()
                    img = f.to_PIL()
                    img.save(os.path.join(out, base + (f"_f{i}" if frames > 1 else "") + ".png"))
                print(f"{group:11} {base:46} {tex.width}x{tex.height} frames={tex.frame_count} {tex.format.name}")
            except Exception as e:
                print(f"{group:11} {base:46} FAILED {type(e).__name__}: {e}")
