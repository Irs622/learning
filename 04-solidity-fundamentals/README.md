# 04 — Solidity Fundamentals

> **Level**: 2–3 (Technical Fundamentals + Implementation)
> **Phase**: 4 of 13
> **Estimated Time**: 🚀 Intensif 10–14 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 4–5 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [03-cryptography-and-wallets](../03-cryptography-and-wallets/README.md) ✅
> **Status verifikasi**: **Reviewed** · 9 Okt 2026 · teks direview penuh; snippet utama di-compile — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menulis smart contract Solidity yang terstruktur dengan benar dari nol.
- **Memilih** tipe Solidity yang tepat (value, reference, `constant`/`immutable`) dan **memprediksi** apakah sebuah ekspresi compile, revert, atau berjalan normal.
- **Menemukan dan memperbaiki** bug data location (`storage` vs `memory` vs `calldata`) serta menjelaskan dampak gas-nya.
- Menulis **functions** dengan visibility, state mutability, modifiers, dan error handling yang tepat.
- Menggunakan **events** untuk logging on-chain yang efisien.
- **Merancang** arsitektur multi-contract dengan **inheritance** (urutan linearisasi yang benar), **interfaces**, dan **libraries**.
- Membaca dan menulis kode Solidity sambil selalu memikirkan implikasi **gas cost** dan **security**.

---

## 📋 Prerequisites

- [x] Memahami EVM Storage layout dan slot assignment (Phase 2).
- [x] Memahami bagaimana calldata, memory, dan storage berbeda di EVM (Phase 2).
- [x] Node.js dan npm terinstall.
- [ ] **Foundry terinstall** → Kita install bersama di awal phase ini.

---

## ⚙️ Setup: Install Foundry

Sebelum mulai, install **Foundry** — modern smart contract development toolkit:

```bash
# Install Foundry (Mac/Linux)
curl -L https://foundry.paradigm.xyz | bash
# atau pin: foundryup -i v1.7.1 (versi yang dipakai untuk memverifikasi materi)
foundryup

# Verify installation
forge --version   # forge Version: 1.x.x
cast --version
anvil --version

# Init project untuk Phase 4 — di SUBFOLDER lab/
cd 04-solidity-fundamentals/
forge init lab --no-git   # init tanpa nested git
cd lab
```

> ⚠️ **Jangan** `forge init .` di folder fase: folder ini sudah berisi `README.md` materi, sehingga `forge init` menolak berjalan, dan jika dipaksa dengan `--force` **README materi akan ditimpa** README bawaan Foundry.

Struktur folder yang akan dibuat Foundry:
```
04-solidity-fundamentals/
├── README.md          ← Materi (file ini)
└── lab/
    ├── src/           ← Smart contracts Anda
    ├── test/          ← Test files
    ├── script/        ← Deployment scripts
    ├── lib/           ← Dependencies (di-.gitignore, install ulang dengan forge install)
    └── foundry.toml   ← Config file
```

