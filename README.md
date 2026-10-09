# 🌐 Web3 Developer Learning Journey & Security Portfolio

> Dokumentasi pembelajaran personal, jurnal teknis, implementasi smart contract, pengujian invarian (*fuzzing/testing*), dan audit keamanan (*security exploit lab*) dalam transisi dari **Full-Stack Engineer (Web2 / Mobile)** menuju **Web3 Security & Smart Contract Engineer**.

---

## 👤 Developer Profile & Focus

- **Background**: Full-Stack Software Engineer (Laravel, React, Mobile, Docker, Linux, Relational DB, Distributed Systems).
- **Target Specialization**: **Web3 Security / Smart Contract Security & Blockchain Infrastructure**.
- **Hardware Profile**: MacBook M3 (8 GB Unified Memory) — *Dioptimalkan untuk tooling ultra-ringan: Foundry (`forge`, `cast`, `anvil`) tanpa beban full node lokal.*

---

## 🧠 The Paradigm Shift: Web2 vs Web3 Architecture

Perbedaan paling krusial bagi seorang Full-Stack Engineer adalah pergeseran dari **Centralized Trust (Server/Database)** ke **Trustless Deterministic State Machine (Blockchain/EVM)**:

```text
WEB2 ARCHITECTURE (Centralized Trust)
User
 │
 ▼ (HTTPS / REST / GraphQL)
Frontend (React / Next.js / Mobile)
 │
 ▼ (JWT / Session Cookie)
Backend Server (Laravel / Node.js)
 │
 ▼ (SQL Queries - Read/Write/Delete)
Database (PostgreSQL / MySQL)  <--- Single Point of Failure & Absolute Admin Power
```

```text
WEB3 ARCHITECTURE (Trustless / Cryptographic Verification)
User
 │
 ▼ (Private Key Signature)
Wallet (MetaMask / Rabby / Hardware)
 │
 ▼ (JSON-RPC)
Frontend DApp (Next.js + Viem + Wagmi)
 │
 ▼ (Gossip Protocol / Mempool)
RPC Node Gateway
 │
 ▼ (Consensus & Execution)
Smart Contract on EVM
 │
 ▼ (Append-Only Replicated State)
Blockchain (Ethereum / Layer 2) <--- Immutable, No Admin Master Key, Publicly Auditable
```

---

## 🗺️ Master Curriculum (13 Phases)

```text
WEB2 FUNDAMENTAL (Laravel, React, Mobile, DevOps)
       │
       ▼
1. Blockchain Fundamentals
       │
       ▼
2. Ethereum & EVM
       │
       ▼
3. Cryptography & Wallet
       │
       ▼
4. Solidity
       │
       ▼
5. Smart Contract Development
       │
       ▼
6. Tooling (Foundry)
       │
       ▼
7. Smart Contract Testing
       │
       ▼
8. Smart Contract Security
       │
       ▼
9. Web3 Frontend (Viem, Wagmi)
       │
       ▼
10. Web3 Backend & Indexing
       │
       ▼
11. Tokenomics & DeFi
       │
       ▼
12. Layer 2 & Scaling
       │
       ▼
13. Advanced Web3 (AA, MEV, ZK)
       │
       ▼
WEB3 / SECURITY ENGINEER
```

> 🔀 **Urutan belajar yang disarankan: 4 → 6 → 5 → 7.** Phase 5 (Smart Contract Development) memakai Foundry untuk test & deployment, sehingga Phase 6 (Foundry Tooling, prerequisite-nya hanya Phase 4) sebaiknya diselesaikan lebih dulu. Penomoran folder tetap mengikuti roadmap konseptual di atas.

---

### Detailed Phase Breakdown

#### Phase 0: Web2 Baseline Validation
- [x] JavaScript / TypeScript proficiency
- [x] HTTP / HTTPS, REST API, WebSockets
- [x] Relational Database (PostgreSQL/MySQL), ACID properties, indexing
- [x] Backend architecture, authentication (JWT, OAuth, Sessions)
- [x] Git, Docker, Linux, CI/CD, and basic security hygiene

#### Phase 1: Blockchain Fundamentals
- **Core Concepts**: Distributed ledger, P2P networking, Consensus mechanisms (PoW vs PoS), Blockchain Trilemma, Immutability, Permissionless vs Permissioned.
- **Transaction Flow**: `User -> Wallet -> RPC -> Mempool -> Validator -> Block -> Confirmation -> Finality`.
- **Key Mechanics**: Block anatomy, transaction payload, nonce, gas economics, chain reorganization (reorg).
- **Target**: Mampu menjelaskan secara presisi bagaimana transaksi berpindah dari wallet hingga terkonfirmasi di block.

