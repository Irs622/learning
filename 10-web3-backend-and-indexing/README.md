# 10 — Web3 Backend & Indexing

> **Level**: 3–4 — Data Infrastructure
> **Phase**: 10 of 13
> **Estimated Time**: 🚀 Intensif 14–21 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 5–8 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [09-web3-frontend](../09-web3-frontend/README.md) ✅ | [01-blockchain-fundamentals](../01-blockchain-fundamentals/README.md) ✅ (reorg & finality)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan mengapa DApp nyata **tetap membutuhkan backend**, dan apa yang boleh/tidak boleh dipercayakan kepadanya.
- Menguasai **JSON-RPC** untuk data historis: `eth_getLogs`, topic filtering, batas rentang block, dan rate limit provider.
- Membangun **custom event indexer** (Node.js + Viem + PostgreSQL) yang idempotent dan bisa dilanjutkan dari checkpoint.
- Menangani **chain reorganization** dengan benar (confirmation depth, block hash tracking, rollback).
- Menggunakan **The Graph / subgraph** dan memahami trade-off dibanding indexer custom.
- Menyediakan **API** (REST/GraphQL) dengan caching **Redis** dan autentikasi **SIWE**.
- Mengoperasikan **service on-chain** (relayer, keeper) dengan key management & monitoring yang aman.

---

## 📋 Prerequisites

- [x] Node.js/TypeScript, PostgreSQL, Redis, Docker (Phase 0 — Web2 baseline).
- [x] Memahami block, log, reorg, dan finality (Phase 1 & 2).
- [x] Memahami event & `indexed` topic (Phase 4).
- [x] Viem dan SIWE di sisi frontend (Phase 9).

---

## ⚙️ Setup

```bash
cd 10-web3-backend-and-indexing/
mkdir indexer && cd indexer
npm init -y
npm install viem pg ioredis fastify zod siwe dotenv
npm install -D typescript tsx @types/node @types/pg
npx tsc --init
```

`docker-compose.yml` untuk infrastruktur lokal:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: indexer
      POSTGRES_PASSWORD: indexer
      POSTGRES_DB: indexer
    ports: ["5432:5432"]
  redis:
    image: redis:7
    ports: ["6379:6379"]
```

> 💡 Hardware MacBook 8 GB: jangan menjalankan full node. Gunakan `anvil` untuk lokal dan RPC provider (Alchemy/Infura/public RPC) untuk Sepolia.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Mengapa Web3 Butuh Backend](#c1-mengapa-web3-butuh-backend) | ⬜ |
| **C2** | [JSON-RPC & Logs Deep Dive](#c2-json-rpc--logs-deep-dive) | ⬜ |
| **C3** | [Membangun Custom Event Indexer](#c3-membangun-custom-event-indexer) | ⬜ |
| **C4** | [Reorg Handling & Finality](#c4-reorg-handling--finality) | ⬜ |
| **C5** | [The Graph & Indexing Frameworks](#c5-the-graph--indexing-frameworks) | ⬜ |
| **C6** | [API Layer, Caching & SIWE Auth](#c6-api-layer-caching--siwe-auth) | ⬜ |
| **C7** | [Operasional: Relayer, Keeper & Monitoring](#c7-operasional-relayer-keeper--monitoring) | ⬜ |

---

---

# C1: Mengapa Web3 Butuh Backend

## Mental Model: Blockchain = Write-Optimized Log, Bukan Database Query

Blockchain sangat baik untuk **menjamin kebenaran state**, tetapi buruk untuk **menjawab pertanyaan**:

| Pertanyaan Produk | Bisa langsung dari contract? |
|---|---|
| Berapa saldo Alice sekarang? | ✅ `balanceOf(alice)` |
| Siapa 10 holder terbesar? | ❌ mapping tidak bisa di-iterate |
| Riwayat donasi Alice 30 hari terakhir? | ❌ butuh scan event historis |
| Total volume per hari minggu ini? | ❌ butuh agregasi |
| Cari NFT dengan trait "Gold"? | ❌ butuh full-text/filter |

Ini mirip pola **CQRS / Event Sourcing** di Web2:

```text
WRITE SIDE (sumber kebenaran)            READ SIDE (proyeksi untuk query)
───────────────────────────              ─────────────────────────────────
Smart contract  ──emit event──▶ Indexer ──▶ PostgreSQL ──▶ API ──▶ Frontend
                                        └─▶ Redis (cache)
