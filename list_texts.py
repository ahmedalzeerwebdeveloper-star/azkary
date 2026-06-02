import json

with open('parsed_wird.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

texts = set()
for day, dhikrs in data.items():
    for dhikr in dhikrs:
        texts.add(dhikr['text'].strip())

for idx, t in enumerate(sorted(texts)):
    print(f"{idx}: {t[:60]}...")