Hapus contoh bawaan (`src/Counter.sol`, `test/Counter.t.sol`, `script/Counter.s.sol`) setelah Anda melihat isinya. Semua path `src/`, `test/`, `script/` di fase ini relatif terhadap `lab/`.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Anatomy of a Solidity Contract](#c1-anatomy-of-a-solidity-contract) | ⬜ |
| **C2** | [Type System: Value Types](#c2-type-system--value-types) | ⬜ |
| **C3** | [Type System: Reference Types & Data Locations](#c3-type-system--reference-types--data-locations) | ⬜ |
| **C4** | [Functions: Visibility, Mutability & Modifiers](#c4-functions--visibility-mutability--modifiers) | ⬜ |
| **C5** | [Error Handling: require, revert, assert & Custom Errors](#c5-error-handling--require-revert-assert--custom-errors) | ⬜ |
| **C6** | [Events & Logging](#c6-events--logging) | ⬜ |
| **C7** | [Inheritance, Interfaces & Libraries](#c7-inheritance-interfaces--libraries) | ⬜ |

---

---

# C1: Anatomy of a Solidity Contract

## Mental Model: Solidity adalah "Bahasa Konfigurasi State Machine"

Di Laravel, satu controller bisa punya method yang baca DB, tulis DB, panggil API eksternal, dan return response dalam satu request.

Di Solidity, setiap function adalah "instruksi untuk mengubah state machine" yang berjalan di dalam EVM yang:
- Deterministik (tidak ada random, tidak ada eksternal call bebas)
- Dibatasi gas
- Semua state perubahan bersifat atomic (semua berhasil atau semua di-revert)

---

## Struktur Lengkap Sebuah Contract

```solidity
// ℹ️ Ilustrasi struktur — import `./interfaces/IMyInterface.sol` hanya contoh; tidak
// dimaksudkan di-compile apa adanya.
// SPDX-License-Identifier: MIT
// [1] License declaration — sangat dianjurkan (sejak 0.6.8 compiler memberi WARNING jika tidak ada)
// Penting untuk open-source compliance & verifikasi di Etherscan.

pragma solidity ^0.8.24;
// [2] Compiler version declaration
// ^0.8.24 = "0.8.24 atau lebih tinggi, tapi bukan 0.9.x ke atas"
// =0.8.24  = "persis versi 0.8.24 saja"
// >=0.8.0 <0.9.0 = "range explicit"
// Best practice: gunakan versi spesifik di production untuk reproducibility

// [3] Imports (jika ada)
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMyInterface.sol";

// [4] Contract declaration dengan optional inheritance
contract MyContract is Ownable {
    
    // [5] Type definitions (struct, enum) — biasanya di atas state variables
    struct UserProfile {
        address wallet;
        uint256 balance;
        bool isActive;
    }
    
    enum Status { Inactive, Active, Suspended }

    // [6] State variables (tersimpan di storage — PERMANEN di blockchain)
    uint256 public constant MAX_SUPPLY = 1_000_000;  // constant: tidak butuh storage slot
    uint256 public immutable deployedAt;              // immutable: diset sekali di constructor
    
    uint256 private _totalMinted;
    mapping(address => UserProfile) private _profiles;
    address[] private _registeredUsers;
    
    // [7] Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount);
    
    // [8] Custom Errors (lebih gas-efisien dari string revert message)
    error UserAlreadyExists(address user);
    error InsufficientBalance(uint256 available, uint256 requested);
    error ZeroAddress();

    // [9] Modifiers
    modifier onlyActiveUser() {
        require(_profiles[msg.sender].isActive, "User not active");
        _;
    }

    // [10] Constructor — dieksekusi SEKALI saat deployment
    constructor() Ownable(msg.sender) {
        deployedAt = block.timestamp;
    }
    
    // [11] Receive & Fallback (special functions untuk handling ETH)
    receive() external payable {
        // Dipanggil ketika ETH dikirim ke contract tanpa calldata
    }
    
    fallback() external payable {
        // Dipanggil ketika fungsi yang dipanggil tidak ada (function selector tidak match)
    }

    // [12] External functions (public API contract ini)
    function register() external {
        if (_profiles[msg.sender].wallet != address(0)) {
            revert UserAlreadyExists(msg.sender);
        }
        
        _profiles[msg.sender] = UserProfile({
            wallet: msg.sender,
            balance: 0,
            isActive: true
        });
        _registeredUsers.push(msg.sender);
        
        emit UserRegistered(msg.sender, block.timestamp);
    }

    // [13] Internal functions (hanya bisa dipanggil dari contract ini dan turunannya)
    function _validateAmount(uint256 amount) internal pure {
        require(amount > 0, "Amount must be > 0");
    }
    
    // [14] View functions (baca state, tidak tulis)
    function getProfile(address user) external view returns (UserProfile memory) {
        return _profiles[user];
    }
}
```

---

## Konteks Global: `msg`, `block`, `tx`

Solidity menyediakan variabel global yang menyimpan informasi tentang transaksi/block saat ini:

```solidity
// msg — Informasi tentang TRANSAKSI SAAT INI
msg.sender    // address yang memanggil fungsi ini (bisa EOA atau contract)
msg.value     // jumlah ETH (dalam wei) yang dikirim bersama transaksi
msg.data      // full calldata (bytes) dari transaksi
msg.sig       // bytes4 function selector dari calldata

// block — Informasi tentang BLOCK SAAT INI
block.number      // nomor block saat ini
block.timestamp   // Unix timestamp block saat ini (dalam detik)
                  // Di Ethereum PoS ditentukan oleh slot (kelipatan 12 detik) — proposer
                  // tidak bisa menggesernya bebas, tetapi JANGAN dipakai sebagai sumber
                  // randomness; di L2/chain lain aturannya bisa berbeda (Phase 12).
block.basefee     // base fee dalam wei (EIP-1559)
block.chainid     // chain ID (1=Ethereum, 137=Polygon, dll)
block.coinbase    // address penerima fee (fee recipient) yang di-set proposer block ini

// tx — Informasi tentang TRANSAKSI
tx.gasprice   // gas price dari transaksi asal
tx.origin     // EOA address yang MEMULAI transaksi
              // ⚠️ tx.origin berbeda dari msg.sender ketika ada contract-to-contract call!
              // ⚠️ JANGAN gunakan tx.origin untuk authorization — rentan phishing!
```

**Ilustrasi penting: `msg.sender` vs `tx.origin`**

```text
Skenario: Alice → ContractA → ContractB

Di ContractB:
  msg.sender = address(ContractA)  ← siapa yang langsung memanggil
  tx.origin  = address(Alice)      ← EOA yang memulai seluruh chain

Bug jika ContractB menggunakan tx.origin untuk auth:
  Attacker bisa membuat ContractEvil yang memanggil ContractB.
  Alice tertipu berinteraksi dengan ContractEvil (phishing).
  tx.origin = Alice → ContractB pikir Alice yang memanggil → EXPLOIT!
```

---

## Latihan C1: Contract Structure

### Soal 1 — Contract Reading Exercise

Baca contract berikut dan jawab pertanyaan di bawah:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleVault {
    address public owner;
    uint256 private _balance;
    bool private _locked;
    
    event Deposited(address indexed depositor, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    
    error NotOwner();
    error InsufficientFunds();
    error ReentrantCall();
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier noReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }
    
    receive() external payable {
        _balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external onlyOwner noReentrant {
        if (amount > _balance) revert InsufficientFunds();
        _balance -= amount;
        (bool success,) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(owner, amount);
    }
    
    function getBalance() external view returns (uint256) {
        return _balance;
    }
}
```

**Pertanyaan**:
- a) Berapa storage slot yang digunakan contract ini? Variabel apa yang di-pack bersama?
- b) Kenapa `_locked` dan `_balance` tidak di-pack dalam satu slot meskipun `bool` hanya 1 byte? (Lihat urutan deklarasi!)
- c) Apa yang dilakukan modifier `noReentrant` dan mengapa urutan operasinya penting untuk keamanan?
- d) Kenapa `receive()` dipakai bukan `fallback()` untuk menerima ETH?
- e) Kenapa `(bool success,) = owner.call{value: amount}("")` lebih disukai daripada `owner.transfer(amount)` di Solidity modern?

<details>
<summary>💡 Pembahasan</summary>

**a)** Tiga storage slot:
- Slot 0: `owner` (address, 20 bytes — mengisi sebagian slot, sisanya kosong)
- Slot 1: `_balance` (uint256, 32 bytes — penuh satu slot)
- Slot 2: `_locked` (bool, 1 byte)

**b)** Karena `_balance` (uint256 = 32 bytes) berada di antara `owner` dan `_locked`. Aturan packing: variabel hanya bisa di-pack jika mereka berurutan dan muat dalam 32 bytes. Setelah `owner` (20 bytes), tersisa 12 bytes di slot 0. `_balance` butuh 32 bytes penuh → tidak muat → slot 1 dimulai. `_locked` menjadi slot 2.

Jika deklarasi diubah menjadi `address public owner; bool private _locked; uint256 private _balance;`, maka `owner` (20 bytes) dan `_locked` (1 byte) bisa di-pack di slot 0, menghemat 1 storage slot.

**c)** `noReentrant` adalah **Reentrancy Guard**. Sebelum fungsi berjalan, set `_locked = true`. Setelah selesai, set `_locked = false`. Jika attacker mencoba memanggil `withdraw()` lagi **sebelum** eksekusi pertama selesai (via malicious contract di dalam `owner.call`), modifier akan cek `if (_locked) revert`. Urutan `_locked = false` di akhir (`_`) sangat kritis — jika di awal, guard tidak efektif.

**d)** `receive()` dipanggil ketika ETH dikirim **tanpa calldata** (plain ETH transfer). `fallback()` dipanggil ketika calldata tidak cocok dengan fungsi manapun (atau tidak ada calldata dan tidak ada `receive()`). Untuk menerima ETH dari wallet biasa, `receive()` lebih tepat semantiknya.

**e)** `transfer()` dan `send()` dulu populer karena hanya forward 2300 gas (dianggap cukup untuk prevent reentrancy). Tapi setelah EIP-1884 mengubah gas cost beberapa opcode, 2300 gas tidak cukup untuk beberapa contract — menyebabkan transfer gagal. `.call{value: amount}("")` forward semua available gas (lebih fleksibel) tapi developer bertanggung jawab untuk proteksi reentrancy sendiri (via modifier seperti `noReentrant`).

</details>

---

---

# C2: Type System — Value Types

> *Solidity memiliki type system yang lebih ketat dari JavaScript tapi lebih mirip Rust dalam hal memory safety. Sebagai engineer, pahami ini dengan baik karena bug tipe adalah sumber vulnerability yang umum.*

---

## Unsigned Integers (`uint`)

```solidity
// uint adalah alias untuk uint256 (paling umum dipakai)
uint8   a = 255;          // 0 sampai 2^8-1  = 255
uint16  b = 65535;        // 0 sampai 2^16-1 = 65,535
uint32  c = 4294967295;   // 0 sampai 2^32-1
uint64  d = type(uint64).max;
uint128 e = type(uint128).max;
uint256 f = type(uint256).max;  // Default "uint"
// =
// 115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,935

// Useful constants:
uint256 public constant MAX = type(uint256).max; // 2^256 - 1
uint256 public constant MIN = type(uint256).min; // 0

// Arithmetic di Solidity ≥ 0.8.0: OVERFLOW/UNDERFLOW auto-revert!
uint8 x = 255;
x = x + 1;  // ← REVERT! (SafeMath behavior built-in sejak 0.8.0)
// Sebelum 0.8.0: x would silently wrap to 0 → sumber bug besar!

// Jika Anda perlu wrap behavior (misalnya untuk gas optimization):
unchecked {
    x = x + 1; // Wrap silently — gunakan hanya jika Anda YAKIN tidak bisa overflow
}
```

---

## Signed Integers (`int`)

```solidity
int8   a = -128;   // -2^7 sampai 2^7-1  = -128 sampai 127
int16  b = -32768;
int256 c = type(int256).min; // -2^255
int256 d = type(int256).max; //  2^255 - 1

// Common use case: price changes, profit/loss calculations
int256 priceChange = int256(newPrice) - int256(oldPrice); // bisa negatif
```

---

## Address

```solidity
address           wallet = 0x1234...;  // 20 bytes, bisa receive ETH
// Tipe yang bisa dipanggil .transfer() dan .send()
address payable   payableWallet = payable(wallet);

// Properties & methods:
wallet.balance;                           // Wei balance (opcode BALANCE, bukan SLOAD)
payableWallet.transfer(1 ether);          // Kirim 1 ETH, revert jika gagal
bool ok = payableWallet.send(1 ether);   // Kirim, return false jika gagal
(bool success,) = wallet.call{value: 1 ether}(""); // Paling fleksibel

// Type conversions:
address(this)          // address contract ini sendiri
// zero address (null address — tidak ada yang diketahui memegang private key-nya)
address(0)
// konversi dari integer — WAJIB lewat uint160 (address(uint256(x)) = compile error)
address(uint160(123))
uint256(uint160(addr)) // konversi address ke uint256

// ⚠️ address(0) sering digunakan untuk "burn" token (kirim ke sini = hilang selamanya)
// ⚠️ Selalu validasi: require(to != address(0), "Cannot send to zero address")
```

---

## Boolean, Bytes & String

```solidity
// Boolean
bool isActive = true;
bool flag = !isActive;   // false
bool result = (a && b) || (!c);

// Fixed-size bytes (bytes1 sampai bytes32)
bytes1  single = 0xFF;      // 1 byte
bytes4  selector = 0xa9059cbb;  // function selector
bytes32 hash = keccak256(abi.encodePacked("hello")); // 32 bytes

// bytes32 vs string: bytes32 lebih gas-efisien untuk data tetap
// bytes32 bisa dicompare: hash1 == hash2 (O(1))
// string tidak bisa dicompare langsung: keccak256(bytes(s1)) == keccak256(bytes(s2))

// Dynamic bytes (seperti string tapi untuk binary data)
bytes memory data = abi.encodePacked(address(this), uint256(42));

// String (dynamic, stored as bytes internally)
string memory name = "Ethereum";
string memory greeting = string.concat("Hello, ", name); // Solidity 0.8.12+

// PENTING: string tidak bisa di-compare langsung!
// ❌ if (name == "Ethereum") → COMPILE ERROR
// ✅ if (keccak256(bytes(name)) == keccak256(bytes("Ethereum")))

// String di storage mahal! Pertimbangkan bytes32 untuk string pendek (≤ 31 chars):
bytes32 shortName = "ETH"; // Lebih gas-efisien dari string
```

---

## Special Types: `constant` dan `immutable`

```solidity
contract TokenConfig {
    // CONSTANT: Nilainya ditentukan saat compile time
    // Tidak menggunakan storage slot! Langsung di-embed ke bytecode.
    uint256 public constant MAX_SUPPLY = 21_000_000 * 10**18;
    string  public constant NAME = "MyToken";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // IMMUTABLE: Nilainya diset SEKALI di constructor, tidak bisa diubah lagi
    // Tidak menggunakan storage slot! Di-embed ke bytecode setelah deploy.
    address public immutable OWNER;
    uint256 public immutable CHAIN_ID;
    uint256 public immutable DEPLOYED_AT;
    
    constructor() {
        OWNER = msg.sender;          // set sekali
        CHAIN_ID = block.chainid;    // set sekali
        DEPLOYED_AT = block.timestamp; // set sekali
        // Setelah constructor selesai, nilai-nilai ini TIDAK BISA BERUBAH
    }
}

// Gas comparison:
// constant/immutable: ~3 gas (PUSH opcode, langsung dari bytecode)
// regular state var:  ~2100 gas (SLOAD dari storage)
// → Gunakan constant/immutable sebanyak mungkin untuk nilai yang tidak berubah!
```

---

## Enums

```solidity
contract Auction {
    enum Phase {
        Inactive,  // 0
        Commit,    // 1
        Reveal,    // 2
        Finalized  // 3
    }
    
    Phase public currentPhase;  // default: Phase.Inactive (0)
    
    function startCommit() external {
        require(currentPhase == Phase.Inactive, "Wrong phase");
        currentPhase = Phase.Commit;
    }
    
    // Enum disimpan sebagai uint8 di storage
    // Max 256 values per enum
    // Casting: uint8(Phase.Commit) = 1
    //          Phase(1) = Phase.Commit
}
```

---

## Latihan C2: Type System

### Soal 2 — Type Safety & Overflow Analysis

```solidity
// ⚠️ SENGAJA mengandung error — bagian dari soal. Tebak dulu, lalu buktikan dengan `forge build`.
pragma solidity ^0.8.24;

contract TypeExercise {
    // Soal: Analisis setiap baris, apakah compile? Apakah revert saat runtime?
    
    function test1() external pure returns (uint256) {
        uint8 a = 200;
        uint8 b = 100;
        return a + b; // ???
    }
    
    function test2() external pure returns (uint256) {
        uint8 a = 200;
        uint8 b = 100;
        uint256 result = uint256(a) + uint256(b);
        return result; // ???
    }
    
    function test3() external pure returns (uint8) {
        unchecked {
            uint8 a = 200;
            uint8 b = 100;
            return a + b; // ???
        }
    }
    
    function test4(address addr) external view returns (uint256) {
        return addr.balance; // ???
    }
    
    function test5() external pure returns (bool) {
        string memory s1 = "hello";
        string memory s2 = "hello";
        return s1 == s2; // ???
    }
}
```

**Pertanyaan**: Untuk setiap fungsi, prediksi apakah akan: (A) Compile error, (B) Runtime revert, (C) Berjalan normal. Jelaskan mengapa.

<details>
<summary>💡 Pembahasan</summary>

**test1()**: **(B) Runtime REVERT** — ekspresi `a + b` dihitung dalam tipe `uint8` (tipe operand), sehingga `200 + 100 = 300` melebihi max uint8 (255) → **panic `0x11` (arithmetic overflow)**. Subtlety: kode ini **tetap compile**, karena konversi implisit `uint8` → `uint256` untuk nilai return itu sah — tetapi konversi baru terjadi *setelah* penjumlahan `uint8` yang sudah overflow. Itulah sebabnya `test2()` melakukan cast **sebelum** menjumlahkan.

**test2()**: **(C) Normal** — cast ke `uint256` dulu sebelum dijumlahkan. `uint256(200) + uint256(100) = 300` — valid, jauh dari max uint256.

**test3()**: **(C) Normal, return 44** — `unchecked` menonaktifkan overflow check. `200 + 100 = 300`, tapi karena `uint8`, wrap: `300 mod 256 = 44`. Return value: `44`.

**test4()**: **(C) Normal** — `.balance` adalah property valid di setiap `address`, mengembalikan wei balance. Ini adalah `BALANCE` opcode, bukan SLOAD.

**test5()**: **(A) Compile Error** — Solidity tidak mendukung `==` untuk `string`. Harus gunakan `keccak256(bytes(s1)) == keccak256(bytes(s2))`.

</details>

---

### Soal 3 — Gas-Conscious Type Selection

Anda membuat contract untuk sistem absensi karyawan. Setiap karyawan punya:
- ID (1 sampai 10.000)
- Nama (max 32 karakter)
- Status (Aktif, Cuti, Resign)
- Total hari hadir (max 365 per tahun)
- Timestamp terakhir hadir

**Pertanyaan**:
- a) Pilih type yang paling efisien (secara gas/storage) untuk setiap field di atas.
- b) Tuliskan struct `Employee` yang optimal (perhatikan packing order!).
- c) Mengapa urutan field dalam struct mempengaruhi gas cost?

<details>
<summary>💡 Pembahasan</summary>

**a) Type selection**:
- ID (1-10.000): `uint16` (max 65.535 — muat, hanya 2 bytes)
- Nama (≤32 chars): `bytes32` (fixed 32 bytes, lebih efisien dari `string`, bisa langsung compare)
- Status: `enum Status { Active, Leave, Resigned }` → disimpan sebagai `uint8` (1 byte)
- Total hari hadir: `uint16` (max 65.535, lebih dari cukup untuk 365 — hanya 2 bytes)
- Timestamp terakhir: `uint40` (cukup untuk timestamp sampai tahun ~36,000 — 5 bytes) atau `uint48` untuk safety

**b) Struct Optimal (dengan packing)**:
```solidity
enum Status { Active, Leave, Resigned }

struct Employee {
    bytes32 name;       // slot N    (32 bytes penuh — tidak bisa di-pack)
    uint48  lastSeen;   // slot N+1  (6 bytes)
    uint16  totalDays;  // slot N+1  (2 bytes, pack bersama lastSeen)
    uint16  id;         // slot N+1  (2 bytes, pack bersama)
    Status  status;     // slot N+1  (1 byte, pack bersama)
    // Total slot N+1: 6+2+2+1 = 11 bytes < 32 bytes ✅
    // Sisa slot N+1: 21 bytes kosong
}
// Total: 2 storage slots per employee
```

Bandingkan dengan struct yang tidak dioptimasi:
```solidity
struct EmployeeBad {
    uint256 id;         // slot N    (32 bytes)
    string name;        // slot N+1  (32 bytes minimum untuk length) + lebih jika panjang
    uint256 lastSeen;   // slot N+2  (32 bytes)
    Status status;      // slot N+3  (32 bytes untuk 1 byte data!)
    uint256 totalDays;  // slot N+4  (32 bytes)
}
// Total: 5+ storage slots per employee vs 2 slots yang dioptimasi!
```

**c)** Solidity mengisi slot dari kanan ke kiri dalam 32-byte window. Jika dua variabel berurutan dalam deklarasi dan ukurannya muat dalam 32 bytes sisa, mereka di-pack. Jika Anda meletakkan `uint256` di antara dua `uint128`, mereka tidak bisa di-pack bersama karena `uint256` membutuhkan slot baru. Urutan: "kumpulkan variabel kecil bersama" → minimasi jumlah slot.

</details>

---

---

# C3: Type System — Reference Types & Data Locations

> *Ini adalah topik paling kritis di Solidity bagi developer yang datang dari bahasa lain. Kesalahan di sini bisa menyebabkan bug diam-diam (silent bugs) atau vulnerability serius.*

---

## Data Locations: Tiga Alam di Solidity

```solidity
// STORAGE: Persisten di blockchain
// ─────────────────────────────────
// - State variables selalu di storage
// - SLOAD: 2100 gas (cold), 100 gas (warm)
// - SSTORE: 20,000 gas (slot kosong → terisi), 2,900 gas (ubah nilai) — +2,100 jika slot masih cold
// - Perubahan tidak terbalik jika tidak ada revert

// MEMORY: Sementara, per-call
// ─────────────────────────────────
// - Local variables dalam fungsi (reference types)
// - MSTORE: 3 gas + biaya alokasi (makin besar makin mahal secara kuadratik)
// - Hilang ketika fungsi selesai

// CALLDATA: Read-only input
// ─────────────────────────────────
// - Hanya untuk parameter fungsi `external`
// - Tidak bisa dimodifikasi
// - Paling murah: 4 gas/byte (zero), 16 gas/byte (nonzero)
```

---

## Array

```solidity
contract ArrayDemo {
    // Fixed-size array (di storage)
    uint256[5] private fixedArray;   // Selalu 5 elemen, tidak bisa berubah ukuran
    
    // Dynamic array (di storage)
    uint256[] private dynamicArray;  // Bisa push/pop
    address[] private users;

    function playWithArrays() external {
        // Dynamic array operations
        dynamicArray.push(42);           // Tambah elemen di akhir
        dynamicArray.push(100);
        dynamicArray.pop();              // Hapus elemen terakhir — TIDAK mengembalikan nilai
                                         // (`uint256 x = arr.pop();` = compile error)
        uint256 len  = dynamicArray.length;
        
        // Delete: tidak menghapus elemen dari array, hanya reset ke default value (0)!
        delete dynamicArray[0];  // ← dynamicArray[0] = 0, tapi length tetap sama!
        // ⚠️ Ini adalah source of bug! Array tidak "compact" setelah delete.
        
        // Akses: akan REVERT jika index out of bounds (≥0.8.0)
        uint256 val = dynamicArray[0];  // OK
        uint256 bad = dynamicArray[999]; // REVERT: array out-of-bounds
    }

    // ⚠️ Data location wajib untuk array sebagai parameter/return
    function processMemory(uint256[] memory arr) external pure returns (uint256) {
        arr[0] = 999;  // OK — memodifikasi COPY di memory (tidak affect storage)
        return arr.length;
    }
    
    function processCalldata(uint256[] calldata arr) external pure returns (uint256) {
        // arr[0] = 999;  // ← COMPILE ERROR: calldata is read-only!
        return arr.length; // OK — hanya baca
    }
    
    function readStorage() external view returns (uint256[] memory) {
        return dynamicArray;  // Copy dari storage ke memory untuk dikembalikan
    }
}
```

---

## Mapping

```solidity
contract MappingDemo {
    // mapping(KeyType => ValueType)
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances; // nested
    mapping(bytes32 => bool) private _usedSignatures;
    
    // Properti mapping yang HARUS Anda pahami:
    // 1. TIDAK bisa di-iterate (tidak ada .length, .keys, .values)
    // 2. Semua key "ada" secara virtual dengan default value (0, false, address(0), dll)
    // 3. TIDAK bisa di-assign ke memory
    // 4. TIDAK bisa di-return sebagai return value fungsi publik
    // 5. Key tidak disimpan — hanya value-nya
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    function approve(address spender, uint256 amount) external {
        allowances[msg.sender][spender] = amount;
    }
    
    // ❌ Tidak bisa: "return semua balances"
    // function getAllBalances() external view returns (mapping(address => uint256) memory) { }
    
    // ✅ Solusi: simpan array of keys secara terpisah
    address[] private _holders;
    mapping(address => bool) private _isHolder;
    
    function _addHolder(address user) internal {
        if (!_isHolder[user]) {
            _isHolder[user] = true;
            _holders.push(user);
        }
    }
}
```

---

## Structs

```solidity
contract StructDemo {
    struct Order {
        address buyer;
        uint256 amount;
        uint256 price;
        bool    fulfilled;
    }
    
    // Mapping of orders
    mapping(uint256 => Order) private _orders;
    uint256 private _nextOrderId;
    
    function createOrder(uint256 price) external payable returns (uint256 orderId) {
        orderId = _nextOrderId++;
        
        // Cara 1: Named initialization (lebih readable)
        _orders[orderId] = Order({
            buyer:     msg.sender,
            amount:    msg.value,
            price:     price,
            fulfilled: false
        });
    }
    
    // ⚠️ CRITICAL: storage pointer vs copy!
    function badUpdate(uint256 orderId) external {
        Order memory order = _orders[orderId]; // COPY dari storage ke memory!
        order.fulfilled = true;                // Update COPY — tidak affect storage!
        // _orders[orderId] masih fulfilled = false!
    }
    
    function goodUpdate(uint256 orderId) external {
        Order storage order = _orders[orderId]; // POINTER ke storage!
        order.fulfilled = true;                  // Update LANGSUNG storage!
        // _orders[orderId].fulfilled = true ✅
    }
    
    // Return struct ke luar: harus pakai memory
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return _orders[orderId]; // Otomatis copy storage ke memory
    }
}
```

---

## Storage Reference vs Memory Copy: The Most Common Bug

```solidity
contract StorageBug {
    uint256[] private _numbers;
    
    function addNumbers() external {
        _numbers.push(10);
        _numbers.push(20);
        _numbers.push(30);
    }
    
    // ❌ BUG: "storage" reference digunakan seperti "memory" copy
    function buggyDoubleAll() external {
        uint256[] memory nums = _numbers; // Ini adalah COPY!
        for (uint256 i = 0; i < nums.length; i++) {
            nums[i] *= 2; // Mengubah COPY di memory, bukan storage!
        }
        // _numbers tidak berubah sama sekali!
    }
    
    // ✅ CORRECT: Menggunakan storage reference
    function correctDoubleAll() external {
        for (uint256 i = 0; i < _numbers.length; i++) {
            _numbers[i] *= 2; // Langsung mengubah storage
        }
    }
    
    // ✅ CORRECT ALTERNATIVE: Gunakan storage pointer
    function correctDoubleAllV2() external {
        uint256[] storage nums = _numbers; // Pointer ke storage!
        for (uint256 i = 0; i < nums.length; i++) {
            nums[i] *= 2; // Mengubah storage via pointer
        }
    }
    
    function getNumbers() external view returns (uint256[] memory) {
        return _numbers;
    }
}
```

---

## Latihan C3: Data Locations Deep Dive

### Soal 4 — Storage vs Memory Bug Hunt

Review kode berikut dan identifikasi semua bug:

```solidity
// ⚠️ SENGAJA mengandung bug — bagian dari soal Bug Hunt (salah satunya bahkan compile error).
contract StudentRegistry {
    struct Student {
        string name;
        uint256[] grades;
        bool active;
    }
    
    mapping(address => Student) private _students;
    
    function enroll(string calldata name) external {
        _students[msg.sender] = Student({
            name: name,
            grades: new uint256[](0),
            active: true
        });
    }
    
    // Bug 1: Coba temukan!
    function addGrade(uint256 grade) external {
        Student memory student = _students[msg.sender];
        student.grades.push(grade);
    }
    
    // Bug 2: Coba temukan!
    function deactivate(address studentAddr) external {
        Student memory s = _students[studentAddr];
        s.active = false;
    }
    
    // Apakah ini benar?
    function getGradesAverage(address studentAddr) external view returns (uint256) {
        Student memory s = _students[studentAddr];
        if (s.grades.length == 0) return 0;
        
        uint256 total = 0;
        for (uint256 i = 0; i < s.grades.length; i++) {
            total += s.grades[i];
        }
        return total / s.grades.length;
    }
}
```

**Pertanyaan**:
- a) Identifikasi dan jelaskan Bug 1 dan Bug 2.
- b) Tulis versi yang sudah diperbaiki untuk `addGrade` dan `deactivate`.
- c) Apakah `getGradesAverage` punya bug? Apakah ada masalah lain (non-bug) yang perlu Anda perhatikan dari perspektif gas?

<details>
<summary>💡 Pembahasan</summary>

**Bug 1 — `addGrade`** — ini bahkan **tidak bisa di-compile**:
```solidity
Student memory student = _students[msg.sender]; // COPY ke memory
student.grades.push(grade);
// ❌ Error (4994): Member "push" is not available in uint256[] memory outside of storage.
```
Array di `memory` berukuran tetap — `push`/`pop` hanya tersedia untuk array di **storage**. Compiler menyelamatkan Anda di sini. Tetapi akar masalahnya sama dengan Bug 2: `student` adalah **salinan**. Seandainya Anda mengganti `push` dengan sesuatu yang lolos compile (misalnya `student.grades[0] = grade;`), perubahan itu hanya mengenai salinan di memory dan **diam-diam hilang** — persis seperti Bug 2.
Perbaikan:
```solidity
function addGrade(uint256 grade) external {
    _students[msg.sender].grades.push(grade); // Langsung ke storage
    // atau: Student storage student = _students[msg.sender];
    //       student.grades.push(grade);
}
```

**Bug 2 — `deactivate`**:
```solidity
Student memory s = _students[studentAddr]; // COPY ke memory!
s.active = false; // Set false di COPY — storage tidak berubah!
```
Perbaikan:
```solidity
function deactivate(address studentAddr) external {
    _students[studentAddr].active = false; // Langsung ke storage
}
```

**`getGradesAverage`**: Tidak ada bug logika. Tapi ada masalah gas: `Student memory s = _students[studentAddr]` menyalin **seluruh struct termasuk array `grades`** ke memory. Jika seorang student punya 1000 grades, ini sangat mahal. Lebih efisien:
```solidity
function getGradesAverage(address studentAddr) external view returns (uint256) {
    uint256[] storage grades = _students[studentAddr].grades; // Pointer, no copy!
    if (grades.length == 0) return 0;
    uint256 total = 0;
    for (uint256 i = 0; i < grades.length; i++) {
        total += grades[i];
    }
    return total / grades.length;
}
```
Tapi perhatikan: ini masih O(n) loop yang bisa sangat mahal untuk array besar. Untuk produksi, pertimbangkan menyimpan running average atau menghitung off-chain.

</details>

---

---

# C4: Functions — Visibility, Mutability & Modifiers

## Visibility: Siapa yang Bisa Memanggil?

```solidity
contract VisibilityDemo {
    uint256 private _secret;    // Storage tapi "private"
    uint256 internal _shared;   // Bisa diakses child contract
    uint256 public exposed;     // Auto-generates getter function

    // PUBLIC: Bisa dipanggil dari luar DAN dari dalam contract
    function publicFn() public { /* ... */ }
    
    // EXTERNAL: Hanya bisa dipanggil dari LUAR contract
    // Dulu lebih hemat gas dari public; sejak Solidity 0.6.9 public juga boleh memakai
    // parameter calldata sehingga selisihnya kecil. Pilih external untuk menyatakan INTENT:
    // "fungsi ini bagian dari API eksternal, bukan helper internal".
    function externalFn(uint256[] calldata data) external { /* ... */ }
    
    // INTERNAL: Hanya dari dalam contract ini DAN contract turunan (seperti protected di OOP)
    function _internalFn() internal { /* ... */ }
    
    // PRIVATE: Hanya dari dalam contract ini saja (tidak terwariskan)
    function __privateFn() private { /* ... */ }
    
    // Konvensi naming (best practice):
    // _underscorePrefix → internal/private functions dan variables
    // noUnderscore → public/external functions dan variables
    
    function callInternal() public {
        _internalFn();    // ✅ OK — memanggil internal dari public
        publicFn();       // ✅ OK
        // externalFn([]); // ❌ Tidak bisa memanggil external secara internal
        this.externalFn(new uint256[](0)); // ✅ Bisa via `this` (tapi ini membuat external call!)
    }
}
```

> **⚠️ Penting**: `private` di Solidity **bukan berarti data tidak bisa dibaca**. Semua data di storage bisa dibaca via `eth_getStorageAt`. "Private" hanya berarti fungsi/variabel tidak bisa dipanggil dari contract lain, bukan bahwa datanya rahasia dari user blockchain.

---

## State Mutability

```solidity
contract MutabilityDemo {
    uint256 public value = 42;
    
    // PURE: Tidak baca dan tidak tulis state
    // Hanya komputasi berdasarkan parameter (atau konstanta)
    // Dipanggil via eth_call — gratis!
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
    
    // VIEW: Bisa BACA state (SLOAD), tapi tidak bisa TULIS
    // Dipanggil via eth_call — gratis!
    function getValue() external view returns (uint256) {
        return value;        // SLOAD dari storage — OK
    }
    
    // (default/nonpayable): Bisa baca DAN tulis state
    // TIDAK bisa menerima ETH (akan revert jika ada value)
    // Dipanggil via eth_sendTransaction — perlu gas!
    function setValue(uint256 newVal) external {
        value = newVal;      // SSTORE ke storage
    }
    
    // PAYABLE: Bisa baca, tulis, DAN menerima ETH
    function deposit() external payable {
        value += msg.value;  // msg.value tersedia karena payable
    }
}
```

---

## Modifiers: Logic yang Bisa Di-reuse

```solidity
contract AccessControl {
    address public owner;
    bool    public paused;
    mapping(address => bool) public admins;
    
    // Modifier basic: ownership check
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _; // Placeholder untuk kode fungsi yang menggunakan modifier
    }
    
    // Modifier dengan parameter
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "Missing role");
        _;
    }
    
    // Modifier untuk emergency stop (Circuit Breaker pattern)
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    // Modifier dengan before DAN after logic
    modifier measureGas() {
        uint256 gasBefore = gasleft();
        _;
        uint256 gasUsed = gasBefore - gasleft();
        emit GasUsed(gasUsed);
    }
    
    event GasUsed(uint256 amount);
    
    // Penggunaan multiple modifiers (dieksekusi dari kiri ke kanan)
    function criticalFunction() external onlyOwner whenNotPaused {
        // Modifier chain: onlyOwner check → whenNotPaused check → kode fungsi
    }
    
    // Fungsi owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
    
    function pause() external onlyOwner {
        paused = true;
    }
    
    function unpause() external onlyOwner {
        paused = false;
    }
    
    function hasRole(bytes32 role, address account) public view returns (bool) {
        // Implementasi role checking
        return false; // Placeholder
    }
}
```

---

## Function Overloading

```solidity
contract Overloading {
    // Fungsi dengan nama sama tapi parameter berbeda
    function transfer(address to, uint256 amount) external { /* ... */ }
    function transfer(address to, uint256 amount, bytes calldata data) external { /* ... */ }
    
    // Saat dipanggil, Solidity pilih berdasarkan function selector:
    // bytes4(keccak256("transfer(address,uint256)"))          → versi 1
    // bytes4(keccak256("transfer(address,uint256,bytes)"))    → versi 2
}
```

---

## Constructor Patterns

```solidity
// Pattern 1: Simple constructor
contract SimpleToken {
    string public name;
    uint256 public totalSupply;
    
    constructor(string memory _name, uint256 _initialSupply) {
        name = _name;
        totalSupply = _initialSupply;
    }
}

// Pattern 2: Dengan inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnedToken is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {
        // Ownable constructor dipanggil dengan initialOwner
    }
}

// Pattern 3: Initializer (untuk upgradeable contracts — preview, detail di Phase 13 C1)
// Di balik proxy, constructor implementation menulis ke storage IMPLEMENTATION, bukan
// storage proxy — jadi setup awal dipindah ke fungsi initialize() yang dipanggil sekali.
// ⚠️ Contoh di bawah rentan front-running jika deploy & initialize dilakukan di tx terpisah
//    (Phase 8 C3); di production gunakan Initializable dari OpenZeppelin.
contract UpgradeableToken {
    bool private _initialized;
    string public name;
    
    function initialize(string memory _name) external {
        require(!_initialized, "Already initialized");
        _initialized = true;
        name = _name;
    }
}
```

---

## Latihan C4: Functions & Modifiers

### Soal 5 — Modifier Composition

Anda membangun kontrak DeFi staking. Buat modifier-modifier berikut dan tunjukkan cara composing-nya:

```solidity
contract StakingPool {
    address public owner;
    bool public paused;
    uint256 public minStakeAmount = 0.1 ether;
    mapping(address => uint256) public stakes;
    
    // TUGAS: Implementasikan modifier berikut:
    // 1. onlyOwner() — hanya owner
    // 2. whenNotPaused() — hanya ketika tidak paused
    // 3. validAmount(uint256 amount) — amount harus > minStakeAmount
    // 4. onlyStaker() — hanya user yang punya stake > 0
    
    // Kemudian gunakan modifier secara tepat pada fungsi:
    // - stake(): validAmount + whenNotPaused
    // - unstake(): onlyStaker + whenNotPaused
    // - setMinStake(): onlyOwner
    // - emergencyPause(): onlyOwner
    // - emergencyUnpause(): onlyOwner
}
```

**✅ Selesai jika:**
- [ ] Contract compile di `lab/` (`forge build`)
- [ ] Test: stake ≤ minimum revert, stake saat paused revert, unstake tanpa stake revert, non-owner tidak bisa pause
- [ ] Penjelasan di Notes: apakah urutan `validAmount` vs `whenNotPaused` mengubah perilaku atau hanya error yang muncul lebih dulu?


---

---

# C5: Error Handling — require, revert, assert & Custom Errors

## Tiga Mekanisme Error di Solidity

```solidity
contract ErrorHandling {
    
    // ===== require() =====
    // Untuk: Validasi input dan kondisi yang diharapkan
    // Gas behavior: Refund sisa gas yang tersisa
    // Best for: User-facing validation
    function transferV1(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be positive");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // ... do transfer
    }
    
    // ===== revert() =====
    // Untuk: Kondisi error yang lebih kompleks, custom errors
    // Gas behavior: Refund sisa gas
    // Best for: Conditional errors dengan context
    function transferV2(address to, uint256 amount) external {
        if (to == address(0)) revert("Cannot transfer to zero address");
        if (amount == 0) revert("Amount must be positive");
        if (balances[msg.sender] < amount) revert("Insufficient balance");
    }
    
    // ===== assert() =====
    // Untuk: Invariant checks — kondisi yang "tidak mungkin" salah
    // Gas behavior: TIDAK refund gas (mengkonsumsi semua gas!) — sebelum 0.8.0
    //               Sejak 0.8.0: menggunakan opcode REVERT (refund gas)
    // Best for: Internal consistency checks (bug detection, bukan user errors)
    function _validateInvariant(uint256 a, uint256 b) internal pure {
        assert(a + b >= a); // Ini harusnya SELALU true (tidak bisa overflow jika uint256)
        // Jika assert gagal: berarti ada bug serius di logic contract kita
    }
    
    // ===== Custom Errors (BEST PRACTICE ≥ 0.8.4) =====
    // Lebih gas-efisien: tidak menyimpan string panjang
    // Bisa menyertakan data konteks
    error InsufficientBalance(address user, uint256 available, uint256 requested);
    error ZeroAddress(string parameter);
    error Unauthorized(address caller, bytes32 requiredRole);
    
    function transferV3(address to, uint256 amount) external {
        if (to == address(0)) revert ZeroAddress("recipient");
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balances[msg.sender], amount);
        }
        // Lebih informatif DAN lebih murah dari string revert!
    }
    
    mapping(address => uint256) balances;
}
```

---

## Gas Cost Comparison: String vs Custom Error

```solidity
// Test: berapa byte yang dikirim sebagai revert data?

