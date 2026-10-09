# 08 — Smart Contract Security

> **Level**: 4 — Adversarial Thinking
> **Phase**: 8 of 13
> **Estimated Time**: 🚀 Intensif 21–30 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 8–11 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [05-smart-contract-development](../05-smart-contract-development/README.md) ✅ | [07-smart-contract-testing](../07-smart-contract-testing/README.md) ✅
> **Status verifikasi**: **Reviewed (parsial)** · 9 Okt 2026 · LoyaltyRewards & contoh CoinFlip (exploit 5/5) diuji — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Berpikir seperti **attacker**: memetakan aset, aktor, trust boundary, dan attack surface sebuah protokol.
- Mengidentifikasi dan mengeksploitasi **vulnerability klasik**: reentrancy, access control, arithmetic, oracle manipulation, front-running, signature replay, dan DoS.
- Menulis **exploit Proof-of-Concept** di Foundry untuk setiap kelas bug.
- Menerapkan **mitigasi standar**: CEI, pull-over-push, least privilege, TWAP, nonce + domain separator.
- Menggunakan **static analysis** (Slither, Aderyn) dan memahami batasannya.
- Menulis **audit report** profesional dengan klasifikasi severity yang konsisten.

---

## 📋 Prerequisites

- [x] Mampu menulis unit, fuzz, dan invariant test (Phase 7).
- [x] Memahami ECDSA, `ecrecover`, EIP-191 & EIP-712 (Phase 3).
- [x] Memahami storage layout, `delegatecall`, dan gas (Phase 2).
- [x] Python 3 terinstall (untuk Slither).

---

## ⚖️ Etika & Batasan Hukum (WAJIB DIBACA)

Fase ini mengajarkan cara **menyerang** smart contract agar Anda mampu **mempertahankannya**. Aturan berikut tidak bisa ditawar:

- ✅ Jalankan exploit **hanya** di lingkungan yang Anda kendalikan: `forge test`, `anvil`, atau fork lokal (`--fork-url`). Fork adalah salinan lokal — transaksi di sana tidak menyentuh jaringan asli.
- ✅ Wargame (Ethernaut, Damn Vulnerable DeFi) dan contest audit (Code4rena, Sherlock, Cantina) adalah tempat legal untuk berlatih.
- ✅ Jika menemukan kerentanan di protokol nyata: laporkan secara **responsible disclosure** lewat program bug bounty (misal Immunefi) atau kontak keamanan resmi tim tersebut — jangan mengeksploitasinya, jangan mempublikasikannya sebelum diperbaiki.
- ❌ **Jangan** mengirim transaksi exploit ke mainnet/testnet milik pihak lain, meskipun "hanya untuk membuktikan". Di banyak yurisdiksi (termasuk UU ITE di Indonesia) mengakses atau memanipulasi sistem elektronik tanpa hak adalah tindak pidana, dan dana yang diambil tetap dianggap pencurian.
- ❌ Jangan menggunakan private key, wallet, atau dana milik orang lain dalam latihan apa pun.

> Seluruh contoh di fase ini memakai contract buatan sendiri dan akun default anvil yang publik.

---

## ⚙️ Setup

```bash
cd 08-smart-contract-security/
forge init lab --no-git
cd lab
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git

# Static analysis
python3 -m pip install slither-analyzer
# (pin: cargo install aderyn --version <x.y.z>) atau: curl -L https://raw.githubusercontent.com/Cyfrin/aderyn/dev/cyfrinup/install | bash
cargo install aderyn
```

> ⚠️ Kode fase ini ditempatkan di subfolder **`lab/`**. Jangan `forge init .` di folder fase — folder ini sudah berisi `README.md` materi, dan `forge init --force` akan **menimpanya**. Semua path `src/`, `test/`, `script/`, `audits/` di fase ini relatif terhadap `lab/`. `forge init` sudah memasang `forge-std`; hapus contoh `Counter*.sol` bawaan.

Struktur yang disarankan untuk exploit lab:

