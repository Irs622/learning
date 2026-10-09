# 🔒 Solutions — Phase 5

> **Jangan buka folder ini sebelum Anda mengerjakan latihannya sendiri.**
> Membaca jawaban sebelum mencoba menghilangkan bagian paling berharga dari belajar: kebingungan yang Anda pecahkan sendiri.

| File | Jawaban untuk | Starter Anda |
|---|---|---|
| `src/SimpleStorage.sol` | Contract 1 | `../src/SimpleStorage.sol` |
| `src/VotingSystem.sol` | Contract 2 | `../src/VotingSystem.sol` |
| `src/Crowdfunding.sol` | Contract 3 | `../src/Crowdfunding.sol` |
| `src/ERC20Token.sol` | Contract 4 | `../src/ERC20Token.sol` |
| `src/NFTCollection.sol` | Contract 5 | `../src/NFTCollection.sol` |
| `src/TokenStaking.sol` | 🏆 Challenge | `../src/TokenStaking.sol` |
| `test/VotingSystem.t.sol` | Contract 2 — *Test Suite (Lengkapi sendiri!)*, kecuali `testFuzz_VoteCount` | `../test/VotingSystem.t.sol` |

Isi `src/` contract 1–5 di folder ini **sama dengan** blok *Implementation* (tersembunyi) di README Phase 5.

## Cara Memakai

```bash
cd 05-smart-contract-development/

# 1. Kerjakan sendiri sampai SEMUA test lulus terhadap kode ANDA
forge test

# 2. Setelah itu: jalankan test yang sama terhadap implementasi referensi
FOUNDRY_PROFILE=solutions forge test

# 3. Jawaban test "Lengkapi sendiri"
FOUNDRY_PROFILE=answers forge test

# 4. Bandingkan implementasi Anda dengan referensi
diff src/Crowdfunding.sol solutions/src/Crowdfunding.sol
diff test/VotingSystem.t.sol solutions/test/VotingSystem.t.sol
```

Profil `solutions` & `answers` memetakan `import "src/..."` ke `solutions/src/` (lihat `foundry.toml`), sehingga test yang sama bisa dijalankan terhadap dua implementasi.

## Saat Membandingkan, Tanyakan

- Apakah referensi menangani kondisi revert yang Anda lewatkan (atau sebaliknya)?
- Apakah urutan Checks → Effects → Interactions sama?
- Berapa gas implementasi Anda dibanding referensi? (`forge test --gas-report` di kedua profil)
- Referensi `getStakeInfo` mengembalikan 4 nilai (termasuk `pendingReward`), sedangkan spesifikasi meminta 3. Mana yang lebih baik untuk frontend (Phase 9)?
- **Referensi bukan berarti sempurna.** Implementasi `TokenStaking` di sini punya masalah desain yang dibahas di *Review keamanan* Challenge (minting authority, pokok ikut terkunci jika `mint` gagal, return value `transfer` tidak dicek). Temukan dan tulis perbaikannya di **🗒️ Notes**.