// String revert:
require(false, "Insufficient balance for this transfer operation");
// Revert data: ABI-encoded string = 4 bytes (selector) + 32 bytes (offset) 
//              + 32 bytes (length) + 64 bytes (string padded) ≈ 132 bytes
// Gas untuk decode di frontend: lebih besar

// Custom error:
error InsufficientBalance(uint256 available, uint256 requested);
revert InsufficientBalance(100, 200);
// Revert data: 4 bytes (error selector) + 32+32 bytes (params) = 68 bytes
// Lebih kecil = lebih murah untuk kirim + lebih informatif!
```

---

## Checks-Effects-Interactions (CEI) Pattern

Ini adalah pola keamanan **paling penting** di Solidity:

```solidity
// ❌ VULNERABLE: Interaction sebelum Effects
function withdrawVulnerable() external {
    uint256 amount = balances[msg.sender];
    
    // 1. INTERACTION (sebelum effects!) — BAHAYA!
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    
    // 2. EFFECTS (terlambat!)
    balances[msg.sender] = 0;
    
    // BUG: Jika msg.sender adalah contract jahat yang memanggil withdraw() lagi
    // dalam callback-nya, balance belum di-set ke 0 → bisa drain contract!
    // Ini adalah REENTRANCY ATTACK!
}

