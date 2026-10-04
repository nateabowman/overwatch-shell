#!/usr/bin/env python3
"""Adds chosen Workshop screenshots (names from ~/.local/share/overwatch/workshop/img, without
extension) to the backdrop rotation: pick-backdrops.py rp_city8__1 gm_citadel__2 ..."""
import os, sys
from PIL import Image
src = os.path.expanduser("~/.local/share/overwatch/workshop/img/")
dst = os.path.expanduser("~/Pictures/Wallpapers/overwatch/")
os.makedirs(dst, exist_ok=True)
for name in sys.argv[1:]:
    f = src + name + ".jpg"
    if not os.path.exists(f): print("missing", name); continue
    Image.open(f).convert("RGB").save(dst + "workshop_" + name + ".jpg", quality=93)
print(len(os.listdir(dst)), "images in", dst)
