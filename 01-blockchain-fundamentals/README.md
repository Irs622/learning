# 01 — Blockchain Fundamentals

> **Level**: 1 — Beginner Conceptual Mastery
> **Phase**: 1 of 13
> **Estimated Time**: 🚀 Intensif 5–7 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 2–3 minggu (Core, ~10 jam/minggu)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan perbedaan arsitektur **Centralized Database (Web2)** vs **Decentralized State Machine (Blockchain)** secara presisi dari kacamata seorang engineer.
- Menjelaskan komponen-komponen jaringan blockchain: *nodes*, *peers*, *validators*, *mempool*.
- Menguraikan secara rinci **anatomi sebuah transaksi** (nonce, gas, payload, signature).
- Melacak siklus hidup transaksi penuh: dari wallet → RPC → mempool → validator → block → finality.
- Memahami implikasi teknis dari **Blockchain Trilemma** terhadap keputusan arsitektur.

---

## 📋 Prerequisites

- [x] Memahami arsitektur Client-Server dan relational database (ACID).
- [x] Memahami konsep HTTP request lifecycle dan REST API.
- [x] Familiar dengan konsep autentikasi dan otorisasi (JWT, Sessions).
- [x] Memahami dasar-dasar jaringan komputer (TCP/IP, DNS, latency).

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Web2 vs Web3: The Architecture Paradigm Shift](#c1-web2-vs-web3--the-architecture-paradigm-shift) | ⬜ |
| **C2** | [Distributed Ledger & P2P Network](#c2-distributed-ledger--p2p-network) | ⬜ |
| **C3** | [Anatomy of a Blockchain Transaction](#c3-anatomy-of-a-blockchain-transaction) | ⬜ |
| **C4** | [Transaction Lifecycle: From Wallet to Finality](#c4-transaction-lifecycle--from-wallet-to-finality) | ⬜ |
| **C5** | [Consensus, Finality & Blockchain Trilemma](#c5-consensus-finality--blockchain-trilemma) | ⬜ |

---

---

# C1: Web2 vs Web3 — The Architecture Paradigm Shift

> *Ini adalah konsep paling krusial. Jika Anda belum memahami ini, semua yang datang setelahnya tidak akan punya makna.*

---

## Mental Model: Siapa yang Memegang Database?

Bayangkan tiga skenario berbeda untuk fitur yang sama: **"Transfer Saldo dari Alice ke Bob sebesar 100 unit"**.

### Skenario A: Aplikasi Konvensional (Web2)

```text
┌─────────────┐
│ Alice       │  1. Alice klik "Kirim"
│ (Browser)   │
└──────┬──────┘
       │ HTTPS POST /api/transfer  {to: "bob", amount: 100}
       ▼
┌─────────────────────────────────┐
│ Backend Server (Laravel/Node)   │  2. Server verifikasi JWT Alice
│                                 │     Cek saldo Alice >= 100
└──────────────┬──────────────────┘
               │ SQL Transaction
               ▼
┌─────────────────────────────────┐
│ Database (PostgreSQL)           │  3. BEGIN TRANSACTION
│                                 │     UPDATE users SET balance = balance - 100 WHERE id = alice_id;
│   alice | balance: 1000 -> 900  │     UPDATE users SET balance = balance + 100 WHERE id = bob_id;
│   bob   | balance:  500 -> 600  │     COMMIT;
└─────────────────────────────────┘
```

**Trust Model**: Alice harus percaya pada:
- Developer yang menulis kode `backend` (tidak ada bug atau backdoor?)
- Admin database yang bisa langsung jalankan `UPDATE users SET balance = 0 WHERE id = alice_id;`
- Perusahaan yang bisa membekukan akun kapan saja
- Server yang bisa down atau kena hack

---

### Skenario B: Aplikasi Web3 (DApp on Ethereum)

```text
┌─────────────┐
│ Alice       │  1. Alice klik "Kirim"
│ (Browser +  │     DApp membentuk transaksi
│  MetaMask)  │
└──────┬──────┘
       │  2. MetaMask meminta Alice SIGN dengan Private Key
       │     Alice memverifikasi & konfirmasi
       ▼
┌─────────────────────────────────────────────────────┐
│  Signed Transaction Object                          │
│  {                                                  │
│    from:     "0xAlice...",                          │
│    to:       "0xTokenContract...",                  │
│    data:     transfer(0xBob, 100_000000),           │
│    nonce:    42,                                    │
│    gasLimit: 65000,                                 │
│    maxFee:   20 gwei,                               │
│    yParity: 0, r: "0xabc...", s: "0xdef..."         │
│  }                                                  │
└──────────────────────┬──────────────────────────────┘
                       │ 3. Broadcast ke RPC Node
                       ▼
┌─────────────────────────────────┐
│ Ethereum P2P Network            │  4. Disebarkan ke ribuan nodes
│ (Gossip Protocol)               │     via Gossip Protocol
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│ Global Mempool                  │  5. Antrean transaksi publik
│ (Waiting Room for Transactions) │     siapapun bisa melihatnya
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│ Validator (Block Proposer)      │  6. Memilih transaksi, menjalankan EVM
│                                 │     Verifikasi signature Alice secara matematis
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│ New Block (Ethereum Blockchain) │  7. Transaksi tersimpan PERMANEN
│ Block #21,500,000               │     Tidak bisa diubah oleh siapapun
│   [tx1] [tx2] [alice->bob:100] │
└─────────────────────────────────┘
```

**Trust Model**: Alice hanya perlu percaya pada:
- **Matematika kriptografi** (bukan pada manusia atau perusahaan)
- **Kode smart contract** yang sudah ter-deploy (bisa diaudit publik oleh siapapun)
- **Aturan konsensus** jaringan yang berjalan di ribuan komputer independen

---

## Tabel Komparasi Kritis (Engineering Perspective)

| Dimensi | Web2 | Web3 |
|---|---|---|
| **State Storage** | Database terpusat (MySQL, PostgreSQL) | Distributed state machine (ribuan node) |
| **Data Mutability** | Mutable — bisa di-UPDATE, DELETE, ROLLBACK | Append-only — hanya bisa tambah state baru |
| **Authentication** | Email/password + server-issued tokens (JWT, Session) | Kriptografi asymetris (Private Key signature) |
| **Authorization** | Server-side rules (`if ($user->role === 'admin')`) | Smart contract logic yang di-enforce oleh EVM |
| **Admin Power** | Sysadmin / DBA bisa ubah data apapun | Tidak ada superuser — code is law |
| **Deployment Updates** | CI/CD — push bugfix kapan saja | Code is permanent setelah deploy (kecuali upgradeable pattern) |
| **Trust Requirement** | Trust the company/server | Verify via cryptography & open-source code |
| **Failure Mode** | Single point of failure (server down → app down) | No single point of failure |
| **Execution Cost** | Flat rate server cost (VPS/cloud) | Per-instruction cost (gas fee) |
| **Transparency** | Kode source tertutup, database private | Smart contract source bisa diverifikasi publik di Etherscan |

---

## Deep Dive: Mengapa "Code is Law"?

Di Web2, jika Anda menulis bug di kode backend Laravel:
```php
// Bug: harusnya >= bukan >
if ($user->balance > $amount) {  
    $user->balance -= $amount;
}
```
Anda bisa:
1. Fix bug-nya
2. Deploy ulang ke server
3. Masalah selesai — user tidak pernah tahu

Di Web3, jika Anda deploy smart contract dengan bug:
```solidity
// Bug yang sama dalam smart contract
function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] > amount); // Bug! harusnya >=
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```
- Contract sudah deployed ke alamat tetap di blockchain
- **Tidak ada tombol "edit" atau "redeploy" ke alamat yang sama**
- Hacker bisa mengeksploitasi bug ini selamanya
- Jika tidak ada mekanisme upgrade yang sudah direncanakan sebelumnya, **dana user bisa terlock selamanya**

> **Ini adalah kenapa security bukan fitur tambahan di Web3. Security ADALAH produknya.**

---

## Latihan C1: Web2 → Web3 Mindset Mapping

### Soal 1 — Analisis Arsitektur
Bayangkan fitur "Forgot Password" di aplikasi Laravel Anda.

**Pertanyaan**: Kenapa secara fundamental mustahil membuat fitur "Reset Private Key" versi Web3 yang setara?

Tulis jawaban Anda di bagian **Notes** README ini sebelum lanjut.

<details>
<summary>💡 Pembahasan (Buka setelah menjawab sendiri!)</summary>

**Jawaban**:

Di Web2, fitur "Forgot Password" bekerja karena ada **server yang menjadi perantara otoritas**:
1. User klik "Forgot Password" 
2. Server menerima request, verify email user di database
3. Server *generate* token reset baru
4. Server *kirim* email ke user
5. User klik link, server *update* password di database

Seluruh proses ini bergantung pada fakta bahwa **server adalah "pemilik data"** — server bisa mengubah password user kapan saja.

Di Web3:
- Private Key **tidak disimpan di server mana pun**
- Private Key **hanya ada di device/hardware wallet user**
- Ethereum blockchain tidak menyimpan Private Key sama sekali — hanya menyimpan **Public Key / Address** (hasil derivasi dari Private Key)
- Tidak ada "pusat" yang bisa mengganti atau me-reset Private Key karena tidak ada yang menyimpannya selain user sendiri

Jika Private Key hilang:
- Tidak ada cara yang diketahui untuk menghitung Private Key dari Address: address adalah hash satu arah dari Public Key, dan Public Key → Private Key terlindungi oleh *Elliptic Curve Discrete Logarithm Problem* (Phase 3)
- **Dana di alamat tersebut hilang selamanya**
- Inilah kenapa seed phrase (12-24 kata) sangat sakral di Web3 — itu adalah satu-satunya "backup" Private Key

</details>

---

### Soal 2 — Skenario Bencana
Anggap Anda CTO di sebuah DeFi protocol. Smart contract Anda baru saja dihack dan $2 juta dana user hilang.

**Pertanyaan**: Dalam konteks Web3 (tanpa mekanisme upgrade atau emergency pause), apakah Anda bisa:
- a) Membatalkan transaksi exploit yang baru terjadi?
- b) Me-revert state blockchain ke kondisi sebelum hack?
- c) Membekukan aset hacker di blockchain?

Tulis analisis Anda. Apa implikasinya terhadap cara Anda menulis smart contract?

<details>
<summary>💡 Pembahasan</summary>

**Jawaban**:

- **a) Tidak.** Transaksi yang sudah included di block tidak bisa dibatalkan. Bahkan validator tidak bisa — konsensus jaringan sudah menyepakati validitas transaksi tersebut.
- **b) Tidak.** Ini akan memerlukan *chain reorganization* (reorg) yang membutuhkan konsensus dari mayoritas validator. Di Ethereum yang sudah mature, melakukan intentional reorg untuk satu protocol adalah praktis mustahil (dan akan merusak kepercayaan terhadap seluruh jaringan — bayangkan jika setiap protocol bisa minta "undo" ketika dihack).
- **c) Tidak secara default.** Aset di blockchain mengikuti kepemilikan berdasarkan Private Key. Tidak ada "freeze" global kecuali token contract-nya sendiri sudah memiliki fungsi `freeze(address)` yang diimplementasikan sebelumnya (seperti USDC yang terpusat).

