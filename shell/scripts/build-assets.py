#!/usr/bin/env python3
"""Stages game assets for the OVERWATCH shell from the user's own installs:
sounds (grouped by event), interface art, wallpapers, a cursor theme, the soundtrack.
Everything is written under ~/.local/share/overwatch, ~/Pictures, ~/Music and ~/.local/share/icons.
Run through the private venv after convert-textures.py. Sections: sounds ui cursors music (default: all).
"""
import glob, os, re, shutil, struct, subprocess, sys, warnings
warnings.simplefilter("ignore")
import vpk
from PIL import Image

HOME = os.path.expanduser("~")
DATA = HOME + "/.local/share/overwatch/"
GAME = HOME + "/.local/share/Steam/steamapps/common/Half-Life 2/"
TEX = DATA + "textures/"
want = set(sys.argv[1:]) or {"sounds", "ui", "cursors", "music"}

def vo_pack():
    # the vpk library mis-derives archive names containing "english"; use neutral symlinks
    d = DATA + "raw/vo/"; os.makedirs(d, exist_ok=True)
    for f in glob.glob(GAME + "hl2/hl2_sound_vo_english_*.vpk"):
        link = d + os.path.basename(f).replace("hl2_sound_vo_english_", "vo_")
        if not os.path.lexists(link): os.symlink(f, link)
    return vpk.open(d + "vo_dir.vpk")

# event -> sound paths (several = picked at random). Prefix "voice_" = spoken lines,
# "amb_" = ambience; both are skipped at the "effects only" sound level.
SOUNDS = {
    "notify":    ["npc/metropolice/vo/on1", "npc/metropolice/vo/on2", "npc/combine_soldier/vo/on1", "npc/combine_soldier/vo/on2", "npc/overwatch/radiovoice/on1", "npc/overwatch/radiovoice/on3"],
    "alert":     ["npc/scanner/scanner_siren1", "npc/scanner/scanner_alert1"],
    "open":      ["buttons/combine_button1", "buttons/combine_button3"],
    "close":     ["common/wpn_hudoff"],
    "hover":     ["ui/buttonrollover"],
    "click":     ["ui/buttonclickrelease"],
    "move":      ["common/wpn_moveselect"],
    "select":    ["common/wpn_select"],
    "deny":      ["buttons/combine_button_locked", "common/wpn_denyselect"],
    "workspace": ["buttons/combine_button7"],
    "step":      ["buttons/blip1"],
    "minimize":  ["npc/turret_floor/click1"],
    "maximize":  ["buttons/combine_button5"],
    "scan":      ["npc/scanner/scanner_photo1"],
    "lock":      ["ambient/levels/citadel/pod_close1"],
    "unlock":    ["ambient/levels/citadel/pod_open1"],
    "plug":      ["items/suitchargeok1"],
    "unplug":    ["items/suitchargeno1"],
    "lowpower":  ["ambient/alarms/klaxon1"],
    "login":     ["npc/overwatch/radiovoice/on3"],
    "amb_terminal": ["ambient/machines/combine_terminal_idle1", "ambient/machines/combine_terminal_idle2", "ambient/machines/combine_terminal_idle4"],
    "amb_lock":     ["ambient/machines/combine_shield_loop3"],
    "voice_login":  ["vo/breencast/br_welcome01", "vo/breencast/br_welcome02"],
    "voice_alert":  ["npc/overwatch/cityvoice/f_anticitizenreport_spkr", "npc/overwatch/cityvoice/f_protectionresponse_1_spkr"],
    "voice_lock":   ["npc/overwatch/cityvoice/f_confirmcivilstatus_1_spkr"],
}

if "sounds" in want:
    packs = [vpk.open(GAME + "hl2/hl2_sound_misc_dir.vpk"), vo_pack()]
    index = {}
    for p in packs:
        for n in p: index.setdefault(n.lower(), (p, n))
    out = DATA + "sounds/"; raw = DATA + "raw/"
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out); os.makedirs(raw, exist_ok=True)
    for event, paths in SOUNDS.items():
        i = 0
        for path in paths:
            hit = index.get(("sound/" + path + ".wav").lower())
            if not hit:
                print(f"  missing  {event:13} {path}"); continue
            tmp = raw + "tmp.wav"
            open(tmp, "wb").write(hit[0][hit[1]].read())
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-t", "20", "-c:a", "pcm_s16le", f"{out}{event}.{i}.wav"], check=True)
            i += 1
        print(f"  {event:13} {i} variant(s)")
    if os.path.exists(raw + "tmp.wav"): os.remove(raw + "tmp.wav")