```

## Batas Kepercayaan

> Backend Web3 adalah **cache/proyeksi**, bukan sumber kebenaran. Jika database dan chain berbeda, **chain yang benar**.

- ✅ Backend boleh: mengindeks, mengagregasi, mencari, men-cache, mengirim notifikasi.
- ⚠️ Hati-hati: backend yang menandatangani (relayer, signer airdrop) — kini menjadi target bernilai tinggi.
- ❌ Jangan: menjadikan database backend satu-satunya catatan kepemilikan aset.

## Latihan C1

### Soal 1 — On-chain atau Off-chain?
Untuk DApp Crowdfunding Phase 9, putuskan apakah data berikut dibaca langsung dari contract, dari indexer, atau keduanya: (a) progress bar kampanye, (b) leaderboard donor terbesar, (c) status `finalized`, (d) grafik donasi per jam, (e) apakah tombol refund aktif untuk user.

<details>
<summary>💡 Pembahasan</summary>

- **(a)** Contract (`totalRaised`) — nilai tunggal, harus akurat real-time. Indexer boleh sebagai fallback/cache.
- **(b)** Indexer — butuh sorting atas semua donor.
- **(c)** Contract — menentukan aksi yang valid; jangan mengandalkan data yang mungkin tertinggal.
- **(d)** Indexer — agregasi time-series dari event `Donated`.
- **(e)** Contract (`finalized`, `succeeded`, `getDonation(user)`) — keputusan yang memicu transaksi harus berdasarkan state chain. Prinsip: **data untuk keputusan transaksi → chain; data untuk eksplorasi/analitik → indexer.**

</details>

---

---

# C2: JSON-RPC & Logs Deep Dive

## Anatomi Sebuah Log

```text
event Transfer(address indexed from, address indexed to, uint256 value);

Log {
  address:          0xToken...                       ← contract yang emit
  topics[0]:        keccak256("Transfer(address,address,uint256)")   ← event signature
  topics[1]:        from (di-pad 32 byte)            ← indexed
  topics[2]:        to   (di-pad 32 byte)            ← indexed
  data:             abi.encode(value)                ← non-indexed
  blockNumber, blockHash, transactionHash, logIndex, removed
}
```

- Maksimum **3 parameter `indexed`** (4 topic termasuk signature; event `anonymous` tidak punya topic0).
- Filter hanya bisa dilakukan pada **topic**, bukan pada `data`.
- `indexed` untuk tipe dinamis (`string`, `bytes`) menyimpan **hash**-nya, bukan nilainya.

## `eth_getLogs` dengan Viem

```ts
import { parseAbiItem } from "viem";

