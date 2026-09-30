# 02 — Ethereum & EVM

> **Level**: 1–2 (Conceptual + Technical Fundamentals)
> **Phase**: 2 of 13
> **Estimated Time**: 7–10 hari
> **Prerequisite**: [01-blockchain-fundamentals](../01-blockchain-fundamentals/README.md) ✅

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan Ethereum sebagai **World Computer** dan apa artinya secara teknis.
- Memahami perbedaan fundamental **EOA** vs **Contract Account** dan implikasinya terhadap arsitektur DApp.
- Menjelaskan arsitektur internal **EVM**: Stack, Memory, Storage, Calldata, dan bagaimana bytecode dieksekusi.
- Memahami **storage slot layout** dan mengapa ini krusial untuk keamanan smart contract.
- Menghitung biaya gas secara manual dari opcode primitif.
- Memahami **ABI (Application Binary Interface)** dan bagaimana frontend berkomunikasi dengan smart contract.

---

## 📋 Prerequisites

- [x] Memahami siklus hidup transaksi Ethereum (Phase 1).
- [x] Memahami konsep Gas, Mempool, dan Finality (Phase 1).
- [x] Memahami mengapa immutability adalah properti mendasar blockchain.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Ethereum: The World Computer](#c1-ethereum-the-world-computer) | ⬜ |
| **C2** | [Account Model: EOA vs Contract Account](#c2-account-model-eoa-vs-contract-account) | ⬜ |
| **C3** | [EVM Architecture: Stack, Memory, Storage & Calldata](#c3-evm-architecture-stack-memory-storage--calldata) | ⬜ |
| **C4** | [Storage Layout: Slot Packing & Mappings](#c4-storage-layout-slot-packing--mappings) | ⬜ |
| **C5** | [ABI: Bagaimana Frontend Bicara ke Smart Contract](#c5-abi-bagaimana-frontend-bicara-ke-smart-contract) | ⬜ |

---

---

# C1: Ethereum — The World Computer

## Mental Model: Dari Database ke State Machine Global

Di Phase 1, kita memahami blockchain sebagai *replicated, append-only state machine*.

Ethereum mengambil ide ini lebih jauh: bukan hanya mencatat transfer nilai (seperti Bitcoin), Ethereum adalah **Turing-complete programmable state machine** — artinya Anda bisa menjalankan **program arbitrer** di atasnya, dan hasilnya dieksekusi dan diverifikasi oleh ribuan node di seluruh dunia secara konsensus.

```text
Bitcoin:    State Machine untuk transfer nilai
            State = {address → balance}
            Transition = "Alice kirim X BTC ke Bob"

Ethereum:   State Machine yang dapat diprogram
            State = {address → {balance, nonce, code, storage}}
            Transition = "Jalankan bytecode ini dengan input ini"
```

---

## Ethereum World State

Seluruh Ethereum pada dasarnya adalah sebuah **key-value store raksasa** (Merkle Patricia Trie) yang memetakan setiap **address** (20 bytes / 160 bits) ke **account state**-nya:

```
World State = {
  "0xAlice...":    { nonce: 42,    balance: 5e18,  codeHash: EMPTY, storage: {} },
  "0xBob...":      { nonce: 7,     balance: 2e18,  codeHash: EMPTY, storage: {} },
  "0xContract...": { nonce: 1,     balance: 0,     codeHash: 0x1f2.., storage: {
                                                      slot[0]: 0x000...100,
                                                      slot[1]: 0x000...001,
                                                      ...
                                                   }},
  ... (jutaan address lainnya)
}
```

Ketika sebuah transaksi dieksekusi, ia merubah **state** ini sesuai instruksi bytecode. Validator menjalankan semua transaksi dalam sebuah blok, menghitung **state root baru** (hash dari seluruh world state setelah eksekusi), dan state root ini disertakan dalam block header.

> **Implikasi Kritis**: Jika dua validator menjalankan transaksi yang sama pada state yang sama, mereka HARUS menghasilkan state root yang identik. Inilah arti **deterministik**: tidak ada randomness, tidak ada `Date.now()`, tidak ada `Math.random()`, tidak ada network call ke external API.

---

## Turing Completeness & The Halting Problem

Jika EVM Turing-complete, bukankah seseorang bisa menulis program dengan **infinite loop** yang membekukan seluruh jaringan?

```javascript
// Kode ini di JavaScript bisa membekukan browser:
while(true) {}

// Equivalentnya di Solidity:
while(true) {}  // Kenapa ini tidak membekukan Ethereum?
```

**Jawabannya: GAS.**

Gas adalah "bahan bakar" yang membatasi berapa banyak komputasi yang bisa dijalankan dalam satu transaksi. Setiap operasi EVM mengkonsumsi gas. Ketika gas habis → eksekusi berhenti → `out of gas` revert.

Dengan kata lain, Gas adalah solusi Ethereum untuk **Halting Problem** dalam konteks praktis: Anda tidak bisa menjalankan program selamanya karena Anda akan kehabisan gas (dan uang).

---

## Ethereum sebagai "World Computer" vs Cloud Computing

| Aspek | Cloud Computing (AWS/GCP) | Ethereum World Computer |
|---|---|---|
| **Eksekutor** | Server milik Amazon/Google | 10,000+ node independen di seluruh dunia |
| **Trust** | Trust Amazon/Google tidak memanipulasi data | Verifikasi matematis, tidak perlu trust siapapun |
| **Uptime** | 99.99% SLA (bisa down jika Amazon masalah) | Selama ada 1 node berjalan, network hidup |
| **Cost Model** | Flat rate (bayar per jam/bulan) | Per-instruction (gas fee per opcode) |
| **Execution Speed** | Milidetik | Detik sampai menit |
| **Cost per Computation** | Murah ($0.00001 per 1M operasi) | Sangat mahal ($0.01–$100 per transaksi) |
| **Immutability** | Kode bisa diupdate kapan saja | Kode locked setelah deploy |
| **Privacy** | Kode dan data bisa privat | Semua bytecode dan storage bisa dibaca publik |
| **Access Control** | Username/password + IAM roles | Kriptografi (Private Key signature) |

**Mengapa ada orang yang mau pakai Ethereum jika lebih lambat dan mahal dari AWS?**

Karena untuk use case tertentu, **trust > speed dan cost**:
- Sistem keuangan yang memerlukan trustless guarantee (tidak ada admin yang bisa manipulasi)
- Protokol yang memerlukan permissionless participation (siapapun bisa join tanpa izin)
- Asset ownership yang tidak bisa dikonfiskasi oleh satu entitas

---

## Latihan C1: The "World Computer" Mental Model

### Soal 1 — Deterministic Execution
Seorang developer ingin membuat smart contract yang menampilkan harga ETH saat ini untuk menentukan apakah user bisa redeem reward.

```solidity
// Developer naif menulis ini:
function canClaim() external view returns (bool) {
    uint256 price = getETHPrice(); // Ambil dari API CoinGecko
    return price > 2000;
}
```

**Pertanyaan**:
- a) Kenapa kode ini **secara fundamental mustahil** diimplementasikan langsung di smart contract (tanpa bantuan alat lain)?
- b) Jika setiap node Ethereum menjalankan fungsi ini dan mendapat harga berbeda (karena network latency, timing API call berbeda), apa yang akan terjadi pada konsensus?
- c) Apa solusi yang benar untuk use case ini di Web3? *(Hint: pikirkan tentang Oracle)*

<details>
<summary>💡 Pembahasan</summary>

**a)** Smart contract berjalan di dalam EVM yang **deterministik dan terisolasi**. EVM tidak memiliki kemampuan untuk melakukan HTTP request ke service eksternal. Ini bukan bug — ini adalah desain yang disengaja untuk menjaga deterministik. Jika contract bisa call API eksternal, setiap node akan mendapat respons yang berbeda (latency, server down, data berbeda berdasarkan waktu), sehingga state root yang dihasilkan berbeda → jaringan tidak bisa mencapai konsensus.

**b)** Konsensus akan **rusak** (fork). Node A mengeksekusi `canClaim()` dan mendapat `true` (harga $2,100), Node B mendapat `false` (harga $1,990) karena timestamp API call berbeda. Kedua node akan menghasilkan **state root yang berbeda** dan tidak bisa sepakat tentang state yang valid.