#### Phase 2: Ethereum & EVM
- **Core Concepts**: Ethereum as a World Computer, EVM Architecture, Deterministic State Transition.
- **Account Model**: EOA (*Externally Owned Account*) vs Contract Account.
- **EVM Internals**: Opcodes, Bytecode, Stack, Memory, Storage (slot layout), Calldata.
- **Economic Model**: Gas limit, gas price, base fee (EIP-1559), priority fee, out of gas reverts.

#### Phase 3: Cryptography & Wallets
- **Hashing**: SHA-256 vs Keccak-256, pre-image resistance, collision resistance, avalanche effect.
- **Asymmetric Cryptography**: Elliptic Curve Cryptography (`secp256k1`), Private Key $\rightarrow$ Public Key $\rightarrow$ Ethereum Address derivation.
- **Digital Signatures**: ECDSA signing, verifying, parameter $(r, s, v)$, and `ecrecover`.
- **Wallet Architecture**: Mnemonic seeds (BIP-39), Hierarchical Deterministic (HD) wallets (BIP-32/BIP-44), derivation paths, MetaMask, Hardware wallets.

#### Phase 4: Solidity Fundamentals
- **Language Primitives**: Types (`uint`, `int`, `address`, `bool`, `bytes`), State variables, Functions, Visibility (`public`, `external`, `internal`, `private`).
- **Data Structures**: Structs, Enums, Arrays, Mappings (hash-table on storage slots).
- **Control & Logic**: Modifiers, Custom Errors (`error Unauthorized()`), Events, Revert semantics.
- **Data Locations**: `storage` (persistent, expensive) vs `memory` (temporary) vs `calldata` (immutable read-only payload).

#### Phase 5: Smart Contract Development
- **Project 1**: *Simple Storage* — State reading and writing mechanics.
- **Project 2**: *Decentralized Voting* — Proposals, voter mapping, access control, state transitions.
- **Project 3**: *Crowdfunding* — `payable`, ETH transfers, `msg.sender`, `msg.value`, withdrawal pattern.
- **Project 4**: *ERC-20 Token* — Fungible standard, `totalSupply`, `balanceOf`, `transfer`, `approve`, `allowance`.
- **Project 5**: *NFT (ERC-721 / 1155)* — Non-fungible standard, metadata JSON, IPFS, `tokenURI`.

#### Phase 6: Tooling (Foundry)
- **Framework**: Foundry (`forge`, `cast`, `anvil`) over heavy local stacks.
- **CLI Workflows**:
  - `forge init`, `forge build`, `forge test`
  - `cast call`, `cast send`, `cast balance`, `cast to-hex`
  - `anvil` (instant local EVM testnet)
- **Dependency Management**: Git submodules (`forge install OpenZeppelin/openzeppelin-contracts`).

#### Phase 7: Smart Contract Testing
- **Philosophy**: Testing bukan sekadar "apakah fungsi jalan", tapi "apakah fungsi gagal dengan benar ketika diserang".
- **Test Categories**:
  - Unit Tests: Isolation of individual functions.
  - Integration Tests: Multi-contract interactions.
  - Revert & Access Control Tests: Expecting specific reverts (`vm.expectRevert`).
  - Fuzz Testing: Generating pseudo-random inputs to find edge cases.
  - Invariant Testing: Proving global protocol truths (e.g. `totalShares <= totalAssets`).
  - Fork Testing: Running tests against live mainnet state.

#### Phase 8: Smart Contract Security
- **Core Principles**: Checks-Effects-Interactions (CEI), Pull over Push payments, Principle of Least Privilege.
- **Classic Vulnerabilities**:
  - Reentrancy (Single-function, Cross-function, Read-only)
  - Access Control breakdowns & `tx.origin` phishing
  - Integer arithmetic & precision loss
  - Oracle Manipulation & Flash Loan exploits
  - Front-running & Maximal Extractable Value (MEV)
  - Denial of Service (DoS via block gas limit or unexpected revert)
  - Signature replay & malleability
- **Tooling**: Slither (static analysis), Foundry fuzzing, Echidna.

