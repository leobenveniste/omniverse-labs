import os
import re

lib_dir = r"c:\Projects\Omniverse Labs\apps\omni_trade\lib"

# Check for hardcoded Spanish or English strings in Dart files outside of l10n and constants
dart_files = []
for root, dirs, filenames in os.walk(lib_dir):
    if "l10n" in root:
        continue
    for fn in filenames:
        if fn.endswith(".dart"):
            dart_files.append(os.path.join(root, fn))

# Regex to catch Text('...'), Text("..."), SnackBar(content: Text(...)), hintText: '...', title: Text('...'), etc.
# where string is longer than 3 chars and contains alphabet
str_pattern = re.compile(r"['\"]([A-Za-zÁÉÍÓÚáéíóúñÑ][^'\"]{3,})['\"]")

ignored_keys = {
    "package:", "assets/", "omnitrade_", "Crypto", "Stocks", "Forex", "Futures", "Options", "Commodities",
    "Breakout", "Pullback / Retest", "Trend Following", "Range / Mean Reversion", "Scalp", "Support & Resistance",
    "Order Block / Liquidity", "News Catalyst", "Disciplined", "Followed Plan", "Patience", "FOMO", "Revenge Trade",
    "Greedy / Late Exit", "Early Exit (Fear)", "Over-leveraged", "USD", "EUR", "GBP", "ARS", "BRL", "JPY", "USDT",
    "yyyy-MM-dd", "HH:mm", "MMM dd", "dd/MM", "en_US", "es_ES", "pt_BR", "fr_FR", "it_IT",
    "com.omniverselabs.omnitrade", "sqlite", "trades.db", "images"
}

results = []
for fp in sorted(dart_files):
    rel = os.path.relpath(fp, lib_dir)
    with open(fp, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("import ") or stripped.startswith("export "):
                continue
            for match in str_pattern.finditer(line):
                val = match.group(1).strip()
                if any(val.startswith(ig) for ig in ignored_keys):
                    continue
                if "t('" in line or 't("' in line or "l10n.t" in line:
                    # Likely a key
                    continue
                if val in ["openPlayStore", "application/json", "text/csv"]:
                    continue
                results.append((rel, idx, val, stripped))

for r in results:
    print(f"{r[0]}:{r[1]} -> [{r[2]}]  in: {r[3]}")
print(f"Total found: {len(results)}")