**c)** Solusinya adalah menggunakan **Oracle** — sistem yang secara kriptografis terdesentralisasi menyediakan data off-chain ke smart contract.

Arsitektur:
```
External Price Feed (CoinGecko, Binance)
          │
          ▼
Oracle Network (Chainlink node operators)
          │ → Setiap node melaporkan harga
          │ → Hasil di-aggregate secara on-chain
          ▼
Chainlink Price Feed Contract (on-chain)
          │ → menyimpan harga yang sudah di-aggregate
          │ → bisa dipanggil oleh smart contract lain
          ▼
Your Contract
  function canClaim() external view returns (bool) {
      (, int256 price,,,) = priceFeed.latestRoundData();
      return price > 2000 * 1e8; // Chainlink menggunakan 8 desimal
  }
```

Sekarang semua node memanggil **contract yang sama di blockchain yang sama** → hasil deterministik.

</details>

---

### Soal 2 — Gas sebagai Mekanisme Keamanan
Analisis kode berikut dari perspektif keamanan jaringan:

```solidity
function processAllUsers() external {
    for (uint256 i = 0; i < users.length; i++) {
        _processUser(users[i]);
    }
}
```

**Pertanyaan**:
- a) Jika `users.length` adalah 1.000.000 (1 juta user), apa yang akan terjadi ketika fungsi ini dipanggil?
- b) Ini adalah pola yang umum di Laravel (`User::all()->each(fn($u) => $u->process())`). Mengapa pola yang sama berbahaya di Solidity?
- c) Bagaimana cara mendesain ulang fungsi ini agar aman untuk digunakan di production smart contract?

<details>
<summary>💡 Pembahasan</summary>

**a)** Transaksi akan **revert dengan `out of gas`**. Looping 1 juta iterasi di EVM akan mengkonsumsi gas yang jauh melampaui `gasLimit` per block (30 juta gas di Ethereum, cukup untuk sekitar ~1,400 transfer ETH biasa). Pengirim transaksi kehilangan gas yang sudah dibayarkan, dan tidak ada satu pun user yang ter-process.

**b)** Di Laravel, server Anda punya CPU dan RAM tanpa batas (secara praktis). Di Solidity, setiap opcode dikuantifikasi dengan tepat dan dibatasi oleh gasLimit block. Selain itu, ukuran array `users` bisa saja dimanipulasi oleh attacker (jika ada fungsi `addUser`) untuk menyebabkan transaksi selalu `out of gas` — ini adalah serangan **DoS (Denial of Service) via gas exhaustion**.

**c)** Gunakan pola **pagination/batching**:

```solidity
// Solusi 1: Pagination dengan index
function processBatch(uint256 startIndex, uint256 batchSize) external {
    uint256 endIndex = startIndex + batchSize;
    if (endIndex > users.length) endIndex = users.length;
    
    for (uint256 i = startIndex; i < endIndex; i++) {
        _processUser(users[i]);
    }
}

// Solusi 2: Pull pattern (user process dirinya sendiri)
function processMyself() external {
    _processUser(msg.sender);
}
```

Ini adalah salah satu contoh bagaimana **gas constraints memaksa developer untuk memikirkan ulang arsitektur algoritma mereka** di Web3.

</details>

---

---

# C2: Account Model — EOA vs Contract Account

> *Semua di Ethereum adalah "Account". Namun tidak semua Account diciptakan sama.*

---

## Dua Jenis Account

Di Ethereum, hanya ada dua jenis entitas:

```text
ETHEREUM ACCOUNT
       │
       ├── EOA (Externally Owned Account)
       │   "Wallet biasa, dikontrol manusia / Private Key"
       │
       └── Contract Account
           "Smart contract, dikontrol oleh bytecode"
```

### EOA: Externally Owned Account

```text
State EOA di Ethereum:
{
  nonce:    42,        // Jumlah transaksi yang sudah dikirim dari alamat ini
  balance:  5000000000000000000,  // 5 ETH dalam wei
  codeHash: EMPTY_HASH,           // Selalu hash dari string kosong
  storageRoot: EMPTY_HASH         // Tidak ada storage
}
```

**Karakteristik EOA**:
- Diidentifikasi oleh **alamat** yang diturunkan dari Public Key.
- Dikontrol oleh **Private Key** — siapapun yang punya Private Key bisa menandatangani transaksi atas nama alamat ini.
- Bisa **menginisiasi transaksi** (kirim ETH, panggil contract, deploy contract).
- Tidak memiliki bytecode — tidak bisa diprogram.
- Bisa menerima ETH tanpa logika apapun.

```
Private Key (256-bit random number)
    │
    │ Elliptic Curve Multiplication (secp256k1)
    ▼
Public Key (64 bytes, uncompressed)
    │
    │ Keccak-256 hash
    ▼
Hash (32 bytes)
    │
    │ Ambil 20 bytes terakhir
    ▼
Ethereum Address (0x + 40 hex chars = 20 bytes)
```

---

### Contract Account

```text
State Contract Account:
{
  nonce:       1,           // Jumlah contract yang sudah di-deploy dari contract ini
  balance:     0,           // ETH yang dimiliki contract ini
  codeHash:    0x1f2a3b..., // Keccak-256 dari bytecode contract
  storageRoot: 0x9a8b7c...  // Root dari Merkle Patricia Trie storage contract ini
}
```

**Karakteristik Contract Account**:
- Diidentifikasi oleh **alamat** yang deterministik (berdasarkan deployer address + nonce saat deploy, atau `CREATE2`).
- Dikontrol oleh **bytecode** — tidak ada Private Key, tidak ada "pemilik" secara inheren.
- **Tidak bisa menginisiasi transaksi** secara sendiri — hanya bisa bereaksi terhadap transaksi dari EOA atau dari contract lain.
- Memiliki **storage** — key-value store yang persisten.
- Bisa menyimpan dan mentransfer ETH berdasarkan logika bytecode-nya.

---

## Perbedaan Kritis: Siapa yang Bisa "Memulai" Sesuatu?

```text
VALID TRANSACTION ORIGINS:

EOA → EOA:
  Alice kirim 1 ETH ke Bob (transfer ETH biasa)

EOA → Contract:
  Alice memanggil fungsi transfer() di token contract

EOA → Deploy Contract:
  Alice men-deploy smart contract baru ke blockchain

Contract → EOA:
  Contract mengirim ETH ke Alice (bagian dari eksekusi yang diinisiasi Alice)
  [Ini adalah "internal transaction" atau "message call"]

Contract → Contract:
  Token contract memanggil approval contract
  [Ini adalah "internal transaction"]

TIDAK VALID:
Contract → (inisiasi mandiri):
  Contract TIDAK BISA mengirim transaksi sendiri tanpa EOA yang memicunya
```

> **Implikasi Arsitektur**: Ini berarti semua logic di blockchain pada akhirnya dimulai oleh seorang manusia (atau bot — tapi bot juga EOA). Tidak ada smart contract yang bisa "bangun di pagi hari" dan menjalankan kode sendiri. Inilah mengapa ada layanan seperti **Chainlink Keepers / Automation** atau **Gelato Network** — bot EOA yang memantau kondisi tertentu dan memicu fungsi contract ketika kondisi terpenuhi.