**Implikasi**: Ini adalah kenapa **testing, auditing, dan security review SEBELUM deployment** adalah hal terpenting dalam lifecycle smart contract. Bukan patch, bukan hotfix — pencegahan adalah satu-satunya pilihan yang efektif.

</details>

---

---

# C2: Distributed Ledger & P2P Network

## Mental Model: Dari Bank ke Jaringan Gossip

Bayangkan sistem pembukuan di dunia nyata:

**Bank Konvensional**:
```text
Kantor Pusat Bank (Server)
│
├── Semua nasabah percaya pada catatan ini
├── Hanya karyawan bank yang bisa baca/tulis
└── Jika gedung terbakar → data bisa hilang (kecuali ada backup)
```

**Blockchain**:
```text
Node 1 (Amsterdam) ── Node 2 (Tokyo) ── Node 3 (New York)
│                         │                    │
Node 4 (London) ── Node 5 (Singapore) ── Node 6 (Jakarta)
│
... ±10.000 node lainnya di seluruh dunia

Setiap node menyimpan SALINAN IDENTIK dari SELURUH riwayat transaksi.
```

---

## Anatomi Jaringan P2P Ethereum

### Node & Jenis-Jenisnya

```text
FULL NODE
├── Menyimpan: Seluruh blockchain history (header + body + state)
├── Melakukan: Verifikasi SETIAP transaksi secara independen
├── Ukuran Storage: ~1-2 TB (Ethereum mainnet, 2024)
└── Peran: Tulang punggung jaringan, tidak perlu percaya siapapun

ARCHIVE NODE
├── Menyimpan: Full node + seluruh historical state di setiap block
├── Melakukan: Bisa query state blockchain di block manapun di masa lalu
├── Ukuran Storage: ~20+ TB
└── Peran: Digunakan oleh block explorers (Etherscan), analytics, indexers

LIGHT NODE
├── Menyimpan: Hanya block headers (metadata blok)
├── Melakukan: Verifikasi terbatas — meminta data ke full nodes
├── Ukuran Storage: ~GB
└── Peran: Wallet mobile, aplikasi resource-terbatas

VALIDATOR NODE (khusus Ethereum PoS)
├── Menyimpan: Semua yang full node miliki
├── Melakukan: Mengusulkan & memvote blok baru
├── Syarat: Stake 32 ETH sebagai jaminan (dislash jika berlaku jahat)
└── Peran: Mengamankan jaringan, mendapat reward block
```

---

### Gossip Protocol: Bagaimana Berita Transaksi Menyebar

Ketika Anda broadcast sebuah transaksi, berita tersebut menyebar seperti gosip di desa:

```text
Langkah 1: Anda kirim transaksi ke RPC Node (misal Infura, Alchemy, atau node sendiri)

Langkah 2: RPC Node broadcast ke ~5-10 peer terdekat
           (Node Amsterdam → Node Frankfurt, London, Paris, Dublin, Amsterdam-2)

Langkah 3: Setiap peer menerima, memvalidasi, dan teruskan ke peer mereka sendiri
           (Frankfurt → Berlin, Vienna, Zurich...)

Langkah 4: Dalam ~1-5 detik, hampir seluruh ribuan node di dunia sudah menerima transaksi
           dan memasukkannya ke mempool lokal mereka
```

