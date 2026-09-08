import urllib.request
import json
import re
import os
import sys

BASE_URL = "https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/hafs/kfqc/json/{page_str}.json"
OUTPUT_FILE = "/home/ahmed/Desktop/wrd/assets/quran_ayah_bounds.json"

def parse_svg_path(path_str):
    points = []
    if ',' in path_str and 'M' not in path_str and 'L' not in path_str:
        for pair in path_str.strip().split():
            parts = pair.split(',')
            if len(parts) == 2:
                try:
                    points.append((float(parts[0]), float(parts[1])))
                except ValueError:
                    pass
        return points

    tokens = re.findall(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', path_str)
    for i in range(0, len(tokens) - 1, 2):
        try:
            points.append((float(tokens[i]), float(tokens[i+1])))
        except ValueError:
            pass
    return points

def main():
    print("📥 Downloading and generating ayah bounds for 604 pages...")
    result = {}
    
    for page in range(1, 605):
        page_str = f"{page:03d}"
        url = BASE_URL.format(page_str=page_str)
        sys.stdout.write(f"\r📄 Processing page {page}/604...")
        sys.stdout.flush()
        
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=15) as resp:
                items = json.loads(resp.read().decode('utf-8'))
        except Exception as e:
            print(f"\n❌ Error fetching page {page}: {e}")
            items = []
            
        page_ayahs = []
        for it in items:
            sura = it.get('surahNumber') or it.get('surah') or it.get('sura')
            aya = it.get('ayahNumber') or it.get('ayah') or it.get('aya')
            poly_str = it.get('polygon', '')
            pts = parse_svg_path(poly_str)
            
            if pts:
                xs = [p[0] for p in pts]
                ys = [p[1] for p in pts]
                min_x, max_x = min(xs), max(xs)
                min_y, max_y = min(ys), max(ys)
            else:
                min_x = max_x = it.get('x', 0.0)
                min_y = max_y = it.get('y', 0.0)
                
            page_ayahs.append({
                "sura": sura,
                "aya": aya,
                "marker_x": it.get('x'),
                "marker_y": it.get('y'),
                "min_x": round(min_x, 2),
                "max_x": round(max_x, 2),
                "min_y": round(min_y, 2),
                "max_y": round(max_y, 2),
                "points": [(round(p[0], 2), round(p[1], 2)) for p in pts]
            })
            
        result[str(page)] = page_ayahs
        
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False)
        
    size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"\n\n✅ Done! Saved {len(result)} pages to {OUTPUT_FILE} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    main()