const logs = await client.getLogs({
  address: TOKEN,
  event: parseAbiItem("event Transfer(address indexed from, address indexed to, uint256 value)"),
  args: { to: alice },           // filter topic2
  fromBlock: 5_000_000n,
  toBlock:   5_001_999n,
});
// logs[i].args.from / .to / .value sudah ter-decode & bertipe
```

## Batasan Provider

| Batasan | Dampak | Strategi |
|---|---|---|
| Rentang block maksimum per `getLogs` (misal 2k–10k block, atau batas jumlah hasil) | Request ditolak | **Chunking** rentang block, perkecil adaptif saat error |
| Rate limit (request/detik, compute units) | 429 Too Many Requests | Backoff eksponensial + jitter, batching |
| Node tidak konsisten (load balancer) | Block N ada di node A, belum di node B | Retry, gunakan `blockHash` untuk konsistensi |
| `eth_newFilter`/WebSocket putus | Event terlewat | Selalu punya mekanisme **backfill** dari checkpoint |

## Latihan C2

### Soal 2 — Topic Manual
Tanpa library decoding, hitung `topics[0]` untuk event `Donated(address,uint256,uint256)` menggunakan `cast keccak` (Phase 6). Lalu ambil log mentah dengan `cast logs` dan decode `data`-nya menggunakan `cast abi-decode`. Tulis langkah-langkahnya di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] `topics[0]` hasil `cast keccak` sama dengan topic dari `cast logs`
- [ ] Hasil `cast abi-decode` sama dengan nilai yang ditampilkan Etherscan


### Soal 3 — Chunking Adaptif (Hands-On)
Tulis fungsi `fetchLogsInRange(from, to)` yang memecah rentang menjadi chunk, dan jika provider mengembalikan error "range too large / too many results", membagi chunk menjadi dua secara rekursif. Uji terhadap Sepolia untuk rentang 100.000 block.

**✅ Selesai jika:**
- [ ] 100.000 block terambil tanpa error yang tidak tertangani
- [ ] Jumlah log sama dengan hasil pengambilan memakai chunk kecil tetap (bandingkan dua konfigurasi)
- [ ] HTTP 429 ditangani dengan retry + backoff (uji dengan menurunkan rate limit atau mock)


---

---

# C3: Membangun Custom Event Indexer

## Arsitektur

```text
┌──────────────┐  getLogs(chunk)  ┌─────────────────┐  upsert (1 transaksi DB)  ┌──────────────┐
│  RPC Node    │ ───────────────▶ │  Indexer Worker │ ────────────────────────▶ │  PostgreSQL  │
└──────────────┘                  │  - checkpoint   │                           │  - events    │
                                  │  - decode       │                           │  - projections│
                                  │  - confirmations│                           │  - checkpoint │
                                  └─────────────────┘                           └──────────────┘
```

## Skema Database

```sql
-- Event mentah: append-only, satu baris per log
CREATE TABLE raw_events (
  chain_id      INTEGER     NOT NULL,
  block_number  BIGINT      NOT NULL,
  block_hash    TEXT        NOT NULL,
  tx_hash       TEXT        NOT NULL,
  log_index     INTEGER     NOT NULL,
  contract      TEXT        NOT NULL,
  event_name    TEXT        NOT NULL,
  args          JSONB       NOT NULL,
  PRIMARY KEY (chain_id, tx_hash, log_index)       -- ⇐ kunci idempotency
);

-- Proyeksi: state turunan untuk query cepat
CREATE TABLE donations (
  chain_id     INTEGER  NOT NULL,
  donor        TEXT     NOT NULL,
  total_wei    NUMERIC(78,0) NOT NULL,             -- uint256 muat di NUMERIC(78)
  PRIMARY KEY (chain_id, donor)
);

