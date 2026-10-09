"""Cek tautan eksternal di semua README materi.

- GAGAL jika ada tautan yang mati pasti: HTTP 404/410 atau domain tidak ditemukan.
- PERINGATAN (tidak gagal) untuk 401/403/429/5xx dan timeout — sering karena situs
  memblokir bot atau sedang gangguan, perlu dicek manual.

Jalankan dari root repo: python3 -I .github/scripts/check_external_links.py
"""
import concurrent.futures as cf
import glob
import re
import socket
import sys
import urllib.error
import urllib.request

HARD_FAIL = {404, 410}


def collect() -> dict[str, list[str]]:
    urls: dict[str, list[str]] = {}
    files = sorted(glob.glob("*.md") + glob.glob("*/README.md") + glob.glob("*/*/README.md"))
    for f in files:
        for i, line in enumerate(open(f, encoding="utf-8"), 1):
            for u in re.findall(r"\]\((https?://[^)\s]+)\)", line):
                urls.setdefault(u, []).append(f"{f}:{i}")
    return urls


def check(url: str):
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers={"User-Agent": "Mozilla/5.0 (link-check)"})
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                return resp.status
        except urllib.error.HTTPError as e:
            if method == "GET":
                return e.code
        except urllib.error.URLError as e:
            if method == "GET":
                return "DNS" if isinstance(e.reason, socket.gaierror) else f"ERR:{type(e.reason).__name__}"
        except Exception as e:  # noqa: BLE001
            if method == "GET":
                return f"ERR:{type(e).__name__}"


def main() -> int:
    urls = collect()
    with cf.ThreadPoolExecutor(16) as ex:
        results = dict(zip(urls, ex.map(check, urls)))
    failed = warned = 0
    for url, status in sorted(results.items(), key=lambda kv: str(kv[1])):
        if isinstance(status, int) and status < 400:
            continue
        where = ", ".join(urls[url][:3])
        if status in HARD_FAIL or status == "DNS":
            failed += 1
            print(f"FAIL {status} {url}  ({where})")
        else:
            warned += 1
            print(f"WARN {status} {url}  ({where})")
    print(f"Diperiksa {len(urls)} URL — {failed} mati, {warned} perlu cek manual")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
