#!/usr/bin/env python3
"""Adapt a checked-out GPLv3 Sparkle source tree for the RS Insta tweak build.

Preserve the upstream SPK class/function names because internal references depend on
them. Only tweak target/package metadata and a handful of user-facing labels.
"""
from pathlib import Path

root = Path("RSInstaSparkle")
makefile = root / "Makefile"
control = root / "control"
if not makefile.exists() or not control.exists():
    raise SystemExit("Sparkle source not imported correctly")

m = makefile.read_text()
assert "TWEAK_NAME = Sparkle" in m
makefile.write_text(m.replace("TWEAK_NAME = Sparkle", "TWEAK_NAME = RSInsta", 1))

c = control.read_text()
for before, after in [
    ("Package: com.sparkle.sparkle", "Package: com.rsinsta.tweak"),
    ("Name: Sparkle for Instagram", "Name: RS Insta"),
    ("Homepage: https://github.com/efibalogh/sparkle-ig",
     "Homepage: https://github.com/userpc5661-png/RsYT2"),
]:
    assert before in c, before
    c = c.replace(before, after, 1)
control.write_text(c)

# Keep upstream resource-bundle identifiers and all internal SPK symbols unchanged.
# Replace only the exact localized settings-title string values. Other strings
# and translation catalogs stay untouched until integration tests confirm safety.
changed = 0
for path in (root / "resources").rglob("*.strings"):
    raw = path.read_text(encoding="utf-8", errors="surrogateescape")
    revised = raw.replace('= "Sparkle";', '= "RS Insta";')
    if revised != raw:
        path.write_text(revised, encoding="utf-8", errors="surrogateescape")
        changed += 1
print(f"RSInsta build target and package metadata updated; {changed} localization files adjusted.")