-- Checkpoint: sampai block mana sudah diproses
CREATE TABLE checkpoints (
  chain_id      INTEGER PRIMARY KEY,
  last_block    BIGINT  NOT NULL,
  last_hash     TEXT    NOT NULL
);
```

> ⚠️ Simpan `uint256` sebagai `NUMERIC(78,0)` atau `TEXT`, **jangan** `BIGINT` (maks 2⁶³−1).

## Prinsip Desain Indexer

| Prinsip | Implementasi |
|---|---|
| **Idempotent** | Primary key `(chain_id, tx_hash, log_index)` + `ON CONFLICT DO NOTHING` — memproses ulang chunk yang sama tidak menggandakan data |
| **Atomic** | Insert event + update proyeksi + update checkpoint dalam **satu transaksi DB** |
| **Resumable** | Saat restart, lanjut dari `checkpoints.last_block + 1` |
| **Deterministic** | Proyeksi bisa dibangun ulang 100% dari `raw_events` (replay) |
| **Ordered** | Proses berurutan berdasarkan `(block_number, log_index)` |

## Kerangka Loop Utama

```ts
async function run() {
  while (true) {
    const head      = await client.getBlockNumber();
    const safeHead  = head - BigInt(CONFIRMATIONS);         // lihat C4
    const from      = (await getCheckpoint()) + 1n;
    if (from > safeHead) { await sleep(POLL_MS); continue; }

    const to   = min(from + CHUNK - 1n, safeHead);
    const logs = await fetchLogsInRange(from, to);           // Soal 3

    await db.tx(async (t) => {
      // TODO (latihan): insert raw_events ON CONFLICT DO NOTHING
      // TODO (latihan): update proyeksi (donations, holders, ...)
      // TODO (latihan): simpan checkpoint (to, blockHash(to))
    });
  }
}
```

## Latihan C3

### Soal 4 — Idempotency
Worker crash **setelah** commit transaksi DB tetapi **sebelum** log "chunk selesai" dicetak. Saat restart, apa yang terjadi? Bagaimana jika crash terjadi **di tengah** transaksi DB? Jelaskan mengapa desain di atas aman untuk kedua kasus.

<details>
<summary>💡 Pembahasan</summary>

- **Crash setelah commit**: checkpoint sudah tersimpan bersama data, sehingga worker melanjutkan dari block berikutnya. Log aplikasi yang hilang tidak memengaruhi kebenaran data.
- **Crash di tengah transaksi**: PostgreSQL me-rollback seluruh transaksi — event, proyeksi, dan checkpoint **tidak ada yang tersimpan**. Worker memproses ulang chunk yang sama dari checkpoint lama.
- Jika karena suatu sebab chunk diproses dua kali (misal dua worker), primary key + `ON CONFLICT DO NOTHING` mencegah duplikasi pada `raw_events`. **Namun proyeksi berbasis increment** (`total_wei = total_wei + x`) **tidak** otomatis idempotent — update proyeksi hanya boleh dilakukan untuk baris yang benar-benar baru ter-insert (gunakan `RETURNING`), atau proyeksi dihitung ulang dari `raw_events`.

</details>

---

---

# C4: Reorg Handling & Finality

## Apa yang Terjadi Saat Reorg

```text
Sebelum:  ... ─ 100 ─ 101a ─ 102a          (indexer sudah memproses 101a, 102a)
Sesudah:  ... ─ 100 ─ 101b ─ 102b ─ 103b   (chain kanonik berganti)

Event di 101a/102a mungkin TIDAK PERNAH TERJADI di chain kanonik,
atau terjadi di block berbeda dengan urutan berbeda.
```

Di Ethereum PoS, reorg dalam 1–2 block jarang namun bisa terjadi; block dianggap **final** setelah ~2 epoch (~13 menit). Di L2, ada tingkat finality berbeda (Phase 12).

## Strategi

| Strategi | Cara | Trade-off |
|---|---|---|
| **Confirmation depth** | Hanya indeks sampai `head - N` | Sederhana; data tertinggal N block; tidak 100% aman jika reorg > N |
| **Finalized tag** | `getBlock({ blockTag: "finalized" })` | Aman; tertinggal ~13 menit |
| **Hash tracking + rollback** | Simpan `block_hash` tiap block; jika parent hash tidak cocok → hapus data dari block divergen, proses ulang | Real-time & benar; paling kompleks |
| **Hybrid** | Tampilkan data "unconfirmed" dari head, tandai "final" setelah finalized | UX terbaik |

## Deteksi Reorg dengan Parent Hash

```ts
const block = await client.getBlock({ blockNumber: checkpoint.lastBlock + 1n });
if (block.parentHash !== checkpoint.lastHash) {
  // REORG terdeteksi
  // TODO (latihan): mundur sampai menemukan block bersama (common ancestor),
  //                 DELETE raw_events WHERE block_number > ancestor,
  //                 rebuild proyeksi, set checkpoint = ancestor
}
```

## Latihan C4

### Soal 5 — Simulasi Reorg di Anvil (Hands-On)
Anvil mendukung snapshot & revert state:
1. `cast rpc evm_snapshot` → simpan id.
2. Kirim beberapa transaksi `donate()`; biarkan indexer memprosesnya **tanpa** confirmation depth.
3. `cast rpc evm_revert <id>`, lalu kirim transaksi berbeda.
4. Amati: apakah database indexer Anda kini berisi donasi "hantu"?
Perbaiki indexer sampai langkah 4 menghasilkan data yang benar.

**✅ Selesai jika:**
- [ ] Setelah `evm_revert`, tidak ada donasi "hantu" di database
- [ ] Proyeksi `donations` cocok 100% dengan `getDonation()` on-chain untuk semua donor


### Soal 6 — Pilih Strategi
Pilih strategi reorg untuk: (a) notifikasi Telegram "Anda menerima NFT", (b) saldo poin loyalty yang bisa ditukar hadiah fisik, (c) dashboard analitik volume harian.

<details>
<summary>💡 Pembahasan</summary>

- **(a)** Confirmation depth kecil (1–3 block) atau hybrid — kecepatan penting; jika reorg, kirim koreksi. Kerugian salah notifikasi rendah.
- **(b)** **Finalized** — data dipakai untuk keputusan bernilai ekonomi yang tidak bisa dibatalkan (hadiah fisik). Lebih baik lambat daripada salah.
- **(c)** Confirmation depth atau finalized — data agregat tidak perlu real-time; konsistensi lebih penting.

</details>

---

---

# C5: The Graph & Indexing Frameworks

## The Graph: Indexer sebagai Layanan Terdesentralisasi

```text
subgraph.yaml   → contract mana, event mana, mulai dari block berapa
schema.graphql  → entity (seperti tabel)
mapping.ts      → handler AssemblyScript: event → update entity
        │
        ▼  graph deploy