---

## Contract Address: Bagaimana Alamatnya Ditentukan?

Berbeda dengan EOA yang alamatnya dari Public Key, alamat Contract ditentukan saat **deployment**:

### `CREATE` (Standard Deployment)
```
contractAddress = keccak256(RLP(deployerAddress, deployerNonce))[12:]

Contoh:
  deployer: 0xAlice... (nonce = 5)
  contractAddress = keccak256(RLP(0xAlice..., 5))[last 20 bytes]
```

Ini berarti jika Alice men-deploy contract dengan nonce yang sama, alamatnya akan selalu sama. Tetapi jika nonce berubah, alamatnya berbeda.

### `CREATE2` (Deterministic Deployment)
```
contractAddress = keccak256(0xFF, deployerAddress, salt, keccak256(bytecode))[12:]
```

`CREATE2` memungkinkan Anda memprediksi alamat contract **sebelum** deploy, asalkan bytecode dan salt sama. Ini sangat berguna untuk:
- **Counterfactual deployment** (bayar ke alamat yang belum ada, deploy belakangan)
- **Upgradeable patterns** (deploy proxy ke alamat yang sama setelah di-destroy)
- **State channel factories**

---

## Latihan C2: Account Types Deep Dive

### Soal 3 — EOA atau Contract?
Anda menerima alamat `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`. Bagaimana cara menentukan apakah ini EOA atau Contract Account?

**Pertanyaan**:
- a) Apa yang perlu Anda cek? Jelaskan langkah teknisnya.
- b) Buka Etherscan, cari alamat ini. Apa yang Anda temukan?
- c) Dalam kode JavaScript (menggunakan `fetch` ke RPC endpoint), bagaimana cara membedakan EOA vs Contract secara programatik?

<details>
<summary>💡 Pembahasan</summary>

**a)** Untuk membedakan EOA vs Contract:
- **EOA**: `codeHash` selalu sama dengan `keccak256("")` = `0xc5d246...` (hash dari string kosong)
- **Contract**: `codeHash` adalah hash dari bytecode yang non-empty

Cara paling langsung: Gunakan RPC method `eth_getCode(address, "latest")`:
- Jika return `"0x"` (empty/zero bytes) → EOA
- Jika return bytecode hex string yang panjang → Contract Account

**b)** `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D` adalah **Uniswap V2 Router** — salah satu contract paling terkenal di Ethereum. Anda akan melihat tab "Contract" di Etherscan, source code yang terverifikasi, dan ribuan transaksi.

**c)**
```javascript
async function isContract(address) {
  const response = await fetch("https://rpc.ankr.com/eth", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "eth_getCode",
      params: [address, "latest"]
    })
  });
  const data = await response.json();
  // "0x" = EOA, anything longer = Contract
  return data.result !== "0x";
}

// Contoh penggunaan:
const aliceWallet  = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"; // EOA (Vitalik's wallet)
const uniswapV2    = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // Contract

console.log(await isContract(aliceWallet));  // false
console.log(await isContract(uniswapV2));    // true
```

</details>

---

### Soal 4 — Implikasi Desain Arsitektur
Sebuah tim startup Web3 ingin membuat fitur: **"Jika saldo ETH sebuah multisig wallet turun di bawah 0.1 ETH, otomatis topup dari treasury contract."**

**Pertanyaan**:
- a) Bisakah smart contract treasury mendeteksi kondisi ini dan mengirim ETH **secara otomatis tanpa pemicu dari luar**? Mengapa?
- b) Solusi arsitektur apa yang bisa digunakan di dunia nyata untuk mengimplementasikan fitur ini?
- c) Apa saja trade-off dari solusi yang Anda usulkan (sentralisasi, gas cost, keamanan)?

<details>
<summary>💡 Pembahasan</summary>

**a)** Tidak bisa. Contract tidak bisa menginisiasi transaksi sendiri. Contract hanya "tidur" di blockchain dan hanya aktif ketika ada EOA yang mengirim transaksi untuk memicunya. Ini adalah batasan fundamental dari model eksekusi Ethereum.

**b)** Solusi yang umum digunakan:
1. **Chainlink Automation (formerly Keepers)**: Oracle network yang memantau kondisi on-chain dan secara otomatis memanggil fungsi contract ketika kondisi terpenuhi. Biayanya dibayar dalam LINK token.
2. **Gelato Network**: Serupa dengan Chainlink Automation, alternatif yang lebih fleksibel.
3. **In-house bot/keeper**: Tim membuat EOA bot sendiri (Node.js script) yang berjalan di server, polling kondisi setiap beberapa menit, dan mengirim transaksi ketika kondisi terpenuhi.

**c)** Trade-offs:
- **Chainlink/Gelato**: Desentralisasi tinggi, tapi tambah dependency eksternal, biaya ongoing, ada risiko oracle manipulation.
- **In-house bot**: Kontrol penuh, lebih murah, tapi single point of failure (server bot bisa down), lebih terpusat (team bisa manipulasi timing), perlu kelola private key bot dengan aman.

</details>

---

---

# C3: EVM Architecture — Stack, Memory, Storage & Calldata

> *EVM adalah inti dari Ethereum. Memahami arsitekturnya adalah kunci untuk menulis smart contract yang efisien dan aman.*

---

## The Ethereum Virtual Machine

EVM adalah **stack-based virtual machine** — berbeda dengan register-based VM yang mungkin Anda kenal (seperti JVM untuk Java, atau LLVM untuk C/C++).

Ketika Anda menulis Solidity, compiler (`solc`) mengkompilasi kode Anda menjadi **EVM bytecode** — serangkaian instruksi opcode yang dieksekusi oleh EVM.

```text
Anda menulis:       → Solidity code
Compiler mengubah:  → EVM Bytecode (hex)
EVM mengeksekusi:   → Opcode satu per satu
Hasil:              → State changes di blockchain
```

Contoh sederhana:
```solidity
// Solidity
function add(uint256 a, uint256 b) pure returns (uint256) {
    return a + b;
}
```

Setelah kompilasi menjadi EVM bytecode (disederhanakan):
```
PUSH1 0x04  // push arg 'a' ke stack
PUSH1 0x24  // push arg 'b' ke stack
ADD         // ambil dua nilai teratas dari stack, tambahkan, push hasilnya
SWAP1       // swap dua nilai teratas stack
POP         // buang nilai teratas
JUMP        // lompat ke return location
```

---

## Empat Area Memory di EVM

Memahami perbedaan keempat area ini adalah **kunci absolut** untuk menulis Solidity yang benar dan efisien:

```text
EVM MEMORY AREAS

┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│     STACK       │ │     MEMORY      │ │    STORAGE      │ │    CALLDATA     │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ Max 1024 items  │ │ Expandable byte │ │ 2^256 slots     │ │ Read-only byte  │
│ Each 32 bytes   │ │ array           │ │ Each 32 bytes   │ │ array           │
│                 │ │                 │ │                 │ │                 │
│ Volatile:       │ │ Volatile:       │ │ Persistent:     │ │ Volatile:       │
│ Cleared after   │ │ Cleared after   │ │ Permanent di    │ │ Cleared after   │
│ execution ends  │ │ execution ends  │ │ blockchain      │ │ execution ends  │
│                 │ │                 │ │                 │ │                 │
│ Cost: Very Low  │ │ Cost: Low-Med   │ │ Cost: Very High │ │ Cost: Cheapest  │
│ (3 gas/op)      │ │ (quadratic!)    │ │ SLOAD: 2100     │ │ 4 gas/byte(0)  │
│                 │ │                 │ │ SSTORE: 20000   │ │ 16 gas/byte(nz) │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## Stack: The EVM's Primary Workspace

EVM adalah stack-based machine. Stack adalah LIFO (Last In, First Out) data structure.

```text
Stack Operations:
  PUSH1 0x05  →  Stack: [5]
  PUSH1 0x03  →  Stack: [5, 3]
  ADD         →  Stack: [8]    (pop 5 dan 3, push 5+3=8)
  PUSH1 0x02  →  Stack: [8, 2]
  MUL         →  Stack: [16]   (pop 8 dan 2, push 8*2=16)