*Tidak ada server pusat yang meneruskan transaksi — murni peer-to-peer.*

---

### Mempool: Global Waiting Room

**Mempool** (Memory Pool) adalah kumpulan transaksi yang sudah valid secara kriptografis tapi belum dimasukkan ke dalam block.

```text
MEMPOOL (setiap full node punya copy-nya sendiri)

┌────────────────────────────────────────────────────────┐
│ tx_hash: 0xabc...  gasPrice: 50 gwei  status: pending  │
│ tx_hash: 0xdef...  gasPrice: 30 gwei  status: pending  │
│ tx_hash: 0x123...  gasPrice: 80 gwei  status: pending  │
│ tx_hash: 0x456...  gasPrice: 15 gwei  status: pending  │
│ ... (bisa ribuan transaksi di saat sibuk)              │
└────────────────────────────────────────────────────────┘
         ▲                              │
         │ Broadcast masuk             │ Builder/validator pilih yang priority fee tertinggi
         │                             ▼
     User Wallet                   New Block (ratusan tx)
```

**Key Insight**: Karena mempool bersifat publik, **siapapun bisa melihat transaksi yang belum dieksekusi**. Ini adalah sumber dari serangan **MEV (Maximal Extractable Value)** dan **Front-running** — topik yang sangat penting di security.

---

### Block: Unit Penyimpanan State

Setiap ~12 detik di Ethereum, validator memilih transaksi dari mempool dan mengemas menjadi sebuah **Block**:

```text
BLOCK #21,500,000
┌───────────────────────────────────────────────────────────┐
│ HEADER                                                    │
│   parentHash:    0x7f3... (hash dari blok sebelumnya)    │
│   stateRoot:     0x9a1... (hash seluruh state setelah    │
│                             semua tx di blok ini)        │
│   transactionsRoot: 0x4b2... (merkle root semua tx)      │
│   timestamp:     1735000012                              │
│   gasLimit:      36,000,000+ (dinaikkan bertahap; cek    │
│                  nilai terkini di Etherscan)             │
│   gasUsed:       18,432,000                              │
│   proposer:      0xValidator...                          │
├───────────────────────────────────────────────────────────┤
│ TRANSACTIONS (berurutan)                                  │
│   [0] 0xAlice sends 1 ETH to Bob           gas: 21000    │
│   [1] 0xSwap on Uniswap                   gas: 120000    │
│   [2] 0xMint NFT                          gas: 80000     │
│   ... (hingga batas gasLimit blok terpenuhi)             │
└───────────────────────────────────────────────────────────┘
```

**Kunci Immutability**: Field `parentHash` adalah hash dari SELURUH isi blok sebelumnya. Jika seseorang mengubah transaksi di blok lama, hash-nya berubah, sehingga `parentHash` di blok berikutnya jadi salah, lalu semua blok setelahnya juga invalid. Itulah kenapa sejarah tidak bisa diubah tanpa me-recompute ulang seluruh rantai.

---

## Latihan C2: Network Anatomy

### Soal 3 — Skenario Ketahanan Jaringan
Seorang politisi di sebuah negara memerintahkan semua ISP untuk memblokir traffic blockchain. 1.000 node di negara tersebut tiba-tiba offline.

**Pertanyaan**:
- a) Apakah blockchain Ethereum berhenti berfungsi?
- b) User dari negara tersebut masih bisa bertransaksi? Bagaimana caranya?
- c) Bandingkan dengan skenario yang sama jika terjadi pada PayPal (yang punya satu data center utama).

<details>
<summary>💡 Pembahasan</summary>

**a)** Tidak. Jika 1.000 node offline, masih ada ~9.000+ node lain di seluruh dunia yang terus beroperasi. Jaringan terus berjalan — mungkin sedikit lebih lambat jika node tersebut adalah validator aktif, tapi tidak berhenti.

**b)** Ya, masih bisa. User bisa menggunakan:
- VPN untuk terhubung ke RPC node di luar negeri
- Layanan RPC publik (Infura, Alchemy, Ankr) yang ada di negara lain
- Menjalankan node sendiri via Tor atau jaringan terenkripsi lainnya

**c)** Jika PayPal data center utama turun (atau pemerintah memintanya untuk membekukan akun), PayPal *tidak bisa* memproses transaksi. Seluruh sistem bergantung pada ketersediaan server mereka. Ini adalah perbedaan fundamental: **censorship resistance** (ketahanan terhadap sensor) adalah properti inheren blockchain yang tidak dimiliki sistem terpusat.

</details>

---

### Soal 4 — Mempool Visibility & MEV
Anda mengirim transaksi untuk membeli token di Uniswap ketika harga sedang murah. Transaksi masuk ke mempool dengan gas price 20 gwei.

Seorang MEV bot melihat transaksi Anda di mempool dan mengirim transaksi pembelian yang sama TAPI dengan gas price 21 gwei (lebih tinggi 1 gwei).

**Pertanyaan**:
- a) Transaksi mana yang dieksekusi lebih dulu oleh validator, dan mengapa?
- b) Apa yang terjadi ke token price ketika transaksi MEV bot dieksekusi sebelum transaksi Anda?
- c) Anda akhirnya membeli token tersebut di harga lebih mahal dari yang Anda mau. Serangan jenis apa ini?

<details>
<summary>💡 Pembahasan</summary>

**a)** Transaksi MEV bot (21 gwei) dieksekusi lebih dulu. Validator secara rasional selalu memilih transaksi dengan gas price tertinggi terlebih dahulu karena itu memaksimalkan pendapatan mereka.

**b)** Bot membeli token lebih dulu → harga naik (karena AMM model x*y=k, pembelian menaikkan harga). Ketika transaksi Anda dieksekusi, harga sudah lebih tinggi.

**c)** Ini disebut **Front-running** — spesifiknya adalah variasi dari **Sandwich Attack** (bot beli sebelum Anda, lalu jual setelah transaksi Anda, memanfaatkan perubahan harga yang disebabkan oleh transaksi Anda). Ini adalah serangan yang sangat relevan untuk developer DeFi dan akan kita pelajari mendalam di Phase 8 (Smart Contract Security).

</details>

---

---

# C3: Anatomy of a Blockchain Transaction

> *Transaksi adalah unit komputasi dasar di blockchain. Memahami setiap field-nya adalah kunci untuk debugging dan security.*

---

## Mental Model: Cek Bertanda Tangan vs HTTP Request

Di Web2, "transaksi" ke server adalah sebuah HTTP request:
```http
POST /api/transfer
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "recipient": "bob",
  "amount": 100
}
```
Server percaya pada token JWT yang diterbitkan olehnya sendiri. Jika JWT dicuri, orang lain bisa berpura-pura jadi Anda.

