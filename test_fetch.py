import urllib.request
import re
import html

url = "https://www.wattpad.com/499399373-%D9%83%D9%86-%D9%85%D8%B9-%D8%A7%D9%84%D9%84%D9%87-4-%D8%A7%D9%84%D8%A3%D9%88%D8%B1%D8%A7%D8%AF-%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%E2%9C%AF-%D9%88%D8%B1%D8%AF-%D9%8A%D9%88%D9%85-%D8%A7%D9%84%D8%B3%D8%A8%D8%AA-%E2%9C%AF/page/2"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as response:
    content = response.read().decode('utf-8')
    content = html.unescape(content)
    parts = content.split('▪')
    print(len(parts) - 1)
