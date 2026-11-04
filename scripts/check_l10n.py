import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

with open("apps/circulo/lib/l10n/app_localizations.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Match 'es': { ... }, 'en': { ... }, etc.
lang_blocks = {}
for lang in ['es', 'en', 'pt', 'fr', 'it', 'de']:
    start_token = f"'{lang}': {{"
    idx = text.find(start_token)
    if idx != -1:
        # find matching brace
        brace_count = 1
        pos = idx + len(start_token)
        while pos < len(text) and brace_count > 0:
            if text[pos] == '{':
                brace_count += 1
            elif text[pos] == '}':
                brace_count -= 1
            pos += 1
        block = text[idx + len(start_token):pos - 1]
        keys = re.findall(r"'([a-zA-Z0-9_]+)':", block)
        lang_blocks[lang] = set(keys)
        print(f"Language {lang}: {len(keys)} keys")

es_keys = lang_blocks.get('es', set())
for lang, keys in lang_blocks.items():
    if lang == 'es':
        continue
    diff = es_keys - keys
    if diff:
        print(f"Missing in {lang} ({len(diff)}): {sorted(list(diff))}")
    else:
        print(f"✅ {lang} is complete and matches 'es' perfectly!")
