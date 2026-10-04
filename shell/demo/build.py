#!/usr/bin/env python3
"""Cut the recorded segments into one captioned video.

    build.py <demo dir> [--scale WIDTH] [--no-captions] [--only 01-boot,03-desktop] [--name NAME]

Reads raw/<segment>.mkv and raw/<segment>.tl (written by owdemo). A .tl line is
`seconds<TAB>kind<TAB>text`: keep_on/keep_off bracket the parts to keep, and a cue is a
caption shown until the next cue. Edit a .tl by hand to move a cut or reword a caption,
then build again; nothing is re-recorded.
"""
import argparse, os, subprocess, sys, tempfile

FONT = next((f for f in ("/usr/share/fonts/overwatch/gordin-bold.ttf",
                         os.path.expanduser("~/.local/share/fonts/overwatch-game/gordin-bold.ttf"))
             if os.path.exists(f)), None)
HERE = os.path.dirname(os.path.realpath(__file__))
FADE = 0.25
CARD = 3.2      # seconds each title card stays up


def size(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=p=0", path],
                         capture_output=True, text=True).stdout.strip()
    w, h = (out or "2560,1600").split(",")[:2]
    return int(w), int(h)


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True).stdout.strip()
    return float(out)


def timeline(path, length):
    """-> (keep ranges, cues as (start, end, text)) in the segment's own time."""
    keeps, cues, on = [], [], None
    if os.path.exists(path):
        for line in open(path):
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            t, kind, text = float(parts[0]), parts[1], parts[2] if len(parts) > 2 else ""
            if kind == "keep_on" and on is None:
                on = t
            elif kind == "keep_off" and on is not None:
                keeps.append((on, min(t, length)))
                on = None
            elif kind == "cue":
                if cues:
                    cues[-1][1] = t
                cues.append([t, length, text])
    if on is not None:
        keeps.append((on, length))
    if not keeps:
        keeps = [(0.0, length)]
    keeps = [(a, b) for a, b in keeps if b - a > 2 * FADE]
    return keeps, [c for c in cues if c[2]]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dir")
    ap.add_argument("--scale", type=int, help="output width (height follows), e.g. 1920")
    ap.add_argument("--no-captions", action="store_true")
    ap.add_argument("--only", help="comma-separated segment names")
    ap.add_argument("--name", default="overwatch-demo")
    ap.add_argument("--chapters-only", action="store_true", help="write <name>.chapters.txt and stop (no encoding)")
    ap.add_argument("--title", default="OVERWATCH|A HALF-LIFE 2 COMBINE DESKTOP  //  HYPRLAND + QUICKSHELL",
                    help="opening card as TITLE|SUBTITLE; empty for none")
    ap.add_argument("--outro", default="OVERWATCH|BOOT MENU  //  SPLASH  //  LOGIN  //  SHELL  //  LOCK",
                    help="closing card as TITLE|SUBTITLE; empty for none")
    a = ap.parse_args()

    raw = os.path.join(a.dir, "raw")
    segs = sorted(f[:-4] for f in os.listdir(raw) if f.endswith(".mkv") and os.path.exists(os.path.join(raw, f[:-4] + ".tl")))
    if a.only:
        segs = [s for s in segs if s in a.only.split(",")]
    if not segs:
        sys.exit(f"No recorded segments in {raw}. Run owdemo first.")

    tmp = tempfile.mkdtemp(prefix="owdemo-build-")
    inputs, chains, labels, captions, pos = [], [], [], [], 0.0
    first = os.path.join(raw, segs[0] + ".mkv")
    w, h = size(first)
    cards = len(segs)       # card inputs come after the segment inputs

    # the Combine claw for the cards, tinted teal, from the shell's own vector
    claw = os.path.join(tmp, "claw.png")
    subprocess.run(["magick", "-background", "none", "-density", "900", os.path.join(HERE, "..", "assets", "claw.svg"),
                    "-resize", f"{h // 5}x{h // 5}", "-fill", "#5fd7e8", "-colorize", "100", claw], check=True)

    def card(text, n):
        """A plain title card: big title, teal subtitle, on the shell's base colour."""
        nonlocal cards
        if not text or not FONT:
            return 0.0
        title, _, sub = text.partition("|")
        files = []
        for j, t in enumerate((title, sub)):
            f = os.path.join(tmp, f"card{n}_{j}.txt")
            open(f, "w").write(t)
            files.append(f)
        vi, ai, ci = cards, cards + 1, cards + 2
        cards += 3
        inputs.extend(["-f", "lavfi", "-t", str(CARD), "-i", f"color=c=0x0a0f14:s={w}x{h}:r=60",
                       "-f", "lavfi", "-t", str(CARD), "-i", "anullsrc=r=48000:cl=stereo",
                       "-loop", "1", "-t", str(CARD), "-i", claw])
        chains.append(f"[{vi}:v][{ci}:v]overlay=(W-w)/2:H*0.12:shortest=1[card{n}c]")
        chain = (f"[card{n}c]drawtext=fontfile={FONT}:textfile={files[0]}:expansion=none:fontsize={h // 9}:"
                 f"fontcolor=0xe6f6fa:x=(w-text_w)/2:y=h*0.40")
        if sub:
            chain += (f",drawtext=fontfile={FONT}:textfile={files[1]}:expansion=none:fontsize={h // 42}:"
                      f"fontcolor=0x5fd7e8:x=(w-text_w)/2:y=h*0.54")
        chain += f",format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st={CARD - 0.5}:d=0.5[card{n}v]"
        chains.append(chain)
        chains.append(f"[{ai}:a]aresample=48000[card{n}a]")
        return CARD

    for i, seg in enumerate(segs):
        path = os.path.join(raw, seg + ".mkv")
        inputs += ["-i", path]
    intro = card(a.title, 0)
    if intro:
        labels.append("[card0v][card0a]")
        pos = intro
    for i, seg in enumerate(segs):
        path = os.path.join(raw, seg + ".mkv")
        length = duration(path)
        keeps, cues = timeline(os.path.join(raw, seg + ".tl"), length)
        print(f"{seg}: {length:.1f}s recorded, keeping " + ", ".join(f"{x:.1f}-{y:.1f}" for x, y in keeps))
        for k, (s, e) in enumerate(keeps):
            n = e - s
            v, au = f"v{i}_{k}", f"a{i}_{k}"
            chains.append(f"[{i}:v]trim=start={s:.3f}:end={e:.3f},setpts=PTS-STARTPTS,fps=60,scale={w}:{h},format=yuv420p,"
                          f"fade=t=in:st=0:d={FADE},fade=t=out:st={n - FADE:.3f}:d={FADE}[{v}]")
            chains.append(f"[{i}:a]atrim=start={s:.3f}:end={e:.3f},asetpts=PTS-STARTPTS,aresample=48000,"
                          f"afade=t=in:st=0:d={FADE},afade=t=out:st={n - FADE:.3f}:d={FADE}[{au}]")
            labels.append(f"[{v}][{au}]")
            for cs, ce, text in cues:       # the part of each caption that falls in this kept range
                x, y = max(cs, s), min(ce, e)
                if y - x > 0.4:
                    captions.append((pos + x - s, pos + y - s, text))
            pos += n
    if card(a.outro, 1):
        labels.append("[card1v][card1a]")
        pos += CARD
    chains.append("".join(labels) + f"concat=n={len(labels)}:v=1:a=1[vcat][aout]")

    last = "vcat"
    if not a.no_captions and FONT:
        for j, (s, e, text) in enumerate(captions):
            tf = os.path.join(tmp, f"cue{j}.txt")
            open(tf, "w").write(text)
            s, e = s + FADE, e - 0.1
            fade = f"min(1\\,min((t-{s:.3f})/0.25\\,({e:.3f}-t)/0.25))"
            chains.append(f"[{last}]drawtext=fontfile={FONT}:textfile={tf}:expansion=none:fontsize={h // 36}:fontcolor=0xe6f6fa:"
                          f"x=(w-text_w)/2:y=h*0.855:box=1:boxcolor=0x0a0f14@0.82:boxborderw={h // 80}:"
                          f"alpha='{fade}':enable='between(t,{s:.3f},{e:.3f})'[c{j}]")
            last = f"c{j}"
    elif not a.no_captions:
        print("GorDIN font not found, building without captions")
    if a.scale:
        chains.append(f"[{last}]scale={a.scale}:-2:flags=lanczos[vout]")
        last = "vout"

    # YouTube chapters: first at 0:00, each at least 10 seconds long
    marks, lastt = [(0, "Intro")], 0
    for cs, ce, text in sorted(captions):
        t = int(cs)
        if t - lastt >= 10:
            marks.append((t, " ".join(text.replace("//", "-").split()).title()))
            lastt = t
    chapters = os.path.join(a.dir, a.name + ".chapters.txt")
    open(chapters, "w").write("".join(f"{t // 60}:{t % 60:02d} {name}\n" for t, name in marks))
    print(f"chapters: {chapters}")
    if a.chapters_only:
        return

    script = os.path.join(tmp, "filter.txt")
    open(script, "w").write(";\n".join(chains))
    out = os.path.join(a.dir, a.name + (f"-{a.scale}" if a.scale else "") + ".mp4")
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-stats", "-y", *inputs,
           "-/filter_complex", script, "-map", f"[{last}]", "-map", "[aout]",
           "-c:v", "libx264", "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p",
           "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out]
    print(f"building {out} ({pos:.0f}s, {len(captions)} captions)")
    r = subprocess.run(cmd)
    if r.returncode:
        sys.exit(f"ffmpeg failed; the filter graph is in {script}")
    print(f"done: {out} ({os.path.getsize(out) / 1e6:.0f} MB, {duration(out):.0f}s)")


if __name__ == "__main__":
    main()
