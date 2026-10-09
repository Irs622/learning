# 12 — Layer 2 & Scaling

> **Level**: 4 — Protocol Architecture
> **Phase**: 12 of 13
> **Estimated Time**: 🚀 Intensif 10–14 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 4–5 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [01-blockchain-fundamentals](../01-blockchain-fundamentals/README.md) ✅ | [02-ethereum-and-evm](../02-ethereum-and-evm/README.md) ✅ | [11-tokenomics-and-defi](../11-tokenomics-and-defi/README.md) ✅
> **Status verifikasi**: **Reviewed (parsial)** · 9 Okt 2026 · RPC L2 & parameter blob mainnet diverifikasi on-chain — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan mengapa Ethereum memilih **rollup-centric roadmap** untuk scaling.
- Menguraikan anatomi **rollup**: sequencer, batch, state root, data availability, dan bridge.
- Membandingkan **Optimistic Rollup** (fraud proof, challenge period) dan **ZK Rollup** (validity proof).
- **Menjelaskan** peran data availability, dampak **EIP-4844** dan **PeerDAS (Fusaka)** terhadap biaya L2, serta **memverifikasi** parameter blob jaringan saat ini.
- Menganalisis **bridge** & **cross-chain messaging** beserta model keamanannya.
- Men-deploy dan menguji contract di **L2 (Base, Arbitrum, Optimism)** dengan memperhatikan perbedaan perilaku EVM, model gas, dan finality.

---

## 📋 Prerequisites

- [x] Memahami consensus, block, finality, dan reorg (Phase 1).
- [x] Memahami gas, EIP-1559, dan opcode (Phase 2).
- [x] Merkle tree & hashing (Phase 3).
- [x] Deployment workflow Foundry (Phase 5 & 6), Chainlink oracle (Phase 11).

---

## ⚙️ Setup

```bash
cd 12-layer-2/
forge init lab --no-git
cd lab
```

> ⚠️ Kode fase ini ditempatkan di subfolder **`lab/`**. Jangan `forge init .` di folder fase — folder ini sudah berisi `README.md` materi, dan `forge init --force` akan **menimpanya**. Semua path `src/`, `test/`, `script/`, `audits/` di fase ini relatif terhadap `lab/`. `forge init` sudah memasang `forge-std`; hapus contoh `Counter*.sol` bawaan.

Tambahkan endpoint testnet L2 di `foundry.toml`:

```toml
[rpc_endpoints]
sepolia          = "${SEPOLIA_RPC_URL}"
base_sepolia     = "https://sepolia.base.org"
op_sepolia       = "https://sepolia.optimism.io"
arbitrum_sepolia = "https://sepolia-rollup.arbitrum.io/rpc"
```

