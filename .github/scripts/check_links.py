"""Cek link internal di semua README materi.

- Anchor `](#...)` harus cocok dengan heading (aturan slug GitHub).
- Link relatif ke file `.md` harus menunjuk file yang ada.
- Tag <details> harus seimbang dan jumlah ``` harus genap.

Jalankan dari root repo: python3 -I .github/scripts/check_links.py
"""
import glob
import os
import re
import sys


def slug(heading: str) -> str:
    s = heading.strip().lower()
    s = re.sub(r"[^\w\- ]", "", s)
    return s.replace(" ", "-")


def check(path: str) -> list[str]:
    text = open(path, encoding="utf-8").read()
    errors = []

    body = re.sub(r"```.*?```", "", text, flags=re.S)
    headings = {slug(h) for h in re.findall(r"^#{1,6} (.*)$", body, flags=re.M)}
    for anchor in re.findall(r"\]\(#([^)]+)\)", text):
        if anchor not in headings:
            errors.append(f"anchor tidak ditemukan: #{anchor}")

    base = os.path.dirname(path)
    for link in re.findall(r"\]\(((?:\.\./|\./)?[^):#\s]+\.md)(?:#[^)]*)?\)", text):
        if link.startswith("http"):
            continue
        if not os.path.exists(os.path.normpath(os.path.join(base, link))):
            errors.append(f"file tidak ditemukan: {link}")

    if text.count("<details>") != text.count("</details>"):
        errors.append("jumlah <details> dan </details> tidak seimbang")
    if text.count("```") % 2:
        errors.append("jumlah ``` ganjil (code block tidak tertutup)")
    return errors


def main() -> int:
    files = sorted(glob.glob("README.md") + glob.glob("*/README.md") + glob.glob("*/*/README.md"))
    failed = False
    for f in files:
        for err in check(f):
            failed = True
            print(f"{f}: {err}")
    print(f"Diperiksa {len(files)} file — {'GAGAL' if failed else 'OK'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