Graph Node (hosted / decentralized network) → GraphQL endpoint
```

```graphql
# schema.graphql
type Donation @entity(immutable: true) {
  id: Bytes!              # txHash + logIndex
  donor: Bytes!
  amount: BigInt!
  blockNumber: BigInt!
  timestamp: BigInt!
}

type Donor @entity {
  id: Bytes!              # address
  totalDonated: BigInt!
  donations: [Donation!]! @derivedFrom(field: "donor")
}
```

```ts
// src/mapping.ts
export function handleDonated(event: DonatedEvent): void {
  // TODO (latihan): buat entity Donation, load-or-create Donor, tambahkan totalDonated
}
```

Graph Node menangani reorg, checkpoint, dan GraphQL secara otomatis.

## Perbandingan

| | Custom Indexer (C3) | The Graph | Ponder / Envio |
|---|---|---|---|
| Bahasa | Bebas (TS/Go/Rust) | AssemblyScript | TypeScript |
| Reorg handling | Anda tulis sendiri | Otomatis | Otomatis |
| Query | Bebas (SQL, REST, GraphQL) | GraphQL | GraphQL/SQL |
| Join dengan data off-chain | Mudah | Sulit | Sedang |
| Kontrol & debugging | Penuh | Terbatas | Baik |
| Biaya operasional | Anda yang hosting | Query fee / hosted | Self-host / hosted |

## Latihan C5

### Soal 7 — Subgraph (Hands-On)
Buat subgraph untuk `ERC20Token` Phase 5 di Sepolia dengan entity `Account { balance }` dan `Transfer`. Deploy ke Subgraph Studio, lalu tulis query GraphQL untuk 10 holder terbesar. Bandingkan hasilnya dengan indexer custom Anda.

**✅ Selesai jika:**
- [ ] Subgraph ter-deploy dan query GraphQL top-10 holder berhasil
- [ ] Hasilnya sama dengan indexer custom Anda, atau perbedaannya dijelaskan


---

---

# C6: API Layer, Caching & SIWE Auth

## API di Atas Proyeksi

```ts
// Fastify route
app.get("/v1/campaigns/:address/donors", async (req) => {
  const { address } = paramsSchema.parse(req.params);       // validasi dengan zod
  const cacheKey = `donors:${address}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const rows = await db.query(
    `SELECT donor, total_wei::text FROM donations
     WHERE chain_id = $1 ORDER BY total_wei DESC LIMIT 20`, [CHAIN_ID]);

  await redis.set(cacheKey, JSON.stringify(rows), "EX", 15);
  return rows;
});
```

**Invalidasi cache**: TTL pendek, atau hapus key saat indexer memproses event yang relevan (pub/sub Redis).

> Selalu kembalikan `uint256` sebagai **string** di JSON. `JSON.stringify` tidak mendukung `bigint`, dan `number` kehilangan presisi.

## Backend SIWE (Melanjutkan Phase 9 C5)

```text
GET  /auth/nonce    → nonce acak, simpan di Redis (TTL 5 menit)
POST /auth/verify   → { message, signature }
        1. parse SIWE message
        2. cek domain == domain kita, chainId didukung, belum expired
        3. cek nonce ada di Redis → HAPUS (sekali pakai)
        4. verifikasi signature (dukung juga smart contract wallet via ERC-1271)
        5. set session cookie httpOnly, Secure, SameSite
POST /auth/logout
```

ERC-1271: smart contract wallet (Safe, ERC-4337 di Phase 13) tidak punya private key tunggal; verifikasi dilakukan dengan memanggil `isValidSignature(hash, sig)` pada contract wallet. Viem `verifyMessage` di public client menangani EOA dan ERC-1271.

## Latihan C6

### Soal 8 — Celah SIWE
Backend berikut punya beberapa celah. Temukan semuanya.

```ts
app.post("/auth/verify", async (req) => {
  const { message, signature } = req.body;
  const siwe = new SiweMessage(message);
  const ok = await verifyMessage({ address: siwe.address, message, signature });
  if (ok) req.session.address = siwe.address;
  return { ok };
});
```

<details>
<summary>💡 Pembahasan</summary>

1. **Nonce tidak diverifikasi** → signature lama bisa di-replay selamanya.
2. **Domain tidak dicek** → signature yang dibuat user di situs phishing (`evil.com`) untuk pesan dengan domain kita bisa dipakai; atau sebaliknya pesan untuk domain lain diterima.
3. **Expiration / issuedAt tidak dicek**.
4. **ChainId tidak dicek**.
5. **Tidak ada validasi input** (`message`/`signature` bisa bukan string).
6. Jika `verifyMessage` adalah versi util murni (bukan dari public client), **smart contract wallet (ERC-1271) tidak didukung**.
7. Session fixation: regenerasi session ID setelah login.

</details>

---

---

# C7: Operasional: Relayer, Keeper & Monitoring

## Service yang Menandatangani Transaksi

| Service | Tugas | Contoh |
|---|---|---|
| **Relayer** | Men-submit tx atas nama user (gasless) | Gasless voting Phase 9 |
| **Keeper / bot** | Memanggil fungsi berkala | `finalize()` crowdfunding setelah deadline, likuidasi (Phase 11) |
| **Signer** | Menandatangani voucher/allowlist off-chain | Airdrop claim |

## Key Management

```text
❌ PRIVATE_KEY di .env di server production
⚠️ Secret manager (AWS Secrets Manager, GCP Secret Manager, Vault) — lebih baik, tapi key tetap ada di memori
✅ KMS/HSM signing (key tidak pernah keluar dari HSM), atau layanan seperti OpenZeppelin Defender/Relayer
✅ Key relayer punya privilege MINIMAL di contract (hanya role yang dibutuhkan) + saldo ETH secukupnya
```

## Manajemen Nonce & Gas

- Banyak tx paralel dari satu key → **nonce collision**. Gunakan antrean tunggal per key atau nonce manager.
- Tx macet karena gas terlalu rendah → mekanisme **replace-by-fee** (nonce sama, fee lebih tinggi).
- Pantau saldo ETH relayer; alert sebelum habis.

## Monitoring

| Sinyal | Alert jika |
|---|---|
| Indexer lag (`head - checkpoint`) | > N block selama > M menit |
| Error rate RPC | > threshold |
| Reorg terdeteksi | Kedalaman > ekspektasi |
| Event berbahaya | `OwnershipTransferred`, `Upgraded`, `Paused`, transfer besar dari treasury |
| Saldo relayer/keeper | < minimum |

## Latihan C7

### Soal 9 — Keeper Finalize (Hands-On)
Tulis worker yang memantau semua kampanye Crowdfunding (dari indexer), dan memanggil `finalize()` untuk kampanye yang sudah lewat deadline dan belum final. Pastikan: (a) tidak mengirim tx dobel untuk kampanye yang sama, (b) mensimulasi tx sebelum mengirim, (c) mencatat semua tx yang dikirim ke database.

**✅ Selesai jika:**
- [ ] Setiap kampanye lewat deadline di-finalize **tepat sekali** (cek event `Finalized`)
- [ ] Restart worker di tengah jalan tidak menghasilkan tx ganda
- [ ] Tx yang gagal simulasi tidak dikirim tetapi tercatat di database


---

---

# 📝 Mini Project: Real-Time Blockchain Indexer (Portfolio L9)

## Scope

Indexer + API untuk **semua contract Phase 5** di anvil dan Sepolia.

```text
10-web3-backend-and-indexing/
├── indexer/
│   ├── src/
│   │   ├── rpc/            # client, chunking, retry
│   │   ├── handlers/       # satu handler per event
│   │   ├── db/             # migrasi SQL, repository
│   │   ├── reorg.ts
│   │   └── worker.ts
│   └── migrations/
├── api/                    # Fastify REST (atau GraphQL)
├── subgraph/               # pembanding (C5)
└── docker-compose.yml
```

## Deliverable

- [ ] Mengindeks event: `Updated`, `ProposalCreated`, `Voted`, `ProposalExecuted`, `Donated`, `Finalized`, `Refunded`, `Withdrawn`, ERC-20 `Transfer`/`Approval`, NFT `Transfer`/`Minted`/`Revealed`, `Staked`, `Unstaked`, `RewardClaimed` (cocokkan dengan definisi event di `05-smart-contract-development/src/`).
- [ ] Idempotent, resumable, reorg-safe (lulus simulasi Soal 5).
- [ ] Endpoint: holders ERC-20, NFT milik address, riwayat donasi, leaderboard staking, status proposal.
- [ ] Cache Redis dengan invalidasi berbasis event.
- [ ] Auth SIWE untuk endpoint "profil saya".
- [ ] Metrik: indexer lag, jumlah event per menit, error RPC.
- [ ] Frontend Phase 9 memakai API ini untuk semua data historis.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Indeks `Donated` & `Transfer` (2 contract), idempotent + resumable, 2 endpoint API |
| 🟡 **Extended** — disarankan | Semua event, reorg-safe, cache Redis, auth SIWE |
| 🔴 **Stretch** — untuk portfolio | Metrik, multi-chain, perbandingan dengan subgraph |

### ✅ Kriteria Lulus (Core)

- [ ] Kill worker di tengah backfill lalu restart → tidak ada duplikat & tidak ada event terlewat
- [ ] Total di tabel proyeksi **sama** dengan state on-chain (`getDonation`, `balanceOf`) untuk 5 address acak
- [ ] `uint256` disimpan sebagai `NUMERIC(78,0)` / `TEXT` dan dikembalikan sebagai string di JSON
- [ ] Endpoint merespons < 200 ms untuk query leaderboard (dengan index yang tepat)


---

# 🏆 Challenge: Chaos-Tested Indexer

> *Challenge tanpa tutorial. Buktikan indexer Anda benar di bawah kondisi buruk.*

## Skenario yang Harus Lolos

```text
1. RPC flaky       → 20% request gagal acak / timeout       (buat proxy RPC yang menyuntikkan error)
2. Reorg acak      → evm_snapshot/evm_revert di anvil setiap ~30 detik
3. Crash acak      → kill -9 worker di waktu acak, lalu restart
4. Duplikasi       → jalankan DUA worker bersamaan
5. Backfill besar  → mulai dari block 0 dengan 50.000 event
```

## Tugas Challenge

1. Buat **load generator** yang mengirim transaksi acak ke contract Phase 5 di anvil.
2. Buat **verifier** yang membandingkan proyeksi database dengan state contract (`balanceOf`, `totalRaised`, `getDonation`, dst.) — inilah *invariant* indexer Anda (lihat Phase 7 C4).
3. Jalankan kelima skenario selama minimal 30 menit; verifier harus selalu cocok.
4. Tulis `CHAOS-REPORT.md`: bug yang ditemukan, root cause, perbaikan, dan batasan yang tersisa.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Skenario 2 (reorg) & 3 (crash) dengan verifier |
| 🟡 **Extended** — disarankan | + Skenario 1 (RPC flaky) & 4 (dua worker) |
| 🔴 **Stretch** — untuk portfolio | + Skenario 5 (backfill 50.000 event), run 30 menit, `CHAOS-REPORT.md` |

### ✅ Kriteria Lulus (Core)

- [ ] Verifier membandingkan database vs chain dan selalu cocok selama skenario Core berjalan ≥ 10 menit
- [ ] Minimal 1 bug yang ditemukan oleh chaos test terdokumentasi (atau bukti bahwa tidak ada, dengan log)


---

## 📁 GitHub Task

```bash
cd 10-web3-backend-and-indexing/

git add .
git commit -m "learn: web3 backend & indexing — json-rpc logs, custom indexer, reorg, the graph"

git add indexer/ api/ docker-compose.yml
git commit -m "feat: real-time event indexer with postgres, redis cache and siwe auth (L9)"

git add subgraph/
git commit -m "feat: add subgraph for phase 5 erc20 token"

git add .
git commit -m "test: chaos testing for indexer — flaky rpc, reorg, crash, duplicate workers"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Mengapa mapping di Solidity tidak bisa menjawab "siapa 10 holder terbesar"? Bagaimana indexer menyelesaikannya?
2. Apa isi `topics[0]` sebuah log? Mengapa event hanya bisa punya maksimal 3 parameter `indexed`?
3. Apa yang terjadi jika parameter `string` diberi `indexed`?
4. Mengapa `uint256` tidak boleh disimpan di kolom `BIGINT`?
5. Jelaskan tiga sifat indexer yang baik: idempotent, atomic, resumable.
6. Apa itu reorg? Bandingkan strategi confirmation depth, finalized tag, dan hash tracking.
7. Kapan Anda memilih The Graph dibanding indexer custom, dan sebaliknya?
8. Langkah apa saja yang wajib dilakukan backend saat memverifikasi SIWE?
9. Apa itu ERC-1271 dan mengapa backend harus mendukungnya?
10. Bagaimana mengamankan private key relayer/keeper di production?

---

## 📊 Progress Tracker

- [ ] **Setup**: Node + TypeScript, Docker Postgres & Redis
- [ ] **C1**: Mengapa Backend — *CQRS analogi, batas kepercayaan*
- [ ] **C2**: JSON-RPC & Logs — *topics, getLogs, chunking, rate limit*
- [ ] **C3**: Custom Indexer — *skema, idempotency, checkpoint, atomic*
- [ ] **C4**: Reorg — *confirmation depth, finalized, parent hash rollback*
- [ ] **C5**: The Graph — *subgraph, schema, mapping, perbandingan framework*
- [ ] **C6**: API & Auth — *Fastify, Redis cache, SIWE, ERC-1271*
- [ ] **C7**: Operasional — *relayer, keeper, key management, monitoring*
- [ ] **Exercise**: Soal 1–9
- [ ] **Mini Project**: Real-time indexer + API (L9)
- [ ] **Challenge**: Chaos-tested indexer
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Ethereum JSON-RPC Specification](https://ethereum.github.io/execution-apis/api-documentation/)
- [Viem — getLogs](https://viem.sh/docs/actions/public/getLogs)
- [The Graph Docs](https://thegraph.com/docs/en/)
- [EIP-1271: Standard Signature Validation for Contracts](https://eips.ethereum.org/EIPS/eip-1271)

### Frameworks
- [Ponder](https://ponder.sh/) — indexer TypeScript
- [Envio](https://envio.dev/) — HyperIndex
- [OpenZeppelin Defender / Relayer](https://docs.openzeppelin.com/defender)

### Konsep
- [Ethereum.org — Proof-of-Stake: Finality](https://ethereum.org/en/developers/docs/consensus-mechanisms/pos/#finality)
- Martin Fowler — *Event Sourcing* & *CQRS* (pola Web2 yang sangat mirip dengan arsitektur indexer)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk langkah decode log manual dari Soal 2)*