#### Phase 9: Web3 Frontend
- **Stack**: Next.js, React, TypeScript, TailwindCSS / Vanilla CSS.
- **Web3 Layer**: Viem (lightweight Ethereum interface), Wagmi (React hooks for Ethereum), WalletConnect / RainbowKit.
- **Key Flows**: Wallet connection, reading on-chain state, preparing and signing transactions, optimistic UI updates, transaction receipts.

#### Phase 10: Web3 Backend & Indexing
- **Real-World Architecture**: Web3 apps still need backends for performance, search, and analytics.
- **Components**:
  - JSON-RPC event listeners & polling
  - Custom Event Indexer using Node.js & PostgreSQL
  - The Graph / Subgraphs
  - Database caching with Redis

#### Phase 11: Tokenomics & DeFi
- **Primitives**: Automated Market Makers (AMM: $x \times y = k$), Liquidity Pools, Impermanent Loss.
- **Money Legos**: Staking contracts, Lending & Borrowing (Overcollateralized debt, health factor, liquidations).
- **Price Feeds**: Chainlink Decentralized Oracle Networks.

#### Phase 12: Layer 2 & Scaling
- **Rollups**: Optimistic Rollups (Arbitrum, Optimism, Base) vs Zero-Knowledge (ZK) Rollups (zkSync, Scroll).
- **Mechanics**: Sequencers, Fraud Proofs vs Validity Proofs, Bridges, L1 Data Availability.

#### Phase 13: Advanced Web3
- **Account Abstraction (ERC-4337)**: Smart Contract Wallets, UserOperations, Paymasters (gasless transactions), Bundlers.
- **Institutional Infra**: Multisig wallets (Safe), Timelocks, DAO Governance contracts.

---

## 🏆 Portfolio Projects (Level 1 — 10)

| Level | Project | Key Concepts Mastered |
|:---:|---|---|
| **L1** | **Simple Storage DApp** | State variables, getters, setters, gas cost awareness. |
| **L2** | **Decentralized Voting System** | Mappings, structs, authorization, election finality. |
| **L3** | **Crowdfunding Protocol** | `payable`, pull-payment pattern, deadline checks, refund mechanics. |
| **L4** | **ERC-20 Token Suite** | Token standard, minting, burning, transfer fee logic, allowances. |
| **L5** | **NFT Marketplace** | ERC-721, custody escrow, buy/sell orders, royalties (EIP-2981). |
| **L6** | **Decentralized Autonomous Org (DAO)** | Proposal creation, timelock, voting quorum, on-chain execution. |
| **L7** | **Mini DEX (Uniswap v2 Style AMM)** | Constant product formula ($x \cdot y = k$), LP tokens, swap fees. |
| **L8** | **Lending & Borrowing Protocol** | Collateral ratios, liquidation incentives, interest rate curve. |
| **L9** | **Real-Time Blockchain Indexer** | Node.js worker, PostgreSQL, RPC event polling, REST/GraphQL API. |
| **L10** | **Smart Contract Security & Exploit Lab** | Vulnerable CTF contracts, written exploit scripts in Foundry, audit reports. |

---

## 📅 Timeline (Dua Jalur)

Estimasi dihitung dari beban tiap fase (lihat header README fase). Pilih jalur yang realistis untuk Anda — **konsistensi lebih penting daripada kecepatan**.

| Blok | Phase | 🚀 Intensif (~6 jam/hari kerja, Core + Extended) | 🐢 Paruh Waktu (~10 jam/minggu, Core) |
|---|---|:---:|:---:|
| Fondasi | 1 → 2 → 3 | Bulan 1 | Bulan 1–3 |
| Solidity & Tooling | 4 → 6 → 5 | Bulan 2–3 | Bulan 3–7 |
| Testing & Security | 7 → 8 | Bulan 4–5 | Bulan 7–10 |
| Full-Stack DApp | 9 → 10 | Bulan 5–7 | Bulan 10–14 |
| DeFi | 11 | Bulan 7–8 | Bulan 12–17 |
| Scaling & Advanced | 12 → 13 | Bulan 8–11 | Bulan 15–20 |

- **Stretch** tidak dihitung dalam estimasi di atas — kerjakan saat membangun portfolio atau setelah roadmap selesai.
- Jika tertinggal lebih dari 2 minggu dari rencana: turunkan target ke **Core saja** untuk fase tersebut, jangan melewati fase.
- Roadmap awal repo ini menargetkan 6–9 bulan; setelah beban latihan dihitung ulang, angka itu hanya realistis untuk jalur intensif **Core saja**.

---

## 📝 Commit Conventions

Repository ini menerapkan **Conventional Commits**:

- `learn:` Catatan konsep, ringkasan teori, dan latihan pemahaman.
- `feat:` Implementasi smart contract, modul frontend, atau service backend.
- `test:` Test suite (Unit, Fuzz, Invariant, Fork tests) di Foundry.
- `fix:` Bug fix atau mitigasi celah keamanan.
- `refactor:` Optimasi gas (*gas golf*) atau perapian arsitektur kode.
- `docs:` Pembaruan README dan dokumentasi teknis.
- `security:` Script exploit CTF, simulasi serangan, atau audit report.

---

## 📂 Repository Structure

```text
.
├── README.md                           # Master Roadmap & Learning Journal Index
├── 01-blockchain-fundamentals/         # Phase 1
├── 02-ethereum-and-evm/                # Phase 2
├── 03-cryptography-and-wallets/        # Phase 3
├── 04-solidity-fundamentals/           # Phase 4
├── 05-smart-contract-development/      # Phase 5
├── 06-foundry-tooling/                 # Phase 6
├── 07-smart-contract-testing/          # Phase 7
├── 08-smart-contract-security/         # Phase 8
├── 09-web3-frontend/                   # Phase 9
├── 10-web3-backend-and-indexing/       # Phase 10
├── 11-tokenomics-and-defi/             # Phase 11
├── 12-layer-2/                         # Phase 12
├── 13-advanced-web3/                   # Phase 13
├── projects/                           # Indeks Milestone Projects (L1 - L10) + spesifikasi L5
├── GLOSSARY.md                         # Istilah teknis Inggris ↔ Indonesia
├── PILOT.md                            # Protokol uji coba dengan pembelajar
├── CONTRIBUTING.md                     # Cara melaporkan masalah & berkontribusi
└── LICENSE                             # MIT (kode) + CC BY-SA 4.0 (materi)
```

---

## 🧭 Cara Menggunakan Repository Ini

Setiap `README.md` fase memakai struktur yang sama:

```text
🎯 Objective → 📋 Prerequisites → ⚙️ Setup → 📚 Concepts Overview
→ C1..Cn (materi + Latihan) → 📝 Mini Project → 🏆 Challenge
→ 📁 GitHub Task → 🧠 Knowledge Check → 📊 Progress Tracker
→ 🔗 Resources → 📝 What I Learned → 🗒️ Notes
```

| Elemen | Cara Memakai |
|---|---|
| **Latihan konseptual** | Jawab sendiri dulu, baru buka `💡 Pembahasan` (collapsible) |
| **Latihan hands-on** | Sengaja tanpa jawaban — buktikan dengan kode/test Anda sendiri |
| **`// TODO (latihan)`** di contoh kode | Bagian yang harus Anda lengkapi |
| **Knowledge Check** | Tanpa kunci jawaban — jawab di **🗒️ Notes** |
| **Progress Tracker** | Centang `[x]` hanya setelah benar-benar selesai |
| **What I Learned / Notes** | Ditulis oleh Anda, bukan template |

**📖 Istilah** — istilah teknis dipakai dalam bahasa Inggris; artinya ada di [`GLOSSARY.md`](GLOSSARY.md).

**🎚️ Sistem Tingkat** — setiap Mini Project & Challenge dibagi tiga:

| Tingkat | Aturan |
|---|---|
| 🟢 **Core** | **Wajib** sebelum lanjut ke fase berikutnya. Lulus jika semua *✅ Kriteria Lulus (Core)* tercentang |
| 🟡 **Extended** | Disarankan — memperdalam pemahaman, termasuk dalam estimasi jalur Intensif |
| 🔴 **Stretch** | Opsional — untuk portfolio atau setelah roadmap selesai |

**✅ Kriteria lulus** — setiap latihan hands-on punya daftar *✅ Selesai jika* yang bisa Anda verifikasi sendiri (test hijau, output yang cocok dengan `cast`/Etherscan, dsb.). Jangan centang Progress Tracker sebelum semua kriteria terpenuhi.

**Konvensi kode:**
- Phase 5 memakai pola **Test-Driven**: `src/` berisi *starter* (antarmuka lengkap, body fungsi `revert NotImplemented()`), `test/` berisi test sebagai spesifikasi, dan jawaban ada di `05-smart-contract-development/solutions/` (`FOUNDRY_PROFILE=solutions forge test` — hanya setelah mencoba sendiri).
- Phase lain: kode Anda ditulis di subfolder **`lab/`** (`forge init lab --no-git`) agar `README.md` materi tidak tertimpa. Phase 9 & 10 memakai subfolder `dapp/` dan `indexer/`.
- Dependencies (`lib/`), build output, dan `.env` di-ignore oleh `.gitignore` root — install ulang dengan `forge install` sesuai Setup tiap fase.