```text
08-smart-contract-security/lab/
├── src/vulnerable/      # contract rentan (satu file per kelas bug)
├── src/fixed/           # versi yang sudah dimitigasi
├── test/exploits/       # PoC: test yang MEMBUKTIKAN dana bisa dicuri
├── test/fixed/          # test yang membuktikan exploit gagal setelah fix
└── audits/              # laporan audit (markdown)
```

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Security Mindset & Threat Modeling](#c1-security-mindset--threat-modeling) | ⬜ |
| **C2** | [Reentrancy (Single, Cross-Function, Read-Only)](#c2-reentrancy-single-cross-function-read-only) | ⬜ |
| **C3** | [Access Control & `tx.origin`](#c3-access-control--txorigin) | ⬜ |
| **C4** | [Arithmetic, Precision Loss & Share Inflation](#c4-arithmetic-precision-loss--share-inflation) | ⬜ |
| **C5** | [Oracle Manipulation & Flash Loans](#c5-oracle-manipulation--flash-loans) | ⬜ |
| **C6** | [Front-Running, MEV & Signature Replay](#c6-front-running-mev--signature-replay) | ⬜ |
| **C7** | [Denial of Service & Unexpected Revert](#c7-denial-of-service--unexpected-revert) | ⬜ |
| **C8** | [Security Tooling & Audit Report](#c8-security-tooling--audit-report) | ⬜ |
| **C9** | [Insecure Randomness & Input Validation](#c9-insecure-randomness--input-validation) | ⬜ |

### Pemetaan ke OWASP Smart Contract Top 10

[OWASP Smart Contract Top 10](https://owasp.org/www-project-smart-contract-top-10/) adalah daftar risiko yang disusun dari insiden nyata. Gunakan tabel ini untuk memastikan cakupan belajar Anda.

| OWASP 2025 | Dibahas di |
|---|---|
| SC01 Access Control | C3 |
| SC02 Price Oracle Manipulation | C5 |
| SC03 Logic Errors | C1 (threat model), C8 (manual review), Challenge |
| SC04 Lack of Input Validation | C9 |
| SC05 Reentrancy | C2 |
| SC06 Unchecked External Calls | C7, C9 (+ `SafeERC20` di Phase 7 C5) |
| SC07 Flash Loan Attacks | C5 |
| SC08 Integer Overflow/Underflow | C4 |
| SC09 Insecure Randomness | C9 |
| SC10 Denial of Service | C7 |

> Per Oktober 2026, OWASP juga menerbitkan daftar **2026** yang bersifat *forward-looking* (masih membuka survei komunitas) di [scs.owasp.org](https://scs.owasp.org/sctop10/). Perubahan pentingnya: *Business Logic* naik ke SC02, *Arithmetic Errors (Rounding & Precision)* menjadi kategori sendiri (→ C4), dan *Proxy & Upgradeability* masuk SC10 (→ C3 & Phase 13 C1). Cek ulang edisi terbaru sebelum mengajarkan peringkatnya.

---

---

# C1: Security Mindset & Threat Modeling

## Mental Model: "Setiap Fungsi `external` adalah Pintu"

Di Web2, attacker harus menemukan celah di server yang tersembunyi. Di Web3:

- Source code (atau bytecode) **publik**.
- Siapa pun bisa memanggil fungsi `external`/`public` **dengan argumen apa pun**, **berkali-kali**, **dalam urutan apa pun**, **dari contract**.
- Attacker bisa meminjam **ratusan juta dolar** dalam satu transaksi (flash loan) tanpa modal.
- Attacker bisa **melihat transaksi Anda sebelum dieksekusi** (mempool) dan menyisipkan transaksi sebelum/sesudahnya.

## Threat Modeling dalam 4 Pertanyaan

```text
1. ASET      → Apa yang bisa dicuri / dikunci / dirusak?   (ETH, token, NFT, hak voting, data)
2. AKTOR     → Siapa saja yang berinteraksi?                (user, admin, keeper, oracle, contract lain)
3. TRUST     → Siapa dipercaya untuk apa?                   (admin bisa pause? oracle bisa salah?)
4. ENTRY     → Jalur apa yang mengubah state?               (setiap fungsi external + callback)
```

## Klasifikasi Severity (Standar Audit)

| Severity | Impact | Likelihood | Contoh |
|---|---|---|---|
| **Critical** | Dana user dicuri / dikunci permanen | Mudah dieksekusi | Reentrancy di `withdraw()` |
| **High** | Kerugian dana signifikan | Butuh kondisi tertentu | Oracle spot price bisa dimanipulasi |
| **Medium** | Fungsi rusak, kerugian terbatas | — | DoS pada fungsi non-kritis |
| **Low** | Best practice dilanggar, tanpa kerugian langsung | — | Event tidak di-emit |
| **Informational / Gas** | Kualitas kode | — | Variabel bisa `immutable` |

## Latihan C1: Threat Model

### Soal 1 — Peta Serangan Crowdfunding
Untuk `Crowdfunding.sol` (Phase 5), isi tabel berikut: **Aset**, **Aktor** (creator, donor, pihak luar), **Trust assumption**, dan **Entry point** (setiap fungsi). Untuk setiap entry point, tulis satu pertanyaan "bagaimana jika…?" yang akan diuji seorang attacker.

<details>
<summary>💡 Contoh Pembahasan (sebagian)</summary>

| Entry Point | "Bagaimana jika…?" |
|---|---|
| `donate()` | …donor adalah contract? …dipanggil tepat di `DEADLINE`? |
| `finalize()` | …tidak ada yang memanggil? …dipanggil bersamaan dengan donate di block yang sama? |
| `withdraw()` | …creator adalah contract yang `receive()`-nya me-reenter? |
| `refund()` | …donor me-reenter `refund()` sebelum `_donations` di-nol-kan? |

Trust assumption utama: creator tidak bisa mengambil dana sebelum goal tercapai — ini yang harus dibuktikan oleh test.

</details>

---

---

# C2: Reentrancy (Single, Cross-Function, Read-Only)

## Mekanisme Dasar

Saat contract mengirim ETH dengan `call`, **kontrol eksekusi pindah** ke penerima. Jika penerima adalah contract, fungsi `receive()`-nya bisa memanggil kembali contract asal **sebelum state diperbarui**.

```solidity
// ❌ VULNERABLE
function withdraw() external {
    uint256 amount = balances[msg.sender];
    (bool ok,) = msg.sender.call{value: amount}("");   // ← INTERACTION dulu
    require(ok);
    balances[msg.sender] = 0;                           // ← EFFECT terlambat
}
```

```text
Attacker.attack()
  └─▶ Bank.withdraw()                    balances[attacker] = 1 ETH
        └─▶ call{value: 1 ETH} ─▶ Attacker.receive()
                                     └─▶ Bank.withdraw()   balances MASIH 1 ETH!
                                           └─▶ call ─▶ Attacker.receive() ─▶ ... (loop sampai Bank kosong)
```

## Varian Reentrancy

| Varian | Deskripsi | Guard per fungsi cukup? |
|---|---|---|
| **Single-function** | Reenter fungsi yang sama | Ya |
| **Cross-function** | Reenter fungsi **lain** yang membaca state yang sama (misal `transfer()` saat `withdraw()` belum update balance) | Hanya jika guard dipasang di **semua** fungsi terkait |
| **Cross-contract** | Dua contract berbagi state/asumsi; reenter contract B saat A belum konsisten | Tidak — butuh desain CEI global |
| **Read-only** | Reenter fungsi **`view`** (misal `getPrice()`) yang dibaca protokol lain saat state sedang tidak konsisten | Tidak — `view` tidak terlindungi `nonReentrant` |
| **Via token hooks** | ERC-777 `tokensReceived`, ERC-721 `onERC721Received`, ERC-1155 hooks | Sama dengan ETH `call` |

## Mitigasi

1. **Checks-Effects-Interactions** — selalu perbarui state sebelum external call.
2. **Reentrancy guard** (`nonReentrant` / `ReentrancyGuardTransient` dengan transient storage EIP-1153).
3. **Pull over push** — user menarik dananya sendiri.
4. Untuk read-only reentrancy: protokol yang **membaca** state contract lain harus memeriksa lock contract tersebut (misal Curve/Balancer menyediakan fungsi pengecekan).

## Latihan C2: Reentrancy

### Soal 2 — Exploit PoC (Hands-On)
Tulis `src/vulnerable/EtherBank.sol` dengan pola `withdraw()` di atas dan `test/exploits/Reentrancy.t.sol` berisi contract `Attacker` yang menguras bank. Test harus membuktikan: saldo bank awal 10 ETH, attacker deposit 1 ETH, setelah serangan saldo bank 0. Kemudian tulis versi `src/fixed/` dan test yang membuktikan serangan gagal. *(Tidak ada pembahasan — ini latihan implementasi.)*

**✅ Selesai jika:**
- [ ] `test/exploits/Reentrancy.t.sol` hijau: saldo bank 0 setelah serangan, attacker menerima > deposit awalnya
- [ ] `test/fixed/` hijau: serangan yang sama revert dan saldo deposan lain utuh
- [ ] Trace `-vvvv` menunjukkan rekursi `receive()` → `withdraw()` pada versi rentan


### Soal 3 — Cross-Function
Contract berikut memasang `nonReentrant` di `withdraw()`. Apakah aman?

```solidity
function withdraw() external nonReentrant {
    uint256 amount = balances[msg.sender];
    (bool ok,) = msg.sender.call{value: amount}("");
    require(ok);
    balances[msg.sender] = 0;
}

function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

<details>
<summary>💡 Pembahasan</summary>

**Tidak aman.** Di dalam `receive()`, attacker tidak memanggil `withdraw()` lagi (yang terkunci), tetapi memanggil `transfer(accomplice, amount)`. Karena `balances[attacker]` belum di-nol-kan, transfer berhasil memindahkan saldo ke akun kedua. Setelah kembali, `withdraw()` meng-nol-kan saldo attacker — tetapi accomplice kini punya saldo yang sama dan bisa withdraw lagi. Hasil: saldo digandakan.

Fix: terapkan CEI (`balances[msg.sender] = 0` sebelum `call`) dan/atau pasang guard di **semua** fungsi yang menyentuh `balances`.

</details>

---

---

# C3: Access Control & `tx.origin`

## Pola Kegagalan Access Control

| Pola | Contoh |
|---|---|
| **Missing modifier** | `function setOwner(address) external` tanpa `onlyOwner` |
| **Unprotected initializer** | Proxy dengan `initialize()` yang bisa dipanggil siapa pun setelah deploy |
| **`tx.origin` untuk auth** | `require(tx.origin == owner)` |
| **Default visibility / salah visibility** | Fungsi internal helper tidak sengaja `public` |
| **Privilege terlalu besar** | Satu EOA admin bisa upgrade, mint, pause, dan menarik dana |
| **Role tidak bisa dicabut** | Tidak ada `revokeRole`, atau admin role tidak punya admin |

## `tx.origin` Phishing

```solidity
// ❌ Wallet milik korban
function transferTo(address payable to, uint256 amount) external {
    require(tx.origin == owner, "not owner");     // tx.origin = EOA yang MEMULAI transaksi
    to.transfer(amount);
}
```

```text
Korban (owner) ──tx──▶ MaliciousContract.claimAirdrop()
                         └─▶ Wallet.transferTo(attacker, ALL)
                               tx.origin == korban ✔  → dana terkirim ke attacker
```

`msg.sender` di sini adalah `MaliciousContract`, tetapi `tx.origin` tetap korban. **Gunakan `msg.sender` untuk otorisasi.**

## Unprotected Initializer (Pengantar Proxy)

```solidity
// ℹ️ Ilustrasi — butuh `import {Initializable} from
// "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";`
contract VaultV1 is Initializable {
    address public owner;
    function initialize(address _owner) external initializer {   // ✅ modifier initializer
        owner = _owner;
    }
}
// Risiko: jika deploy proxy & initialize dilakukan di DUA transaksi terpisah,
// attacker bisa front-run memanggil initialize() lebih dulu.
// Risiko lain: implementation contract sendiri tidak di-initialize →
// gunakan _disableInitializers() di constructor implementation.
```

## Least Privilege

```text
❌ owner: mint + pause + upgrade + withdrawFees + setOracle
✅ MINTER_ROLE   → contract staking saja
   PAUSER_ROLE   → multisig 2/3 (respons cepat)
   UPGRADER_ROLE → timelock 48 jam + multisig 3/5
   FEE_ROLE      → treasury
```

## Latihan C3

### Soal 4 — Audit Mini
Temukan semua masalah access control:

```solidity
contract Treasury {
    address public owner;
    mapping(address => bool) public isAdmin;

    constructor() { owner = msg.sender; }

    function addAdmin(address a) public { isAdmin[a] = true; }
    function withdraw(uint256 amt) external {
        require(isAdmin[msg.sender] || tx.origin == owner);
        payable(msg.sender).transfer(amt);
    }
    function _setOwner(address o) public { owner = o; }
}
```

<details>
<summary>💡 Pembahasan</summary>

1. **`addAdmin` tanpa access control** — siapa pun menjadikan dirinya admin lalu `withdraw` → **Critical**.
2. **`_setOwner` public** — prefix underscore menandakan internal, tetapi visibility-nya `public`; siapa pun bisa mengambil alih ownership → **Critical**.
3. **`tx.origin == owner`** — phishing: owner yang berinteraksi dengan contract jahat akan memberi akses withdraw ke contract tersebut → **High**.
4. Tidak ada event untuk perubahan admin/owner → **Low** (sulit dimonitor).
5. `transfer` dengan gas stipend 2300 bisa gagal untuk penerima contract (multisig) → **Low/Medium**.

</details>

---

---

# C4: Arithmetic, Precision Loss & Share Inflation

## Solidity ≥0.8: Overflow Tidak Lagi Diam-Diam

Sejak 0.8.0, overflow/underflow otomatis revert. Tetapi masih ada jebakan:

| Jebakan | Contoh |
|---|---|
| Blok `unchecked { }` | Optimasi gas yang salah membuka kembali overflow |
| **Downcasting** | `uint128(x)` memotong diam-diam jika `x > type(uint128).max` → gunakan `SafeCast` |
| **Pembagian sebelum perkalian** | `a / b * c` kehilangan presisi |
| **Pembulatan berpihak salah** | Protokol membulatkan ke arah user, bukan ke arah protokol |
| **Decimals berbeda** | USDC (6) vs DAI (18) dijumlahkan langsung |

## Precision Loss

```solidity
// ❌ fee = 0 untuk amount < 1000 → user bisa memecah transaksi untuk menghindari fee
uint256 fee = amount / 1000 * 3;

// ✅ kalikan dulu
uint256 fee = amount * 3 / 1000;
```

**Aturan pembulatan protokol**: saat menghitung apa yang user **terima** → bulatkan ke bawah; saat menghitung apa yang user **bayar/hutang** → bulatkan ke atas. Kesalahan arah pembulatan yang kecil bisa diulang ribuan kali (atau dengan flash loan) hingga menjadi kerugian besar.

## First Depositor / Share Inflation Attack

Vault berbasis shares (`shares = assets × totalShares / totalAssets`) rentan saat masih kosong:

```text
1. Attacker deposit 1 wei            → mendapat 1 share. totalAssets = 1.
2. Attacker DONASI langsung 10_000e18 token ke vault (transfer, bukan deposit)
                                      → totalAssets = 10_000e18 + 1, totalShares = 1.
3. Korban deposit 19_999e18:
     shares = 19_999e18 × 1 / (10_000e18 + 1) = 1   (dibulatkan ke bawah!)
4. Attacker & korban masing-masing punya 1 share dari ~30_000e18.
   Attacker withdraw → mendapat ~15_000e18. Untung ~5_000e18 dari korban.
```

Mitigasi: **virtual shares/offset** (ERC-4626 OpenZeppelin `_decimalsOffset`), dead shares (mint shares awal ke `address(0)`), atau deposit awal oleh deployer.

## Latihan C4

### Soal 5 — Hitung Kerugian
Dengan skenario inflation di atas, berapa minimum donasi attacker agar korban yang deposit `D` token menerima **0 shares**? Nyatakan dalam `D`. Kemudian tuliskan bagaimana `_decimalsOffset = 3` mengubah biaya serangan.

<details>
<summary>💡 Pembahasan</summary>

Korban menerima `D × 1 / (1 + donasi)`. Hasilnya 0 jika `D < 1 + donasi`, jadi **donasi ≥ D** (lebih tepatnya `donasi > D - 1`). Attacker harus "membakar" modal sebesar deposit korban — tetapi modal itu tidak hilang karena attacker memegang satu-satunya share lain.

Dengan offset 3, vault seolah memiliki `10³` shares virtual. Korban menerima `D × (1 + 10³) / (1 + donasi + 1)`; agar menjadi 0, donasi harus sekitar `1000 × D`, dan sebagian besar donasi itu "dimiliki" oleh shares virtual — sehingga attacker justru merugi. Serangan menjadi tidak ekonomis.

</details>

---

---

# C5: Oracle Manipulation & Flash Loans

## Flash Loan: Modal Tanpa Batas Selama Satu Transaksi

```text
Satu transaksi:
  1. Pinjam 100M USDC dari Aave/Balancer (tanpa collateral)
  2. Lakukan apa pun (swap, deposit, manipulasi harga)
  3. Kembalikan 100M + fee
  → Jika langkah 3 gagal, SELURUH transaksi revert seolah tidak pernah terjadi.
```

Flash loan bukan bug. Flash loan **membuat setiap asumsi "attacker tidak punya modal besar" menjadi salah**.

## Spot Price Oracle = Bisa Dimanipulasi

```solidity
// ❌ Harga dari reserve AMM saat ini
function getPrice() public view returns (uint256) {
    (uint112 r0, uint112 r1,) = pair.getReserves();
    return uint256(r1) * 1e18 / r0;
}
```

```text
1. Flash loan token A dalam jumlah besar
2. Swap A → B di pool → reserve berubah drastis → getPrice() melonjak
3. Gunakan harga palsu: borrow sebanyak-banyaknya dengan collateral yang "nilainya" naik
4. Swap balik, kembalikan flash loan, simpan hasil pinjaman
```

## Mitigasi Oracle

| Pendekatan | Kelebihan | Catatan |
|---|---|---|
| **Chainlink Price Feed** | Agregasi off-chain dari banyak sumber | Cek `updatedAt` (staleness), `answer > 0`, sequencer uptime di L2 |
| **TWAP (Uniswap V3)** | On-chain, sulit dimanipulasi dalam 1 block | Window pendek tetap bisa dimanipulasi dengan modal besar |
| **Multiple sources + deviation check** | Defense in depth | Lebih kompleks |

## Latihan C5

### Soal 6 — Validasi Chainlink
Daftar semua validasi yang seharusnya dilakukan saat membaca `latestRoundData()`. Untuk masing-masing, jelaskan apa yang terjadi jika validasi itu tidak ada.

<details>
<summary>💡 Pembahasan</summary>

```solidity
(uint80 roundId, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
```
1. `answer > 0` — harga 0/negatif bisa membuat collateral bernilai 0 (likuidasi massal) atau pembagian dengan nol.
2. `block.timestamp - updatedAt <= HEARTBEAT` — harga **stale** saat feed berhenti update (volatilitas tinggi, gangguan jaringan) → protokol memakai harga lama.
3. Gunakan `feed.decimals()` — jangan asumsikan 8 atau 18.
4. Di L2: cek **Sequencer Uptime Feed** dan grace period — saat sequencer down lalu kembali, harga bisa melompat dan user tidak sempat menambah collateral.
5. (Opsional) batas min/max harga yang masuk akal — mitigasi kasus circuit breaker (misal LUNA, `minAnswer`).

</details>

---

---

# C6: Front-Running, MEV & Signature Replay

## Mempool adalah Ruang Publik

```text
User kirim tx: swap 100 ETH → USDC, slippage 5%
    │
    ▼ (mempool publik)
Searcher melihat tx →  [Front-run: beli USDC]  [Tx User: harga lebih buruk]  [Back-run: jual USDC]
                         = SANDWICH ATTACK, profit searcher = kerugian user (hingga batas slippage)
```

| Serangan | Target | Mitigasi |
|---|---|---|
| **Sandwich** | Swap dengan slippage longgar | `amountOutMin` ketat, private mempool (Flashbots Protect) |
| **Front-running** | Commit jawaban, klaim hadiah, `approve` race | **Commit-reveal**, batch auction |
| **Back-running** | Likuidasi, arbitrase setelah update oracle | Biasanya *benign*, tapi perhatikan desain insentif |
| **Deadline hilang** | Tx tertahan lama lalu dieksekusi di harga buruk | Parameter `deadline` di setiap swap |

## Signature Replay

Signature off-chain (EIP-712, permit, meta-transaction) bisa **digunakan ulang** jika tidak terikat ke konteks unik.

```solidity
// ❌ VULNERABLE
function claim(uint256 amount, bytes calldata sig) external {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount));
    require(ECDSA.recover(hash, sig) == signer);
    token.transfer(msg.sender, amount);       // bisa dipanggil berulang kali dengan sig yang sama!
}
```

Signature harus terikat ke:

| Elemen | Mencegah |
|---|---|
| **Nonce** per user (dan di-increment) | Replay di contract yang sama |
| **`chainId`** (domain separator) | Replay di chain lain (fork, L2) |
| **`address(this)`** (verifyingContract) | Replay di contract lain dengan kode sama |
| **Deadline** | Signature lama digunakan jauh di masa depan |

## Signature Malleability

Untuk setiap signature ECDSA valid `(r, s, v)`, ada pasangan `(r, n - s, v')` yang juga valid. Jika contract memakai **hash dari signature** sebagai ID "sudah dipakai", attacker bisa membuat signature kedua yang berbeda byte-nya. Mitigasi: gunakan `ECDSA.recover` OpenZeppelin (menolak `s` di upper half) dan **lacak nonce, bukan signature**.

## `abi.encodePacked` Collision

```solidity
keccak256(abi.encodePacked("aa", "bb")) == keccak256(abi.encodePacked("a", "abb"))  // TRUE!
```

Dua tipe dinamis berurutan di `encodePacked` bisa bertabrakan. Gunakan `abi.encode` untuk hashing data yang akan diverifikasi.

## Latihan C6

### Soal 7 — Perbaiki `claim()`
Tulis ulang `claim()` di atas agar aman dari replay lintas-transaksi, lintas-chain, dan lintas-contract menggunakan EIP-712. Tulis test yang membuktikan: (a) signature yang sama gagal di panggilan kedua, (b) signature dari chainId lain gagal (gunakan `vm.chainId()`). *(Latihan implementasi — tanpa pembahasan.)*

**✅ Selesai jika:**
- [ ] Test (a) dan (b) hijau
- [ ] Tambahan: signature dengan deadline lewat revert, signer palsu revert
- [ ] Hash dibangun dengan EIP-712 (`_hashTypedDataV4` / domain separator) dan `abi.encode`, bukan `encodePacked`


---

---

# C7: Denial of Service & Unexpected Revert

## Pola DoS

| Pola | Contoh | Mitigasi |
|---|---|---|
| **Unbounded loop** | Loop atas array yang terus tumbuh → melebihi block gas limit | Pagination, pull pattern |
| **Push payment ke penerima jahat** | Auction mengembalikan ETH ke bidder sebelumnya; bidder contract yang selalu revert → tidak ada yang bisa bid lagi | Pull pattern (`withdrawRefund()`) |
| **Dependensi pada external call** | Fungsi gagal jika satu token di list mem-blacklist contract | Isolasi kegagalan, `try/catch` |
| **Griefing via `selfdestruct`/forced ETH** | `require(address(this).balance == expected)` | Internal accounting |
| **Block stuffing** | Mengisi block agar tx lain tidak masuk sebelum deadline | Deadline yang tidak terlalu ketat |
| **Return bomb** | Callee mengembalikan data sangat besar → caller kehabisan gas saat copy returndata | Batasi returndata (assembly `call` tanpa copy) |

## Contoh: King of the Ether

```solidity
// ❌ Siapa pun yang menjadi king lewat contract tanpa receive() akan menjadi raja selamanya
function claimThrone() external payable {
    require(msg.value > price);
    payable(king).transfer(price);    // revert jika king adalah contract yang menolak ETH
    king  = msg.sender;
    price = msg.value;
}
```

## Latihan C7

### Soal 8 — Identifikasi DoS
Buka kembali `VotingSystem.sol`, `Crowdfunding.sol`, dan `NFTCollection.sol` dari Phase 5. Apakah ada jalur yang bisa di-DoS oleh satu user jahat? Untuk setiap temuan, tulis skenario serangan dan severity-nya di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Setiap contract Phase 5 dinilai (ada / tidak ada jalur DoS) dengan alasan
- [ ] Setiap DoS yang ditemukan dibuktikan dengan test PoC, atau dijelaskan mengapa hanya teoretis


---

---

# C8: Security Tooling & Audit Report

## Static Analysis

```bash
slither .                                   # semua detector
slither . --print human-summary             # ringkasan
slither . --exclude-dependencies --filter-paths "lib|test"
aderyn .                                    # menghasilkan report.md
```

| Tool | Kekuatan | Kelemahan |
|---|---|---|
| **Slither** | Cepat, >90 detector, printer (call graph, inheritance) | Banyak false positive; tidak paham logika bisnis |
| **Aderyn** | Output markdown siap pakai | Detector lebih sedikit |
| **Fuzzing/Invariant** (Phase 7) | Menemukan bug logika | Butuh properti yang tepat |
| **Manual review** | Satu-satunya yang paham *intent* | Lambat, butuh pengalaman |

> Tools menemukan **pola**. Auditor menemukan **pelanggaran intent**. Mayoritas exploit besar adalah bug logika bisnis yang tidak terdeteksi tool mana pun.

## Alur Kerja Audit

```text
1. Scoping       → commit hash, file in-scope, nSLOC, dokumentasi, asumsi trust
2. Recon         → baca docs & test, pahami intent, buat threat model (C1)
3. Tooling       → slither/aderyn, triage false positive
4. Manual review → baris per baris, fokus pada aliran dana & state transition
5. PoC           → setiap temuan High/Critical WAJIB punya test exploit
6. Report        → temuan + severity + rekomendasi
7. Fix review    → verifikasi perbaikan tidak memperkenalkan bug baru
```

## Template Temuan

```markdown
### [H-01] Reentrancy di `Bank.withdraw()` memungkinkan pengurasan seluruh saldo

**Severity**: High  (Impact: High, Likelihood: High)
**Lokasi**: `src/Bank.sol#L42-L48`

**Deskripsi**
`withdraw()` mengirim ETH sebelum meng-nol-kan `balances[msg.sender]`...

**Impact**
Attacker dapat menguras seluruh ETH milik semua depositor.

**Proof of Concept**
`test/exploits/Reentrancy.t.sol::test_DrainBank` — (ringkas langkah atau tempel kode)

**Rekomendasi**
Terapkan CEI ... / tambahkan `nonReentrant` ...
```

## Latihan C8

### Soal 9 — Triage Slither
Jalankan `slither .` di project Phase 5. Untuk setiap temuan, klasifikasikan sebagai **True Positive**, **False Positive**, atau **Acknowledged (by design)** dan berikan alasan satu kalimat. Simpan sebagai `audits/slither-triage-phase5.md`.

**✅ Selesai jika:**
- [ ] Setiap temuan Slither diberi status TP / FP / Acknowledged + alasan satu kalimat
- [ ] Minimal satu False Positive dijelaskan secara teknis (mengapa tool keliru)


### Soal 10 — Severity Calibration
Tentukan severity untuk tiga temuan berikut dan jelaskan alasannya: (a) `owner` bisa menarik semua dana user kapan saja (dan ini terdokumentasi), (b) event `Withdrawn` di-emit dengan argumen yang salah, (c) fungsi `claim()` bisa di-DoS hanya oleh owner.

<details>
<summary>💡 Pembahasan</summary>

- **(a)** Umumnya dilaporkan sebagai **Medium/centralization risk** atau *acknowledged*. Bukan bug teknis, tetapi risiko trust — auditor wajib menuliskannya agar user sadar. Jika **tidak** terdokumentasi dan bertentangan dengan klaim "non-custodial", bisa High.
- **(b)** **Low** — tidak ada kerugian dana langsung, tetapi indexer/frontend/akuntansi off-chain menjadi salah. Bisa naik jika ada sistem off-chain kritis yang bergantung pada event tersebut.
- **(c)** Biasanya **Low/Informational** — aktor yang dipercaya (owner) memang sudah punya kekuasaan lebih besar. Severity naik jika user tidak punya jalur lain untuk mengklaim dana.

</details>

---

---

# C9: Insecure Randomness & Input Validation

## Tidak Ada Angka Acak "Gratis" di Blockchain

Semua node harus mendapatkan hasil eksekusi yang **sama persis** (Phase 2 C1). Karena itu tidak ada sumber acak rahasia di dalam EVM. Nilai yang sering disalahgunakan sebagai "acak":

| Sumber | Masalah |
|---|---|
| `block.timestamp`, `block.number` | Bisa dibaca siapa pun; contract lain di transaksi yang sama mendapat nilai identik |
| `block.prevrandao` | Diketahui sebelum transaksi dieksekusi dan bisa dibaca contract penyerang di tx yang sama; proposer punya sedikit pengaruh |
| `blockhash(block.number - 1)` | Sudah publik saat transaksi Anda dieksekusi |
| `keccak256(...)` dari nilai di atas | Hash dari input yang bisa ditebak tetap bisa ditebak |

```solidity
/// ❌ VULNERABLE: "acak" dari data block yang bisa dibaca contract lain di tx yang sama
contract CoinFlip {
    error WrongValue();

    function play(bool guess) external payable {
        if (msg.value != 0.1 ether) revert WrongValue();
        bool result = uint256(keccak256(abi.encode(block.prevrandao, block.timestamp, msg.sender))) % 2 == 0;
        if (guess == result) {
            (bool ok,) = msg.sender.call{value: 0.2 ether}("");
            require(ok);
        }
    }

    receive() external payable {}
}

/// Attacker menghitung "hasil acak" yang SAMA di dalam transaksi yang sama
contract CoinFlipAttacker {
    CoinFlip public immutable target;

    constructor(CoinFlip _target) {
        target = _target;
    }

    function attack() external payable {
        bool predicted = uint256(keccak256(abi.encode(block.prevrandao, block.timestamp, address(this)))) % 2 == 0;
        target.play{value: 0.1 ether}(predicted);
    }

    receive() external payable {}
}
```

Kuncinya: `CoinFlipAttacker.attack()` menghitung rumus yang sama **di dalam transaksi yang sama**, jadi tebakannya selalu benar. Test `vm.prevrandao` + `vm.warp` membuktikan attacker menang 5 dari 5 kali.

## Mitigasi

| Pendekatan | Cara Kerja | Catatan |
|---|---|---|
| **Chainlink VRF** | Angka acak + bukti kriptografis dari oracle, dikirim di transaksi **terpisah** (callback) | Butuh biaya & langganan; hasil tidak bisa dimanipulasi oracle karena ada proof |
| **Commit-reveal** | Peserta commit `hash(nilai, salt)` dulu, reveal setelah semua commit (Phase 3 Challenge) | Peserta terakhir bisa memilih tidak reveal → perlu deposit/penalti |
| **Pisahkan aksi & penentuan hasil** | User "mendaftar" di tx 1, hasil ditentukan di tx berikutnya dengan sumber acak yang belum diketahui saat tx 1 | Tetap butuh sumber acak yang baik |

## Input Validation (OWASP SC04)

Banyak exploit besar terjadi bukan karena logika rumit, tetapi karena **parameter tidak divalidasi**:

```solidity
// ❌ Tanpa validasi
// 10_000+ bps = 100%+ fee
function setFee(uint256 newFeeBps) external onlyOwner { feeBps = newFeeBps; }
function withdrawTo(address to, uint256 amount) external { /* to bisa address(0) */ }
// pool palsu buatan attacker
function swap(address pool, ...) external { IPool(pool).swap(...); }

// ✅ Dengan validasi
error FeeTooHigh(uint256 fee, uint256 max);
error ZeroAddress();
error UnknownPool(address pool);

function setFee(uint256 newFeeBps) external onlyOwner {
    if (newFeeBps > MAX_FEE_BPS) revert FeeTooHigh(newFeeBps, MAX_FEE_BPS);
    feeBps = newFeeBps;
}
```

Checklist validasi:
- **Batas numerik**: min/max, tidak nol jika nol tidak bermakna, `deadline >= block.timestamp`.
- **Address**: bukan `address(0)`; jika harus contract terpercaya → whitelist / registry, jangan menerima address sembarang dari user.
- **Array**: panjang array yang berpasangan sama (`recipients.length == amounts.length`); batasi panjang (Phase 8 C7).
- **Data dari luar**: return value external call (SC06), harga oracle (C5), signature (C6).

## Latihan C9

### Soal 11 — Exploit Randomness (Hands-On)
Salin `CoinFlip` & `CoinFlipAttacker` ke `src/vulnerable/`, buat test exploit, lalu buat versi `src/fixed/` dengan **commit-reveal** (pemain commit `keccak256(abi.encode(guess, salt, msg.sender))`, reveal minimal 1 block kemudian, hasil diambil dari `blockhash` block **setelah** commit).

**✅ Selesai jika:**
- [ ] Test exploit menang 5/5 terhadap versi rentan (bandingkan dengan contoh di atas)
- [ ] Attacker yang sama **tidak lagi** bisa menang dengan pasti terhadap versi fix (uji minimal 20 putaran dengan `vm.prevrandao` berbeda — tingkat menang mendekati 50%)
- [ ] Reveal di block yang sama dengan commit → revert
- [ ] Penjelasan di Notes: mengapa `blockhash` hanya tersedia untuk 256 block terakhir, dan apa akibatnya jika pemain tidak reveal tepat waktu

### Soal 12 — Audit Validasi Input
Tinjau fungsi publik di `TokenStaking` dan `Crowdfunding` (Phase 5). Daftar setiap parameter, validasi yang sudah ada, dan validasi yang hilang.

**✅ Selesai jika:**
- [ ] Tabel `Fungsi | Parameter | Validasi ada | Validasi hilang | Severity` mencakup semua fungsi external
- [ ] Minimal satu validasi yang hilang dibuktikan dengan test yang menunjukkan perilaku tak diinginkan

---

---

> ⚖️ **Pengingat**: semua exploit di lab ini dijalankan **hanya** sebagai test Foundry / di anvil atau fork lokal. Lihat bagian **⚖️ Etika & Batasan Hukum** di awal fase ini.

# 📝 Mini Project: Exploit Lab

Bangun "lab" berisi minimal **8 contract rentan** (satu per kelas bug C2–C7 & C9), masing-masing dengan exploit PoC dan versi fix.

| # | Kelas Bug | Vulnerable | Exploit Test | Fixed + Test |
|---|---|---|---|---|
| 1 | Reentrancy (single) | `EtherBank.sol` | ⬜ | ⬜ |
| 2 | Reentrancy (cross-function) | `SharedBank.sol` | ⬜ | ⬜ |
| 3 | `tx.origin` phishing | `PhishableWallet.sol` | ⬜ | ⬜ |
| 4 | Share inflation | `NaiveVault.sol` | ⬜ | ⬜ |
| 5 | Spot price oracle | `SpotLending.sol` + mock AMM | ⬜ | ⬜ |
| 6 | Signature replay | `AirdropClaim.sol` | ⬜ | ⬜ |
| 7 | DoS push payment | `KingOfEther.sol` | ⬜ | ⬜ |
| 8 | Insecure randomness | `CoinFlip.sol` | ⬜ | ⬜ |

Setiap folder bug dilengkapi `README.md` singkat: **Root cause → Exploit steps → Fix → Referensi exploit nyata**.

**Latihan tambahan (wargame)** — kerjakan dan tulis writeup per level:
- [Ethernaut](https://ethernaut.openzeppelin.com/) level 1–20
- [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/) challenge 1–6

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Bug #1 (reentrancy), #3 (`tx.origin`), #6 (signature replay) + Ethernaut level 1–10 |
| 🟡 **Extended** — disarankan | Kedelapan bug + Damn Vulnerable DeFi 1–3 |
| 🔴 **Stretch** — untuk portfolio | Ethernaut 11–20, DVD 4–6, reproduksi 1 exploit nyata dari DeFiHackLabs |

### ✅ Kriteria Lulus (Core)

- [ ] Untuk setiap bug Core: test exploit **hijau** (membuktikan dana bisa dicuri) pada versi `vulnerable/`
- [ ] Test yang sama **gagal mencuri** (revert / saldo utuh) pada versi `fixed/`
- [ ] Setiap folder bug punya README: root cause → langkah exploit → fix
- [ ] Writeup singkat untuk setiap level Ethernaut yang diselesaikan


---

# 🏆 Challenge: Audit Contract Sungguhan

> *Challenge tanpa tutorial. Bertindaklah sebagai auditor independen.*

## Target

Contract `LoyaltyRewards` di bawah mengandung **minimal 6 issue** dengan severity berbeda.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IPriceSource { function getReserves() external view returns (uint112, uint112, uint32); }
interface IERC20 { function transfer(address, uint256) external returns (bool); }

contract LoyaltyRewards {
    address public owner;
    address public signer;
    IERC20  public rewardToken;
    IPriceSource public pool;

    mapping(address => uint256) public points;
    mapping(bytes32 => bool) public usedSig;
    address[] public members;

    constructor(address _signer, IERC20 _token, IPriceSource _pool) {
        owner = tx.origin;
        signer = _signer;
        rewardToken = _token;
        pool = _pool;
    }

    function join() external { members.push(msg.sender); }

    function earn(uint256 amount, bytes calldata sig) external {
        bytes32 h = keccak256(abi.encodePacked(msg.sender, amount));
        require(!usedSig[keccak256(sig)], "used");
        require(ECDSA.recover(h, sig) == signer, "bad sig");
        usedSig[keccak256(sig)] = true;
        points[msg.sender] += amount;
    }

    function rate() public view returns (uint256) {
        (uint112 a, uint112 b,) = pool.getReserves();
        return uint256(b) / uint256(a) * 1e18;
    }

    function redeem(uint256 pts) external {
        uint256 out = pts * rate() / 1e18;
        rewardToken.transfer(msg.sender, out);
        points[msg.sender] -= pts;
    }

    function airdropAll(uint256 pts) external {
        require(msg.sender == owner);
        for (uint256 i; i < members.length; i++) points[members[i]] += pts;
    }

    function setSigner(address s) external { signer = s; }
}
```

## Tugas Challenge

1. Buat **threat model** (aset, aktor, trust, entry point).
2. Jalankan Slither & Aderyn, lakukan triage.
3. Temukan semua issue secara manual; klasifikasikan severity (Critical → Informational).
4. Tulis **PoC Foundry** untuk setiap temuan High/Critical.
5. Tulis `audits/LoyaltyRewards-audit.md` menggunakan template C8, lengkap dengan executive summary dan tabel ringkasan temuan.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Threat model + minimal 4 temuan dengan severity + PoC untuk 2 temuan High/Critical |
| 🟡 **Extended** — disarankan | Minimal 6 temuan + laporan lengkap (executive summary & tabel ringkasan) |
| 🔴 **Stretch** — untuk portfolio | Bandingkan dengan review orang lain (peer review) dan kalibrasi severity Anda |

### ✅ Kriteria Lulus (Core)

- [ ] Setiap temuan Core memiliki: lokasi baris, deskripsi, impact, rekomendasi
- [ ] PoC Foundry untuk 2 temuan tertinggi lulus
- [ ] Triage Slither: setiap temuan tool diberi status TP / FP / Acknowledged
- [ ] Laporan memakai template Phase 8 C8


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Exploit tidak menguras contract | `receive()` attacker tidak memanggil ulang, atau `transfer` (2300 gas) dipakai korban | Log di `receive()`, cek trace `-vvvv` untuk melihat urutan call |
| `slither: command not found` / error versi solc | Slither belum terpasang atau solc tidak cocok | `python3 -m pip install slither-analyzer` lalu `solc-select install 0.8.24 && solc-select use 0.8.24` |
| Tidak yakin severity sebuah temuan | Belum memisahkan impact & likelihood | Pakai matriks severity di C1 dan contoh kalibrasi di Soal 10 |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 08-smart-contract-security/   # path di bawah relatif ke folder fase; kode ada di lab/

git add .
git commit -m "learn: smart contract security — threat modeling, classic vulnerabilities, tooling"

git add src/vulnerable/ test/exploits/
git commit -m "security: add exploit lab with 7 vulnerable contracts and PoCs"

git add src/fixed/ test/fixed/
git commit -m "fix: add mitigated versions and regression tests for exploit lab"

git add audits/
git commit -m "security: add LoyaltyRewards audit report (Phase 8 challenge)"
```

---

## 🧠 Knowledge Check (12 Pertanyaan)

1. Jelaskan Checks-Effects-Interactions dan mengapa `nonReentrant` saja tidak selalu cukup.
2. Apa itu read-only reentrancy? Mengapa guard pada fungsi state-changing tidak melindunginya?
3. Mengapa `tx.origin` tidak boleh dipakai untuk otorisasi? Adakah penggunaan `tx.origin` yang sah?
4. Apa risiko proxy yang `initialize()`-nya dipanggil di transaksi terpisah dari deployment?
5. Mengapa urutan perkalian dan pembagian penting di Solidity? Ke arah mana protokol seharusnya membulatkan?
6. Jelaskan first-depositor/share inflation attack dan dua mitigasinya.
7. Mengapa flash loan membuat spot price oracle berbahaya? Apa alternatifnya?
8. Sebutkan empat validasi yang wajib saat membaca Chainlink price feed.
9. Elemen apa saja yang harus terikat ke sebuah signature agar aman dari replay?
10. Mengapa melacak "signature yang sudah dipakai" (hash dari bytes signature) berbahaya?
11. Berikan dua contoh DoS yang disebabkan oleh push payment atau unbounded loop.
12. Apa batasan static analysis tools dibanding manual review? Kelas bug apa yang paling sering terlewat?

<details>
<summary>🔑 Kunci jawaban Knowledge Check — buka <b>setelah</b> Anda menjawab sendiri</summary>

> Jawaban ringkas sebagai acuan. Jika jawaban Anda berbeda tetapi alasannya benar, itu tetap benar — bandingkan alasannya, bukan kalimatnya.

1. CEI memperbarui state sebelum external call. `nonReentrant` hanya melindungi fungsi yang memakainya; reentrancy lintas fungsi, lintas contract, atau read-only bisa melewatinya. Gunakan keduanya.
2. Contract lain memanggil fungsi `view` milik contract A ketika A sedang di tengah eksekusi dengan state tidak konsisten (saat external call). `view` tidak diberi guard, sehingga pembaca mendapat nilai yang salah (misal harga LP).
3. Contract perantara yang dipanggil korban akan lolos pengecekan `tx.origin`. Penggunaan yang sah sangat jarang; `tx.origin == msg.sender` pernah dipakai untuk memastikan pemanggil adalah EOA, tetapi rapuh dan rusak oleh account abstraction/EIP-7702.
4. Attacker bisa front-run memanggil `initialize()` lebih dulu dan menjadi owner. Mitigasi: deploy & initialize dalam satu transaksi (data init di constructor proxy), dan `_disableInitializers()` di implementation.
5. Pembagian integer membulatkan ke bawah, jadi membagi dulu membuang presisi. Bulatkan berpihak ke protokol: ke bawah untuk yang dibayarkan ke user, ke atas untuk yang harus dibayar user.
6. Attacker deposit 1 wei, lalu "mendonasikan" token langsung agar harga per share sangat tinggi, sehingga deposit korban dibulatkan menjadi 0–1 share dan attacker mengambil bagiannya. Mitigasi: virtual shares/decimals offset (OZ ERC-4626), dead shares, atau deposit awal oleh deployer.
7. Flash loan memberi modal sangat besar sementara untuk menggeser reserve AMM di transaksi yang sama, sehingga harga spot yang dibaca di transaksi itu palsu. Alternatif: Chainlink, TWAP, atau beberapa sumber dengan cek deviasi.
8. `answer > 0`; tidak stale (`block.timestamp - updatedAt` ≤ heartbeat); pakai `decimals()` feed; di L2 cek Sequencer Uptime Feed + grace period. (Tambahan: batas kewajaran harga.)
9. Nonce, chainId, address contract (verifying contract), deadline, serta parameter aksi yang dimaksud (penerima/jumlah) — idealnya lewat domain separator EIP-712.
10. Signature ECDSA *malleable*: (r, n − s) juga valid untuk pesan yang sama, sehingga signature "baru" lolos pengecekan bytes. Lacak hash pesan/nonce, bukan bytes signature, dan gunakan library yang menolak `s` tinggi.
11. (1) Mengembalikan ETH ke "raja" sebelumnya dengan push; contract yang selalu revert membuat tidak ada yang bisa menggantikannya. (2) Loop pembagian reward/airdrop atas array yang terus bertambah hingga melebihi block gas limit.
12. Tool mendeteksi pola, tetapi tidak memahami intent, logika bisnis, atau asumsi ekonomi; banyak false positive. Yang paling sering terlewat: logic errors, manipulasi ekonomi/oracle, dan desain access control yang keliru.

</details>

---

## 📊 Progress Tracker

- [ ] **Setup**: Foundry project, OpenZeppelin, Slither & Aderyn terinstall
- [ ] **C1**: Security Mindset — *threat modeling, severity matrix*
- [ ] **C2**: Reentrancy — *single, cross-function, cross-contract, read-only, token hooks*
- [ ] **C3**: Access Control — *missing modifier, tx.origin, initializer, least privilege*
- [ ] **C4**: Arithmetic — *downcast, precision loss, rounding direction, share inflation*
- [ ] **C5**: Oracle & Flash Loan — *spot price, TWAP, Chainlink validation*
- [ ] **C6**: Front-Running & Signatures — *sandwich, commit-reveal, replay, malleability*
- [ ] **C7**: DoS — *unbounded loop, push payment, forced ETH, return bomb*
- [ ] **C8**: Tooling & Report — *Slither, Aderyn, audit workflow, template temuan*
- [ ] **C9**: Randomness & Input Validation — *prevrandao, VRF, commit-reveal, checklist validasi*
- [ ] **Exercise**: Soal 1–12
- [ ] **Mini Project**: Exploit Lab (8 bug + PoC + fix)
- [ ] **Wargame**: Ethernaut 1–20, Damn Vulnerable DeFi 1–6
- [ ] **Challenge**: Audit LoyaltyRewards + report
- [ ] **Knowledge Check**: 12 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [SWC Registry](https://swcregistry.io/) — klasifikasi dasar; **tidak diperbarui sejak 2020**, lengkapi dengan Solodit di bawah
- [Consensys — Smart Contract Best Practices: Attacks](https://consensysdiligence.github.io/smart-contract-best-practices/attacks/)
- [Solidity Docs — Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [EIP-712: Typed Structured Data Hashing and Signing](https://eips.ethereum.org/EIPS/eip-712)

### Belajar dari Exploit Nyata
- [Rekt News](https://rekt.news/) — post-mortem exploit DeFi
- [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs) — reproduksi exploit nyata dalam Foundry
- [Solodit](https://solodit.xyz/) — database temuan audit dari berbagai firma

### Standar Klasifikasi Risiko
- [OWASP Smart Contract Top 10 (2025)](https://owasp.org/www-project-smart-contract-top-10/) · [edisi 2026](https://scs.owasp.org/sctop10/)
- [Chainlink VRF](https://docs.chain.link/vrf)

### Wargame & Kompetisi
- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)
- [Code4rena](https://code4rena.com/) · [Sherlock](https://www.sherlock.xyz/) · [Cantina](https://cantina.xyz/) — contest audit

### Tools
- [Slither](https://github.com/crytic/slither) · [Aderyn](https://github.com/Cyfrin/aderyn)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — `ReentrancyGuard`, `AccessControl`, `SafeERC20`, `ECDSA`, `EIP712`

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk temuan DoS dari Soal 8)*