// ✅ SAFE: Checks → Effects → Interactions
function withdrawSafe() external {
    // 1. CHECKS
    uint256 amount = balances[msg.sender];
    require(amount > 0, "Nothing to withdraw");
    
    // 2. EFFECTS (update state SEBELUM external call)
    balances[msg.sender] = 0;
    
    // 3. INTERACTIONS (external call di akhir)
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    
    emit Withdrawn(msg.sender, amount);
}
```

> **CEI adalah rule #1 keamanan smart contract.** Kita akan bahas eksploit reentrancy secara mendalam di Phase 8 (Security).

---

## Latihan C5: Error Handling Engineering

### Soal 6 — Convert ke Custom Errors

Convert contract berikut untuk menggunakan **custom errors** dan terapkan **CEI pattern** yang benar:

```solidity
contract LendingPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;
    uint256 public totalDeposited;
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        totalDeposited += msg.value;
    }
    
    function borrow(uint256 amount) external {
        require(amount > 0, "Borrow amount must be greater than zero");
        require(amount <= address(this).balance, "Insufficient liquidity in pool");
        require(deposits[msg.sender] >= amount * 2, "Need 2x collateral");
        
        borrows[msg.sender] += amount;
        
        // ❌ CEI violation! Transfer sebelum state final
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
    
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient deposit balance");
        require(deposits[msg.sender] - amount >= borrows[msg.sender] * 2, 
                "Cannot withdraw: would leave insufficient collateral");
        
        // ❌ CEI violation!
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
        
        deposits[msg.sender] -= amount;
        totalDeposited -= amount;
    }
}
```

**✅ Selesai jika:**
- [ ] Tidak ada `require(..., "string")` tersisa; setiap custom error membawa parameter yang membantu debugging
- [ ] Setiap `call` terjadi **setelah** semua perubahan state
- [ ] Test dengan contract attacker membuktikan `withdraw` tidak bisa di-reenter untuk menguras pool
- [ ] Bonus: tulis di Notes satu bug **logika** lain yang Anda temukan (bukan soal error/CEI)


---

---

# C6: Events & Logging

## Best Practices Event Design

```solidity
contract TokenWithEvents {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    // ===== Event Design Rules =====
    
    // 1. Selalu emit event untuk setiap perubahan state penting
    // 2. Index parameters yang sering di-filter (address, ID, status)
    // 3. Max 3 indexed parameters per event (keterbatasan EVM)
    // 4. Non-indexed untuk data yang perlu dibaca tapi jarang di-filter
    
    event Transfer(
        address indexed from,    // Indexed: sering filter by sender
        address indexed to,      // Indexed: sering filter by recipient
        uint256 value            // Non-indexed: nilai yang dikirim
    );
    
    event Approval(
        address indexed owner,   // Indexed
        address indexed spender, // Indexed
        uint256 value            // Non-indexed
    );
    
    // Event lebih kompleks dengan lebih banyak data
    event Swap(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,    // Non-indexed (max 3 indexed sudah penuh)
        uint256 amountOut,
        uint256 fee
    );
    
    // ===== Contoh Emit =====
    function transfer(address to, uint256 amount) external returns (bool) {
        address from = msg.sender;
        
        require(_balances[from] >= amount, "Insufficient balance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);  // Selalu emit setelah state berubah
        return true;
    }
    
    // ===== Query Events dari Frontend =====
    // (Kode JavaScript/TypeScript — bukan Solidity)
    /*
    // Menggunakan viem:
    const logs = await publicClient.getLogs({
        address: tokenAddress,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        args: {
            to: '0xMyAddress...',  // Filter by recipient
        },
        fromBlock: 18000000n,
        toBlock: 'latest',
    });
    */
}
```

---

## `indexed` vs Non-indexed: Implikasi Teknis

```text
Event LOG opcode di EVM:
  Topics (indexed): bisa di-filter efisien (diindeks oleh logs Bloom filter di block header)
    - Max 3 indexed params (+ 1 topic untuk event signature hash)
    - Value type (address, uint, bool, bytes32) disimpan APA ADANYA sebagai topic (di-pad 32 byte)
    - Dynamic types (string, bytes, array, struct) yang di-index: hanya keccak256(value) yang disimpan!
      → Anda kehilangan nilai aslinya dari event topics!
    
  Data (non-indexed): Disimpan di-apa adanya (ABI encoded)
    - Bisa baca nilai asli
    - Tidak bisa di-filter oleh filter node
    
GAS COST:
  LOG0 (0 topics): 375 gas + 8 gas/byte
  LOG1 (1 topic):  375 + 375 = 750 gas + 8 gas/byte
  LOG2 (2 topics): 375 + 750 = 1125 gas + 8 gas/byte
  LOG3 (3 topics): 375 + 1125 = 1500 gas + 8 gas/byte
  LOG4 (4 topics): 375 + 1500 = 1875 gas + 8 gas/byte
```

---

## Latihan C6: Event Design

### Soal 7 — Design Events for NFT Marketplace

Anda membangun NFT Marketplace. Design events untuk fitur-fitur berikut dan jelaskan pilihan indexed/non-indexed Anda:

```
Fitur:
1. User list NFT untuk dijual (NFT contract, tokenId, price, expiry timestamp)
2. User membeli NFT (buyer, seller, NFT contract, tokenId, price yang dibayar)
3. User membatalkan listing (NFT contract, tokenId)
4. Harga ditawar (offerer, NFT contract, tokenId, offered price, expiry)
5. Tawaran diterima (acceptor, offerer, NFT contract, tokenId, final price)
```

Tuliskan deklarasi event Solidity untuk semua fitur di atas.

**✅ Selesai jika:**
- [ ] Setiap event memakai ≤ 3 parameter `indexed`
- [ ] Untuk setiap `indexed`, tulis query frontend/indexer yang dilayaninya (misal "semua listing milik seller X")
- [ ] Bandingkan dengan event marketplace nyata (cari di Etherscan, misal Seaport) dan catat 2 perbedaan


---

---

# C7: Inheritance, Interfaces & Libraries

## Inheritance: Membangun di Atas Contract Lain

```solidity
// ℹ️ Ilustrasi konsep inheritance — beberapa contract di bawah sengaja tidak lengkap (argumen
// constructor, isi `/* ... */`).
// Base contract
contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    error NotOwner();
    
    constructor(address initialOwner) {
        _owner = initialOwner;
    }
    
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    // virtual: mengizinkan child contract untuk override
    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Child contract: inherits Ownable
contract MyToken is Ownable {
    uint256 public totalSupply;
    
    constructor(address _owner) Ownable(_owner) {
        // Ownable constructor dipanggil dengan _owner
    }
    
    // override: menimpa implementasi parent
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Cannot set zero address as owner");
        super.transferOwnership(newOwner); // Panggil implementasi parent
    }
    
    function mint(uint256 amount) external onlyOwner {
        // onlyOwner dari Ownable bisa dipakai karena inheritance
        totalSupply += amount;
    }
}

