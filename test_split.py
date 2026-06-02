import json

with open('parsed_wird.json', 'r', encoding='utf-8') as f:
    wird_data = json.load(f)

for day, items in wird_data.items():
    print(f"Day: {day}")
    for item in items:
        text = item['text']
        if '▪' in text:
            parts = text.split('▪')
            print(f"  Split into {len(parts)} parts.")
            for p in parts[:3]: # show first 3
                print(f"    - {p.strip()[:50]}")
        else:
            print("  No separator found in text!")