Testnet ETH di L2 didapat dengan **bridge dari Sepolia** (lihat C6) atau faucet L2.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Scaling Problem & Rollup-Centric Roadmap](#c1-scaling-problem--rollup-centric-roadmap) | ⬜ |
| **C2** | [Anatomi Rollup](#c2-anatomi-rollup) | ⬜ |
| **C3** | [Optimistic Rollups](#c3-optimistic-rollups) | ⬜ |
| **C4** | [ZK Rollups](#c4-zk-rollups) | ⬜ |
| **C5** | [Data Availability & EIP-4844](#c5-data-availability--eip-4844) | ⬜ |
| **C6** | [Bridges & Cross-Chain Messaging](#c6-bridges--cross-chain-messaging) | ⬜ |
| **C7** | [Developing on L2: Perbedaan yang Wajib Diketahui](#c7-developing-on-l2-perbedaan-yang-wajib-diketahui) | ⬜ |

---

---

# C1: Scaling Problem & Rollup-Centric Roadmap

## Mental Model: Jalan Tol Utama vs Jalur Ekspres

Ethereum L1 memproses sekitar belasan transaksi per detik karena **setiap node memverifikasi setiap transaksi**. Itu yang membuat L1 terdesentralisasi dan aman — sekaligus mahal saat ramai.

```text
Blockchain Trilemma (Phase 1):  Decentralization ── Security ── Scalability
                                        pilih dua, kecuali...

Solusi rollup:
  Eksekusi dipindahkan ke L2  (cepat & murah)
  Data + bukti di-posting ke L1  (mewarisi keamanan L1)
```

## Pendekatan Scaling

| Pendekatan | Ide | Keamanan |
|---|---|---|
| **Sidechain** (misal Polygon PoS) | Chain terpisah dengan validator sendiri + bridge | Bergantung pada validator sidechain |
| **State channel** (Lightning, Raiden) | Transaksi off-chain antar pihak, settle di L1 | Kuat, tapi terbatas untuk peserta tetap |
| **Plasma** | Hanya commitment di L1, data off-chain | Masalah data availability & exit massal |
| **Rollup** | Eksekusi off-chain, **data di L1**, bukti validitas/fraud | **Mewarisi keamanan L1** |
| **Validium** | Seperti ZK rollup, tetapi data di luar L1 | Bergantung pada komite DA |

Ethereum memilih **rollup-centric roadmap**: L1 menjadi lapisan settlement & data availability, sementara eksekusi pengguna berpindah ke rollup.

## Latihan C1

### Soal 1 — Sidechain atau Rollup?
Sebuah chain mengklaim "Layer 2 Ethereum". Pertanyaan apa yang harus Anda ajukan untuk memastikan apakah ia benar-benar rollup atau sidechain? Tuliskan minimal 4.

<details>
<summary>💡 Pembahasan</summary>

1. **Di mana data transaksi disimpan?** Jika tidak di Ethereum (calldata/blob), user tidak bisa merekonstruksi state sendiri → bukan rollup (sidechain/validium).
2. **Bagaimana state root divalidasi di L1?** Ada fraud proof atau validity proof yang dieksekusi oleh contract L1? Atau hanya ditandatangani validator/multisig?
3. **Bisakah user keluar (withdraw) tanpa izin operator?** Adakah *forced inclusion / escape hatch* jika sequencer menyensor?
4. **Siapa yang bisa upgrade contract bridge, dan dengan delay berapa lama?** Upgrade instan oleh multisig berarti keamanan akhirnya = multisig.
5. **Apakah proof system sudah aktif dan permissionless?** (Lihat klasifikasi "Stages" di L2BEAT.)

</details>

---

---

# C2: Anatomi Rollup

```text
                         L2                                          L1 (Ethereum)
┌─────────────────────────────────────────────┐        ┌──────────────────────────────────────┐
│ User ─tx─▶ Sequencer                         │        │                                      │
│             │ urutkan & eksekusi             │        │  Inbox / Batch storage (blob/calldata)│
│             │ (soft confirmation ~detik)     │ batch  │  ◀───────────────────────────────────│
│             ▼                                │ ─────▶ │  State commitment contract            │
│         L2 State (balances, contracts)       │ state  │   (state root + proof/challenge)      │
│             │                                │  root  │                                      │
│         Batcher / Proposer ─────────────────────────▶ │  Bridge contract (deposit/withdraw)   │
└─────────────────────────────────────────────┘        └──────────────────────────────────────┘
```

| Komponen | Tugas |
|---|---|
| **Sequencer** | Menerima & mengurutkan tx L2, memberi konfirmasi cepat. Saat ini umumnya **tunggal & terpusat**. |
| **Batcher** | Mengompres tx dan mem-posting ke L1 (blob/calldata) → data availability |
| **Proposer** | Mem-posting state root L2 ke L1 |
| **Proof system** | Fraud proof (optimistic) atau validity proof (ZK) yang meyakinkan L1 bahwa state root benar |
| **Bridge** | Mengunci aset di L1, mencetak representasinya di L2, dan sebaliknya |

## Tingkat Finality di L2

```text
1. Soft confirmation  → sequencer menerima tx           (~detik, percaya sequencer)
2. Posted to L1       → batch ada di L1                 (urutan tidak bisa diubah sequencer)
3. L1 finalized       → block L1 yang berisi batch final (~13 menit)
4. Settled / proven   → state root terbukti di L1        (optimistic: ~7 hari; ZK: setelah proof diverifikasi)
```

Untuk sebagian besar aksi di dalam L2, (1)–(3) cukup. Untuk **withdraw ke L1**, perlu (4).

## Sequencer: Risiko Sentralisasi

- **Censorship**: sequencer menolak tx Anda → mitigasi: *forced inclusion* via L1 inbox (tx dimasukkan langsung dari L1 setelah delay).
- **Downtime**: sequencer mati → tidak ada tx baru di L2 (protokol DeFi harus memeriksa *Sequencer Uptime Feed*, Phase 8 C5).
- **MEV**: sequencer menentukan urutan → potensi ekstraksi MEV terpusat.

## Latihan C2

### Soal 2 — Peta Kepercayaan
Untuk satu rollup pilihan Anda (Base/Arbitrum/Optimism/zkSync/Scroll), buka halamannya di [L2BEAT](https://l2beat.com/) dan isi tabel: tipe proof, DA layer, stage, delay upgrade, mekanisme forced inclusion, dan risiko utama yang disebutkan. Simpan di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Tabel terisi lengkap dengan link sumber L2BEAT
- [ ] Anda bisa menjelaskan *stage* rollup tersebut dalam satu kalimat


---

---

# C3: Optimistic Rollups

## Ide: "Anggap Benar, Kecuali Dibuktikan Salah"

```text
1. Proposer mem-posting state root ke L1 (dengan bond/jaminan)
2. Challenge period dimulai (~7 hari)
3. Verifier mengeksekusi ulang batch dari data di L1
   ├─ Cocok      → tidak melakukan apa pun
   └─ Tidak cocok → ajukan FRAUD PROOF
                     → bisection game: persempit sengketa hingga 1 instruksi
                     → L1 mengeksekusi 1 instruksi itu on-chain
                     → pihak yang salah kehilangan bond
4. Setelah challenge period tanpa sengketa berhasil → state root final
```

**Asumsi keamanan**: cukup **satu verifier jujur** (1-of-N) yang mengawasi dan mau menantang.

## Mengapa Withdraw Butuh ~7 Hari?

Withdraw L2 → L1 hanya bisa diselesaikan setelah state root yang memuatnya **melewati challenge period**. Waktu itu memberi kesempatan verifier mendeteksi fraud bahkan jika L1 sedang padat atau disensor sementara.

```text
OP Stack (Optimism, Base):  initiate (L2) → prove (L1) → tunggu ~7 hari → finalize (L1)
Arbitrum:                   initiate (L2) → tunggu ~1 minggu → execute di Outbox (L1)
```

**Fast bridge / liquidity provider** menawarkan withdraw instan: mereka membayar Anda di L1 sekarang dan menunggu 7 hari sendiri, dengan imbalan fee.

## Implementasi Populer

| | OP Stack (Optimism, Base, dll.) | Arbitrum Nitro |
|---|---|---|
| Fraud proof | Fault proof (Cannon, MIPS) | Interactive fraud proof (WAVM), BoLD |
| Ekosistem | "Superchain" — banyak chain berbagi stack | Arbitrum One, Nova, Orbit chains |
| Bahasa contract | EVM-equivalent | EVM + Stylus (Rust/C/C++ via WASM) |

## Latihan C3

### Soal 3 — Asumsi Keamanan
Mengapa optimistic rollup aman dengan asumsi "1 verifier jujur", sementara sidechain butuh "mayoritas validator jujur"? Apa yang terjadi pada optimistic rollup jika **tidak ada satu pun** verifier yang mengawasi?

<details>
<summary>💡 Pembahasan</summary>

Pada optimistic rollup, **L1 adalah hakim**: siapa pun yang punya data (tersedia di L1) bisa membuktikan state root salah, dan L1 akan memutuskan secara deterministik. Satu pihak jujur cukup karena kebenaran ditentukan oleh eksekusi, bukan voting. Di sidechain, kebenaran ditentukan oleh tanda tangan validator — jika mayoritas berkolusi, mereka bisa menyetujui state palsu dan tidak ada hakim di atasnya.

Jika **tidak ada verifier**, state root palsu akan lolos setelah challenge period, dan proposer jahat bisa mencuri dana di bridge. Karena itu ekosistem menjalankan banyak verifier independen dan membuat proses challenge *permissionless*.

</details>

---

---

# C4: ZK Rollups

## Ide: "Buktikan Benar Sebelum Diterima"

```text
1. Sequencer mengeksekusi batch
2. Prover menghasilkan VALIDITY PROOF (SNARK/STARK):
     "Saya tahu sekumpulan tx yang, dieksekusi dari state root A, menghasilkan state root B"
3. Verifier contract di L1 memeriksa proof (murah, konstan)
4. Jika valid → state root B langsung final di L1 (tanpa challenge period)
```

## Intuisi Zero-Knowledge Proof

Bukti bahwa sebuah komputasi dilakukan dengan benar, yang **jauh lebih murah diverifikasi** daripada menjalankan ulang komputasinya. (Sifat "zero-knowledge"/privasi sebenarnya tidak selalu dipakai di rollup — yang utama adalah *succinctness*.)

| | SNARK | STARK |
|---|---|---|
| Ukuran proof | Sangat kecil (ratusan byte) | Lebih besar (puluhan–ratusan KB) |
| Trusted setup | Umumnya perlu (Groth16, PLONK punya universal setup) | Tidak perlu |
| Post-quantum | Tidak | Ya (berbasis hash) |
| Contoh | zkSync, Scroll, Polygon zkEVM | Starknet |

## Tipe zkEVM (Klasifikasi Vitalik)

```text
Type 1  — Sepenuhnya setara Ethereum (bisa membuktikan block L1)    → paling kompatibel, proving paling lambat
Type 2  — EVM-equivalent, beda struktur data internal
Type 2.5— Seperti Type 2, tapi biaya gas opcode berbeda
Type 3  — Hampir EVM-equivalent, beberapa precompile/opcode berbeda
Type 4  — Kompilasi Solidity/Vyper ke VM lain (misal zkSync EraVM)  → proving cepat, kompatibilitas paling rendah
```

Implikasi praktis: di zkEVM Type 4, bytecode berbeda dari EVM → `CREATE2` address, `extcodehash`, dan beberapa opcode bisa berperilaku lain. Selalu baca dokumentasi "differences from Ethereum".

## Optimistic vs ZK

| | Optimistic | ZK |
|---|---|---|
| Withdraw ke L1 | ~7 hari (tanpa fast bridge) | Menit–jam (setelah proof) |
| Biaya komputasi off-chain | Rendah | Tinggi (proving) |
| Kompatibilitas EVM | Sangat tinggi | Bervariasi (Type 1–4) |
| Asumsi keamanan | 1 verifier jujur + data tersedia | Matematika/kriptografi + data tersedia |

## Latihan C4

### Soal 4 — Pilih Rollup
Untuk masing-masing kebutuhan berikut, pilih optimistic atau ZK rollup dan jelaskan: (a) exchange yang butuh withdraw ke L1 cepat tanpa fast bridge, (b) protokol DeFi kompleks yang memakai banyak opcode & precompile khusus, (c) aplikasi gaming dengan jutaan tx kecil.

**✅ Selesai jika:**
- [ ] Setiap pilihan disertai minimal satu trade-off yang Anda terima

<details>
<summary>💡 Pembahasan</summary>

- **(a) ZK rollup** — withdraw final setelah proof diverifikasi di L1 (menit–jam), tanpa challenge period 7 hari dan tanpa bergantung pada fast bridge.
- **(b) Optimistic rollup** (atau zkEVM Type 1–2) — kompatibilitas EVM paling tinggi; opcode & precompile berperilaku sama seperti L1 sehingga risiko perbedaan perilaku paling kecil.
- **(c) Keduanya mungkin** — faktor penentunya adalah **biaya data per tx**. Untuk jutaan tx kecil, pertimbangkan kompresi agresif, alt-DA/validium, atau app-chain/L3; trade-off-nya adalah asumsi keamanan data availability yang lebih lemah daripada rollup murni.

</details>


---

---

# C5: Data Availability & EIP-4844

## Mengapa Data Harus Tersedia?

State root tanpa data = janji tanpa bukti. Jika data transaksi tidak tersedia:
- Verifier optimistic **tidak bisa** membuat fraud proof.
- User **tidak bisa** merekonstruksi state untuk membuktikan saldo dan keluar sendiri (bahkan di ZK rollup).

## Biaya L2 Didominasi Data

```text
Biaya tx L2 = L2 execution fee (murah)  +  L1 data fee (porsi data batch di L1)
```

Sebelum 2024, rollup menyimpan data di **calldata** L1 (16 gas per byte non-zero) — mahal dan bersaing dengan tx L1 biasa.

## EIP-4844 (Proto-Danksharding, Dencun 2024)

```text
Blob = ~128 KB data yang:
  - Dibawa oleh tx tipe-3 ("blob-carrying transaction")
  - TIDAK bisa diakses EVM (hanya commitment-nya via BLOBHASH)
  - Dihapus oleh node setelah ~18 hari (cukup untuk challenge period & sinkronisasi)
  - Punya pasar fee terpisah (blob base fee, mekanisme mirip EIP-1559)
```

Dampak: biaya tx di rollup turun drastis karena data tidak lagi bersaing dengan eksekusi L1.

## Setelah EIP-4844: Pectra & Fusaka

| Upgrade | Aktif di mainnet | Perubahan DA yang relevan |
|---|---|---|
| **Pectra** | 7 Mei 2025 | EIP-7691: target/max blob per block naik dari 3/6 → **6/9**. EIP-7623: lantai biaya calldata (10/40 gas per byte nol/non-nol) untuk transaksi data-heavy — mendorong rollup memakai blob, bukan calldata |
| **Fusaka** | 3 Des 2025 | **PeerDAS (EIP-7594)**: node tidak lagi mengunduh seluruh blob, cukup *sampling* sebagian kecil dan tetap yakin secara kriptografis bahwa seluruh data tersedia → kapasitas blob bisa dinaikkan jauh lebih besar tanpa memperberat node. **BPO forks (EIP-7892)**: fork "konfigurasi saja" untuk menaikkan target/max blob bertahap tanpa hard fork penuh |

> ✅ *Terverifikasi 9 Okt 2026 via `eth_config` di mainnet: blob **target 14 / max 21** (fork terakhir aktif 7 Jan 2026).*

Langkah selanjutnya di roadmap adalah **full danksharding** — kapasitas blob jauh lebih besar dengan sampling dua dimensi. Ini **belum aktif**.

### Latihan: Verifikasi Sendiri Status Jaringan

```bash
# Konfigurasi fork aktif & jadwal blob (EIP-7910)
cast rpc eth_config --rpc-url https://ethereum-rpc.publicnode.com | jq '.current.blobSchedule'

# Apakah Fusaka aktif? Eksekusi opcode CLZ (EIP-7939, bagian dari Fusaka).
# Bytecode: PUSH1 1, CLZ, simpan ke memory, RETURN 32 byte → 255 jika aktif
cast rpc eth_call '{"data":"0x60011e60005260206000f3"}' latest \
  --rpc-url https://ethereum-rpc.publicnode.com
```

Bandingkan hasil Anda dengan tabel di atas. Jika angka blob sudah berbeda, berarti ada BPO fork baru — catat di **🗒️ Notes**.

## Alternative DA

| DA | Keamanan |
|---|---|
| Ethereum (blob/calldata) | Setara L1 — **rollup** |
| Celestia, EigenDA, Avail | Asumsi keamanan jaringan DA tersebut — sering disebut **validium/optimium** |
| Data Availability Committee | Kepercayaan pada komite |

## Latihan C5

### Soal 5 — Mengapa Blob Boleh Dihapus?
Blob dihapus setelah ~18 hari, padahal blockchain seharusnya "permanen". Mengapa ini tidak merusak keamanan rollup? Siapa yang tetap menyimpan data historis?

<details>
<summary>💡 Pembahasan</summary>

Data availability menjamin data **dipublikasikan dan bisa diambil oleh siapa pun selama jendela waktu yang dibutuhkan** — cukup untuk (1) challenge period optimistic rollup (~7 hari) dan (2) node L2 serta verifier menyinkronkan & menyimpan data. Commitment (KZG) blob tetap permanen di block L1, sehingga data yang disimpan pihak lain bisa diverifikasi keasliannya kapan pun.

Data historis disimpan oleh node L2 (full/archive), block explorer, indexer, dan layanan arsip. Keamanan tidak memerlukan L1 menyimpan data selamanya — hanya memastikan data **pernah tersedia** untuk semua pihak.

</details>

---

---

# C6: Bridges & Cross-Chain Messaging

## Canonical Bridge (Native)

```text
DEPOSIT (L1 → L2): menit
  User ─deposit─▶ L1 Bridge (lock ETH/token) ─message─▶ L2 (mint/credit) 

WITHDRAW (L2 → L1): optimistic ~7 hari, ZK setelah proof
  User ─withdraw─▶ L2 Bridge (burn) ─▶ state root di-settle ─▶ prove/finalize di L1 (unlock)
```

## Cross-Domain Messaging (OP Stack)

Bukan hanya token — **contract di L1 bisa memanggil contract di L2** dan sebaliknya:

```solidity
// Di L1: kirim pesan ke L2
ICrossDomainMessenger(L1_MESSENGER).sendMessage(
    l2Target,
    abi.encodeCall(L2Greeter.setGreeting, ("hello from L1")),
    200_000                                        // gas limit di L2
);

// Di L2: verifikasi pengirim
function setGreeting(string calldata g) external {
    require(msg.sender == address(L2_MESSENGER), "not messenger");
    require(L2_MESSENGER.xDomainMessageSender() == l1Owner, "not L1 owner");  // ⇐ WAJIB
    greeting = g;
}
```

> ⚠️ Memeriksa `msg.sender == messenger` saja **tidak cukup** — siapa pun bisa mengirim pesan lewat messenger. Selalu periksa `xDomainMessageSender()`.

## Address Aliasing (L1 → L2)

Saat **contract** L1 mengirim tx ke L2 lewat inbox (bukan lewat messenger), `msg.sender` di L2 adalah address L1 yang di-*alias* (`L1 address + 0x1111000000000000000000000000000000001111`). Tujuannya mencegah contract L1 menyamar sebagai contract L2 dengan address yang sama.

## Third-Party Bridges & Risiko

| Model | Contoh Keamanan | Risiko |
|---|---|---|
| **Canonical** | Proof system rollup | Lambat untuk withdraw (optimistic) |
| **Multisig / MPC** | N-of-M penandatangan | Kompromi key penandatangan |
| **Light client / ZK bridge** | Verifikasi konsensus chain sumber | Kompleksitas implementasi |
| **Liquidity network** | LP di kedua chain | Likuiditas, LP risk |

Bridge adalah salah satu target exploit terbesar dalam sejarah crypto (Ronin, Wormhole, Nomad, Multichain) — hampir semuanya karena **validasi pesan atau manajemen key**, bukan karena kriptografi yang rusak.

## Latihan C6

### Soal 6 — Analisis Exploit Bridge
Pilih satu exploit bridge (Ronin 2022, Wormhole 2022, atau Nomad 2022). Baca post-mortem-nya dan jawab: (a) komponen apa yang gagal, (b) kelas bug Phase 8 mana yang paling relevan, (c) satu mitigasi yang seharusnya mencegahnya. Tulis di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Jawaban (a)–(c) dengan link post-mortem
- [ ] Kelas bug dipetakan ke salah satu konsep Phase 8 (C2–C7)


### Soal 7 — Bug Messaging
Mengapa contract L2 berikut berbahaya?

```solidity
function mintFromL1(address to, uint256 amount) external {
    require(msg.sender == address(L2_MESSENGER));
    token.mint(to, amount);
}
```

<details>
<summary>💡 Pembahasan</summary>

Contract hanya memastikan pesan datang **melalui** messenger, bukan **dari siapa** di L1. Siapa pun bisa memanggil `L1CrossDomainMessenger.sendMessage(thisContract, mintFromL1(attacker, 1e30), ...)` dari L1 → messenger di L2 meneruskannya → `msg.sender` memang messenger → mint tanpa batas. Fix: tambahkan `require(L2_MESSENGER.xDomainMessageSender() == TRUSTED_L1_BRIDGE)`.

</details>

---

---

# C7: Developing on L2: Perbedaan yang Wajib Diketahui

"EVM-equivalent" ≠ "identik". Hal-hal yang sering membuat bug:

| Aspek | Perbedaan | Dampak |
|---|---|---|
| **`block.number`** | Arbitrum: mengembalikan **perkiraan nomor block L1**. Gunakan `ArbSys(address(100)).arbBlockNumber()` untuk block L2 | Logika berbasis block number (vesting, voting) salah hitung |
| **`block.timestamp`** | Ditentukan sequencer (dalam batas tertentu) | Jangan bergantung pada presisi detik |
| **Block time** | Base/OP ~2 detik, Arbitrum ~0,25 detik | Asumsi "12 detik per block" salah |
| **Gas model** | Biaya = L2 execution + **L1 data fee** | Estimasi gas `eth_estimateGas` saja tidak cukup; OP Stack menyediakan `GasPriceOracle` predeploy |
| **Calldata** | Byte data mahal (dibayar ke L1) | Optimasi: kompres argumen, hindari data berulang |
| **Opcode/precompile** | Versi EVM & dukungan opcode (misal `PUSH0`) bisa tertinggal; zkEVM Type 3–4 punya perbedaan | Atur `evm_version` sesuai chain target |
| **Sequencer downtime** | Chain berhenti memproduksi block | Oracle & likuidasi: cek Sequencer Uptime Feed |
| **`tx.origin` / aliasing** | Tx dari L1 inbox punya address alias | Otorisasi berbasis `msg.sender` bisa meleset |
| **Predeploys** | Contract sistem di address tetap (OP: `0x4200…`) | Gunakan, jangan menimpanya |

## Deploy ke L2 dengan Foundry

```bash
forge script script/Deploy.s.sol:DeployAll \
  --rpc-url base_sepolia --broadcast --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

> Etherscan API V2 memakai **satu API key untuk 50+ chain** (Ethereum, Base, Optimism, Arbitrum, dst.). Gunakan Foundry versi terbaru (`foundryup`). Untuk verifikasi terpisah setelah deploy:
>
> ```bash
> forge verify-contract <ADDRESS> src/SimpleStorage.sol:SimpleStorage \
>   --chain base-sepolia --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY --watch
> ```
>
> Jika Foundry belum mengenal chain tersebut ("No known Etherscan API URL"), arahkan ke endpoint V2 dengan chain ID eksplisit: `--verifier-url "https://api.etherscan.io/v2/api?chainid=84532"` (84532 = Base Sepolia). Alternatif tanpa API key: `--verifier sourcify` atau `--verifier blockscout`.

## Latihan C7

### Soal 8 — Port VotingSystem
`VotingSystem` (Phase 5) memakai `block.timestamp` untuk deadline. Seandainya versi lain memakai `block.number` dengan asumsi 12 detik per block, apa yang terjadi saat di-deploy ke Arbitrum dan Base? Usulkan desain yang portabel lintas chain.

<details>
<summary>💡 Pembahasan</summary>

- **Base** (~2 detik/block): durasi `N` block menjadi **6× lebih pendek** dari yang dimaksud → voting berakhir terlalu cepat.
- **Arbitrum**: `block.number` mengikuti perkiraan block **L1**, sehingga kebetulan mendekati asumsi 12 detik, tetapi berubah tidak merata (bisa lompat) dan bukan block L2 → perilaku tidak konsisten dengan chain lain.
- **Desain portabel**: gunakan **`block.timestamp`** untuk logika berbasis waktu (dengan toleransi beberapa detik), simpan durasi dalam detik, dan jika butuh block number gunakan abstraksi per chain (misal library yang memanggil `ArbSys` di Arbitrum). Ini juga sebabnya OpenZeppelin Governor mendukung *clock mode* `timestamp` (EIP-6372).

</details>

---

---

# 📝 Mini Project: Multi-Chain Deployment & Gas Comparison

## Tugas

1. Deploy seluruh contract Phase 5 ke **Sepolia, Base Sepolia, OP Sepolia, dan Arbitrum Sepolia**.
2. Untuk setiap chain, jalankan skenario yang sama (deploy, 10× transfer ERC-20, 5× mint NFT, 1× stake) dan catat:

| Chain | Gas used | L2 execution fee | L1 data fee | Total (ETH) | Waktu konfirmasi |
|---|---|---|---|---|---|
| Sepolia | | — | — | | |
| Base Sepolia | | | | | |
| OP Sepolia | | | | | |
| Arbitrum Sepolia | | | | | |

3. Bridge sejumlah kecil Sepolia ETH ke Base Sepolia menggunakan **canonical bridge**, lalu lakukan **withdraw** kembali ke Sepolia. Dokumentasikan setiap langkah (initiate → prove → finalize) dan tx hash-nya.
4. Update indexer Phase 10 agar mendukung **multi-chain** (`chain_id` sudah ada di skema).
5. Tulis `REPORT.md`: perbandingan biaya, porsi L1 data fee, dan rekomendasi chain untuk tiap use case.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Deploy ke **satu** L2 testnet + tabel gas L2 vs Sepolia |
| 🟡 **Extended** — disarankan | Tiga L2 + bridge round-trip (deposit & withdraw) |
| 🔴 **Stretch** — untuk portfolio | Indexer multi-chain + `REPORT.md` dengan rekomendasi |

### ✅ Kriteria Lulus (Core)

- [ ] Semua contract terverifikasi di explorer L2 (link di `deployments/`)
- [ ] Tabel memisahkan **L2 execution fee** dan **L1 data fee** untuk minimal 3 jenis transaksi
- [ ] Penjelasan 3 kalimat: mengapa porsi L1 data fee berbeda antar jenis transaksi


---

# 🏆 Challenge: L1 Governance → L2 Execution

> *Challenge tanpa tutorial.*

## Spesifikasi

```text
SKENARIO:
  DAO (VotingSystem) berada di L1 Sepolia. Treasury/parameter protokol berada di L2 Base Sepolia.
  Proposal yang lolos di L1 harus bisa mengubah parameter di L2.

L1 (Sepolia):
  - L1Governor: setelah proposal executed, kirim pesan via L1CrossDomainMessenger
                ke L2ParameterStore.setFee(newFee)

L2 (Base Sepolia):
  - L2ParameterStore: hanya menerima perubahan jika
      msg.sender == L2CrossDomainMessenger  DAN
      xDomainMessageSender() == L1Governor

SECURITY:
  - Tolak pesan dari pengirim L1 lain
  - Event untuk setiap perubahan parameter
  - Test lokal dengan mock messenger (Foundry), lalu uji end-to-end di testnet
```

## Tugas Challenge

1. Implementasi kedua contract + mock messenger untuk unit test.
2. Test negatif: pesan dari L1 contract lain, panggilan langsung (bukan via messenger), replay.
3. Jalankan end-to-end di testnet; catat waktu dari `execute` di L1 sampai parameter berubah di L2.
4. Jelaskan di `CHALLENGE.md`: apa yang terjadi jika arah sebaliknya (L2 → L1) — berapa lama, dan apa implikasinya untuk desain governance?

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Kedua contract + mock messenger + test negatif |
| 🟡 **Extended** — disarankan | Uji end-to-end di testnet (L1 execute → parameter L2 berubah) |
| 🔴 **Stretch** — untuk portfolio | `CHALLENGE.md`: analisis arah L2 → L1 |

### ✅ Kriteria Lulus (Core)

- [ ] Pesan dari L1 contract selain `L1Governor` → revert
- [ ] Panggilan langsung ke `setFee` (bukan via messenger) → revert
- [ ] Pesan sah mengubah parameter & emit event


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Verifikasi contract di explorer L2 gagal | Chain belum dikenal Foundry / API lama | `--chain <nama>` atau `--verifier-url "https://api.etherscan.io/v2/api?chainid=<id>"` |
| `insufficient funds` di L2 testnet | Belum punya ETH di L2 | Bridge dari Sepolia lewat canonical bridge atau faucet L2 |
| Waktu/deadline berbeda dari perkiraan | Block time & `block.number` L2 berbeda dari L1 | Gunakan `block.timestamp` (C7 Soal 8) |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 12-layer-2/   # path di bawah relatif ke folder fase; kode ada di lab/

git add .
git commit -m "learn: layer 2 — rollups, optimistic vs zk, data availability, eip-4844, bridges"

git add script/ deployments/ REPORT.md
git commit -m "feat: deploy phase 5 contracts to base, optimism and arbitrum sepolia with gas report"

git add src/ test/ CHALLENGE.md
git commit -m "feat: l1 governance to l2 execution via cross-domain messenger (Phase 12 challenge)"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Apa perbedaan mendasar antara sidechain dan rollup dari sisi keamanan?
2. Sebutkan peran sequencer, batcher, dan proposer dalam sebuah rollup.
3. Jelaskan empat tingkat finality di L2. Mana yang dibutuhkan untuk withdraw ke L1?
4. Mengapa optimistic rollup butuh challenge period, dan mengapa ZK rollup tidak?
5. Apa itu bisection game dalam fraud proof?
6. Bandingkan SNARK dan STARK. Apa arti zkEVM "Type 1" vs "Type 4"?
7. Mengapa data availability penting bahkan untuk ZK rollup?
8. Apa yang diubah EIP-4844 dan mengapa biaya L2 turun drastis setelahnya?
9. Mengapa contract penerima cross-domain message harus memeriksa `xDomainMessageSender()`?
10. Sebutkan tiga perbedaan perilaku EVM di L2 yang bisa menyebabkan bug jika diabaikan.

---

## 📊 Progress Tracker

- [ ] **Setup**: RPC endpoints L2, testnet ETH di Base/OP/Arbitrum Sepolia
- [ ] **C1**: Scaling — *trilemma, sidechain vs rollup vs validium*
- [ ] **C2**: Anatomi Rollup — *sequencer, batcher, proposer, finality levels*
- [ ] **C3**: Optimistic Rollups — *fraud proof, challenge period, OP Stack vs Arbitrum*
- [ ] **C4**: ZK Rollups — *validity proof, SNARK vs STARK, tipe zkEVM*
- [ ] **C5**: Data Availability — *blob, EIP-4844, alternative DA*
- [ ] **C6**: Bridges — *canonical bridge, cross-domain messaging, aliasing, bridge hacks*
- [ ] **C7**: Developing on L2 — *block.number, gas model, sequencer uptime, deployment*
- [ ] **Exercise**: Soal 1–8
- [ ] **Mini Project**: Multi-chain deployment + gas comparison + bridge round-trip
- [ ] **Challenge**: L1 governance → L2 execution
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Ethereum.org — Layer 2](https://ethereum.org/en/layer-2/)
- [L2BEAT](https://l2beat.com/) — risiko & stage setiap rollup
- [EIP-4844: Shard Blob Transactions](https://eips.ethereum.org/EIPS/eip-4844)
- [Vitalik — An Incomplete Guide to Rollups](https://vitalik.eth.limo/general/2021/01/05/rollup.html)
- [Vitalik — The different types of ZK-EVMs](https://vitalik.eth.limo/general/2022/08/04/zkevm.html)

### Dokumentasi Chain
- [Optimism Docs — Sending data between L1 and L2](https://docs.optimism.io/)
- [Base Docs](https://docs.base.org/)
- [Arbitrum Docs — Solidity support & differences](https://docs.arbitrum.io/)

### Bridge Security
- [Rekt — Leaderboard](https://rekt.news/leaderboard/) (banyak di antaranya bridge)
- [Chainlink L2 Sequencer Uptime Feeds](https://docs.chain.link/data-feeds/l2-sequencer-feeds)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk tabel L2BEAT dari Soal 2 dan analisis exploit bridge dari Soal 6)*