Max depth: 1024 items
Jika melebihi 1024: "Stack overflow" → revert
Setiap item: tepat 32 bytes (256 bits)
```

**Kenapa semua opcode bekerja dengan 32 bytes?** Karena Ethereum dirancang untuk bekerja dengan nilai uint256 secara native — ini cocok untuk kriptografi (256-bit hash, private key, dll).

---

## Memory: Temporary Byte Array

Memory adalah area byte array yang bisa diakses dengan offset apapun, tetapi hanya ada selama satu eksekusi transaksi.

```solidity
// Contoh penggunaan memory di Solidity:
function processName(string calldata name) external pure returns (bytes32) {
    // 'result' dialokasikan di memory (sementara)
    bytes memory encoded = abi.encodePacked(name);
    return keccak256(encoded);
    // Setelah fungsi selesai, 'encoded' hilang dari memory
}
```

**Biaya Memory (Kuadratik!)**: Ini adalah detail penting yang sering dilewatkan:

```
Biaya memory = (words_used × 3) + (words_used² / 512)

Menggunakan 32 bytes (1 word):    ~3 gas
Menggunakan 1024 bytes (32 words): ~98 gas
Menggunakan 1 MB:                  ~24,000 gas
Menggunakan 10 MB:                 ~240,000+ gas (kuadratik!)
```

Biaya kuadratik ini adalah mekanisme proteksi lainnya terhadap serangan DoS dengan alokasi memory sangat besar.

---

## Storage: Persistent Key-Value Store

Storage adalah area paling mahal dan paling penting — ini adalah tempat di mana **state permanen** contract disimpan di blockchain.

```text
CONTRACT STORAGE

Namespace: Per contract address (contract A tidak bisa baca storage contract B)
Layout: 2^256 slots, masing-masing 32 bytes = 32 bytes
         (Secara teori ada 2^256 slot — jumlah yang astronomical)
         (Secara praktis, hanya slot yang pernah ditulis yang exist)

Slot 0: [0x0000...0001]  → misalnya variabel uint256 totalSupply = 1
Slot 1: [0x0000...0042]  → misalnya variabel uint256 someValue = 66
Slot 2: [0x0000...0000]  → slot kosong (belum pernah ditulis)
...
Slot k: [calculated]     → untuk mapping dan dynamic array (lihat C4)
```

**Biaya Storage Operations**:
```
SLOAD  (membaca dari storage):
  - Cold (pertama kali dalam transaksi ini): 2100 gas
  - Warm (sudah dibaca sebelumnya dalam transaksi yang sama): 100 gas

SSTORE (menulis ke storage):
  - Slot 0 → nonzero value: 20,000 gas  (membuat slot baru)
  - Slot nonzero → nonzero value: 2,900 gas (mengubah nilai existing)
  - Slot nonzero → 0 (delete): 2,900 gas + mendapat refund 4,800 gas

Bandingkan: ADD opcode hanya 3 gas, MSTORE (write to memory) hanya 3 gas
```

Ini adalah kenapa **storage adalah resource paling mahal di EVM**, dan optimasi storage adalah kunci gas optimization di smart contract.

---

## Calldata: Read-Only Input dari Luar

Calldata adalah payload **input** yang dikirim bersama transaksi. Ini adalah area paling murah karena:
1. Read-only (tidak bisa dimodifikasi selama eksekusi)
2. Tidak perlu dialokasikan ke dalam VM state

```solidity
// Dalam fungsi Solidity, parameter bisa berasal dari storage, memory, atau calldata:

// ❌ Boros gas: salin array dari calldata ke memory
function process(uint256[] memory data) external { ... }

// ✅ Efisien: baca langsung dari calldata tanpa menyalin
function process(uint256[] calldata data) external { ... }
```

**Kapan pakai `calldata` vs `memory`?**:
- `calldata`: Untuk **parameter fungsi `external`** — data hanya perlu dibaca, tidak dimodifikasi. Selalu lebih murah.
- `memory`: Ketika Anda perlu **memodifikasi** data, atau untuk **local variable** sementara dalam fungsi.
- `storage`: Ketika data perlu **persisten** di antara transaksi.

---

## Visualisasi Lengkap: Dari Transaksi ke Stack Execution

```text
TRANSAKSI MASUK:
{
  to:   0xTokenContract,
  data: 0xa9059cbb                         // function selector: transfer()
        000...0000[BobAddress]             // arg 1: recipient (32 bytes)
        000...000056bc75e2d63100000        // arg 2: amount (32 bytes)
}

                    │
                    ▼ EVM Execution Starts

