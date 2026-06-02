import json
import re

with open('parsed_wird.json', 'r', encoding='utf-8') as f:
    wird_data = json.load(f)

with open('azkar.json', 'r', encoding='utf-8') as f:
    azkar_data = json.load(f)

arabic_days = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الإثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة'
}

def escape_dart_string(s):
    if s is None: return ""
    s = str(s)
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "\\'")
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    return s

dart_code = """import '../models/dhikr_model.dart';

class AdhkarData {
  static const List<DhikrCategory> categories = [
"""

def flatten_azkar(azkar_list):
    res = []
    for item in azkar_list:
        if isinstance(item, list):
            res.extend(item)
        elif isinstance(item, dict):
            res.append(item)
    return res

def parse_count(c):
    try:
        return int(c)
    except:
        return 1

# Essential Adhkar to inject
ayat_alkursi = {
    'text': 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ.',
    'count': 1,
    'desc': 'فضلها: من قالها حين يصبح أجير من الجن حتى يمسي، ومن قالها حين يمسي أجير من الجن حتى يصبح.'
}

al_ikhlas = {
    'text': 'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِ\nقُلْ هُوَ ٱللَّهُ أَحَدٌ، ٱللَّهُ ٱلصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ.',
    'count': 3,
    'desc': 'فضلها: من قالها حين يصبح وحين يمسي كفته من كل شيء.'
}

al_falaq = {
    'text': 'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِى ٱلْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ.',
    'count': 3,
    'desc': 'فضلها: من قالها حين يصبح وحين يمسي كفته من كل شيء.'
}

an_nas = {
    'text': 'بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ، مَلِكِ ٱلنَّاسِ، إِلَٰهِ ٱلنَّاسِ، مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ، ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ، مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ.',
    'count': 3,
    'desc': 'فضلها: من قالها حين يصبح وحين يمسي كفته من كل شيء.'
}

salat_nabi = {
    'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ على نَبِيِّنَا مُحمَّد.',
    'count': 10,
    'desc': 'فضلها: من صلى علي حين يصبح عشراً وحين يمسي عشراً أدركته شفاعتي يوم القيامة.'
}

def write_category(category_id, title, icon, raw_adhkar_list, is_morning_evening=False):
    global dart_code
    dart_code += f"    DhikrCategory(\n      id: '{category_id}',\n      title: '{title}',\n      icon: '{icon}',\n      adhkar: [\n"
    
    if is_morning_evening:
        for a in [ayat_alkursi, al_ikhlas, al_falaq, an_nas]:
            dart_code += f"        Dhikr(text: '{escape_dart_string(a['text'])}', count: {a['count']}, description: '{escape_dart_string(a['desc'])}'),\n"
        
    for dhikr in raw_adhkar_list:
        text = dhikr.get('content', dhikr.get('text', ''))
        if not text or text.strip().lower() == 'stop' or 'صَلِّ وَسَلِّمْ' in text or 'اية الكرسي' in text: continue
        text = text.strip()
        count = parse_count(dhikr.get('count', '1'))
        desc = dhikr.get('description', '')
        if not desc or desc.strip().lower() == 'stpo': desc = ''
        desc = desc.strip()
        if desc and not desc.startswith('فضلها:'):
            desc = f"فضلها: {desc}"
        
        desc_prop = f", description: '{escape_dart_string(desc)}'" if desc else ""
        dart_code += f"        Dhikr(text: '{escape_dart_string(text)}', count: {count}{desc_prop}),\n"
    
    if is_morning_evening:
        dart_code += f"        Dhikr(text: '{escape_dart_string(salat_nabi['text'])}', count: {salat_nabi['count']}, description: '{escape_dart_string(salat_nabi['desc'])}'),\n"
    
    dart_code += "      ],\n    ),\n"

icons = {
    'أذكار الصباح': 'sun',
    'أذكار المساء': 'moon',
    'أذكار بعد السلام من الصلاة المفروضة': 'mosque',
    'تسابيح': 'beads',
    'أذكار النوم': 'bed',
    'أذكار الاستيقاظ': 'sun',
    'أدعية قرآنية': 'quran',
    'أدعية الأنبياء': 'pray',
}

# --- All Adhkar ---
for cat_name, cat_list in azkar_data.items():
    flat_list = flatten_azkar(cat_list)
    cat_id = 'cat_' + str(hash(cat_name))
    if cat_name == 'أذكار الصباح': cat_id = 'morning'
    elif cat_name == 'أذكار المساء': cat_id = 'evening'
    icon = icons.get(cat_name, 'list')
    is_me = (cat_name in ['أذكار الصباح', 'أذكار المساء'])
    write_category(cat_id, cat_name, icon, flat_list, is_me)

# --- Daily Wird ---
virtues = {
    'آية الكرسي': 'فضلها: من قرأها حين يصبح أجير من الجن حتى يمسي.',
    'اللّهـمَّ أَنْتَ رَبِّـي': 'فضلها: من قالها موقناً بها فمات من يومه أو ليلته دخل الجنة.',
}

def clean_count_from_text(text):
    text = text.strip()
    count = 1
    match = re.search(r'\(([^)]*مرات|عشراً|عشر|ثلاث|سبع|مائة[^)]*)\)[.\s]*$', text)
    if match:
        times_str = match.group(1)
        if 'ثلاث' in times_str: count = 3
        elif 'عشراً' in times_str or 'عشر' in times_str and 'عشرة' not in times_str: count = 10
        elif 'عشرة' in times_str: count = 10
        elif 'مائة' in times_str or 'مئة' in times_str: count = 100
        elif 'سبع' in times_str: count = 7
        text = text[:match.start()].strip()
    if text.endswith('.'): text = text[:-1].strip()
    return text, count

for day, name in arabic_days.items():
    if day not in wird_data: continue
    dart_code += f"    DhikrCategory(\n"
    dart_code += f"      id: 'wird_{day}',\n"
    dart_code += f"      title: 'ورد يوم {name}',\n"
    dart_code += f"      icon: 'book',\n"
    dart_code += f"      adhkar: [\n"
    
    seen_texts = set()
    actual_items = wird_data[day]
    
    for dhikr in actual_items:
        text, c_count = clean_count_from_text(dhikr['text'])
        final_count = c_count if c_count > 1 else dhikr['count']
        
        if not text: continue
        
        text = text.replace('أهدنا', 'اهدنا')
        text = text.replace('رب العلمين', 'رب العالمين')
        
        if text in seen_texts: continue
        seen_texts.add(text)
        
        virtue = ""
        for k, v in virtues.items():
            if k in text: virtue = v
            
        escaped_text = escape_dart_string(text)
        desc_prop = f", description: '{escape_dart_string(virtue)}'" if virtue else ""
        dart_code += f"        Dhikr(text: '{escaped_text}', count: {final_count}{desc_prop}),\n"
        
    dart_code += f"      ],\n"
    dart_code += f"    ),\n"
    
dart_code += """  ];
}
"""

with open('lib/data/repositories/adhkar_data.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)