Di Web3, "transaksi" adalah sebuah pesan kriptografis:
```json
{
  "from":                 "0xAlice...",
  "to":                   "0xContract...",
  "value":                "0",
  "data":                 "0xa9059cbb000...00064",
  "nonce":                42,
  "chainId":              1,
  "maxFeePerGas":         "20000000000",
  "maxPriorityFeePerGas": "1500000000",
  "gasLimit":             "65000",
  "yParity":              0,
  "r":                    "0xabc123...",
  "s":                    "0xdef456..."
}
```
Validitas ditentukan secara matematis dari signature `(yParity/v, r, s)` — bukan oleh server. (Transaksi EIP-1559 / tipe-2 memakai `yParity` bernilai 0 atau 1; transaksi *legacy* memakai `v` = 27/28 atau `chainId × 2 + 35/36` per EIP-155.)

---

## Setiap Field, Explained

### `from` (Address — 20 bytes)
Alamat Ethereum pengirim. Field ini **tidak pernah ikut ditandatangani/dikirim** di dalam transaksi — node selalu me-*recover*-nya secara matematis dari signature `(v, r, s)` dan hash transaksi. Ini adalah bukti bahwa hanya pemilik Private Key yang bisa menghasilkan signature tersebut.

```
Private Key → Sign(hash(tx)) → (v, r, s)
(v, r, s) + hash(tx) → ecrecover → Public Key → Address
```

### `to` (Address — 20 bytes)
- Jika diisi Address EOA (wallet biasa): ini adalah transfer ETH biasa.
- Jika diisi Address Contract: ini adalah pemanggilan fungsi smart contract.
- Jika kosong (`null`): ini adalah **contract deployment transaction** — EVM akan membuat contract baru.

### `value` (uint256, dalam wei)
Jumlah ETH yang ikut dikirim bersama transaksi, dalam satuan **wei** (1 ETH = 10¹⁸ wei).

```
1 ETH     = 1,000,000,000,000,000,000 wei (1e18)
1 Gwei    = 1,000,000,000 wei (1e9)  — dipakai untuk gas price
1 Finney  = 1,000,000,000,000,000 wei (1e15)
```

Bisa nol jika Anda hanya memanggil fungsi yang tidak membutuhkan pembayaran ETH.

### `data` / `calldata` (bytes)
Payload instruksi yang dikirim ke smart contract. Berisi:
- **Function selector**: 4 bytes pertama — Keccak-256 hash dari function signature, ambil 4 bytes pertama.
- **Encoded arguments**: sisanya adalah parameter yang di-ABI encode.

```
Misalnya memanggil: transfer(address to, uint256 amount)
                    transfer(0xBob, 100 * 10^18)

Function Selector = bytes4(keccak256("transfer(address,uint256)"))
                  = 0xa9059cbb

Encoded args (32 bytes per param):
  to:     0x000000000000000000000000[BobAddress]
  amount: 0x0000000000000000000000000000000000000000000000056bc75e2d63100000

Full calldata = 0xa9059cbb
                000000000000000000000000[BobAddress]
                0000000000000000000000000000000000000000000000056bc75e2d63100000
```

### `nonce` (uint64)
Penghitung berapa banyak transaksi yang sudah Alice kirim dari alamatnya (dimulai dari 0). Ini adalah:
1. **Anti-replay protection**: Transaksi yang sama tidak bisa dieksekusi dua kali (karena nonce akan berbeda).
2. **Ordering guarantee**: Transaksi dengan nonce lebih rendah HARUS diproses lebih dulu.

```
Jika Alice sudah kirim 42 transaksi:
- Transaksi ke-43 harus punya nonce = 42
- Jika dikirim dengan nonce = 50 → transaksi macet di mempool menunggu nonce 43-49 lebih dulu
- Jika attacker coba replay transaksi lama (nonce=10) → validator tolak karena nonce sudah dipakai
```

### `chainId` (uint256)
ID unik untuk setiap network agar transaksi tidak bisa di-replay di network lain (EIP-155).

```
Ethereum Mainnet:    chainId = 1
Ethereum Sepolia:    chainId = 11155111
Polygon:             chainId = 137
Arbitrum One:        chainId = 42161
Base:                chainId = 8453
Anvil (local):       chainId = 31337
```

**Tanpa chainId**: Transaksi yang valid di Ethereum bisa di-replay ke network lain dengan cukup menyiarkannya ulang — serangan yang pernah terjadi di awal sejarah Ethereum.

### `gasLimit` (uint64)
Maximum unit gas yang Anda izinkan dikonsumsi oleh transaksi ini. Ini adalah proteksi Anda:
- Terlalu rendah → transaksi gagal "out of gas", tapi **nonce tetap naik** dan ETH untuk gas tetap terpakai.
- Terlalu tinggi → tidak masalah, Anda hanya membayar gas yang benar-benar dipakai.

Referensi biaya gas dasar:
```
Transfer ETH biasa:               21,000 gas
Transfer ERC-20 token:           ~65,000 gas
Swap di Uniswap v3:             ~150,000 gas
Deploy contract sederhana:       ~200,000+ gas
```

### `maxFeePerGas` & `maxPriorityFeePerGas` (EIP-1559)
Sejak upgrade London (2021), Ethereum menggunakan mekanisme baru:

```
Total gas cost = gasUsed × effectiveGasPrice

Dimana:
effectiveGasPrice = min(maxFeePerGas, baseFee + maxPriorityFeePerGas)

baseFee     = ditentukan protokol berdasarkan kepadatan blok sebelumnya (dibakar/burned)
priorityFee = "tip" untuk validator, insentif agar transaksi Anda dipilih lebih cepat
maxFeePerGas= batas maksimum yang bersedia Anda bayar (melindungi dari baseFee spike)
```

### `v`, `r`, `s` — The ECDSA Signature
Ini adalah tanda tangan kriptografis. Dihasilkan dari:
```
hash = keccak256(RLP_encoded(tx_fields_without_signature))
(v, r, s) = ECDSA.sign(hash, privateKey)
```

- `r` dan `s`: Dua komponen bilangan 32-byte dari signature ECDSA.
- `v`: Recovery ID (0, 1, atau offset dari chainId per EIP-155) — memungkinkan verifier merecovery Public Key dari signature tanpa perlu tahu Public Key-nya terlebih dahulu.

Validasi yang dilakukan validator:
```
signer = ecrecover(hash, v, r, s) → returns address
require(signer == tx.from)        → membuktikan kepemilikan Private Key
require(nonce == state.nonce[signer]) → membuktikan urutan yang benar
require(balance[signer] >= value + gasLimit * maxFeePerGas) → cukup saldo
```

---

## Latihan C3: Transaction Dissection

### Soal 5 — Etherscan Investigation
Buka Etherscan ([etherscan.io](https://etherscan.io)) dan cari transaksi hash ini:
`0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060`

*(Ini adalah **transaksi pertama** di mainnet Ethereum — block 46147, Agustus 2015. Transaksi sederhana, tetapi bersejarah.)*

**Pertanyaan**:
- a) Apa isi field `from`, `to`, `value`, dan `input` (calldata)?
- b) Berapa gas yang digunakan vs gas limit yang diset?
- c) Di block nomor berapa transaksi ini included?
- d) Berapa ETH yang dipindahkan?

*Tulis temuan Anda di bagian Notes README ini.*

**✅ Selesai jika:**
- [ ] Jawaban a–d tertulis di Notes, masing-masing dengan nilai mentah dari Etherscan
- [ ] Cek silang: transfer ETH murni (input `0x`) **selalu** memakai tepat 21.000 gas — jika jawaban (b) Anda berbeda, periksa ulang


