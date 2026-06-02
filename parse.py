import re
import os
import json

files = {
    'saturday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/96/content.md',
    'sunday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/5/content.md',
    'monday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/97/content.md',
    'tuesday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/98/content.md',
    'wednesday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/101/content.md',
    'thursday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/102/content.md',
    'friday': '/home/ahmed/.gemini/antigravity/brain/4ebc0551-3ff2-4d02-832a-8a474ec7a886/.system_generated/steps/103/content.md',
}

def parse_count(text):
    text = text.strip()
    count = 1
    # Check if there is a parenthesis at the end containing count-related words (allowing for trailing punctuation)
    match = re.search(r'\(([^)]*(?:مرات|عشراً|عشر|ثلاث|سبع|مائة|مئة|مرة)[^)]*)\)[.\s]*$', text)
    if match:
        times_str = match.group(1)
        is_count = False
        if 'ثلاث' in times_str:
            count = 3
            is_count = True
        elif 'عشراً' in times_str or ('عشر' in times_str and 'عشرة' not in times_str):
            count = 10
            is_count = True
        elif 'عشرة' in times_str:
            count = 10
            is_count = True
        elif 'مائة' in times_str or 'مئة' in times_str:
            count = 100
            is_count = True
        elif 'سبع' in times_str:
            count = 7
            is_count = True
        
        if is_count:
            # Only remove the parenthesis group if it was indeed a count
            text = text[:match.start()].strip()
    
    # Also remove parenthesis around the text if present
    if text.startswith('(') and text.endswith(')'):
        text = text[1:-1].strip()
        
    return text, count

output = {}

for day, path in files.items():
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # We split the entire content by '▪' to ensure we capture each dhikr even if they are on the same line
    parts = content.split('▪')
    
    # Remove duplicates from the list while preserving order
    seen = set()
    unique_lines = []
    # Skip the first part as it's before the first ▪
    for part in parts[1:]:
        # Remove any leading/trailing whitespace or newlines
        line = part.strip()
        if not line: continue
        
        if line not in seen:
            seen.add(line)
            unique_lines.append(line)
            
    dhikrs = []
    for line in unique_lines:
        text, count = parse_count(line)
        dhikrs.append({"text": text, "count": count})
    output[day] = dhikrs

print(json.dumps(output, ensure_ascii=False, indent=2))
