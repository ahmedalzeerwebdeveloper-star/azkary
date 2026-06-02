import json
with open('parsed_wird.json', 'r', encoding='utf-8') as f:
    wird = json.load(f)
long = []
for day, items in wird.items():
    for item in items:
        if len(item['text']) > 500:
            long.append((day, len(item['text']), item['text'][:50]))
print(long)