┌─────────────────────────────────────────────────────────┐
│                    EVM EXECUTION                        │
│                                                         │
│  PROGRAM COUNTER: 0                                     │
│                                                         │
│  STACK: []                                              │
│  MEMORY: [empty]                                        │
│  CALLDATA: [0xa9059cbb][BobAddress][amount]             │
│  STORAGE: {slot0: 1000, slot1: mapping...}  ← READS HERE│
│                                                         │
│  [1] Load function selector from calldata              │
│  [2] Jump to transfer() function body in bytecode       │
│  [3] SLOAD sender balance from storage (2100 gas)       │
│  [4] Check: balance >= amount (stack operation)         │
│  [5] SSTORE: reduce sender balance (20000 gas)          │
│  [6] SSTORE: increase recipient balance (2900 gas)      │
│  [7] MSTORE: prepare event data in memory              │
│  [8] LOG3: emit Transfer event                          │
│  [9] STOP                                               │
│                                                         │
│  STORAGE AFTER: {slot0: 1000, [sender]:900, [bob]:100} │
└─────────────────────────────────────────────────────────┘
```

---

## Latihan C3: EVM Internals

### Soal 5 — Data Location Optimization
Review kode berikut dan identifikasi masalah gas optimization:

```solidity
contract NFTCollection {
    string[] private tokenURIs;  // stored in storage
    
    // Version A
    function getURIsV1(uint256[] memory tokenIds) external view returns (string[] memory) {
        string[] memory results = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            string memory uri = tokenURIs[tokenIds[i]];  // copy to memory
            results[i] = uri;
        }
        return results;
    }
    
    // Version B
    function getURIsV2(uint256[] calldata tokenIds) external view returns (string[] memory) {
        string[] memory results = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            results[i] = tokenURIs[tokenIds[i]];
        }
        return results;
    }
}
```

**Pertanyaan**:
- a) Apa perbedaan gas antara `Version A` dan `Version B`? Di mana tepatnya penghematannya?
- b) Apakah ada masalah dengan cara `tokenURIs[tokenIds[i]]` diakses? Berapa SLOAD yang terjadi per iterasi?
- c) Jika ada 1000 NFT dalam collection dan user request 500 tokenURIs sekaligus, apa masalah yang mungkin terjadi?

<details>
<summary>💡 Pembahasan</summary>

**a)** Perbedaan: `Version B` menggunakan `calldata` untuk parameter `tokenIds`, sementara `Version A` menggunakan `memory`. Ketika fungsi dipanggil, EVM harus menyalin seluruh array `tokenIds` dari calldata ke memory pada `Version A` (operasi tambahan). Pada `Version B`, array dibaca langsung dari calldata tanpa penyalinan → hemat gas proporsional dengan ukuran array.

Selain itu, `Version A` membuat local variable `string memory uri` yang tidak perlu — ini adalah alokasi memory yang sia-sia. `Version B` langsung assign.

**b)** Ya, ada masalah. Setiap kali `tokenURIs[tokenIds[i]]` diakses (untuk string yang panjang), EVM harus melakukan multiple SLOAD karena:
- Panjang string disimpan di satu slot
- Konten string tersebar di slot-slot berikutnya berdasarkan panjangnya

Untuk string dengan panjang > 31 bytes, butuh setidaknya 2+ SLOAD per elemen. Untuk string pendek (≤ 31 bytes), bisa masuk dalam 1 slot.

**c)** Jika user request 500 tokenURIs dengan rata-rata string 50 bytes per URI, ini bisa mengkonsumsi gas yang melebihi block gas limit (30 juta gas). Transaksi akan selalu revert. Ini adalah pattern yang perlu dipecah menjadi batch yang lebih kecil, atau diimplementasikan via off-chain indexer + on-chain verification.

</details>

---

### Soal 6 — Stack vs Storage Mental Model
Jelaskan perbedaan perilaku dua variabel dalam konteks EVM:

```solidity
contract Example {
    uint256 public storedValue = 42;  // Deklarasi A
    
    function calculate() external view returns (uint256) {
        uint256 localValue = 100;     // Deklarasi B
        return localValue + storedValue;
    }
}
```

**Pertanyaan**:
- a) Di area mana (`storage`, `memory`, atau `stack`) masing-masing variabel disimpan? Jelaskan untuk `storedValue` DAN `localValue`.
- b) Berapa kali `SLOAD` terjadi ketika `calculate()` dipanggil? Berapa gas untuk itu?
- c) Jika `calculate()` dipanggil 100 kali dalam satu transaksi (misalnya dalam sebuah loop), berapa total gas untuk SLOAD saja?

<details>
<summary>💡 Pembahasan</summary>

**a)**
- `storedValue` → **STORAGE** (slot 0). Karena dideklarasikan sebagai state variable di level contract. Persisten di antara transaksi.
- `localValue` → **STACK**. Karena ini adalah local variable di dalam fungsi. Nilainya di-PUSH ke stack, digunakan untuk operasi, lalu di-POP. Hilang setelah fungsi selesai.

**b)** Tepat **1 SLOAD** terjadi — saat `storedValue` dibaca dari storage slot 0. Gas: 2100 (cold, karena slot ini belum diakses sebelumnya dalam transaksi ini).

**c)** Jika `calculate()` dipanggil 100 kali dalam satu transaksi (dalam loop):
- Call pertama: SLOAD cold = 2100 gas
- Call ke-2 sampai ke-100: SLOAD warm = 100 gas (sudah "warm" karena slot sudah diakses sebelumnya)
- Total SLOAD gas = 2100 + (99 × 100) = 2100 + 9900 = **12,000 gas**

Optimasi: Jika Anda membaca `storedValue` 100 kali, lebih efisien untuk membacanya sekali di awal, menyimpannya ke local variable (stack), lalu gunakan local variable dalam loop:
```solidity
uint256 cached = storedValue; // 1x SLOAD = 2100 gas
for (uint256 i = 0; i < 100; i++) {
    // gunakan cached, bukan storedValue langsung
    result = cached + i; // hanya stack operations (3 gas each)
}
```

</details>

---

---

# C4: Storage Layout — Slot Packing & Mappings

> *Bagaimana Solidity mengorganisasi data di 2^256 slot storage adalah salah satu topik paling kritis untuk keamanan dan gas optimization.*

---

## State Variable Slot Assignment

Solidity meng-assign storage slot secara **sequential**, dimulai dari slot 0, mengikuti urutan deklarasi:

```solidity
contract StorageLayout {
    uint256 public a;  // slot 0 (32 bytes penuh)
    uint256 public b;  // slot 1 (32 bytes penuh)
    uint128 public c;  // slot 2, bytes 0-15
    uint128 public d;  // slot 2, bytes 16-31 (packing!)
    address public e;  // slot 3, bytes 0-19 (20 bytes)
    bool    public f;  // slot 3, bytes 20   (packing!)
    uint256 public g;  // slot 4 (tidak bisa pack dengan slot 3, perlu 32 bytes)
}
```

```text
STORAGE LAYOUT VISUALISASI:
Slot 0: [00 00 00 ... a (32 bytes) ...]
Slot 1: [00 00 00 ... b (32 bytes) ...]
Slot 2: [c (16 bytes) | d (16 bytes)]     ← PACKED dalam 1 slot!
Slot 3: [e (20 bytes)  | f (1 byte) | 00 00 ... 00 (11 bytes)]
Slot 4: [00 00 00 ... g (32 bytes) ...]
```

**Aturan Slot Packing**:
- Variabel di-pack ke dalam slot yang sama jika ukurannya muat (total ≤ 32 bytes) dan urutan deklarasinya berurutan.
- Jika variabel berikutnya tidak muat, slot baru dimulai.
- `uint256`, `bytes32` selalu mengisi slot penuh (tidak bisa di-pack bersama variabel lain).

---

## Implikasi Keamanan: Storage Layout Collision

Storage layout collision adalah salah satu vulnerability paling berbahaya dalam upgradeable contract patterns.

```solidity
// VERSION 1 - Original Contract
contract V1 {
    uint256 public totalSupply;  // slot 0
    mapping(address => uint256) public balances;  // slot 1
}

// VERSION 2 - "Upgraded" Contract (SALAH - slot collision!)
contract V2 {
    address public owner;        // slot 0 ← MENIMPA totalSupply!
    uint256 public totalSupply;  // slot 1 ← MENIMPA balances!
    mapping(address => uint256) public balances;  // slot 2
}
```

Jika proxy contract mengarah ke V1, lalu di-upgrade ke V2 tanpa memperhatikan storage layout, membaca `totalSupply` via V2 akan membaca nilai yang tersimpan di slot 0 — yang sekarang di-interpretasikan sebagai `address owner`. Data rusak total.

> **Ini adalah salah satu bug yang paling sering terjadi dalam upgradeable contracts — dan akan kita pelajari mendalam di Phase 8 (Security) dan Phase `upgradeable-contracts`.**

---

## Mapping: Bagaimana Slot-nya Dihitung?

Mapping di Solidity tidak menggunakan slot yang berurutan — menggunakan **keccak256 hashing** untuk menghitung slot yang tepat:

```solidity
mapping(address => uint256) public balances;  // berada di slot k

// Slot untuk key tertentu:
slot_for_key = keccak256(abi.encode(key, k))

// Contoh:
// balances di slot 1
// balances[0xAlice] = keccak256(abi.encode(0xAlice, 1))
//                   = 0x3f1d...  ← ini adalah slot yang sebenarnya digunakan
```

Kenapa ini penting?
1. **Tidak ada collision**: Probabilitas dua key berbeda menghasilkan slot yang sama adalah astronomically small (keccak256 collision resistant).
2. **Tidak ada iterasi**: Mapping tidak bisa di-loop/enumerate. Ini adalah property Solidity yang sering mengejutkan developer Web2.
3. **Relevan untuk storage proof dan security research**: Jika Anda tahu slot layout, Anda bisa membaca nilai mapping apapun langsung dari state trie Ethereum.

---

## Dynamic Arrays: Layout yang Berbeda

```solidity
uint256[] public myArray;  // berada di slot k

// Panjang array disimpan di slot k:
length = storage[k]

