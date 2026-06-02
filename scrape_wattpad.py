import urllib.request
import re
import html
import json

base_urls = {
    'wird_saturday': 'https://www.wattpad.com/499399373-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%B3%D8%A8%D8%AA-%E2%9C%AF',
    'wird_sunday': 'https://www.wattpad.com/499400206-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%A3%D8%AD%D8%AF-%E2%9C%AF',
    'wird_monday': 'https://www.wattpad.com/499520658-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%A5%D8%AB%D9%86%D9%8A%D9%86-%E2%9C%AF',
    'wird_tuesday': 'https://www.wattpad.com/500042948-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%AB%D9%84%D8%A7%D8%AB%D8%A7%D8%A1-%E2%9C%AF',
    'wird_wednesday': 'https://www.wattpad.com/501081817-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%A3%D8%B1%D8%A8%D8%B9%D8%A7%D8%A1-%E2%9C%AF',
    'wird_thursday': 'https://www.wattpad.com/501144572-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%AE%D9%85%D9%8A%D8%B3-%E2%9C%AF',
    'wird_friday': 'https://www.wattpad.com/501146594-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%AC%D9%85%D8%B9%D8%A9-%E2%9C%AF'
}

def parse_count(text):
    text = text.strip()
    count = 1
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
            text = text[:match.start()].strip()
    
    if text.startswith('(') and text.endswith(')'):
        text = text[1:-1].strip()
        
    return text, count

output = {}

for day, base_url in base_urls.items():
    dhikrs = []
    seen = set()
    
    for page in range(1, 4): # Fetch up to 3 pages
        url = base_url if page == 1 else f"{base_url}/page/{page}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        try:
            with urllib.request.urlopen(req) as response:
                content = response.read().decode('utf-8')
                content = html.unescape(content)
                
                # Extract <pre> or text content from specific divs
                # Wait, wattpad story text is usually in <pre> tags or <p data-p-id=...>
                paragraphs = re.findall(r'<p[^>]*>(.*?)</p>', content, re.DOTALL)
                
                found_on_page = False
                for p in paragraphs:
                    # Remove all internal HTML tags like <br>, <strong>
                    p_text = re.sub(r'<[^>]+>', '', p)
                    parts = p_text.split('▪')
                    for part in parts[1:]: # Skip text before first ▪
                        line = part.strip()
                        if not line: continue
                        if line not in seen:
                            seen.add(line)
                            t, c = parse_count(line)
                            dhikrs.append({"text": t, "count": c})
                            found_on_page = True
                            
                if not found_on_page:
                    break # No content on this page, stop pagination
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            break
            
    # We map 'wird_saturday' to 'saturday' for compatibility with fix_azkar.py
    day_key = day.split('_')[1]
    output[day_key] = dhikrs
    print(f"Scraped {len(dhikrs)} dhikrs for {day_key}")

with open('parsed_wird.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