---

## ✅ Status Verifikasi Materi

| Status | Arti |
|---|---|
| **Draft** | Ditulis, belum direview akurasinya |
| **Reviewed** | Akurasi teknis direview baris per baris; klaim yang cepat berubah dicek ke sumber resmi |
| **Reviewed (parsial)** | Klaim yang cepat berubah & potongan kode kunci sudah dicek, tetapi teks belum direview baris per baris oleh reviewer independen |
| **Tested** | Perintah & kode dijalankan dari repo bersih dan hasilnya sesuai yang dijanjikan materi |
| **Verified** | Tested + CI hijau + sudah diuji oleh pelajar nyata (lihat [`PILOT.md`](PILOT.md)) |

| Phase | Status (9 Okt 2026) | Bukti |
|---|---|---|
| 01 | **Reviewed** | teks direview penuh; contoh JS kunci & on-chain diuji |
| 02 | **Reviewed** | teks direview penuh; 7/7 snippet contract compile |
| 03 | **Reviewed** | teks direview penuh; derivasi address/HD & contract signature diuji |
| 04 | **Reviewed** | teks direview penuh; snippet utama di-compile |
| 05 | **Tested** | build, format, 97 test referensi, 19 test jawaban, simulasi deploy lulus |
| 06 | **Tested** | setup lab & contoh MyToken (12/12 test) lulus dari README |
| 07 | **Reviewed (parsial)** | challenge BuggyVault & handler di-compile, bug terbukti terdeteksi invariant |
| 08 | **Reviewed (parsial)** | LoyaltyRewards & contoh CoinFlip (exploit 5/5) diuji |
| 09 | **Reviewed (parsial)** | snippet utama lolos tsc dengan versi di-pin; belum `next build` |
| 10 | **Reviewed (parsial)** | inspeksi teks saja; tidak ada kode untuk diuji |
| 11 | **Reviewed (parsial)** | contoh numerik dihitung ulang; kode belum diuji |
| 12 | **Reviewed (parsial)** | RPC L2 & parameter blob mainnet diverifikasi on-chain |
| 13 | **Reviewed (parsial)** | EntryPoint, Noir & pin dependency dicek ke sumber resmi |

> Belum ada fase yang berstatus **Verified**: materi belum diuji oleh pelajar lain, dan CI GitHub Actions belum pernah berjalan sukses. Toolchain yang dipakai untuk verifikasi: Foundry v1.7.1, solc 0.8.24, forge-std v1.17.0, OpenZeppelin v5.6.1, Node 25, wagmi 2.x / viem 2.x.

---

## 📈 Progress Saya

> Perbarui tabel ini setiap menyelesaikan fase. Detail per konsep ada di **📊 Progress Tracker** README masing-masing fase.

| Urutan | Phase | Bulan (Intensif) | Materi | Latihan | Mini Project | Challenge | Selesai |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | [01 — Blockchain Fundamentals](01-blockchain-fundamentals/README.md) | 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 2 | [02 — Ethereum & EVM](02-ethereum-and-evm/README.md) | 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 | [03 — Cryptography & Wallets](03-cryptography-and-wallets/README.md) | 1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 4 | [04 — Solidity Fundamentals](04-solidity-fundamentals/README.md) | 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 5 | [06 — Foundry Tooling *(kerjakan sebelum 05)*](06-foundry-tooling/README.md) | 2 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 6 | [05 — Smart Contract Development](05-smart-contract-development/README.md) | 2–3 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 7 | [07 — Smart Contract Testing](07-smart-contract-testing/README.md) | 4 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 8 | [08 — Smart Contract Security](08-smart-contract-security/README.md) | 4–5 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 9 | [09 — Web3 Frontend](09-web3-frontend/README.md) | 5–6 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 10 | [10 — Web3 Backend & Indexing](10-web3-backend-and-indexing/README.md) | 6–7 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 11 | [11 — Tokenomics & DeFi](11-tokenomics-and-defi/README.md) | 7–8 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 12 | [12 — Layer 2 & Scaling](12-layer-2/README.md) | 8–9 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 13 | [13 — Advanced Web3](13-advanced-web3/README.md) | 9–11 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

Legenda: ⬜ belum · 🟨 sedang dikerjakan · ✅ selesai