// Elemen array disimpan mulai dari:
base_slot = keccak256(k)

// Element ke-i:
slot_for_element_i = keccak256(k) + i
```

```
Contoh: myArray di slot 0
  storage[slot 0]         = panjang array (misalnya: 5)
  storage[keccak256(0)]   = myArray[0]
  storage[keccak256(0)+1] = myArray[1]
  storage[keccak256(0)+2] = myArray[2]
  ...
```

---

## Gas Optimization: Struct Packing

```solidity
// ❌ BOROS GAS — 3 slot storage untuk 1 struct
struct UserBad {
    uint256 id;       // slot X    (32 bytes)
    bool    active;   // slot X+1  (32 bytes, padahal hanya 1 bit yang dipakai!)
    uint256 balance;  // slot X+2  (32 bytes)
}

// ✅ EFISIEN — hanya 2 slot storage untuk 1 struct
struct UserGood {
    uint256 id;       // slot X   (32 bytes)
    uint256 balance;  // slot X+1 (32 bytes)
    bool    active;   // slot X+1 bisa di-pack? No, tapi...
    // Sebenarnya urutannya mempengaruhi packing:
}

// ✅✅ OPTIMAL — hanya 2 slot storage
struct UserOptimal {
    uint256 id;       // slot X   (32 bytes penuh)
    uint128 balance;  // slot X+1 (16 bytes, setengah slot)
    uint64  lastSeen; // slot X+1 (8 bytes, lanjutan)
    bool    active;   // slot X+1 (1 byte, lanjutan)
    // Total slot X+1: 16+8+1 = 25 bytes < 32 bytes ✅
}
```

---

## Latihan C4: Storage Layout Detective

### Soal 7 — Slot Calculation
Diberikan contract berikut:

```solidity
contract Token {
    string  public name;        // slot 0
    string  public symbol;      // slot 1
    uint8   public decimals;    // slot 2, bytes 0
    uint256 public totalSupply; // slot 3 (uint8 tidak bisa pack dengan uint256)
    
    mapping(address => uint256) public balances;           // slot 4
    mapping(address => mapping(address => uint256)) public allowance; // slot 5
}
```

**Pertanyaan**:
- a) Berapa slot nomor yang menyimpan `balances[0xAlice]`? Tulis rumus kalkulasinya.
- b) Berapa slot nomor yang menyimpan `allowance[0xAlice][0xBob]`? Tulis rumus kalkulasinya.
- c) Di block explorer, apakah Anda bisa membaca nilai `balances[0xAlice]` dari storage langsung (tanpa memanggil fungsi)? Bagaimana caranya?

<details>
<summary>💡 Pembahasan</summary>

**a)** `balances` ada di slot 4. Untuk `balances[0xAlice]`:
```
slot = keccak256(abi.encode(0xAlice, 4))

Dalam hex (menggunakan Foundry/Node.js):
  keccak256(abi.encodePacked(
    bytes32(uint256(uint160(0xAlice))),  // address di-pad jadi 32 bytes
    bytes32(uint256(4))                   // slot number di-pad jadi 32 bytes
  ))
```
Hasilnya adalah sebuah angka 32-byte yang merupakan slot storage yang sebenarnya.

**b)** `allowance` adalah nested mapping di slot 5. Untuk `allowance[0xAlice][0xBob]`:
```
// Langkah 1: hitung slot untuk outer mapping (Alice)
outer_slot = keccak256(abi.encode(0xAlice, 5))

// Langkah 2: hitung slot untuk inner mapping (Bob di dalam Alice)
final_slot = keccak256(abi.encode(0xBob, outer_slot))
```

**c)** Ya! Anda bisa membaca raw storage menggunakan RPC method `eth_getStorageAt`:
```javascript
const response = await fetch("https://rpc.ankr.com/eth", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getStorageAt",
    params: [
      "0xContractAddress",
      "0x[calculated_slot_hex]",  // slot yang sudah dihitung
      "latest"
    ]
  })
});
```
Ini adalah kenapa semua data on-chain bersifat **publik** — bahkan data di mapping yang tidak ada getter publiknya. Jangan pernah menyimpan data sensitif (seperti password, private key, secret) di storage contract!

</details>

---

---

# C5: ABI — Bagaimana Frontend Bicara ke Smart Contract

## Apa itu ABI?

**ABI (Application Binary Interface)** adalah "kontrak antarmuka" yang mendefinisikan bagaimana cara memanggil fungsi-fungsi dalam smart contract dari luar (frontend, backend, atau contract lain).

Analoginya: ABI itu seperti **Swagger/OpenAPI spec** untuk REST API — ia mendokumentasikan endpoint apa saja yang ada, parameter apa yang diterima, dan apa yang dikembalikan.

```json
// Contoh ABI untuk fungsi transfer ERC-20:
[
  {
    "type": "function",
    "name": "transfer",
    "inputs": [
      { "name": "to",     "type": "address" },
      { "name": "amount", "type": "uint256" }
    ],
    "outputs": [
      { "name": "", "type": "bool" }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "Transfer",
    "inputs": [
      { "name": "from",  "type": "address", "indexed": true },
      { "name": "to",    "type": "address", "indexed": true },
      { "name": "value", "type": "uint256", "indexed": false }
    ]
  }
]
```

---

## Proses Encoding: ABI Encoding

Ketika frontend ingin memanggil `transfer(0xBob, 100 * 10^18)`:

```text
LANGKAH 1: Hitung function selector
  signature = "transfer(address,uint256)"
  selector  = bytes4(keccak256(signature))
            = bytes4(0xddf252ad...) 
            = 0xa9059cbb

LANGKAH 2: ABI encode arguments
  arg1 (address 0xBob): 
    → di-pad kiri jadi 32 bytes:
    → 0x000000000000000000000000[BobAddress20bytes]
    
  arg2 (uint256 100 * 10^18 = 100000000000000000000):
    → dalam hex: 0x56bc75e2d63100000
    → di-pad kiri jadi 32 bytes:
    → 0x0000000000000000000000000000000000000000000000056bc75e2d63100000

LANGKAH 3: Gabungkan menjadi calldata
  0xa9059cbb                                                       (4 bytes: selector)
  000000000000000000000000[BobAddress]                             (32 bytes: arg1)
  0000000000000000000000000000000000000000000000056bc75e2d63100000 (32 bytes: arg2)
```

---

## State Mutability: Pure, View, Nonpayable, Payable

Setiap fungsi Solidity memiliki **state mutability** yang menentukan interaksinya dengan state:

```solidity
// PURE: Tidak membaca atau mengubah state (hanya komputasi dari input)
// Di RPC: eth_call (tidak butuh transaksi, gratis)
function add(uint256 a, uint256 b) external pure returns (uint256) {
    return a + b;
}

// VIEW: Hanya membaca state, tidak mengubah (SLOAD boleh, SSTORE tidak)
// Di RPC: eth_call (tidak butuh transaksi, gratis)
function getBalance(address user) external view returns (uint256) {
    return balances[user]; // membaca dari storage
}

// NONPAYABLE: Bisa mengubah state, tapi tidak menerima ETH
// Di RPC: eth_sendTransaction (perlu transaksi, butuh gas)
function transfer(address to, uint256 amount) external returns (bool) {
    balances[msg.sender] -= amount;  // SSTORE
    balances[to] += amount;          // SSTORE
    return true;
}

// PAYABLE: Bisa mengubah state DAN menerima ETH
// Di RPC: eth_sendTransaction dengan value > 0
function deposit() external payable {
    balances[msg.sender] += msg.value;  // msg.value = ETH yang dikirim
}
```

---

## Events: Cara Smart Contract "Log" ke Dunia Luar

Events adalah cara murah untuk **mencatat data** tanpa menyimpannya di storage:

```solidity
// Deklarasi event
event Transfer(address indexed from, address indexed to, uint256 value);

// Emit event saat transfer terjadi
emit Transfer(msg.sender, to, amount);
```

```text
EVENT STORAGE (Transaction Receipt Logs):
  ┌────────────────────────────────────────────────────────────┐
  │ LOG3                                                       │
  │  Topics (indexed args — bisa di-filter di query):         │
  │   [0] keccak256("Transfer(address,address,uint256)")       │
  │       = 0xddf252ad... (event signature hash)              │
  │   [1] 0x[from address padded to 32 bytes]                  │
  │   [2] 0x[to address padded to 32 bytes]                    │
  │  Data (non-indexed args):                                  │
  │   0x[value as uint256]                                     │
  └────────────────────────────────────────────────────────────┘
```

**Kenapa Events penting?**
- **Sangat murah** vs SSTORE: LOG opcode ≈ 375 gas vs SSTORE 20,000 gas.
- **Dapat di-query** oleh frontend dan indexer.
- **Off-chain**: Tidak tersimpan di state trie — tersimpan di receipt, sehingga tidak membebani node dengan data permanen.

**Keterbatasan Events**:
- **Smart contract tidak bisa membaca event** — event hanya untuk pihak off-chain (frontend, indexer, analytics).
- Tidak ada cara untuk membaca event dari dalam contract. Data yang perlu dibaca oleh contract lain HARUS disimpan di storage.

---

## Latihan C5: ABI & Interface Engineering

### Soal 8 — Encoding Manual
Anda ingin memanggil fungsi `approve(address spender, uint256 amount)` pada contract token ERC-20 di address `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` (USDC).

Parameter:
- `spender`: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D` (Uniswap Router)
- `amount`: 1,000,000 (1 USDC — ingat USDC hanya 6 desimal, bukan 18)

**Pertanyaan**:
- a) Hitung function selector untuk `approve(address,uint256)`.
- b) Tulis calldata lengkap yang akan dikirim ke contract.
- c) Apa perbedaan jika amount-nya adalah `type(uint256).max` — pattern apa ini dan mengapa umum digunakan di DeFi?