# role -> converted texture (relative to textures/)
UI = {
    "panel_launcher": "displays/hl2_combinedisplay001a.png",
    "panel_alert":    "displays/hl2_combinedisplay001b.png",
    "panel_history":  "displays/hl2_combine_interface_disp.png",
    "panel_session":  "displays/hl2_masterinterface_disp.png",
    "lock_sign":      "displays/hl2_combine_display01a.png",
    "transmission_end": "displays/ez2_combinedisplay_transmission_end001a.png",
    "binoculars":     "hud/ez2_combine_binocoverlay.png",
    "spray":          "posters/hl2_lambdaspray_1a.png",
    "poster":         "posters/hl2_decal_posterbreen.png",
    "core_0": "displays/ep1_combinedisplay_core__f0.png", "core_1": "displays/ep1_combinedisplay_core__f1.png",
    "core_2": "displays/ep1_combinedisplay_core__f2.png", "core_3": "displays/ep1_combinedisplay_core__f3.png",
}
# Chapter images that show City 17, the Citadel or the Combine (the rest are forests, portraits, the logo)
CITY = {"hl2_chapter1", "hl2_chapter3", "hl2_chapter9", "hl2_chapter10", "hl2_chapter11", "hl2_chapter12", "hl2_chapter13",
        "episodic_chapter2", "episodic_chapter4"}       # episodic_chapter3 is a portrait of Alyx
# The four boot-splash backdrops (boot/plymouth/overwatch/bg0..3.png): station, checkpoint, Citadel
BOOT = ["hl2_chapter1", "hl2_chapter11", "hl2_chapter12", "hl2_chapter13"]
if "ui" in want:
    out = DATA + "ui/"; os.makedirs(out, exist_ok=True)
    for role, src in UI.items():
        if os.path.exists(TEX + src): shutil.copyfile(TEX + src, out + role + ".png"); print("  ui", role)
        else: print("  missing ui", role, src)
    for i, f in enumerate(sorted(glob.glob(TEX + "static/*noise*.png"))[:4]):
        shutil.copyfile(f, f"{out}static_{i}.png")
    # Backdrops: only City 17 / Combine scenes from the game's own chapter art.
    walls = HOME + "/Pictures/Wallpapers/hl2/"; os.makedirs(walls, exist_ok=True)
    extra = HOME + "/Pictures/Wallpapers/overwatch/"; os.makedirs(extra, exist_ok=True)
    names = []
    for f in sorted(glob.glob(TEX + "chapters/*.png")):
        name = os.path.basename(f).replace("anniv_", "")
        shutil.copyfile(f, walls + name)
        if name[:-4] in CITY: names.append(walls + name)
    # Community-map screenshots in ~/Pictures/Wallpapers/overwatch are not game art; they only
    # join the rotation when asked for (OW_EXTRA_BACKDROPS=1).
    if os.environ.get("OW_EXTRA_BACKDROPS") == "1":
        names += sorted(glob.glob(extra + "*.jpg") + glob.glob(extra + "*.png"))
    open(DATA + "wallpapers.txt", "w").write("\n".join(names) + "\n")
    splash = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "boot/plymouth/overwatch/")
    for i, name in enumerate(BOOT):
        src = TEX + "chapters/anniv_" + name + ".png"
        if not os.path.exists(src): src = TEX + "chapters/" + name + ".png"
        if not os.path.exists(src): print("  missing boot backdrop", name); continue
        img = Image.open(src).convert("RGB")
        k = max(1280 / img.width, 800 / img.height)          # cover 1280x800, then darken toward the base colour
        img = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
        x, y = (img.width - 1280) // 2, (img.height - 800) // 2
        img = Image.blend(img.crop((x, y, x + 1280, y + 800)), Image.new("RGB", (1280, 800), (10, 15, 20)), 0.58)
        img.save(f"{splash}bg{i}.png")
    print(f"  {len(BOOT)} boot-splash backdrops in {splash}")
    print(f"  {len(names)} backdrops in rotation ({len(CITY)} chapter scenes + {len(names) - len([n for n in names if n.startswith(walls)])} from {extra})")