---

### Soal 6 — Nonce Calculation
Alice memiliki address `0xAlice`. Berdasarkan Etherscan, address Alice sudah mengirimkan 15 transaksi sebelumnya.

**Pertanyaan**:
- a) Nonce berapa yang harus dipakai untuk transaksi Alice berikutnya?
- b) Alice mengirim 3 transaksi sekaligus dari aplikasi yang berbeda, semuanya dengan nonce = 15. Apa yang terjadi?
- c) Alice lupa dan mengirim transaksi dengan nonce = 14 (nonce yang sudah dipakai sebelumnya). Apa yang terjadi?

<details>
<summary>💡 Pembahasan</summary>

**a)** Nonce = 15 (dimulai dari 0, jadi setelah 15 transaksi, nonce berikutnya adalah 15).

**b)** Jika tiga transaksi dikirim dengan nonce sama (15):
- Hanya **satu** transaksi yang akan dieksekusi (biasanya yang gas price paling tinggi)
- Dua transaksi sisanya akan di-drop dari mempool karena nonce sudah "terpakai" oleh transaksi yang dieksekusi
- Ini bisa terjadi ketika Anda mau "cancel" transaksi yang stuck di mempool — caranya adalah mengirim transaksi baru dengan nonce yang sama tapi gas price lebih tinggi dan value=0

**c)** Transaksi dengan nonce = 14 akan langsung **ditolak** oleh validator dan tidak masuk ke mempool. State blockchain sudah mencatat bahwa nonce 14 sudah dipakai. Setiap nonce hanya bisa dipakai SATU KALI per alamat.

</details>

---

---

# C4: Transaction Lifecycle — From Wallet to Finality

## The Complete Journey

```text
┌──────────────────────────────────────────────────────────────────┐
│                     TRANSACTION LIFECYCLE                        │
└──────────────────────────────────────────────────────────────────┘

STEP 1: CONSTRUCTION (di client/frontend)
│
│  DApp membentuk transaction object berdasarkan user input
│  {to, value, data, gasLimit, maxFeePerGas, ...}
│
▼
STEP 2: SIGNING (di wallet — MetaMask, hardware wallet, etc.)
│
│  1. Hitung hash dari transaction object (RLP encode + Keccak256)
│  2. Tanda tangani dengan Private Key user → (v, r, s)
│  3. Signed transaction siap di-broadcast
│  ⚠️  Private Key TIDAK PERNAH meninggalkan wallet
│
▼
STEP 3: BROADCAST (via RPC Provider)
│
│  eth_sendRawTransaction(signedTx)
│  → Dikirim ke RPC endpoint (Infura, Alchemy, atau node sendiri)
│  → Node lakukan basic validation:
│     - Signature valid?
│     - Nonce benar?
│     - Saldo cukup untuk gas?
│  → Jika valid: masuk ke Mempool lokal node, disebarkan via Gossip
│
▼
STEP 4: MEMPOOL (Global Waiting Room)
│
│  Status: "Pending" di frontend/wallet
│  
│  Faktor yang menentukan berapa lama di sini:
│  - Network congestion (berapa banyak transaksi yang bersaing)
│  - Gas price yang ditawarkan vs current baseFee
│
│  Kasus-kasus:
│  ┌─ Normal    → Included dalam 1-3 blocks (~12-36 detik)
│  ├─ Murah     → Stuck berjam-jam/berhari-hari SAMPAI baseFee turun
│  └─ Sangat    → Transaksi di-drop dari mempool setelah beberapa hari
│     Murah       jika tidak pernah diinclude
│
▼
STEP 5: INCLUSION (Validator picks the transaction)
│
│  Setiap ~12 detik, validator yang bertugas (block proposer):
│  1. Ambil transaksi dari mempool (prioritas: priority fee tertinggi)
│  2. Sort transaksi dalam blok (untuk MEV optimization)
│  ℹ️ Saat ini mayoritas block disusun oleh *builder* khusus via
│     MEV-Boost; proposer hanya memilih block bernilai tertinggi (Phase 13)
│  3. Eksekusi transaksi satu per satu di EVM lokal mereka
│  4. Hitung state root baru
│  5. Bentuk block header dan body
│  6. Broadcast block baru ke jaringan
│
▼
STEP 6: EXECUTION (Inside the EVM)
│
│  Untuk setiap transaksi:
│  1. Deduct gas dari sender (gasLimit * gasPrice)
│  2. Increment nonce sender
│  3. Jika `to` adalah contract: load bytecode dan jalankan EVM
│  4. Jika ETH transfer: update balance sender & recipient
│  5. Refund sisa gas yang tidak terpakai ke sender
│  6. Jika REVERT terjadi: semua state change di-rollback,
│     TAPI gas sudah terpakai tidak dikembalikan
│
▼
STEP 7: ATTESTATION & FINALITY (Post-Merge Ethereum PoS)
│
│  Block baru disebarkan ke seluruh jaringan.
│  Validator lain mem-"vote" (attest) bahwa block valid.
│
│  Confirmation levels:
│  ├─ 1 confirmation  → Included di 1 block (~12 detik)
│  │                    [Aman untuk transaksi kecil]
│  ├─ 6 confirmations → Praktis aman untuk sebagian besar use case
│  └─ Finalized       → Setelah ~2 epochs (~12-15 menit)
│                       Secara kriptoekonomi mustahil di-reorg
│                       [Aman untuk transaksi bernilai tinggi]
│
▼
STEP 8: FINAL STATE
   Transaksi tersimpan permanen.
   State baru (balance, storage contract, dll) ter-commit ke blockchain.
   Tidak dapat diubah oleh siapapun.
```

---

## Transaction Status & What They Mean

| Status | Arti | Apa yang Harus Dilakukan? |
|---|---|---|
| `pending` | Di mempool, belum included | Tunggu, atau speed up dengan gas lebih tinggi |
| `included` | Di block, tapi belum final | Tunggu beberapa confirmations |
| `success` | Executed, tidak ada revert | Selesai! |
| `failed/reverted` | Executed, tapi EVM encounter revert | Cek error message. Gas TETAP habis! |
| `dropped` | Di-drop dari mempool | Kirim ulang dengan gas lebih tinggi |

---

## Gas: The Economic Engine

Gas adalah mekanisme yang mencegah seseorang menjalankan infinite loop di EVM dan membekukan seluruh jaringan:

```
Setiap opcode EVM punya "harga gas":
  ADD        = 3 gas
  MSTORE     = 3 gas  
  SLOAD      = 2100 gas  (baca dari storage — mahal!)
  SSTORE     = 20000 gas (tulis ke slot kosong — sangat mahal! detail lengkap di Phase 2)
  CALL       = 2600 gas
  CREATE     = 32000 gas

Total biaya transaksi = (21.000 intrinsik + biaya calldata + Σ opcode yang dijalankan) × effectiveGasPrice
```

**Kenapa mahal di Layer 1?** Karena setiap SSTORE dan SLOAD berarti membaca/menulis ke state database yang disimpan oleh ribuan node di seluruh dunia secara sinkron. Bandingkan dengan `SELECT` di PostgreSQL yang hanya menyentuh satu server.

---

## Latihan C4: Transaction Lifecycle Engineering