// Multiple Inheritance (C3 Linearization)
contract ERC20 is Ownable {
    /* ... */
}

contract ERC20Pausable is ERC20 {
    /* Inherits Ownable melalui ERC20 */
}

// Diamond problem diselesaikan oleh C3 linearization.
// Aturan Solidity: tulis parent dari yang paling "BASE" ke yang paling "DERIVED".
// ❌ contract MyToken2 is ERC20Pausable, Ownable {}  → Error: Linearization of inheritance graph
// impossible
// ✅ (ilustrasi — argumen constructor Ownable diabaikan di sini)
contract MyToken2 is Ownable, ERC20Pausable {
    // Saat ada fungsi yang sama di beberapa parent, `super.method()` mengikuti urutan
    // linearisasi dari KANAN ke KIRI; atau panggil eksplisit: ContractName.method()
}
```

---

## Interfaces: Kontrak Tanpa Implementasi

```solidity
// Interface mendefinisikan "ABI" tanpa implementasi
// Semua fungsi harus external, tidak boleh ada state variables, tidak boleh ada constructor
interface IERC20 {
    // Events boleh ada di interface
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Fungsi yang harus diimplementasikan oleh contract yang menggunakan interface ini
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// Menggunakan interface untuk interact dengan contract yang sudah ada di blockchain
contract TokenInteractor {
    // Memanggil fungsi token ERC-20 yang sudah deployed
    function getTokenBalance(address tokenAddress, address user) external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);  // "Cast" address ke interface
        return token.balanceOf(user);          // Panggil fungsi melalui interface
    }
    
    function transferTokens(address tokenAddress, address to, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(to, amount);
        require(success, "Transfer failed");
    }
}