<details>
<summary>💡 Pembahasan</summary>

**a)** Function selector:
```
signature = "approve(address,uint256)"
selector  = bytes4(keccak256("approve(address,uint256)"))
          = 0x095ea7b3
```

**b)** Calldata lengkap:
```
0x095ea7b3                                                       (selector)
0000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d (spender: Uniswap Router)
00000000000000000000000000000000000000000000000000000000000f4240 (amount: 1,000,000 = 0xF4240)
```

**c)** `type(uint256).max` = `2^256 - 1` = `0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff`

Pattern ini disebut **"infinite approval"** atau **"max approval"**. Maknanya: Anda memberikan izin kepada `spender` untuk mengambil token Anda dalam jumlah tak terbatas.

Mengapa umum? **UX Reason**: Tanpa ini, setiap kali Anda swap di Uniswap, Anda harus melakukan dua transaksi terpisah (1: approve exact amount, 2: swap) yang mahal. Dengan max approval, Anda hanya approve sekali seumur hidup → transaksi berikutnya langsung swap.

**Security concern**: Ini adalah **risiko keamanan signifikan**. Jika contract Uniswap (atau contract yang Anda approve) ternyata punya vulnerability atau kena hack, attacker bisa menguras seluruh token Anda. Best practice: selalu approve **jumlah yang Anda butuhkan saja** jika Anda tidak percaya 100% pada contract tersebut.

</details>

---

### Soal 9 — Events vs Storage Design Decision
Anda membangun sebuah contract `AuctionHouse` dan perlu menyimpan riwayat setiap bid yang masuk.

```solidity
// Pilihan A: Simpan di storage
struct Bid { address bidder; uint256 amount; uint256 timestamp; }
Bid[] public bids;

function placeBid() external payable {
    bids.push(Bid(msg.sender, msg.value, block.timestamp));
}

// Pilihan B: Emit event
event BidPlaced(address indexed bidder, uint256 amount, uint256 timestamp);

function placeBid() external payable {
    emit BidPlaced(msg.sender, msg.value, block.timestamp);
}
```

**Pertanyaan**:
- a) Bandingkan biaya gas `Pilihan A` vs `Pilihan B` untuk 1000 bid.
- b) Anda ingin menampilkan riwayat semua bid di UI frontend. Mana yang lebih efisien?
- c) Smart contract membutuhkan data bid terakhir untuk logika bisnis (misal: menolak bid yang lebih rendah). Mana yang harus digunakan?
- d) Apa arsitektur optimal yang menggabungkan keduanya?

<details>
<summary>💡 Pembahasan</summary>

**a)** Gas cost estimation:
- **Pilihan A (Storage)**: Setiap `push` baru menuliskan 3 storage slot baru (bidder, amount, timestamp). Minimum: 3 × 20,000 (new slot) = ~60,000 gas per bid. Untuk 1000 bid: ~60,000,000 gas — ini melebihi block gas limit!
- **Pilihan B (Event)**: `LOG3` (3 topics + data) ≈ 375 + (topics × 375) + (data_size × 8) gas. Untuk Bid event: sekitar 1,500-3,000 gas per bid. Untuk 1000 bid: ~2,000,000 gas — jauh lebih feasible.

**b)** Untuk UI frontend: **Pilihan B (Events)** lebih efisien. Frontend/indexer bisa query event logs menggunakan `eth_getLogs` RPC call tanpa mengeluarkan gas. Event juga bisa di-filter by address, block range, dll.

**c)** Untuk logika bisnis kontrak: **Pilihan A (Storage)** atau kombinasi yang optimal. Jika contract perlu tahu "berapa bid tertinggi saat ini?", data itu harus ada di storage.

**d)** Arsitektur Optimal — simpan **minimal di storage**, emit **semua di events**:
```solidity
contract AuctionHouse {
    address public highestBidder;   // hanya simpan yang diperlukan logika
    uint256 public highestBid;      // hanya simpan yang diperlukan logika
    
    event BidPlaced(address indexed bidder, uint256 amount, uint256 timestamp);
    
    function placeBid() external payable {
        require(msg.value > highestBid, "Bid too low");
        
        // Update minimal storage (hanya 2 SSTORE)
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        // Emit full history ke events (murah)
        emit BidPlaced(msg.sender, msg.value, block.timestamp);
    }
}
```

Frontend query seluruh history via `eth_getLogs`. Contract hanya akses storage untuk validasi. Best of both worlds!

</details>

---

---

# 📝 Mini Project: EVM Storage Inspector

## Deskripsi
Bangun sebuah **EVM Storage Inspector** — tool CLI yang memungkinkan Anda membaca raw storage slot dari smart contract manapun dan meng-interpret nilainya.

## Requirements

1. **Input**: Contract address + slot number (atau kalkulasi otomatis dari key mapping).
2. **Feature 1 — Direct Slot Read**: Baca nilai dari storage slot yang spesifik.
3. **Feature 2 — Mapping Slot Calculator**: Hitung slot untuk `mapping(address => uint256)` berdasarkan key + base slot.
4. **Feature 3 — Contract Classifier**: Identifikasi apakah address adalah EOA atau Contract (`eth_getCode`).
5. **Feature 4 — ABI Decoder**: Decode function selector dari calldata menggunakan database 4bytes publik.

