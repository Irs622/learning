# 🧪 Protokol Uji Coba Pembelajar (Pilot)

Tujuan: mendapatkan **bukti** bahwa materi bisa diselesaikan oleh orang lain tanpa bantuan langsung, dan mengkalibrasi estimasi waktu yang saat ini masih berupa perkiraan. Sebuah fase baru boleh diberi status **Verified** setelah lolos pilot ini.

## 1. Peserta

| Profil | Jumlah | Contoh |
|---|---|---|
| Programmer Web2 berpengalaman, baru di blockchain | 2 | Backend/full-stack ≥ 2 tahun |
| Programmer junior | 1–2 | ≤ 1 tahun pengalaman |
| Sudah pernah menulis Solidity | 1 | Pembanding |

Peserta mengerjakan **Phase 1 → 2 → 3 → 4 → 6 → 5 (tingkat Core)** di mesin mereka sendiri, mengikuti README apa adanya.

## 2. Aturan

- Fasilitator **tidak membantu**, kecuali peserta buntu > 30 menit pada satu langkah. Setiap bantuan dicatat.
- Peserta menyalakan stopwatch per fase (waktu aktif, bukan waktu kalender).
- Semua error setup dicatat persis seperti muncul (salin pesan errornya).

## 3. Yang Dicatat per Fase

| Metrik | Cara mengukur |
|---|---|
| Waktu aktif | Jam per fase (dibandingkan estimasi di header README) |
| Error setup | Daftar perintah yang gagal + pesan error |
| Titik buntu | Bagian/soal di mana peserta berhenti > 15 menit |
| Bantuan | Berapa kali & untuk apa fasilitator membantu |
| Skor Knowledge Check | Jumlah benar sebelum membuka kunci jawaban |
| Kriteria lulus Core | Tercapai / tidak (per item `✅`) |
| Kejelasan (1–5) | Penilaian subjektif peserta per bagian konsep |

Gunakan template issue **"Laporan pilot"** (lihat [CONTRIBUTING](CONTRIBUTING.md)) untuk setiap peserta & fase.

## 4. Ambang Lulus Pilot

Sebuah fase dianggap **Verified** jika:
- ≥ 80% peserta mencapai semua kriteria Core tanpa bantuan fasilitator;
- tidak ada error setup yang tidak dijelaskan di bagian **🆘 Jika Anda Stuck**;
- median waktu aktif berada dalam rentang estimasi (jika tidak, perbarui estimasi di header fase & README utama);
- rata-rata skor Knowledge Check ≥ 70%.

## 5. Setelah Pilot

1. Perbaiki semua titik buntu dan error setup yang ditemukan.
2. Perbarui estimasi waktu berdasarkan median waktu aktif.
3. Ubah status fase di README utama menjadi **Verified** beserta tanggalnya.
4. Ulangi pilot setiap ada perubahan besar pada toolchain (misal major version Foundry/wagmi).
