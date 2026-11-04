import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

lib_dir = r"apps/circulo/lib"
dart_files = []
for root, dirs, filenames in os.walk(lib_dir):
    if "l10n" in root:
        continue
    for fn in filenames:
        if fn.endswith(".dart"):
            dart_files.append(os.path.join(root, fn))

pattern = re.compile(r"Text\(\s*['\"]([^'\"]{3,})['\"]")

findings = []
for fp in dart_files:
    rel = os.path.relpath(fp, lib_dir)
    with open(fp, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, 1):
            if line.strip().startswith("//") or "l10n.get" in line or "l10n.format" in line:
                continue
            matches = pattern.findall(line)
            for m in matches:
                if not m.startswith("CIR-") and not m.startswith("http") and not m.startswith("assets/") and not m.startswith("AppRoles."):
                    findings.append((rel, idx, m, line.strip()))

for rel, idx, text, line in findings:
    print(f"{rel}:{idx} -> [{text}] in: {line}")
print(f"\nTotal hardcoded Text found: {len(findings)}")