## Tech Stack
- Node.js (native fetch, no external dependencies)
- Public RPC: `https://rpc.ankr.com/eth`
- [4bytes.directory](https://www.4byte.directory/api/v1/signatures/?hex_signature=0xa9059cbb) — Public API untuk decode function selectors

## Hints

<details>
<summary>Hint 1: eth_getStorageAt RPC call</summary>

```javascript
async function readStorageSlot(contractAddress, slotNumber) {
  // slotNumber perlu di-convert ke hex dengan padding 32 bytes
  const slotHex = "0x" + BigInt(slotNumber).toString(16).padStart(64, "0");
  
  const response = await fetch("https://rpc.ankr.com/eth", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "eth_getStorageAt",
      params: [contractAddress, slotHex, "latest"]
    })
  });
  const data = await response.json();
  return data.result; // Nilai slot dalam hex (32 bytes)
}
```

</details>

<details>
<summary>Hint 2: Kalkulasi mapping slot</summary>

```javascript
import { createHash } from "crypto";

function calculateMappingSlot(key, baseSlot) {
  // ABI encode: key (padded 32 bytes) + baseSlot (padded 32 bytes)
  const keyPadded = key.toLowerCase().replace("0x", "").padStart(64, "0");
  const slotPadded = BigInt(baseSlot).toString(16).padStart(64, "0");
  
  const encoded = keyPadded + slotPadded;
  
  const hash = createHash("sha3-256")  // Note: gunakan library keccak yang tepat
    .update(Buffer.from(encoded, "hex"))
    .digest("hex");
  
  return "0x" + hash;
}

// Atau lebih baik, gunakan library 'ethers' atau 'viem' untuk keccak256 yang benar:
// import { keccak256, pad, concat } from 'viem'
```

</details>

<details>
<summary>Hint 3: Decode function selector via 4bytes API</summary>

```javascript
async function decodeFunctionSelector(selector) {
  // selector contoh: "0xa9059cbb"
  const hexSig = selector.replace("0x", "");
  
  const response = await fetch(
    `https://www.4byte.directory/api/v1/signatures/?hex_signature=0x${hexSig}`
  );
  const data = await response.json();
  
  if (data.results.length > 0) {
    return data.results[0].text_signature;
    // Misal: "transfer(address,uint256)"
  }
  return "unknown";
}
```

</details>

---

# 🏆 Challenge: "Smart Contract Reverse Engineer"

> *Tidak ada tutorial untuk bagian ini. Gunakan semua pengetahuan dari C1–C5.*

## Misi
Anda diberikan sebuah contract address yang tidak diketahui (unverified source code) di Ethereum Sepolia testnet.

**Target contract**: Deploy contract berikut ke Sepolia testnet menggunakan Remix IDE, salin address-nya, lalu coba "reverse engineer" contract tersebut tanpa melihat source code — hanya dari raw bytecode dan storage.

*Atau gunakan existing contract yang source code-nya tidak verified di Etherscan.*

## Tugas
1. Fetch bytecode contract menggunakan `eth_getCode`.
2. Identifikasi function selectors yang ada dalam bytecode (fungsi sering dimulai dengan `PUSH4` diikuti selector).
3. Decode setiap function selector menggunakan 4bytes.directory API.
4. Baca storage slot 0, 1, 2, 3 dari contract.
5. Buat hipotesis tentang: Apa yang dilakukan contract ini? Berapa banyak state variables yang ada?
6. Verifikasi hipotesis dengan memanggil fungsi yang Anda temukan menggunakan `eth_call`.
7. Tulis laporan singkat "Reverse Engineering Report" dalam format markdown.

## Output yang Diharapkan
File `reverse-engineering-report.md` berisi:
- Alamat contract
- Fungsi yang ditemukan (selector + decoded signature)
- Analisis storage (apa isi setiap slot)
- Kesimpulan: Apa yang dilakukan contract ini?

---

## 📁 GitHub Task

```bash
# Buat struktur folder untuk Phase 2
cd 02-ethereum-and-evm/

# Setelah selesai mini project dan exercise, commit:
git add .
git commit -m "learn: ethereum and EVM — stack, memory, storage, ABI, calldata"

# Commit mini project
git add .
git commit -m "feat: add EVM storage inspector CLI tool (Phase 2 mini project)"

# Commit challenge
git add .
git commit -m "feat: add smart contract reverse engineering report (Phase 2 challenge)"
```

---

## 🧠 Knowledge Check

1. Mengapa EVM disebut "Turing-complete" tapi tidak bisa menjalankan infinite loop? Mekanisme apa yang mencegahnya?
2. Sebutkan 4 area data di EVM dan jelaskan satu perbedaan kunci antara masing-masing.
3. Kenapa `calldata` lebih murah daripada `memory`? Kapan Anda **harus** menggunakan `memory` meski lebih mahal?
4. Apa yang dimaksud dengan "storage slot collision" dalam context upgradeable contracts dan mengapa ini berbahaya?
5. Sebuah contract memiliki state variable `uint128 x` diikuti `uint128 y`. Berapa slot storage yang digunakan? Dan jika urutannya dibalik menjadi `uint256 z` kemudian `uint128 y` dan `uint128 x`, berapa slot yang digunakan?
6. Mengapa smart contract tidak bisa langsung memanggil external HTTP API?
7. Apa perbedaan antara Contract Account dan EOA dalam hal kemampuan menginisiasi transaksi?
8. Apa itu `eth_call` vs `eth_sendTransaction`? Kapan masing-masing digunakan?
9. Fungsi dengan `view` modifier dieksekusi di mana (oleh siapa), dan apakah memerlukan gas?
10. Jelaskan mengapa events tidak bisa dibaca oleh smart contract lain, dan apa implikasinya terhadap desain arsitektur?

---

## 📊 Progress Tracker

- [ ] **C1**: Ethereum World Computer — *Determinism, Turing-completeness, Gas*
- [ ] **C2**: Account Model EOA vs Contract — *Ownership, initiation, CREATE/CREATE2*
- [ ] **C3**: EVM Architecture — *Stack, Memory, Storage, Calldata*
- [ ] **C4**: Storage Layout — *Slot packing, Mapping slots, Struct optimization*
- [ ] **C5**: ABI & Events — *Encoding, function selectors, state mutability, events vs storage*
- [ ] **Exercise**: Soal 1–9 (termasuk Etherscan exploration)
- [ ] **Mini Project**: EVM Storage Inspector CLI
- [ ] **Challenge**: Smart Contract Reverse Engineering Report
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Ethereum.org: EVM Deep Dive](https://ethereum.org/en/developers/docs/evm/)
- [Ethereum.org: Accounts](https://ethereum.org/en/developers/docs/accounts/)
- [Ethereum.org: Smart Contract Anatomy](https://ethereum.org/en/developers/docs/smart-contracts/anatomy/)
- [Solidity Docs: Data Locations](https://docs.soliditylang.org/en/latest/types.html#data-location)
- [Solidity Docs: Layout of State Variables in Storage](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [EIP-1559: Fee Market Change](https://eips.ethereum.org/EIPS/eip-1559)

### Tools
- [Etherscan](https://etherscan.io) — Block explorer, verify contract, read storage
- [evm.codes](https://www.evm.codes/) — **Interactive opcode reference dengan gas cost** ← Sangat berguna!
- [4bytes.directory](https://www.4byte.directory/) — Decode function selectors
- [ABI Encoder/Decoder](https://abi.hashex.org/) — Encode/decode ABI data manually

### Untuk Eksplorasi Lebih Lanjut
- [Noxx: EVM Deep Dives Series](https://noxx.substack.com/p/evm-deep-dives-the-path-to-shadowy)
- [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) — Spesifikasi formal EVM
- [OpenZeppelin: EVM Puzzles](https://github.com/fvictorio/evm-puzzles) — Teka-teki interaktif untuk memahami EVM bytecode

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi)*