// Contract yang mengimplementasikan interface
contract MyERC20Token is IERC20 {
    // Harus implement SEMUA fungsi dari IERC20
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    // ... implement semua fungsi lainnya
    
    function transfer(address to, uint256 amount) external override returns (bool) { return false; }
    function allowance(address owner, address spender) external view override returns (uint256) { return 0; }
    function approve(address spender, uint256 amount) external override returns (bool) { return false; }
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) { return false; }
}
```

---

## Libraries: Reusable Function Collections

```solidity
// ℹ️ Ilustrasi — memakai `IERC20` dari blok Interfaces di atas; gabungkan keduanya jika ingin
// meng-compile.
// Library: kumpulan fungsi stateless yang bisa digunakan oleh contract lain
// Library tidak punya state, tidak bisa menerima ETH, tidak bisa inherit
library SafeTransfer {
    error TransferFailed(address token, address from, address to, uint256 amount);
    
    // safeTransfer: wrapper yang selalu revert jika transfer gagal
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        bool success = token.transfer(to, amount);
        if (!success) revert TransferFailed(address(token), address(this), to, amount);
    }
    
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bool success = token.transferFrom(from, to, amount);
        if (!success) revert TransferFailed(address(token), from, to, amount);
    }
}

// Using library dengan "using ... for"
contract TokenVault {
    using SafeTransfer for IERC20;  // Menambahkan method library ke type IERC20
    
    IERC20 public token;
    
    function depositTokens(uint256 amount) external {
        // token.safeTransferFrom(msg.sender, address(this), amount);
        // Dipanggil seperti method dari token!
        token.safeTransferFrom(msg.sender, address(this), amount);
    }
    
    function withdrawTokens(address to, uint256 amount) external {
        token.safeTransfer(to, amount); // Library function dipanggil sebagai method
    }
}

