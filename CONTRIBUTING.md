# Berkontribusi & Melaporkan Masalah

Materi ini akan selalu punya kesalahan dan bagian yang usang — ekosistem Web3 berubah cepat. Laporan Anda membantu pembelajar berikutnya.

## Melaporkan materi bermasalah

Buka **Issue** dengan template **"Materi bermasalah"** dan sertakan:
- path file + nomor baris (atau judul bagian),
- apa yang tertulis, apa yang terjadi saat Anda mencobanya (salin pesan error persis),
- versi tool Anda (`forge --version`, `node --version`, dsb.).

Untuk hasil uji coba sebagai pembelajar, gunakan template **"Laporan pilot"** (lihat [PILOT.md](PILOT.md)).

## Mengusulkan perbaikan

1. Satu Pull Request untuk satu jenis perubahan (perbaikan fakta, materi baru, atau kode).
2. Klaim yang bisa berubah (versi, tanggal upgrade, angka jaringan) **wajib** menyertakan sumber primer (ethereum.org, eips.ethereum.org, dokumentasi/rilis resmi) dan tanggal pengecekan.
3. Kode Solidity: jalankan `forge fmt` dan pastikan CI hijau.
4. Jangan menyertakan private key asli, API key, atau `.env` — gunakan placeholder atau akun default anvil.
5. Ikuti konvensi commit di README utama (`learn:`, `fix:`, `docs:`, `test:`, `security:`).

## Kerentanan di contoh kode

Contoh di Phase 8 **sengaja** rentan. Jika Anda menemukan kerentanan yang **tidak disengaja** di kode referensi (`solutions/`) atau contoh yang diklaim aman, laporkan lewat Issue biasa — tidak ada dana nyata yang terancam. Jika menyangkut protokol nyata di luar repo ini, laporkan ke program bug bounty protokol tersebut, bukan ke sini.

## Lisensi kontribusi

Dengan berkontribusi, Anda setuju kontribusi kode dirilis di bawah MIT dan kontribusi materi di bawah CC BY-SA 4.0 (lihat [LICENSE](LICENSE)).