### Soal 7 — "Stuck Transaction" Debugging
User Anda mengirim transaksi dengan gas fee 10 gwei, tapi network sedang sangat sibuk dan current baseFee adalah 50 gwei.

**Pertanyaan**:
- a) Kenapa transaksi user stuck di mempool?
- b) Apa yang harus user lakukan untuk "speed up" transaksi tanpa membuat wallet address baru?
- c) Apa yang dimaksud dengan "cancelling" transaksi di MetaMask, dan secara teknis apa yang sebenarnya terjadi?

<details>
<summary>💡 Pembahasan</summary>

**a)** Karena `maxFeePerGas` (10 gwei) lebih rendah dari `baseFee` (50 gwei). Per aturan protokol EIP-1559, transaksi dengan `maxFeePerGas < baseFee` **tidak valid untuk dimasukkan ke block** — bukan sekadar "tidak menguntungkan", melainkan block yang memuatnya akan ditolak jaringan. Transaksi menunggu di mempool sampai baseFee turun di bawah 10 gwei, atau user me-replace-nya. Selama menunggu, **tidak ada ETH yang terpakai**.

**b)** User harus mengirim transaksi baru dengan nonce yang SAMA (nonce transaksi yang stuck) dengan `maxFeePerGas` yang lebih tinggi dari baseFee saat ini. Karena nonce sama, transaksi baru ini akan "replace" transaksi lama di mempool node — dengan syarat **`maxFeePerGas` dan `maxPriorityFeePerGas` masing-masing naik minimal ~10%** (aturan replacement di Geth; jika kurang, node menolaknya sebagai *replacement transaction underpriced*).

**c)** "Cancel" di MetaMask sebenarnya mengirimkan transaksi baru dengan:
- Nonce yang SAMA dengan transaksi yang mau di-cancel
- `to` = alamat user sendiri (self-transfer)
- `value` = 0 ETH
- Gas fee lebih tinggi dari transaksi original

Jika transaksi "cancel" ini di-include lebih dulu, transaksi original akan di-invalidate karena noncenya sudah terpakai. **Biaya cancel** = biaya gas transaksi baru ini (tidak gratis!).

</details>

---

### Soal 8 — Finality & Business Logic
Anda membangun platform peer-to-peer jual beli barang fisik (seperti Tokopedia versi Web3). Buyer mengirim ETH, dan seller harus kirim barang fisik.

**Pertanyaan**: Berapa block confirmations yang seharusnya Anda tunggu sebelum sistem Anda otomatis memberikan notifikasi ke seller untuk proses pengiriman? Jelaskan reasoning engineering-nya berdasarkan nilai transaksi:
- Transaksi < 0.01 ETH
- Transaksi antara 0.01 - 1 ETH
- Transaksi > 1 ETH

<details>
<summary>💡 Pembahasan</summary>

Ini adalah pertanyaan trade-off antara **user experience** (makin cepat makin bagus) vs **security** (makin banyak confirmations makin aman dari reorg).

**Reorg risk calculation**: Semakin banyak block yang sudah di-built di atas block Anda, semakin mahal biaya untuk mereorg chain dan "menghapus" transaksi Anda.

**Rekomendasi reasoning**:
- **< 0.01 ETH**: 1-3 confirmations (~12-36 detik). Nilai rendah, biaya untuk mereorg jauh lebih mahal dari keuntungan yang bisa didapat attacker. UX > Security di sini.
- **0.01 - 1 ETH**: 6-12 confirmations (~72-144 detik). Balance yang wajar.
- **> 1 ETH**: 32-64 confirmations, atau tunggu hingga block mencapai status "Finalized" (~12-15 menit via Ethereum PoS checkpointing). Nilai tinggi membenarkan penundaan tambahan. Sama seperti mengapa toko emas tidak langsung melepas barang sebelum dana benar-benar clear.

Dalam produk nyata, banyak exchange terpusat menunggu block mencapai **finalized** (atau jumlah konfirmasi setara ~2 epoch) sebelum mengkreditkan deposit ETH.

</details>

---

---

# C5: Consensus, Finality & Blockchain Trilemma

## Consensus: Bagaimana Ribuan Node Sepakat?

Masalah fundamental: Jika tidak ada server pusat sebagai otoritas, bagaimana 10.000 node yang tersebar di seluruh dunia bisa *sepakat* tentang urutan transaksi mana yang valid?

Ini adalah versi komputasi dari **Byzantine Generals Problem** (1982): Bagaimana para jenderal yang tersebar secara geografis bisa koordinasi serangan jika beberapa di antara mereka mungkin pengkhianat?

### Proof of Work (PoW) — Cara Lama (Bitcoin, Ethereum pre-2022)

```text
Untuk mengusulkan block baru:
Miner harus membuktikan bahwa mereka sudah menghabiskan komputasi besar
dengan menemukan angka (nonce) sehingga:
  Hash(blockHeader + nonce) < targetDifficulty

Ini adalah "Proof" bahwa mereka sudah "Work" (bekerja secara komputasi).
Mengubah sejarah = harus melakukan ulang seluruh komputasi tersebut PLUS
semua block setelahnya PLUS menjadi lebih cepat dari seluruh jaringan.
```

**Kelemahan**: Konsumsi energi yang sangat besar (Bitcoin ~150 TWh/tahun, setara negara Polandia).

### Proof of Stake (PoS) — Ethereum Modern (sejak "The Merge", September 2022)

```text
Untuk menjadi validator:
  - Stake (kunci) minimal 32 ETH sebagai jaminan (collateral)
    (sejak Pectra/EIP-7251, satu validator bisa memiliki effective balance hingga 2.048 ETH)

Untuk mengusulkan / menyetujui block:
  - Dipilih secara pseudo-random, proporsional terhadap ETH yang di-stake
  - Tanda tangan digital digunakan sebagai "vote"

Jika validator berlaku jahat (misal: vote untuk dua block yang berkonflik):
  - SLASHING: sebagian stake di-burn & validator dikeluarkan; penalti membesar
    (hingga seluruh stake) jika banyak validator di-slash dalam periode yang sama
  - Ini menciptakan cryptoeconomic security: biaya menyerang jaringan 
    harus lebih besar dari keuntungan yang bisa didapat
```

---

## Finality: Kapan Transaksi Benar-Benar "Done"?

**Finality** adalah jaminan bahwa sebuah block/transaksi tidak akan pernah di-revert.

Di Ethereum PoS, finality dicapai melalui mekanisme **checkpointing**:
```
Setiap EPOCH = 32 slots = ~6.4 menit

Setiap epoch, validator vote untuk "checkpoint" block.
Jika >66.7% dari total staked ETH memvote untuk checkpoint yang sama,
block tersebut dianggap "Justified".

Jika checkpoint berikutnya (epoch tepat setelahnya) juga Justified, checkpoint sebelumnya
— beserta semua block sebelumnya — menjadi "Finalized".

Timeline: ~2 epochs = ~12-15 menit untuk finality
```