// Library yang di-deploy secara terpisah (external library)
library MathLib {
    // Bisa dihubungkan ke contract via linking saat deployment
    function sqrt(uint256 x) external pure returns (uint256) {
        // Implementasi sqrt yang mahal — di-deploy sekali, dipakai banyak contract
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
```

---

## Abstract Contracts

```solidity
// Abstract: punya fungsi yang belum diimplementasikan, tidak bisa di-deploy langsung
abstract contract PaymentSplitter {
    // Fungsi ini HARUS diimplementasikan oleh child contract
    function getRecipients() public view virtual returns (address[] memory);
    function getShares() public view virtual returns (uint256[] memory);
    
    // Implementasi yang bisa digunakan oleh semua child
    function splitPayment() external payable {
        address[] memory recipients = getRecipients();
        uint256[] memory shares = getShares();
        uint256 total = msg.value;
        
        // ⚠️ Contoh sederhana untuk ilustrasi abstract contract. Push payment dalam loop
        //    rawan DoS jika satu penerima menolak ETH, dan `transfer` hanya meneruskan
        //    2300 gas — di production pakai pull pattern (Phase 8 C7).
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = (total * shares[i]) / 100;
            payable(recipients[i]).transfer(amount);
        }
    }
}

// Concrete implementation
contract TeamPaymentSplitter is PaymentSplitter {
    address[] private _team;
    uint256[] private _percentages;
    
    constructor(address[] memory team, uint256[] memory percentages) {
        _team = team;
        _percentages = percentages;
    }
    
    function getRecipients() public view override returns (address[] memory) {
        return _team;
    }
    
    function getShares() public view override returns (uint256[] memory) {
        return _percentages;
    }
}
```

---

## Latihan C7: Architecture Design

### Soal 8 — Design Pattern Challenge

Anda perlu membangun sebuah sistem yang terdiri dari beberapa contract:
1. **`Vault`**: Menyimpan ETH, hanya owner yang bisa withdraw
2. **`TimelockVault`**: Vault dengan delay 48 jam sebelum withdrawal bisa dilakukan
3. **`MultisigVault`**: Vault yang butuh 2 dari 3 approver untuk withdraw

**Pertanyaan**:
- a) Identifikasi fungsi/logic yang bisa di-shared (kandidat base contract atau library).
- b) Buat diagram inheritance atau komposisi yang Anda rekomendasikan.
- c) Tulis interface `IVault` yang mendefinisikan API publik untuk semua tipe vault.
- d) Tulis skeleton implementasi untuk `TimelockVault` yang meng-extends base contract yang tepat.

**✅ Selesai jika:**
- [ ] `IVault` dan ketiga vault compile; ketiganya meng-implement `IVault`
- [ ] Diagram inheritance/komposisi ada di Notes
- [ ] Test `TimelockVault`: withdraw sebelum 48 jam revert, tepat setelah 48 jam berhasil (`vm.warp`)


---

---

# 📝 Mini Project: `SimpleStorage` → `TypedRegistry`

Ini adalah progression dari "Hello World" Solidity menuju contract yang nyata.

## Tahap 1: SimpleStorage (Warmup)

```solidity
// Buat: src/SimpleStorage.sol
// Goal: Pahami basic read/write state

contract SimpleStorage {
    uint256 private _value;
    
    function store(uint256 value) external { /* ... */ }
    function retrieve() external view returns (uint256) { /* ... */ }
}
```

Tulis juga test minimal:
```solidity
// test/SimpleStorage.t.sol
contract SimpleStorageTest is Test {
    function test_StoreAndRetrieve() public { /* ... */ }
    function test_RevertIfZero() public { /* ... */ }  // Tambahkan validation
}
```

## Tahap 2: TypedRegistry (Main Project)

Contract yang menggabungkan semua konsep C1-C7:

```solidity
// Buat: src/TypedRegistry.sol
// Sebuah registry sistem yang mencatat profile developer

// Requirements:
// - Struct: DeveloperProfile { address wallet, string name, uint8 level, bool verified, uint256
// joinedAt }
// - Enum: Level { Junior, Mid, Senior, Lead }
// - Mapping: address → DeveloperProfile
// - Events: Registered, LevelUpdated, Verified
// - Custom Errors: AlreadyRegistered, NotRegistered, Unauthorized, InvalidLevel
// - Modifiers: onlyOwner, onlyRegistered
// - Functions:
//   - register(string calldata name) external
//   - updateLevel(address dev, uint8 newLevel) external onlyOwner
//   - verify(address dev) external onlyOwner
//   - getProfile(address dev) external view returns (DeveloperProfile memory)
//   - isRegistered(address dev) external view returns (bool)
// - Security: Apply CEI pattern, validate all inputs, no zero-address
```

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Tahap 1 SimpleStorage + Tahap 2 TypedRegistry dengan test dasar |
| 🟡 **Extended** — disarankan | Setiap custom error & event TypedRegistry dipicu oleh minimal satu test |
| 🔴 **Stretch** — untuk portfolio | Optimasi storage struct (packing) + bandingkan gas sebelum/sesudah dengan `forge snapshot --diff` |

### ✅ Kriteria Lulus (Core)

- [ ] `forge test` hijau di `lab/`
- [ ] Setiap custom error punya test `vm.expectRevert(Error.selector)` yang memicunya
- [ ] `register` dua kali dengan address sama → revert `AlreadyRegistered`
- [ ] Anda bisa menjelaskan layout storage struct `DeveloperProfile` menggunakan `forge inspect TypedRegistry storageLayout`


---

# 🏆 Challenge: Decentralized Voting Contract

> *Challenge tanpa tutorial. Gunakan semua konsep dari C1-C7.*

## Spesifikasi

```
CONTRACT: DecentralizedVoting

State:
  - Proposal: { id, description, voteCount, executed, deadline }
  - Mapping: voter → hasVoted[proposalId]
  - Array: proposals[]
  - Owner, quorum threshold

Functions:
  - createProposal(description, durationInSeconds) → proposalId (onlyOwner)
  - vote(proposalId) → must be before deadline, one vote per address
  - executeProposal(proposalId) → after deadline, only if quorum met, onlyOwner
  - getProposal(proposalId) → returns Proposal
  - hasVoted(address, proposalId) → bool

Events:
  - ProposalCreated(uint256 indexed id, string description, uint256 deadline)
  - VoteCast(uint256 indexed proposalId, address indexed voter)
  - ProposalExecuted(uint256 indexed proposalId)

Custom Errors:
  - ProposalNotFound
  - VotingEnded
  - AlreadyVoted
  - QuorumNotMet
  - AlreadyExecuted

Security Requirements:
  - Terapkan CEI pattern
  - Validasi semua input
  - Gunakan custom errors (bukan string)
  - Tidak ada reentrancy vulnerability
```

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Semua fungsi di spesifikasi + test happy path & revert |
| 🟡 **Extended** — disarankan | Test semua custom error & event, termasuk tepat di batas deadline |
| 🔴 **Stretch** — untuk portfolio | Bandingkan desain Anda dengan `VotingSystem` Phase 5 dan tulis 3 perbedaan di Notes |

### ✅ Kriteria Lulus (Core)

- [ ] `forge test` hijau dengan minimal 1 test per fungsi dan per custom error
- [ ] Vote dua kali dari address yang sama → revert `AlreadyVoted`
- [ ] Vote setelah deadline → revert `VotingEnded`; execute tanpa quorum → revert `QuorumNotMet`
- [ ] Tidak ada `require(..., "string")` — seluruh revert memakai custom error


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `Cannot run init on a non-empty directory` | `forge init .` di folder fase | Gunakan `forge init lab --no-git` |
| `Explicit type conversion not allowed from "uint256" to "address"` | Konversi langsung | `address(uint160(x))` |
| `Data location must be "storage", "memory" or "calldata"` | Parameter/variabel reference type tanpa lokasi | Tambahkan `memory`/`calldata`/`storage` sesuai C3 |
| `Stack too deep` | Terlalu banyak variabel lokal/parameter | Kelompokkan ke struct, pecah fungsi, atau aktifkan `via_ir = true` |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 04-solidity-fundamentals/

# Commit setup dan materi
git add .
git commit -m "learn: solidity fundamentals — types, data locations, functions, errors, events, inheritance"

# Commit mini project
git add .
git commit -m "feat: add SimpleStorage and TypedRegistry contracts (Phase 4 mini project)"

# Commit challenge
git add .
git commit -m "feat: implement DecentralizedVoting contract (Phase 4 challenge)"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Apa perbedaan antara `external` dan `public` dalam visibility Solidity? Kapan Anda sebaiknya memilih `external`?
2. Kenapa menggunakan `tx.origin` untuk otorisasi adalah vulnerability? Jelaskan attack scenario-nya.
3. Jelaskan perbedaan antara `require()`, `revert()`, dan `assert()` — kapan menggunakan masing-masing?
4. Mengapa `custom errors` lebih disukai daripada `revert("string message")` di Solidity ≥0.8.4?
5. Anda mendeklarasikan: `uint256 a; bool b; uint256 c;`. Berapa slot storage yang digunakan? Bagaimana mengoptimalkannya?
6. Apa perbedaan antara `Student memory s = _students[addr]` dan `Student storage s = _students[addr]`? Jelaskan konsekuensinya.
7. Mengapa `mapping` tidak bisa di-iterate secara native di Solidity? Bagaimana solusi praktisnya?
8. Jelaskan Checks-Effects-Interactions pattern dan mengapa ini penting untuk mencegah reentrancy.
9. Apa perbedaan `interface` dan `abstract contract` di Solidity? Kapan Anda menggunakan masing-masing?
10. Sebuah state variable dideklarasikan `uint256 private _secret = 42`. Benarkah nilainya "private" dan tidak bisa dibaca oleh orang lain? Jelaskan.

<details>
<summary>🔑 Kunci jawaban Knowledge Check — buka <b>setelah</b> Anda menjawab sendiri</summary>

> Jawaban ringkas sebagai acuan. Jika jawaban Anda berbeda tetapi alasannya benar, itu tetap benar — bandingkan alasannya, bukan kalimatnya.

1. `public` bisa dipanggil dari luar dan dari dalam contract; `external` hanya dari luar (dari dalam harus lewat `this.f()`, yang merupakan external call). Pilih `external` untuk fungsi yang memang bagian API eksternal dan tidak dipakai internal — menyatakan intent dengan jelas.
2. `tx.origin` adalah EOA yang memulai transaksi. Jika korban berinteraksi dengan contract jahat, contract itu bisa memanggil contract Anda dan lolos pengecekan `tx.origin == owner` → phishing. Gunakan `msg.sender`.
3. `require` — validasi input/kondisi dari luar. `revert` — sama tetapi untuk percabangan kompleks dan custom error. `assert` — invariant internal yang seharusnya mustahil gagal; jika gagal (Panic 0x01) berarti ada bug.
4. Lebih murah (4 byte selector + argumen, bukan string ABI-encoded; bytecode lebih kecil), bisa membawa parameter terstruktur, dan bisa di-decode frontend menjadi pesan yang jelas.
5. 3 slot: `a` slot 0, `b` slot 1 (bool sendirian), `c` slot 2. Mengubah urutan saja tidak membantu karena kedua `uint256` selalu memenuhi slot. Penghematan hanya mungkin jika salah satu variabel bisa memakai tipe lebih kecil, misal `uint128 a; bool b;` (di-pack) — asalkan rentang nilainya cukup.
6. `memory` membuat **salinan**: perubahan tidak tersimpan dan menyalin struct (termasuk array di dalamnya) memakan gas. `storage` adalah **referensi**: perubahan langsung menulis ke storage.
7. Key tidak disimpan dan semua key "ada" secara virtual dengan nilai default, sehingga tidak ada daftar/length. Solusi: simpan array key + mapping penanda, atau indeks off-chain lewat event.
8. Checks (validasi) → Effects (ubah state) → Interactions (external call terakhir). External call menyerahkan kontrol ke pihak lain yang bisa memanggil balik; jika state belum diperbarui, ia bisa mengeksploitasi state lama.
9. `interface`: hanya deklarasi fungsi external & event, tanpa state, constructor, atau implementasi — untuk berinteraksi dengan contract lain/standar. `abstract contract`: boleh punya state, constructor, dan fungsi yang sudah diimplementasikan — untuk logika dasar bersama yang diwarisi.
10. Tidak. `private` hanya mencegah contract lain mengaksesnya lewat Solidity. Nilainya tetap bisa dibaca siapa pun lewat `eth_getStorageAt` (di sini slot 0). Jangan menyimpan rahasia on-chain.

</details>

---

## 📊 Progress Tracker

- [ ] **Setup**: Foundry terinstall dan project di-init
- [ ] **C1**: Anatomy of a Contract — *SPDX, pragma, structure, global variables*
- [ ] **C2**: Value Types — *uint, int, address, bool, bytes, constant, immutable, enum*
- [ ] **C3**: Reference Types & Data Locations — *Array, Mapping, Struct, storage/memory/calldata*
- [ ] **C4**: Functions — *Visibility, mutability, modifiers, overloading, constructor patterns*
- [ ] **C5**: Error Handling — *require, revert, assert, custom errors, CEI pattern*
- [ ] **C6**: Events & Logging — *indexed/non-indexed, gas cost, frontend queries*
- [ ] **C7**: Inheritance, Interfaces, Libraries — *is, virtual/override, interface, using...for*
- [ ] **Exercise**: Soal 1–8
- [ ] **Mini Project**: SimpleStorage + TypedRegistry
- [ ] **Challenge**: DecentralizedVoting contract
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca (Solidity Official Docs)
- [Solidity Docs: Types](https://docs.soliditylang.org/en/latest/types.html)
- [Solidity Docs: Units and Global Variables](https://docs.soliditylang.org/en/latest/units-and-global-variables.html)
- [Solidity Docs: Expressions and Control Structures](https://docs.soliditylang.org/en/latest/control-structures.html)
- [Solidity Docs: Contracts](https://docs.soliditylang.org/en/latest/contracts.html)
- [Solidity Docs: Layout in Storage](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)

### Tools
- [Remix IDE](https://remix.ethereum.org/) — Browser-based IDE untuk Solidity (sangat bagus untuk eksperimen cepat)
- [Foundry Book](https://book.getfoundry.sh/) — Dokumentasi lengkap Foundry
- [Solidity by Example](https://solidity-by-example.org/) — Contoh kode per topik

### Security References
- [SWC Registry (Smart Contract Weakness Classification)](https://swcregistry.io/) — klasifikasi klasik, **tidak lagi diperbarui sejak 2020**; untuk temuan terkini gunakan [Solodit](https://solodit.xyz/)
- [Consensys Smart Contract Best Practices](https://consensysdiligence.github.io/smart-contract-best-practices/)

### Untuk Pemahaman Lebih Dalam
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — Baca source code-nya, ini adalah Solidity terbaik yang bisa Anda pelajari
- [Mastering Ethereum: Chapter 7 — Smart Contracts and Solidity](https://github.com/ethereumbook/ethereumbook/blob/490d19e42e0e5e06184b0298807472756c89cb81/src/chapter_7.md)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi selama belajar)*
