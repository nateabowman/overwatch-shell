#!/usr/bin/env python3
"""Collects gallery screenshots of Combine-city maps (City 8, City 17, City 24, ...) from the
Garry's Mod Steam Workshop for use as personal wallpapers on this machine. Slow on purpose:
Steam rate-limits page fetches. Output: ~/.local/share/overwatch/workshop/img + shots.json."""
import json, os, re, subprocess, time, urllib.parse, urllib.request
OUT = os.path.expanduser("~/.local/share/overwatch/workshop/")
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"
QUERIES = ["rp_city8", "city 8", "rp_city17", "city17", "rp_city24", "rp_city45", "combine citadel", "rp_industrial17", "city 11"]
def get(url, tries=4):
    for n in range(tries):
        r = subprocess.run(["curl", "-sS", "-m", "30", "-A", UA, "-w", "\n%{http_code}", url], capture_output=True, text=True, errors="ignore")
        body, _, code = r.stdout.rpartition("\n")
        if code == "200": return body
        time.sleep(30 * (n + 1))
    return ""
ids = []
for q in QUERIES:
    html = get("https://steamcommunity.com/workshop/browse/?" + urllib.parse.urlencode({"appid": 4000, "searchtext": q, "browsesort": "trend", "section": "readytouseitems", "requiredtags[]": "map", "days": -1}))
    for i in re.findall(r"sharedfiles/filedetails/\?id=(\d+)", html):
        if i not in ids: ids.append(i)
    time.sleep(6)
data = {"itemcount": len(ids)}
for n, i in enumerate(ids): data[f"publishedfileids[{n}]"] = i
req = urllib.request.Request("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", urllib.parse.urlencode(data).encode(), {"User-Agent": UA})
det = json.load(urllib.request.urlopen(req, timeout=30))["response"]["publishedfiledetails"]
want = re.compile(r"city[ _]?(8|17|24|45|11)\b|\bc(8|17|24|45)\b|citadel|industrial17|nexus|combine", re.I)
skip = re.compile(r"caramelldansen|styleguide|lunar|build 210|gateway", re.I)   # last two are already downloaded
items = sorted([(d["publishedfileid"], d.get("title", ""), d.get("subscriptions", 0)) for d in det
                if d.get("result") == 1 and want.search(d.get("title", "")) and not skip.search(d.get("title", ""))], key=lambda x: -x[2])[:18]
shots = []
for i, title, subs in items:
    html = get(f"https://steamcommunity.com/sharedfiles/filedetails/?id={i}")
    urls = []
    for u in re.findall(r"https://images\.steamusercontent\.com/ugc/[0-9A-Za-z_/\-]+/", html):
        if u not in urls: urls.append(u)
    slug = re.sub(r"[^a-z0-9]+", "_", title.lower()).strip("_")[:28]
    for n, u in enumerate(urls[:8]):
        f = f"{OUT}img/{slug}__{n}.jpg"
        if not os.path.exists(f):
            subprocess.run(["curl", "-fsS", "-m", "60", "-A", UA, "-o", f, u], capture_output=True)
            time.sleep(0.5)
        shots.append({"file": f, "title": title, "id": i, "url": u})
    json.dump(shots, open(OUT + "shots.json", "w"), indent=1)
    print(f"{len(urls):2} shots  {title}", flush=True)
    time.sleep(9)
print("done:", len(shots), "screenshots from", len(items), "maps", flush=True)
