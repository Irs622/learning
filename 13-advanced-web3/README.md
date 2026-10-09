# 13 — Advanced Web3

> **Level**: 5 — Protocol & Security Engineer
> **Phase**: 13 of 13
> **Estimated Time**: 🚀 Intensif 30+ hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 11+ minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [08-smart-contract-security](../08-smart-contract-security/README.md) ✅ | [11-tokenomics-and-defi](../11-tokenomics-and-defi/README.md) ✅ | [12-layer-2](../12-layer-2/README.md) ✅

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Merancang dan mengaudit **upgradeable contract** (Transparent, UUPS, Beacon) beserta risiko storage collision.
- Mengamankan protokol dengan **multisig (Safe)** dan **timelock** sebagai infrastruktur institusional.
- Membangun **DAO governance** on-chain (OpenZeppelin Governor + ERC20Votes + Timelock) dan mengenali serangan governance.
- Memahami dan mengimplementasikan **Account Abstraction**: ERC-4337 (UserOperation, EntryPoint, Bundler, Paymaster) dan EIP-7702.
- Menganalisis **MEV** secara mendalam: supply chain (searcher → builder → proposer), PBS, MEV-Boost, dan perlindungan user.
- Menggunakan **Zero-Knowledge proof** di level aplikasi (Circom/Noir → verifier Solidity) untuk membership & privasi.
- Menyusun **jalur karier** sebagai Web3 Security / Smart Contract Engineer setelah roadmap selesai.

---

## 📋 Prerequisites

- [x] Exploit lab & audit report (Phase 8).
- [x] Invariant testing (Phase 7) dan DeFi primitives (Phase 11).
- [x] Cross-chain messaging & perbedaan L2 (Phase 12).
- [x] `delegatecall` & storage layout (Phase 2), EIP-712 (Phase 3 & 9).

---

## ⚙️ Setup

```bash
cd 13-advanced-web3/
forge init lab --no-git
cd lab
forge install OpenZeppelin/openzeppelin-contracts --no-git
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-git
forge install OpenZeppelin/openzeppelin-foundry-upgrades --no-git   # validasi storage layout saat upgrade
forge install eth-infinitism/account-abstraction@v0.9.0 --no-git    # ERC-4337 reference (pin versi!)

# ZK tooling (pilih salah satu)
# Noir:   curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && noirup
# Circom: lihat https://docs.circom.io/getting-started/installation/
```