Setelah block Finalized:
- Untuk me-revert block ini, harus ada konflik finalisasi yang membutuhkan **>1/3 dari seluruh staked ETH** ikut melanggar aturan — dengan ~34 juta ETH ter-stake, itu **>11 juta ETH** (puluhan miliar dolar)
- DAN validator yang melanggar akan di-slash; karena *correlation penalty*, pelanggaran massal seperti ini menghanguskan **sebagian besar hingga seluruh** stake mereka
- Biaya serangan: jauh lebih besar dari keuntungan yang mungkin didapat

---

## Blockchain Trilemma

Vitalik Buterin (pendiri Ethereum) merumuskan bahwa sangat sulit untuk memiliki ketiga properti ini sekaligus dalam satu blockchain:

```text
              SECURITY
             /        \
            /          \
           /____________\
    DECENTRALIZATION    SCALABILITY
```

| Pilihan | Decentralization | Security | Scalability |
|---|:---:|:---:|:---:|
| **Bitcoin** | ✅ Tinggi | ✅ Tinggi | ❌ ~7 TPS |
| **Ethereum L1** | ✅ Tinggi | ✅ Tinggi | ❌ ~15 TPS |
| **Solana** | ⚠️ Sedang | ⚠️ Sedang | ✅ ~65,000 TPS (teoretis; aktual ribuan) |
| **Private Blockchain** | ❌ Rendah | ⚠️ Sedang | ✅ Tinggi |
| **Ethereum L2 (Optimism/Base)** | ⚠️ Sedang (sequencer masih terpusat) | ✅ Mewarisi L1 (tergantung *stage*, Phase 12) | ✅ Ribuan TPS |

**Kenapa ini penting untuk developer?**
- Ini menjelaskan kenapa transaksi di Ethereum L1 mahal dan lambat.
- Ini menjelaskan kenapa sebagian besar DApp modern di-deploy ke **Layer 2** (Base, Arbitrum, Optimism).
- Pemilihan network untuk deployment adalah keputusan arsitektur, bukan preferensi — bergantung pada trade-off security vs cost vs speed yang sesuai untuk use case Anda.

---

## Latihan C5: Trilemma Trade-offs

### Soal 9 — Architecture Decision
Anda ditugaskan untuk memilih blockchain platform untuk tiga klien berbeda:

1. **Klien A**: Bank sentral ingin membuat CBDC (Central Bank Digital Currency) yang bisa diaudit oleh pemerintah, throughput tinggi untuk transaksi retail jutaan orang.
2. **Klien B**: Startup DeFi yang ingin membuat DEX dengan gas fee rendah untuk trader retail.
3. **Klien C**: Protocol NFT high-value (NFT harga ratusan ETH) yang butuh jaminan keamanan tertinggi dan decentralization untuk meyakinkan kolektor.

**Pertanyaan**: Rekomendasikan blockchain/network (bisa dari: Ethereum L1, Ethereum L2 seperti Base/Arbitrum, Private Consortium Blockchain, Solana) untuk masing-masing klien. Jelaskan reasoning berdasarkan Blockchain Trilemma.

<details>
<summary>💡 Pembahasan</summary>

**Klien A (CBDC Bank Sentral)**:
- **Rekomendasi**: Private/Permissioned Consortium Blockchain (misal: Hyperledger Fabric, atau custom EVM chain dengan validator terpilih)
- **Alasan**: Bank sentral MEMBUTUHKAN kontrol dan sensor (bisa membekukan akun, undo transaksi ilegal untuk compliance), throughput tinggi untuk jutaan transaksi/hari, dan tidak memerlukan trustless decentralization karena otoritas moneter adalah entitas terpercaya by design. Paradoxically, "Decentralization" adalah fitur yang TIDAK diinginkan di sini.

**Klien B (DeFi DEX untuk retail)**:
- **Rekomendasi**: Ethereum Layer 2 (Base atau Arbitrum)
- **Alasan**: Gas fee rendah (10-100x lebih murah dari L1), throughput tinggi untuk trading, tetapi inherits security dari Ethereum L1 (lebih aman dari Solana yang sempat beberapa kali down). Ini adalah sweet spot untuk DeFi retail di 2024-2026.

**Klien C (High-Value NFT Protocol)**:
- **Rekomendasi**: Ethereum Mainnet (L1)
- **Alasan**: NFT bernilai ratusan ETH memerlukan jaminan keamanan tertinggi dan decentralization terkuat yang ada. Kolektor kaya rela membayar gas fee L1 yang mahal ($20-$100) untuk transaksi yang melibatkan aset senilai miliaran rupiah. Kepercayaan adalah fitur utama, bukan kecepatan atau biaya.

</details>

---

---

# 📝 Mini Project: Transaction Flow Tracer

## Deskripsi
Buat sebuah script Node.js yang memvisualisasikan perjalanan sebuah transaksi berdasarkan hash yang diberikan.

## Requirements
1. Ambil transaction hash sebagai input dari command line argument.
2. Fetch data transaksi menggunakan public RPC endpoint (Ethereum Sepolia testnet).
3. Tampilkan analisis lengkap ke terminal:
   - Semua field transaksi dengan penjelasan
   - Status transaksi (pending / success / reverted)
   - Berapa block confirmations yang sudah tercapai
   - Biaya gas dalam ETH dan USD (estimasi)
   - Apakah ini transfer ETH biasa, contract deployment, atau contract interaction?