# X cursor name -> (texture, hotspot rule, extra names)
CURSORS = {
    "left_ptr":   ("arrow", "tip", ["default", "arrow", "top_left_arrow", "context-menu", "help", "question_arrow", "left_ptr_help", "alias", "copy", "cell"]),
    "hand2":      ("hand", "top", ["pointer", "hand1", "hand", "pointing_hand", "openhand", "grab", "grabbing", "closedhand", "dnd-move", "dnd-copy"]),
    "xterm":      ("ibeam", "center", ["text", "ibeam", "vertical-text"]),
    "watch":      ("hourglass", "center", ["wait"]),
    "left_ptr_watch": ("waitarrow", "tip", ["progress", "half-busy"]),
    "crossed_circle": ("no", "center", ["not-allowed", "no-drop", "forbidden", "dnd-no-drop", "circle"]),
    "crosshair":  ("crosshair", "center", ["cross", "tcross"]),
    "fleur":      ("sizeall", "center", ["move", "all-scroll", "size_all"]),
    "size_fdiag": ("sizenwse", "center", ["nwse-resize", "nw-resize", "se-resize", "top_left_corner", "bottom_right_corner", "bd_double_arrow"]),
    "size_bdiag": ("sizenesw", "center", ["nesw-resize", "ne-resize", "sw-resize", "top_right_corner", "bottom_left_corner", "fd_double_arrow"]),
    "size_ver":   ("sizens", "center", ["ns-resize", "n-resize", "s-resize", "top_side", "bottom_side", "sb_v_double_arrow", "row-resize", "v_double_arrow", "split_v"]),
    "size_hor":   ("sizewe", "center", ["ew-resize", "e-resize", "w-resize", "left_side", "right_side", "sb_h_double_arrow", "col-resize", "h_double_arrow", "split_h"]),
    "sb_up_arrow": ("up", "top", ["up-arrow", "up_arrow"]),
}
if "cursors" in want:
    theme = HOME + "/.local/share/icons/HL2/"; cdir = theme + "cursors/"
    shutil.rmtree(theme, ignore_errors=True); os.makedirs(cdir)
    open(theme + "index.theme", "w").write("[Icon Theme]\nName=HL2\nComment=Half-Life 2 VGUI cursors (extracted from the local game install)\nInherits=Bibata-Modern-Ice\n")
    for name, (tex, rule, aliases) in CURSORS.items():
        src = Image.open(f"{TEX}cursors/hl2_{tex}.png").convert("RGBA")
        box = src.getbbox()
        a = src.getchannel("A").crop(box)
        if rule == "tip":   hx, hy = box[0] + 1, box[1] + 1
        elif rule == "top":
            row = [x for x in range(a.width) if a.getpixel((x, 1)) > 60] or [a.width // 2]
            hx, hy = box[0] + sum(row) // len(row), box[1] + 1
        else:               hx, hy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
        chunks = []
        for size in (24, 32, 48, 64):
            img = src.resize((size, size), Image.LANCZOS)
            px = bytearray()
            for r, g, b, al in img.getdata():        # premultiplied BGRA
                px += bytes((b * al // 255, g * al // 255, r * al // 255, al))
            head = struct.pack("<9I", 36, 0xFFFD0002, size, 1, size, size, hx * size // 64, hy * size // 64, 0)
            chunks.append((size, head + bytes(px)))
        pos = 16 + 12 * len(chunks)
        toc = b""
        for size, blob in chunks:
            toc += struct.pack("<3I", 0xFFFD0002, size, pos); pos += len(blob)
        with open(cdir + name, "wb") as f:
            f.write(b"Xcur" + struct.pack("<3I", 16, 0x10000, len(chunks)) + toc + b"".join(b for _, b in chunks))
        for alias in aliases:
            os.symlink(name, cdir + alias)
    # Hyprland prefers the hyprcursor format: convert the X cursors and carry the aliases over
    work = DATA + "raw/hyprcursor/"; shutil.rmtree(work, ignore_errors=True); os.makedirs(work)
    subprocess.run(["hyprcursor-util", "--extract", theme, "--output", work], check=True, capture_output=True)
    ext = work + "extracted_HL2/"
    man = open(ext + "manifest.hl").read()
    open(ext + "manifest.hl", "w").write(re.sub(r"(?m)^name = .*$", "name = HL2", man))
    for name, (tex, rule, aliases) in CURSORS.items():
        meta = ext + "hyprcursors/" + name + "/meta.hl"
        lines = [l for l in open(meta).read().splitlines() if not l.startswith("define_override")]
        open(meta, "w").write("\n".join(lines + [f"define_override = {a}" for a in aliases]) + "\n")
    subprocess.run(["hyprcursor-util", "--create", ext, "--output", work], check=True, capture_output=True)
    shutil.copyfile(work + "theme_HL2/manifest.hl", theme + "manifest.hl")
    shutil.copytree(work + "theme_HL2/hyprcursors", theme + "hyprcursors")
    print(f"  cursor theme HL2: {len(os.listdir(cdir))} X cursor names, {len(os.listdir(theme + 'hyprcursors'))} hyprcursor shapes in {theme}")

if "music" in want:
    out = HOME + "/Music/Half-Life 2/"
    n = 0
    for tag, rel in (("Half-Life 2", "hl2/hl2_sound_misc_dir.vpk"), ("Episode One", "episodic/ep1_pak_dir.vpk"), ("Episode Two", "ep2/ep2_pak_dir.vpk")):
        pack = vpk.open(GAME + rel)
        for name in sorted(pack):
            if not re.match(r"sound/music/[^/]+\.(mp3|wav)$", name): continue
            os.makedirs(out + tag, exist_ok=True)
            dst = out + tag + "/" + os.path.basename(name)
            if not os.path.exists(dst): open(dst, "wb").write(pack[name].read())
            n += 1
    print(f"  {n} soundtrack files in {out}")