> ⚠️ Kode fase ini ditempatkan di subfolder **`lab/`**. Jangan `forge init .` di folder fase — folder ini sudah berisi `README.md` materi, dan `forge init --force` akan **menimpanya**. Semua path `src/`, `test/`, `script/`, `audits/` di fase ini relatif terhadap `lab/`. `forge init` sudah memasang `forge-std`; hapus contoh `Counter*.sol` bawaan.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Proxy & Upgradeability](#c1-proxy--upgradeability) | ⬜ |
| **C2** | [Multisig (Safe) & Timelock](#c2-multisig-safe--timelock) | ⬜ |
| **C3** | [DAO Governance On-Chain](#c3-dao-governance-on-chain) | ⬜ |
| **C4** | [Account Abstraction: ERC-4337 & EIP-7702](#c4-account-abstraction-erc-4337--eip-7702) | ⬜ |
| **C5** | [MEV Deep Dive](#c5-mev-deep-dive) | ⬜ |
| **C6** | [Zero-Knowledge untuk Developer Aplikasi](#c6-zero-knowledge-untuk-developer-aplikasi) | ⬜ |
| **C7** | [Jalur Karier Web3 Security](#c7-jalur-karier-web3-security) | ⬜ |

---

---

# C1: Proxy & Upgradeability

## Mental Model: Alamat Tetap, Otak Bisa Diganti

```text
User ──call──▶ Proxy (storage + ETH, alamat permanen)
                  │ delegatecall (kode milik implementation, STORAGE milik proxy)
                  ▼
             Implementation V1  ──upgrade──▶  Implementation V2
```

`delegatecall` menjalankan kode contract lain **dalam konteks storage pemanggil**. Itulah yang memungkinkan upgrade — dan juga sumber hampir semua bug proxy.

## Pola Proxy

| Pola | Logic upgrade ada di | Kelebihan | Risiko |
|---|---|---|---|
| **Transparent** | Proxy (via ProxyAdmin) | Admin & user terpisah jelas | Lebih mahal gas per call |
| **UUPS** (ERC-1822) | Implementation (`upgradeToAndCall`) | Lebih murah, upgrade bisa dihapus permanen | Upgrade ke implementation tanpa fungsi upgrade → **terkunci selamanya** |
| **Beacon** | Beacon contract | Upgrade banyak proxy sekaligus | Satu titik kegagalan |
| **Diamond** (EIP-2535) | Banyak facet | Melewati batas ukuran contract | Kompleks, sulit diaudit |

## EIP-1967: Slot Storage Standar

```text
implementation slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
                    = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
admin slot          = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
```

Slot "acak" ini mencegah tabrakan dengan variabel implementation di slot 0, 1, 2, …

```bash
cast storage <PROXY> 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

## Bug Klasik Upgradeability

| Bug | Penjelasan |
|---|---|
| **Storage collision antar versi** | V2 menyisipkan variabel baru **di tengah** atau mengubah urutan/tipe → semua data bergeser |
| **Constructor tidak berjalan** | Constructor implementation tidak mengisi storage proxy → gunakan `initialize()` |
| **Uninitialized implementation** | Attacker memanggil `initialize()` di implementation langsung lalu (di UUPS lama, OpenZeppelin < 4.3.2, sebelum EIP-6780) `upgradeToAndCall` ke contract berisi `selfdestruct` → implementation hancur → **semua proxy rusak**. Kini `selfdestruct` tidak lagi menghapus kode, tetapi implementation yang tidak di-initialize tetap bisa diambil alih. Fix: `_disableInitializers()` di constructor |
| **Front-run initialize** | Deploy proxy dan initialize di tx terpisah (Phase 8 C3) |
| **Function selector clash** | Fungsi admin proxy dan fungsi implementation punya selector sama (Transparent pattern mengatasinya) |
| **`immutable` di implementation** | Nilainya tertanam di bytecode implementation, bukan storage proxy — kadang memang diinginkan, kadang jebakan |

```solidity
// ✅ ERC-7201 namespaced storage (OpenZeppelin v5): hindari collision dengan struct di slot terhitung
/// @custom:storage-location erc7201:myproject.vault
struct VaultStorage { uint256 totalAssets; mapping(address => uint256) shares; }
```

## Latihan C1

### Soal 1 — Storage Layout
V1 dan V2 berikut di-deploy di belakang proxy yang sama. Apa yang terjadi pada data setelah upgrade?

```solidity
contract VaultV1 { address public owner; uint256 public totalAssets; mapping(address => uint256) public shares; }
contract VaultV2 { address public owner; bool public paused; uint256 public totalAssets; mapping(address => uint256) public shares; }
```

<details>
<summary>💡 Pembahasan</summary>

Layout V1: slot 0 = `owner` (20 byte), slot 1 = `totalAssets`, slot 2 = seed `shares`.
Layout V2: `owner` (20 byte) dan `paused` (1 byte) **dipacking ke slot 0**, `totalAssets` tetap slot 1, `shares` tetap slot 2.

Kebetulan di kasus ini data **tidak bergeser** karena `bool` muat di sisa slot 0 — tetapi `paused` akan membaca byte ke-21 slot 0 yang sebelumnya kosong (0 = false), jadi aman. Jika yang disisipkan adalah `uint256 fee` di posisi yang sama, `totalAssets` V2 akan membaca slot 2 (seed mapping, bernilai 0) dan `fee` membaca `totalAssets` lama → **korupsi data**.

Pelajaran: jangan mengandalkan kebetulan packing. Selalu **tambahkan variabel di akhir**, gunakan storage gap atau ERC-7201, dan validasi otomatis dengan `openzeppelin-foundry-upgrades` (`Upgrades.validateUpgrade`) atau `forge inspect <Contract> storageLayout`.

</details>

### Soal 2 — UUPS Brick (Hands-On)
Buat proxy UUPS dengan V1, lalu "upgrade" ke V2 yang **tidak** mewarisi `UUPSUpgradeable`. Tulis test yang membuktikan proxy kini tidak bisa di-upgrade lagi. Lalu tunjukkan bagaimana `openzeppelin-foundry-upgrades` mendeteksi masalah ini sebelum deploy.

**✅ Selesai jika:**
- [ ] Test membuktikan `upgradeToAndCall` gagal setelah upgrade ke V2
- [ ] Validasi `openzeppelin-foundry-upgrades` menolak V2 **sebelum** deploy


---

---

# C2: Multisig (Safe) & Timelock

## Mengapa Satu EOA Admin adalah Red Flag

Satu private key = satu titik kegagalan: phishing, malware, kehilangan device, atau orang dalam. Banyak exploit terbesar berasal dari **key compromise**, bukan bug Solidity.

## Safe (Multisig)

```text
Safe 3-of-5:
  5 owner (sebaiknya: orang berbeda, device berbeda, hardware wallet)
  Tx dieksekusi jika ≥3 owner menandatangani (signature EIP-712 dikumpulkan off-chain)

  Owner A ─sign─┐
  Owner C ─sign─┼─▶ execTransaction(to, value, data, ..., signatures) ─▶ target
  Owner E ─sign─┘
```

Fitur lanjutan: **Modules** (logika tambahan yang bisa mengeksekusi tanpa threshold — risiko besar jika salah konfigurasi), **Guards** (validasi sebelum/sesudah tx), dan dukungan ERC-4337.

> ⚠️ Multisig tidak melindungi dari **blind signing**: jika semua penandatangan menyetujui tx yang isinya tidak mereka verifikasi (UI di-compromise), threshold tidak berarti apa-apa. Verifikasi calldata & hash tx secara independen sebelum menandatangani.

## Timelock

```text
Admin/Governor ──schedule(op, delay=48h)──▶ TimelockController
                                                │ (op terlihat publik selama 48 jam)
                                                ▼
                          setelah delay ──execute(op)──▶ Protocol
```

Timelock memberi waktu bagi user untuk **melihat perubahan yang akan datang dan keluar** jika tidak setuju. Kombinasi umum: `Safe (proposer) → Timelock (48h) → Protocol`, plus `Guardian (canceller)` untuk membatalkan operasi berbahaya.

## Latihan C2

### Soal 3 — Desain Admin
Protokol lending Anda (Phase 11 Challenge) memiliki fungsi admin: `setOracle`, `setLTV`, `pause`, `upgradeTo`, `withdrawReserves`. Rancang struktur role: siapa memegang apa (EOA/Safe/Timelock/Governor), threshold multisig, dan delay timelock untuk tiap fungsi. Jelaskan mengapa `pause` diperlakukan berbeda dari `upgradeTo`.

<details>
<summary>💡 Contoh Pembahasan</summary>

| Fungsi | Pemegang | Alasan |
|---|---|---|
| `pause` | Safe guardian 2-of-5, **tanpa delay** | Respons darurat harus cepat; dampak pause terbatas (dana tidak berpindah) |
| `unpause` | Timelock 24h | Mencegah guardian "membuka kembali" protokol yang belum aman |
| `setLTV`, `setOracle` | Governor → Timelock 48h | Mengubah risiko user; user perlu waktu keluar |
| `upgradeTo` | Governor → Timelock 7 hari | Mengubah seluruh logika; delay terpanjang |
| `withdrawReserves` | Governor → Timelock 48h, ke treasury Safe | Dana protokol, bukan dana user |

`pause` **mengurangi** kemampuan (fail-safe), sedangkan `upgradeTo` bisa **menambah** kemampuan apa pun (termasuk mencuri dana). Prinsip: kekuasaan yang bisa merugikan user harus lambat dan transparan; kekuasaan yang hanya menghentikan boleh cepat.

</details>

---

---

# C3: DAO Governance On-Chain

## Arsitektur OpenZeppelin Governor

```text
ERC20Votes (token)  ──voting power (checkpoint per block/timestamp)──▶  Governor
                                                                          │
   propose ─▶ votingDelay ─▶ votingPeriod (For/Against/Abstain) ─▶ quorum? ─▶ queue
                                                                          │
                                                                          ▼
                                                          TimelockController (delay)
                                                                          │
                                                                          ▼
                                                                       execute ─▶ target contracts
```

| Komponen | Fungsi |
|---|---|
| **ERC20Votes** | Mencatat voting power historis (checkpoint). **Token harus di-delegate** (termasuk ke diri sendiri) agar voting power aktif |
| **Snapshot** | Voting power diambil di titik waktu proposal dibuat (+ delay) → beli/pinjam token setelahnya tidak berpengaruh |
| **Quorum** | Minimum partisipasi (misal 4% supply) |
| **Proposal threshold** | Minimum token untuk membuat proposal (anti-spam) |
| **Timelock** | Pemegang sebenarnya dari aset/role protokol; Governor hanya proposer |

Bandingkan dengan `VotingSystem` Phase 5 (1 address = 1 suara, owner mengeksekusi) dan Soal 2 Phase 5 tentang Sybil.

## Serangan Governance

| Serangan | Mekanisme | Mitigasi |
|---|---|---|
| **Flash loan voting** | Pinjam token, vote, kembalikan dalam 1 tx | Snapshot voting power **sebelum** voting dimulai |
| **Vote buying / bribery** | Pasar suap (dark DAO) | Sulit; delegasi ke delegate bereputasi, desain insentif |
| **Low quorum takeover** | Partisipasi rendah → whale meloloskan proposal saat sepi | Quorum memadai, timelock, guardian veto |
| **Malicious proposal** | Calldata yang tampak wajar tetapi berbahaya (contoh historis: Tornado Cash governance 2023 — CREATE2 + `selfdestruct` mengganti kode target; sejak EIP-6780 pola *metamorphic contract* ini hanya mungkin dalam transaksi pembuatan yang sama) | Simulasi proposal (Tenderly), review calldata, timelock |
| **Governance token di DEX dangkal** | Membeli mayoritas murah | Distribusi luas, likuiditas memadai |

Off-chain voting (**Snapshot**) gratis bagi voter tetapi hasilnya harus dieksekusi oleh multisig — trust pada eksekutor.

## Latihan C3

### Soal 4 — Snapshot Voting Power
Mengapa `ERC20Votes` memakai checkpoint historis alih-alih langsung membaca `balanceOf` saat vote? Gambarkan serangan yang mungkin jika Governor memakai `balanceOf` saat ini.

<details>
<summary>💡 Pembahasan</summary>

Jika voting power = `balanceOf` saat `castVote`, satu token bisa dipakai berkali-kali: Alice vote, transfer token ke Bob, Bob vote, transfer ke Carol… (double voting). Dan attacker bisa **flash loan** jutaan token, vote, lalu mengembalikannya dalam transaksi yang sama.

Checkpoint menyimpan `(timepoint, votes)` setiap kali balance/delegasi berubah, sehingga Governor membaca `getPastVotes(account, proposalSnapshot)` — voting power **di masa lalu** yang tidak bisa diubah lagi. Token yang dipindahkan atau dipinjam setelah snapshot tidak menambah suara.

</details>

---

---

# C4: Account Abstraction: ERC-4337 & EIP-7702

## Masalah EOA

```text
EOA = private key tunggal
  ✗ Kehilangan seed phrase = kehilangan semua aset
  ✗ Harus punya ETH untuk gas
  ✗ Satu aksi = satu tx (approve + swap = 2 tx)
  ✗ Tidak ada batas pengeluaran, recovery, atau 2FA
```

**Smart account** = wallet berupa contract dengan logika validasi sendiri: multisig, passkey (WebAuthn/P-256), social recovery, session key, batching, gas dibayar pihak lain.

## ERC-4337: AA Tanpa Mengubah Protokol

```text
User ─UserOperation─▶ Alt-mempool ─▶ Bundler ─handleOps([ops])─▶ EntryPoint (singleton)
                                                                     │
                                         1. Validation phase:        │
                                            - deploy account (initCode/factory) jika belum ada
                                            - account.validateUserOp() → cek signature, nonce
                                            - paymaster.validatePaymasterUserOp() (opsional)
                                         2. Execution phase:
                                            - account.execute(callData)
                                            - paymaster.postOp() (opsional)
                                         3. Refund gas ke bundler (dari deposit account/paymaster)
```

| Komponen | Peran |
|---|---|
| **UserOperation** | "Niat" user: `sender`, `nonce`, `callData`, batas gas, fee, `paymasterAndData`, `signature` (v0.7: `PackedUserOperation`) |
| **EntryPoint** | Contract singleton terpercaya yang menjalankan validasi & eksekusi (lihat tabel versi di bawah) |
| **Bundler** | Node off-chain yang mengumpulkan UserOp dan mengirim tx `handleOps` (dibayar ulang oleh EntryPoint) |
| **Paymaster** | Mensponsori gas (gasless) atau menerima pembayaran dalam ERC-20 |
| **Factory** | Men-deploy account via CREATE2 → address bisa diketahui sebelum deploy (counterfactual) |

### Versi EntryPoint

| Versi | Address (sama di semua chain, via CREATE2) | Catatan |
|---|---|---|
| v0.7 (Feb 2024) | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` | Memperkenalkan `PackedUserOperation` |
| v0.8 (Mar 2025) | `0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108` | Dukungan native EIP-7702; UserOp hash berbasis EIP-712 |
| v0.9 (Nov 2025) | `0x433709009B8330FDa32311DF1C2AFA402eD8D009` | ABI-compatible dengan v0.7/v0.8; `paymasterSignature`, validity range berbasis block number, `getCurrentUserOpHash()` |

> ⚠️ EntryPoint adalah contract singleton berprivilege tinggi. **Selalu verifikasi address & code hash** terhadap [rilis resmi eth-infinitism](https://github.com/eth-infinitism/account-abstraction/releases) sebelum memakainya — jangan menyalin address dari tutorial (termasuk tabel ini) tanpa cek ulang. Pin versi library saat install: `forge install eth-infinitism/account-abstraction@v0.9.0 --no-git`.
>
> Catatan v0.9: `initCode` kini **diabaikan tanpa revert** jika account sudah ada. Account yang berasumsi "initCode ≠ kosong berarti UserOp pertama" menjadi tidak aman.

```solidity
// Kerangka smart account minimal
function validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 missingAccountFunds
) external returns (uint256 validationData) {
    require(msg.sender == address(entryPoint), "only EntryPoint");
    // TODO (latihan): verifikasi signature owner atas userOpHash
    //                 → return 0 (valid) atau SIG_VALIDATION_FAILED (1)
    // TODO (latihan): bayar missingAccountFunds ke EntryPoint
}
```

## Aturan Validasi (ERC-7562)

Fase validasi **dibatasi**: tidak boleh memakai opcode yang hasilnya bisa berubah antara simulasi bundler dan eksekusi (`TIMESTAMP`, `BLOCKHASH`, `GASPRICE`, dsb.) dan hanya boleh mengakses storage yang terkait dengan account. Tanpa aturan ini, bundler bisa dibuat membayar gas untuk UserOp yang lolos simulasi tetapi gagal on-chain (DoS terhadap bundler).

## EIP-7702: EOA yang Bisa Menjadi Smart Account (Pectra, 2025)

Tx tipe baru (`0x04`) berisi *authorization list*: EOA menandatangani izin untuk **menetapkan kode delegasi** ke sebuah contract implementation. Setelah itu, address EOA berperilaku seperti smart account (batching, sponsor gas, session key) **tanpa memindahkan aset ke address baru**.

| | ERC-4337 | EIP-7702 |
|---|---|---|
| Address | Address baru (contract) | Address EOA yang sudah ada |
| Private key lama | Bisa diganti (tergantung desain) | **Tetap berkuasa penuh** atas EOA |
| Perubahan protokol | Tidak | Ya (hard fork) |
| Bisa digabung | — | Ya, EOA 7702 bisa memakai infrastruktur 4337 |

> ⚠️ Risiko 7702: menandatangani authorization ke implementation jahat = menyerahkan kendali penuh atas EOA. Phishing "upgrade your wallet" menjadi vektor baru. Implementation juga harus aman terhadap re-inisialisasi & storage collision (C1).

## Latihan C4

### Soal 5 — Paymaster yang Bisa Dikuras
Sebuah paymaster mensponsori **semua** UserOp tanpa syarat. Bagaimana attacker menguras deposit paymaster? Usulkan tiga pembatasan.

<details>
<summary>💡 Pembahasan</summary>

Attacker mengirim banyak UserOp dengan `callGasLimit`/`verificationGasLimit` maksimum yang melakukan pekerjaan tidak berguna (atau sengaja revert di fase eksekusi — gas tetap dibayar paymaster). Deposit paymaster di EntryPoint habis.

Pembatasan:
1. **Verifying paymaster**: hanya sponsor UserOp yang ditandatangani backend (setelah cek user/rate limit) — signature disertakan di `paymasterAndData` dengan `validUntil`.
2. **Whitelist target & selector**: hanya sponsor panggilan ke contract/fungsi milik aplikasi.
3. **Batas gas & kuota** per account per periode; tolak `maxFeePerGas`/gas limit yang tidak wajar.
Bonus: ERC-20 paymaster yang memungut token dari user di `postOp` (dengan oracle harga yang aman).

</details>

### Soal 6 — Smart Account (Hands-On)
Menggunakan library `eth-infinitism/account-abstraction`, implementasikan `SimpleAccount` versi Anda dengan fitur **batch execute**. Tulis test Foundry yang memanggil `EntryPoint.handleOps` langsung (tanpa bundler) untuk: deploy via factory, transfer ETH, dan batch `approve + stake` ke TokenStaking Phase 5.

**✅ Selesai jika:**
- [ ] `handleOps` berhasil untuk: deploy via factory, transfer ETH, batch `approve + stake`
- [ ] UserOp dengan signature salah ditolak
- [ ] Address counterfactual (sebelum deploy) sama dengan address setelah deploy


---

---

# C5: MEV Deep Dive

## Dari Phase 8 ke Gambaran Utuh

Phase 8 C6 membahas MEV dari sisi korban (sandwich, front-run). Di sini: **siapa yang menangkap nilai itu dan bagaimana sistemnya disusun**.

## MEV Supply Chain (Ethereum PoS dengan MEV-Boost)

```text
User tx ─▶ Public mempool ─┐
User tx ─▶ Private RPC ────┤
                           ▼
                     SEARCHERS  (bot: arbitrase, likuidasi, sandwich)
                           │ bundle (urutan tx + bayaran)
                           ▼
                     BUILDERS   (menyusun block paling menguntungkan)
                           │ block + bid
                           ▼
                     RELAYS     (perantara tepercaya, menyembunyikan isi block sampai ditandatangani)
                           │
                           ▼
                     PROPOSER   (validator memilih bid tertinggi via MEV-Boost)
```

**PBS (Proposer-Builder Separation)**: validator tidak perlu canggih untuk mendapatkan MEV; builder bersaing. Saat ini PBS berjalan off-protocol lewat MEV-Boost; *enshrined PBS* masih dalam riset.

## Jenis MEV

| Jenis | Dampak pada Ekosistem |
|---|---|
| **Arbitrase DEX** | Menyamakan harga antar pool (berguna, tetapi mengekstraksi nilai dari LP — LVR, Phase 11) |
| **Likuidasi** | Menjaga solvabilitas lending (berguna) |
| **Sandwich** | Merugikan user langsung (buruk) |
| **JIT liquidity** | LP menyisipkan likuiditas tepat sebelum swap besar lalu menariknya |
| **Cross-domain MEV** | Arbitrase antar L1/L2 — sequencer L2 memegang kekuatan urutan |

## Melindungi User & Protokol

- **Private orderflow**: Flashbots Protect, MEV Blocker — tx tidak masuk mempool publik, sebagian MEV dikembalikan ke user (*MEV refund*).
- **Desain protokol**: batch auction (CoW Protocol), intent-based trading (UniswapX), commit-reveal, slippage & deadline ketat.
- **Order flow auction (OFA)**: user "menjual" hak back-run atas tx-nya.

## Latihan C5

### Soal 7 — Investigasi MEV
Cari satu transaksi sandwich nyata menggunakan explorer MEV (misal EigenPhi atau libMEV). Identifikasi tiga tx (front-run, korban, back-run), hitung kerugian korban dan profit searcher, lalu periksa slippage tolerance yang dipakai korban. Tulis di **🗒️ Notes**. *(Tanpa pembahasan — investigasi sendiri.)*

**✅ Selesai jika:**
- [ ] Tiga tx teridentifikasi dengan link explorer
- [ ] Perhitungan kerugian korban & profit searcher disertai rumus
- [ ] Rekomendasi slippage yang seharusnya dipakai korban


---

---

# C6: Zero-Knowledge untuk Developer Aplikasi

## Dari Rollup ke Aplikasi

Phase 12 membahas ZK untuk scaling. Di level aplikasi, ZK dipakai untuk **membuktikan sesuatu tanpa membuka datanya**:

| Use Case | "Saya membuktikan bahwa…" | Tanpa membuka… |
|---|---|---|
| Anonymous membership | …saya ada di allowlist (Merkle tree) | …address mana saya |
| Private voting | …saya memilih sekali dan sah | …pilihan & identitas saya |
| Proof of age / KYC | …umur saya ≥ 18 | …tanggal lahir |
| Mixer / privacy pool | …saya pernah deposit | …deposit yang mana |

## Alur Pengembangan

```text
1. Tulis CIRCUIT (Circom / Noir)        → batasan (constraints) yang harus dipenuhi
2. Compile + setup                      → proving key & verification key
3. Generate VERIFIER contract Solidity  → verify(proof, publicInputs) → bool
4. Off-chain: user membuat PROOF dari private input (di browser/backend)
5. On-chain: contract memanggil verifier + logika aplikasi
```

```text
// Noir — contoh sederhana: buktikan tahu preimage dari hash tanpa membukanya
fn main(secret: Field, hash: pub Field) {
    assert(std::hash::pedersen_hash([secret]) == hash);
}
```

## Nullifier: Mencegah Double-Use Secara Anonim

```text
nullifier = hash(secret, scope)
  - Dipublikasikan saat proof digunakan
  - Contract menyimpan nullifier yang sudah dipakai → tidak bisa claim/vote dua kali
  - Tidak bisa dihubungkan ke identitas (karena secret tidak terbuka)
```

## Bug Khas ZK

| Bug | Dampak |
|---|---|
| **Under-constrained circuit** | Nilai yang "dihitung" tapi tidak di-*constrain* → attacker membuat proof palsu yang valid |
| **Public input tidak diverifikasi di contract** | Proof valid untuk data yang berbeda dari yang dimaksud |
| **Nullifier tidak terikat ke scope/chain** | Replay lintas aplikasi atau chain (mirip Phase 8 C6) |
| **Trusted setup bocor** (Groth16) | Proof palsu bisa dibuat |

## Latihan C6

### Soal 8 — Allowlist Anonim (Hands-On)
Buat circuit (Noir atau Circom) yang membuktikan "saya memegang secret yang commitment-nya ada di Merkle tree dengan root R", dengan public input `root` dan `nullifier`. Generate verifier Solidity, lalu buat contract `AnonymousClaim` yang mengizinkan setiap anggota claim 1× tanpa mengungkap identitasnya. Uji juga kasus double-claim dan root palsu.

**✅ Selesai jika:**
- [ ] Anggota sah bisa claim; identitasnya tidak muncul di calldata (hanya nullifier & proof)
- [ ] Double-claim dan root palsu revert
- [ ] Proof dengan public input yang dimanipulasi ditolak verifier


---

---

# C7: Jalur Karier Web3 Security

## Peta Peran

| Peran | Fokus | Bukti Kemampuan |
|---|---|---|
| **Smart Contract Engineer** | Membangun protokol | Repo dengan test & invariant berkualitas, deployment nyata |
| **Security Researcher / Auditor** | Menemukan bug | Temuan di audit contest, laporan audit publik |
| **Bug Bounty Hunter** | Bug di kode live | Payout di Immunefi/Cantina |
| **Protocol Security Engineer** | Keamanan internal tim | Threat model, monitoring, incident response |

## Rencana Lanjutan Setelah Roadmap

```text
Bulan 1–2:  Ikut 2–3 audit contest (Code4rena/Sherlock/Cantina) — fokus pada kualitas, bukan jumlah
            Baca seluruh laporan juri & temuan peserta lain setelah contest selesai
Bulan 3–4:  Reproduksi 10 exploit nyata dari DeFiHackLabs + tulis writeup
            Publikasikan 1 artikel teknis per bulan
Bulan 5–6:  Spesialisasi (pilih satu): lending, AMM, bridge/L2, AA, ZK circuits
            Mulai bug bounty pada protokol di spesialisasi tersebut
Berkelanjutan: Solodit, Rekt, laporan audit firma ternama, EIP baru
```

## Portfolio Checklist (Master README L1–L10)

| Level | Project | Lokasi di Repo | Status |
|:---:|---|---|:---:|
| L1 | Simple Storage DApp | `05-…/src/SimpleStorage.sol` + `09-…/dapp` | ⬜ |
| L2 | Decentralized Voting | `05-…/src/VotingSystem.sol` | ⬜ |
| L3 | Crowdfunding Protocol | `05-…/src/Crowdfunding.sol` | ⬜ |
| L4 | ERC-20 Token Suite | `05-…/src/ERC20Token.sol` | ⬜ |
| L5 | NFT Marketplace | Kembangkan dari `05-…/src/NFTCollection.sol` (escrow, order, EIP-2981) | ⬜ |
| L6 | DAO | Mini Project Phase 13 | ⬜ |
| L7 | Mini DEX | Mini Project Phase 11 | ⬜ |
| L8 | Lending Protocol | Challenge Phase 11 | ⬜ |
| L9 | Real-Time Indexer | Mini Project Phase 10 | ⬜ |
| L10 | Security & Exploit Lab | Mini Project + Challenge Phase 8 | ⬜ |

## Latihan C7

### Soal 9 — Self-Assessment
Untuk setiap fase 1–13, beri nilai pemahaman Anda 1–5 dan tulis satu topik yang perlu diulang. Pilih spesialisasi untuk 6 bulan ke depan dan tulis alasannya di **📝 What I Learned**.

**✅ Selesai jika:**
- [ ] 13 nilai + satu topik ulang per fase tertulis
- [ ] Rencana 6 bulan dengan satu spesialisasi dan alasannya


---

---

# 📝 Mini Project: Full-Stack DAO (Portfolio L6)

## Spesifikasi

```text
CONTRACTS:
  - GovToken        : ERC20 + ERC20Votes + ERC20Permit (clock mode: timestamp)
  - MyGovernor      : Governor + GovernorSettings + GovernorCountingSimple
                      + GovernorVotes + GovernorVotesQuorumFraction (4%)
                      + GovernorTimelockControl
  - Timelock        : TimelockController (min delay 1 hari di testnet)
  - Treasury / Box  : contract yang dimiliki Timelock (target proposal)

ROLE:
  - Proposer Timelock : Governor
  - Executor          : siapa pun (address(0))
  - Canceller         : Safe guardian 2-of-3
  - Admin Timelock    : dicabut setelah setup (renounce)

UPGRADE:
  - Treasury memakai UUPS; upgrade hanya lewat proposal governance
```

## Deliverable

- [ ] Test end-to-end: delegate → propose → vote → queue → warp → execute.
- [ ] Test serangan: flash-loan voting gagal, proposal tanpa quorum gagal, eksekusi sebelum delay gagal.
- [ ] Validasi storage layout upgrade dengan `openzeppelin-foundry-upgrades`.
- [ ] Deploy ke L2 testnet (Phase 12) dan buat satu proposal nyata.
- [ ] Frontend governance sederhana (Phase 9) + indexer proposal & vote (Phase 10).

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | GovToken + Governor + Timelock dengan test end-to-end |
| 🟡 **Extended** — disarankan | Test serangan (flash-loan voting, quorum, delay) + UUPS treasury tervalidasi |
| 🔴 **Stretch** — untuk portfolio | Deploy ke L2 + frontend governance + indexer |

### ✅ Kriteria Lulus (Core)

- [ ] Test e2e: delegate → propose → vote → queue → warp → execute hijau
- [ ] Vote dengan token yang diterima **setelah** snapshot tidak menambah suara
- [ ] Execute sebelum delay timelock → revert
- [ ] Admin timelock sudah di-renounce setelah setup (diuji)


---

# 🏆 Challenge (Capstone): Gasless Smart Account untuk Protokol Anda

> *Challenge penutup — menggabungkan seluruh roadmap.*

## Spesifikasi

```text
TUJUAN:
  User baru (tanpa ETH) bisa menggunakan protokol Phase 11 (DEX atau lending) dari smart account,
  dengan gas disponsori aplikasi, dan seluruh sistem diaudit sendiri.

KOMPONEN:
  - Smart account ERC-4337 (owner = passkey atau EOA), batch execute
  - Session key: izin terbatas (target, selector, nilai maks, kedaluwarsa) untuk aksi berulang
  - Verifying paymaster dengan signature backend + rate limit (C4 Soal 5)
  - Backend (Phase 10): endpoint sponsor + SIWE/ERC-1271 auth
  - Frontend (Phase 9): onboarding tanpa seed phrase, approve+swap dalam satu UserOp
  - Deploy di L2 testnet (Phase 12)

SECURITY:
  - Session key tidak bisa memindahkan aset keluar dari whitelist
  - Paymaster tidak bisa dikuras
  - Invariant test (Phase 7) untuk account & paymaster
  - Self-audit report (Phase 8 template) + threat model end-to-end
```

## Tugas Challenge

1. Implementasi seluruh komponen dengan test unit, fuzz, dan invariant.
2. Tulis **threat model end-to-end** (contract, bundler, paymaster backend, frontend, key management).
3. Lakukan **self-audit** dan perbaiki temuan; minta minimal satu orang lain me-review (peer review).
4. Publikasikan **writeup** teknis (blog/README) beserta diagram arsitektur dan pelajaran yang didapat.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Smart account ERC-4337 + verifying paymaster, diuji via `EntryPoint.handleOps` |
| 🟡 **Extended** — disarankan | Session key + backend sponsor (SIWE/ERC-1271) |
| 🔴 **Stretch** — untuk portfolio | Frontend tanpa seed phrase, deploy L2, threat model, self-audit, writeup |

### ✅ Kriteria Lulus (Core)

- [ ] UserOp dengan signature valid dieksekusi; signature salah ditolak
- [ ] Paymaster menolak UserOp tanpa signature backend atau dengan `validUntil` lewat
- [ ] Batch `approve + action` berhasil dalam satu UserOp
- [ ] Address account counterfactual sama dengan address setelah deploy


---

## 📁 GitHub Task

```bash
cd 13-advanced-web3/   # path di bawah relatif ke folder fase; kode ada di lab/

git add .
git commit -m "learn: advanced web3 — upgradeability, multisig, governance, account abstraction, mev, zk"

git add src/dao/ test/dao/
git commit -m "feat: full-stack dao with governor, timelock and uups treasury (L6)"

git add src/aa/ test/aa/
git commit -m "feat: erc-4337 smart account with session keys and verifying paymaster (capstone)"

git add audits/ docs/
git commit -m "security: capstone threat model and self-audit report"
```

---

## 🧠 Knowledge Check (12 Pertanyaan)

1. Jelaskan bagaimana `delegatecall` memungkinkan upgrade, dan mengapa ia juga sumber storage collision.
2. Apa perbedaan Transparent proxy dan UUPS? Apa risiko khusus UUPS?
3. Mengapa implementation contract harus memanggil `_disableInitializers()` di constructor?
4. Apa yang dilindungi oleh multisig, dan serangan apa yang tetap bisa menembusnya?
5. Mengapa timelock penting bagi user, dan fungsi admin apa yang boleh tidak memakai delay?
6. Mengapa token governance harus di-delegate sebelum bisa vote? Bagaimana snapshot mencegah flash-loan voting?
7. Jelaskan alur UserOperation dari user sampai eksekusi di ERC-4337. Apa peran EntryPoint, bundler, dan paymaster?
8. Mengapa fase validasi ERC-4337 membatasi opcode dan akses storage?
9. Apa perbedaan ERC-4337 dan EIP-7702? Apa risiko baru yang dibawa EIP-7702?
10. Gambarkan MEV supply chain dan peran PBS/MEV-Boost.
11. Apa itu nullifier dalam aplikasi ZK, dan bug apa yang terjadi jika circuit under-constrained?
12. Berdasarkan seluruh roadmap, kelas bug apa yang menurut Anda paling sering menyebabkan kerugian besar, dan mengapa?

---

## 📊 Progress Tracker

- [ ] **Setup**: OZ upgradeable, foundry-upgrades, account-abstraction, Noir/Circom
- [ ] **C1**: Upgradeability — *Transparent, UUPS, Beacon, EIP-1967, ERC-7201, storage collision*
- [ ] **C2**: Multisig & Timelock — *Safe, modules/guards, TimelockController, role design*
- [ ] **C3**: Governance — *Governor, ERC20Votes, delegation, snapshot, serangan governance*
- [ ] **C4**: Account Abstraction — *ERC-4337, EntryPoint, bundler, paymaster, ERC-7562, EIP-7702*
- [ ] **C5**: MEV — *supply chain, PBS, MEV-Boost, private orderflow, intents*
- [ ] **C6**: ZK Aplikasi — *circuit, verifier, nullifier, under-constrained bugs*
- [ ] **C7**: Karier — *peran, rencana lanjutan, portfolio L1–L10*
- [ ] **Exercise**: Soal 1–9
- [ ] **Mini Project**: Full-stack DAO (L6)
- [ ] **Challenge**: Capstone gasless smart account
- [ ] **Knowledge Check**: 12 Questions
- [ ] **Review**: Self-assessment seluruh roadmap

---

## 🔗 Resources

### Upgradeability & Admin
- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967) · [ERC-7201: Namespaced Storage Layout](https://eips.ethereum.org/EIPS/eip-7201)
- [OpenZeppelin — Proxy Upgrade Pattern](https://docs.openzeppelin.com/upgrades-plugins/proxies)
- [OpenZeppelin Foundry Upgrades](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades)
- [Safe Docs](https://docs.safe.global/)

### Governance
- [OpenZeppelin Governor Guide](https://docs.openzeppelin.com/contracts/5.x/governance)
- [EIP-6372: Contract clock](https://eips.ethereum.org/EIPS/eip-6372)

### Account Abstraction
- [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) · [ERC-7562: Validation Rules](https://eips.ethereum.org/EIPS/eip-7562) · [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702)
- [eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction)

### MEV
- [Flashbots Docs](https://docs.flashbots.net/)
- [Ethereum.org — MEV](https://ethereum.org/en/developers/docs/mev/)

### Zero-Knowledge
- [Noir Docs](https://noir-lang.org/docs/) · [Circom Docs](https://docs.circom.io/)
- [ZK Bug Tracker (0xPARC)](https://github.com/0xPARC/zk-bug-tracker)

### Karier
- [Code4rena](https://code4rena.com/) · [Sherlock](https://www.sherlock.xyz/) · [Cantina](https://cantina.xyz/) · [Immunefi](https://immunefi.com/)
- [Solodit](https://solodit.xyz/) · [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri — termasuk self-assessment seluruh roadmap dari Soal 9)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk investigasi MEV dari Soal 7)*