## Constraints
- Gunakan hanya Node.js native `fetch` (built-in Node.js v18+) — tanpa library eksternal.
- Gunakan public RPC endpoint gratis tanpa API key: `https://ethereum-sepolia-rpc.publicnode.com` (alternatif: daftar endpoint di [chainlist.org](https://chainlist.org/chain/11155111)). Banyak provider (misal Ankr) kini mewajibkan API key.
- Output harus human-readable, bukan raw JSON dump.

## Hints (Buka satu per satu jika stuck!)

<details>
<summary>Hint 1: Cara memanggil RPC endpoint</summary>

RPC Ethereum menggunakan JSON-RPC 2.0 over HTTP POST:

```javascript
const response = await fetch("https://ethereum-sepolia-rpc.publicnode.com", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getTransactionByHash",
    params: ["0xYourTxHashHere"]
  })
});
const data = await response.json();
console.log(data.result);
```

</details>

<details>
<summary>Hint 2: Methods RPC yang berguna</summary>

```javascript
// Get transaction details
eth_getTransactionByHash(txHash)

// Get transaction receipt (status, gasUsed, logs)
eth_getTransactionReceipt(txHash)

// Get current block number
eth_blockNumber()
// Hasil dalam hex: "0x1234" → parseInt("0x1234", 16) untuk konversi

// Konversi hex wei ke ETH
const weiHex = "0x16345785d8a0000";
const wei = BigInt(weiHex);
// ⚠️ Jangan Number(wei) / 1e18 — Number hanya presisi ~15 digit, nilai wei besar akan terpotong.
const eth = `${wei / 10n ** 18n}.${(wei % 10n ** 18n).toString().padStart(18, "0")}`;
```

</details>

<details>
<summary>Hint 3: Menentukan jenis transaksi</summary>

```javascript
// Transfer ETH biasa
if (tx.to !== null && tx.input === "0x") {
  type = "ETH Transfer";
}

// Contract Deployment
if (tx.to === null) {
  type = "Contract Deployment";
}

// Contract Interaction
if (tx.to !== null && tx.input !== "0x") {
  type = "Contract Interaction";
  // Function selector = tx.input.substring(0, 10)
  // "0xa9059cbb" → transfer(address,uint256)
}
```

</details>

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Requirements 1–3 untuk transaksi **transfer ETH** dan **contract interaction** |
| 🟡 **Extended** — disarankan | Estimasi USD, jumlah konfirmasi yang ter-update, deteksi contract deployment |
| 🔴 **Stretch** — untuk portfolio | Mode `--watch` yang mem-polling tx pending sampai final; decode function selector via 4byte |

### ✅ Kriteria Lulus (Core)

- [ ] Diberi hash transfer ETH dan hash contract interaction, script menampilkan **jenis** yang benar untuk keduanya
- [ ] Status, block number, dan biaya gas (ETH) **sama persis** dengan yang ditampilkan Etherscan untuk hash yang sama
- [ ] Tanpa library eksternal; nilai wei diolah dengan `BigInt` (tidak ada `Number(wei)` untuk nilai besar)
- [ ] Hash yang tidak ada / salah format menghasilkan pesan error yang jelas, bukan stack trace


---

# 🏆 Challenge: "Stuck Transaction" Simulator

> *Challenge ini tanpa tutorial. Gunakan pemahaman Anda dari C1-C5 dan eksperimen sendiri.*

## Deskripsi
Buat sebuah JavaScript/TypeScript script yang mensimulasikan **keputusan strategis gas pricing** untuk developer:

## Requirements
1. Fetch current Ethereum network conditions via RPC: `baseFee`, rata-rata `priorityFee` dari blok terakhir.
2. Berdasarkan data ini, hitung dan tampilkan tiga opsi strategi gas:
   - **🐢 Slow**: Estimasi waktu ~5 menit, berapa yang harus dibayar?
   - **⚡ Standard**: Estimasi waktu ~30 detik, berapa yang harus dibayar?
   - **🚀 Fast**: Estimasi waktu ~12 detik (1 block), berapa yang harus dibayar?
3. Simulasikan skenario "speed up": Jika user sudah kirim transaksi dengan gas price tertentu dan sekarang mau speed up, berapa minimum yang harus dibayar? (Hint: network memerlukan minimal 10% bump dari original gas price)

## Challenge Bonus
Tambahkan estimasi biaya dalam USD (hardcode 1 ETH = $3,500 atau fetch dari CoinGecko public API).

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Requirement 1–2: tiga opsi gas dari data `eth_feeHistory` / block terakhir |
| 🟡 **Extended** — disarankan | Requirement 3: kalkulasi *speed up* (replacement transaction) |
| 🔴 **Stretch** — untuk portfolio | Estimasi USD + bandingkan prediksi Anda dengan block-block berikutnya (backtest sederhana) |

### ✅ Kriteria Lulus (Core)

- [ ] Ketiga opsi selalu terurut `slow ≤ standard ≤ fast` dan `maxFeePerGas ≥ baseFee + priorityFee`
- [ ] Angka Anda berada dalam rentang yang sama dengan gas tracker Etherscan pada saat yang sama (screenshot di Notes)
- [ ] Speed-up menaikkan **`maxFeePerGas` dan `maxPriorityFeePerGas`** masing-masing minimal 10% dari tx asli
- [ ] Penjelasan 3–5 kalimat di Notes: mengapa *base fee* tidak bisa Anda tawar, tetapi *priority fee* bisa


---

## 📁 GitHub Task

Setelah menyelesaikan Soal 1–9 dan Mini Project (minimal Core), commit ke repository:

```bash
# Simpan script exercise dan mini project
cd 01-blockchain-fundamentals/

# Commit catatan & latihan
git add .
git commit -m "learn: blockchain fundamentals — tx lifecycle, P2P network, gas mechanics"

# Commit mini project
git add .
git commit -m "feat: add transaction flow tracer script (Phase 1 mini project)"
```

---

## 🧠 Knowledge Check (Kerjakan setelah semua konsep selesai)

1. Apa perbedaan mendasar antara mutability data di Web2 (SQL) vs Web3 (Blockchain)?
2. Mengapa mempool bersifat publik dan apa implikasi security-nya?
3. Jelaskan tiga jenis transaksi Ethereum berdasarkan kombinasi field `to` dan `input/data`.
4. Apa fungsi `nonce` dan apa yang terjadi jika ada dua transaksi dengan nonce yang sama dari address yang sama?
5. Apa perbedaan antara `gasLimit` dan `gasUsed`? Apa yang terjadi jika `gasUsed > gasLimit`?
6. Setelah "The Merge", apa yang menjadi penjamin keamanan Ethereum menggantikan komputasi (hash power) pada PoW?
7. Dalam konteks Blockchain Trilemma, kenapa Layer 2 dianggap sebagai "solusi" yang elegan?
8. Apa yang dimaksud dengan "Finalized" di Ethereum PoS, dan berapa lama untuk mencapainya?
9. Bandingkan dua kasus: (a) transaksi dengan `maxFeePerGas` terlalu rendah saat network congested, dan (b) transaksi dengan `gasLimit` terlalu rendah. Mana yang membuang ETH Anda walaupun transaksinya gagal, dan mengapa yang lain tidak?
10. Seorang backend developer Web2 terbiasa menangani error dengan "retry logic" otomatis. Mengapa pendekatan yang sama di Web3 (retry transaksi yang gagal secara otomatis) sangat berbahaya?

---

## 📊 Progress Tracker

- [ ] **C1**: Web2 vs Web3 Architecture — *Mental model & paradigm shift*
- [ ] **C2**: Distributed Ledger & P2P Network — *Nodes, mempool, gossip protocol*
- [ ] **C3**: Anatomy of a Transaction — *Every field explained*
- [ ] **C4**: Transaction Lifecycle — *Wallet to finality*
- [ ] **C5**: Consensus, Finality & Trilemma — *How 10,000 nodes agree*
- [ ] **Exercise**: Soal 1–9
- [ ] **Mini Project**: Transaction Flow Tracer (Node.js)
- [ ] **Challenge**: Gas Price Strategy Simulator
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Ethereum.org: Introduction to Ethereum](https://ethereum.org/en/developers/docs/intro-to-ethereum/)
- [Ethereum.org: Transactions Deep Dive](https://ethereum.org/en/developers/docs/transactions/)
- [Ethereum.org: Gas and Fees](https://ethereum.org/en/developers/docs/gas/)
- [Ethereum.org: Nodes and Clients](https://ethereum.org/en/developers/docs/nodes-and-clients/)
- [EIP-1559: Fee Market Change](https://eips.ethereum.org/EIPS/eip-1559)

### Untuk Eksplorasi Lebih Lanjut
- [Vitalik: The Meaning of Decentralization](https://medium.com/@VitalikButerin/the-meaning-of-decentralization-a0c92b76a274)
- [Vitalik: Blockchain Trilemma](https://vitalik.eth.limo/general/2021/05/23/scaling.html)
- [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) *(referensi teknis formal — baca saat butuh kedalaman)*
- [Etherscan Block Explorer](https://etherscan.io)
- [Ethereum PoS Explained](https://ethereum.org/en/developers/docs/consensus-mechanisms/pos/)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep di atas. Ini adalah bagian terpenting dari learning journal Anda.)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi selama belajar)*
