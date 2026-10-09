# 07 — Smart Contract Testing

> **Level**: 3 — Hands-On Verification
> **Phase**: 7 of 13
> **Estimated Time**: 🚀 Intensif 10–14 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 4–5 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [05-smart-contract-development](../05-smart-contract-development/README.md) ✅ | [06-foundry-tooling](../06-foundry-tooling/README.md) ✅
> **Status verifikasi**: **Reviewed (parsial)** · 9 Okt 2026 · challenge BuggyVault & handler di-compile, bug terbukti terdeteksi invariant — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- **Menjelaskan** dengan contoh mengapa jalur kegagalan & serangan harus diuji sama seriusnya dengan happy path di smart contract.
- Menyusun **test strategy** berlapis: unit → integration → fuzz → invariant → fork.
- Menulis **unit test** yang menguji kegagalan (revert path) sama seriusnya dengan happy path.
- Menulis **fuzz test** yang efektif menggunakan `bound()`, `vm.assume()`, dan input yang bermakna.
- Merancang **invariant test** berbasis *handler* dan *ghost variables* untuk membuktikan kebenaran global protokol.
- Menjalankan **fork test** terhadap state mainnet (USDC, Uniswap) secara reproducible.
- Mengukur kualitas test dengan **coverage**, **gas snapshot**, dan **mutation testing**.
- **Menjalankan** satu properti dengan symbolic execution (Halmos) dan **membandingkan** jaminannya dengan fuzzing.

---

## 📋 Prerequisites

- [x] Mampu menulis test Foundry dasar dan memakai cheatcodes (`prank`, `warp`, `deal`, `expectRevert`) — Phase 6.
- [x] Sudah membangun 5 contract + TokenStaking di Phase 5.
- [x] Memahami CEI dan reentrancy di level konsep (Phase 4 & 5).

---

> ⚖️ **Etika**: fork test (C5) membaca state mainnet **secara lokal** — tidak ada transaksi yang dikirim ke jaringan. Jangan pernah menjalankan skenario serangan terhadap protokol nyata; lihat aturan lengkap di [Phase 8 — Etika & Batasan Hukum](../08-smart-contract-security/README.md).

## ⚙️ Setup

```bash
cd 07-smart-contract-testing/
forge init lab --no-git
cd lab

# Opsional: salin contract Phase 5 sebagai "System Under Test".
# Gunakan implementasi referensi (src/ di Phase 5 berisi STARTER yang belum diisi,
# kecuali Anda sudah menyelesaikannya — jika sudah, boleh salin milik Anda sendiri):
cp ../../05-smart-contract-development/solutions/src/*.sol src/
```

> ⚠️ Kode fase ini ditempatkan di subfolder **`lab/`**. Jangan `forge init .` di folder fase — folder ini sudah berisi `README.md` materi, dan `forge init --force` akan **menimpanya**. Semua path `src/`, `test/`, `script/`, `audits/` di fase ini relatif terhadap `lab/`. `forge init` sudah memasang `forge-std`; hapus contoh `Counter*.sol` bawaan.

Tambahkan konfigurasi fuzz & invariant di `foundry.toml`:

```toml
[profile.default]
solc_version = "0.8.24"

[fuzz]
runs = 1000
max_test_rejects = 65536

[invariant]
runs = 256          # berapa sequence berbeda
depth = 50          # berapa call per sequence
fail_on_revert = false
```

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Testing Philosophy & Test Pyramid](#c1-testing-philosophy--test-pyramid) | ⬜ |
| **C2** | [Unit Testing yang Serius](#c2-unit-testing-yang-serius) | ⬜ |
| **C3** | [Fuzz Testing (Property-Based)](#c3-fuzz-testing-property-based) | ⬜ |
| **C4** | [Invariant Testing (Stateful Fuzzing)](#c4-invariant-testing-stateful-fuzzing) | ⬜ |
| **C5** | [Fork Testing terhadap Mainnet State](#c5-fork-testing-terhadap-mainnet-state) | ⬜ |
| **C6** | [Mengukur Kualitas Test: Coverage, Gas & Mutation](#c6-mengukur-kualitas-test-coverage-gas--mutation) | ⬜ |
| **C7** | [Beyond Fuzzing: Symbolic Execution & Formal Verification](#c7-beyond-fuzzing-symbolic-execution--formal-verification) | ⬜ |

---

---

# C1: Testing Philosophy & Test Pyramid

## Mental Model: "Kode yang Tidak Bisa Di-hotfix"

Di Web2, bug di production bisa di-patch dalam hitungan menit: deploy ulang, rollback database, refund manual. Di Web3:

```text
WEB2                                   WEB3
────────────────────────────           ────────────────────────────
Bug ditemukan → hotfix → deploy        Bug ditemukan → dana sudah hilang
Database bisa di-rollback              State immutable, tidak ada rollback
Attacker harus menembus server         Source code & state publik untuk semua
Kerugian: downtime, reputasi           Kerugian: seluruh TVL dalam 1 transaksi
Test = quality assurance               Test = garis pertahanan terakhir
```

> **Prinsip utama**: test bukan sekadar "apakah fungsi bekerja", tetapi **"apakah fungsi gagal dengan benar ketika diserang"**.

## Test Pyramid untuk Smart Contract

```text
                    ▲  Formal Verification   (bukti matematis, mahal)
                   ▲▲▲ Fork Tests            (state mainnet asli)
                  ▲▲▲▲▲ Invariant Tests      (urutan call acak, sifat global)
                ▲▲▲▲▲▲▲ Fuzz Tests           (input acak, sifat lokal)
             ▲▲▲▲▲▲▲▲▲▲ Integration Tests    (multi-contract)
         ▲▲▲▲▲▲▲▲▲▲▲▲▲▲ Unit Tests           (satu fungsi, satu skenario)
```

| Lapisan | Pertanyaan yang Dijawab | Contoh |
|---|---|---|
| Unit | "Apakah `withdraw()` revert jika bukan creator?" | `test_RevertWhen_NotCreator()` |
| Integration | "Apakah TokenStaking bisa mint reward dari ERC20Token?" | Deploy dua contract, uji alurnya |
| Fuzz | "Untuk **semua** `amount` valid, apakah balance selalu benar?" | `testFuzz_Transfer(uint256 amount)` |
| Invariant | "Setelah **urutan apa pun** dari deposit/withdraw, apakah `totalSupply == Σ balances`?" | `invariant_SupplyEqualsBalances()` |
| Fork | "Apakah integrasi dengan USDC asli bekerja (6 decimals, blacklist)?" | `vm.createSelectFork(MAINNET_RPC)` |

## Konvensi Penamaan (Foundry Best Practice)

```solidity
function test_Deposit() public {}                         // happy path
function test_RevertWhen_AmountIsZero() public {}         // revert path
function test_RevertIf_CallerNotOwner() public {}         // revert path (alternatif)
function testFuzz_Deposit(uint256 amount) public {}       // fuzz
function invariant_TotalSupplyMatches() public {}         // invariant
function testFork_SwapOnUniswap() public {}               // fork
```

Konsistensi nama membuat `forge test --match-test "RevertWhen"` bisa menjalankan seluruh kategori sekaligus.

## Latihan C1: Test Strategy

### Soal 1 — Klasifikasi Test
Untuk `Crowdfunding.sol` (Phase 5), kelompokkan skenario berikut ke lapisan pyramid yang paling tepat:
1. `donate()` revert jika `msg.value == 0`.
2. Untuk semua kombinasi donasi dari 1–50 donor, `totalRaised` selalu sama dengan jumlah semua `getDonation()`.
3. Refund tidak bisa dipanggil dua kali oleh donor yang sama.
4. Contract attacker mencoba reentrancy saat `refund()`.
5. Setelah urutan acak `donate/finalize/refund/withdraw`, balance contract tidak pernah kurang dari dana yang masih bisa di-refund.

<details>
<summary>💡 Pembahasan</summary>

1. **Unit** — satu fungsi, satu kondisi.
2. **Fuzz** — properti lokal yang harus benar untuk input acak (jumlah donor & nominal).
3. **Unit** (revert path) — atau bagian dari invariant jika diuji dengan urutan acak.
4. **Integration / PoC** — melibatkan contract kedua (attacker).
5. **Invariant** — properti global yang harus bertahan setelah urutan call apa pun. Ini adalah *solvency invariant*, jenis invariant paling penting di protokol keuangan.

</details>

---

---

# C2: Unit Testing yang Serius

## Anatomy: Arrange → Act → Assert

```solidity
function test_Refund_ReturnsFullDonation() public {
    // ── Arrange ──────────────────────────────
    vm.deal(alice, 5 ether);
    vm.prank(alice);
    cf.donate{value: 2 ether}();
    vm.warp(block.timestamp + DURATION + 1);
    cf.finalize();                                // gagal karena < GOAL
    uint256 balanceBefore = alice.balance;

    // ── Act ──────────────────────────────────
    vm.prank(alice);
    cf.refund();

    // ── Assert ───────────────────────────────
    assertEq(alice.balance, balanceBefore + 2 ether, "refund amount");
    assertEq(cf.getDonation(alice), 0, "donation cleared");
}
```

## Apa yang Wajib Diuji di Setiap Fungsi State-Changing

```text
✔ Happy path                  → state berubah sesuai spesifikasi
✔ Setiap revert condition     → error yang TEPAT (selector + argumen)
✔ Event                       → topic & data yang tepat
✔ Access control              → setiap role yang TIDAK berhak ditolak
✔ Boundary                    → 0, 1, max-1, max, tepat di deadline
✔ Side effect pada pihak lain → balance penerima, allowance, totalSupply
```

## Menguji Revert dengan Presisi

```solidity
// ❌ Lemah: lolos untuk revert APA PUN (termasuk bug lain!)
vm.expectRevert();
cf.withdraw();

// ✅ Kuat: harus error spesifik
vm.expectRevert(Crowdfunding.NotCreator.selector);
cf.withdraw();

// ✅ Lebih kuat: error dengan argumen
vm.expectRevert(abi.encodeWithSelector(
    VotingSystem.AlreadyVoted.selector, alice, 0
));
voting.vote(0, true);
```

## Menguji Event

```solidity
vm.expectEmit(true, true, false, true, address(token));
//            topic1 topic2 topic3 data  emitter
emit ERC20Token.Transfer(alice, bob, 100e18);   // event yang DIHARAPKAN
vm.prank(alice);
token.transfer(bob, 100e18);                     // call yang harus emit event tsb
```

## Boundary Testing: Bug Paling Sering Ada di Tepi

```solidity
// Deadline: apakah donate() di detik TEPAT deadline diterima atau ditolak?
function test_RevertWhen_DonateExactlyAtDeadline() public {
    vm.warp(cf.DEADLINE());           // tepat di batas
    vm.expectRevert(Crowdfunding.CampaignEnded.selector);
    cf.donate{value: 1}();
}

function test_Donate_OneSecondBeforeDeadline() public {
    vm.warp(cf.DEADLINE() - 1);
    cf.donate{value: 1}();            // harus berhasil
}
```

> Off-by-one (`<` vs `<=`) adalah salah satu sumber bug paling umum di time-based logic. Selalu uji **tepat di batas** dan **satu unit di kedua sisi**.

## Helper & Setup yang Bersih

```solidity
abstract contract BaseTest is Test {
    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");   // label otomatis di trace
    address internal bob   = makeAddr("bob");

    function _fund(address who, uint256 amount) internal {
        vm.deal(who, amount);
    }
}

contract CrowdfundingTest is BaseTest { /* ... */ }
```

## Latihan C2: Unit Test Hardening

### Soal 2 — Audit Test Suite
Buka `05-smart-contract-development/test/` dan audit test suite Anda sendiri:
- Berapa banyak `vm.expectRevert()` tanpa selector? Ubah semuanya menjadi spesifik.
- Fungsi state-changing mana yang **belum** punya test event?
- Boundary mana yang belum diuji (deadline tepat, `MIN_STAKE` tepat, `maxPerWallet` tepat)?

Tulis temuan Anda dalam tabel `Fungsi | Yang belum diuji | Status`.

**✅ Selesai jika:**
- [ ] Tabel `Fungsi | Belum diuji | Status` mencakup **semua** fungsi external contract Phase 5
- [ ] `grep -n "expectRevert()" test/` tidak menemukan apa pun
- [ ] Jumlah test bertambah dan semuanya hijau


### Soal 3 — Tebak Bug dari Test
Test berikut **lulus**, tetapi contract-nya punya bug. Apa yang kurang dari test ini?

```solidity
function test_Transfer() public {
    vm.prank(alice);
    token.transfer(bob, 100);
    assertEq(token.balanceOf(bob), 100);
}
```

<details>
<summary>💡 Pembahasan</summary>

Test hanya memeriksa **penerima**. Bug yang lolos:
- `balanceOf(alice)` tidak berkurang (token tercipta dari udara).
- `totalSupply` berubah.
- Event `Transfer` tidak di-emit (indexer & wallet tidak akan melihat transfer).
- Return value `true` tidak dicek.
- `transfer(alice, ...)` ke diri sendiri bisa menggandakan balance jika implementasi memakai variabel cache yang salah.

Aturan praktis: **assert semua state yang seharusnya berubah DAN yang seharusnya tidak berubah**.

</details>

---

---

# C3: Fuzz Testing (Property-Based)

## Mental Model: "Jangan Pilih Input, Nyatakan Properti"

Unit test: *"Jika Alice transfer 100, Bob menerima 100."*
Fuzz test: *"Untuk **setiap** `amount ≤ balance`, transfer tidak mengubah total supply dan memindahkan tepat `amount`."*

Foundry otomatis menghasilkan ratusan–ribuan input, termasuk nilai tepi (0, 1, `type(uint256).max`), dan jika gagal akan melakukan **shrinking** — mencari input terkecil yang masih menyebabkan kegagalan.

## Anatomy Fuzz Test

```solidity
function testFuzz_Transfer(address to, uint256 amount) public {
    // 1. Constrain input agar bermakna
    vm.assume(to != address(0) && to != alice);
    amount = bound(amount, 0, token.balanceOf(alice));

    uint256 supplyBefore = token.totalSupply();
    uint256 aliceBefore  = token.balanceOf(alice);
    uint256 toBefore     = token.balanceOf(to);

    // 2. Act
    vm.prank(alice);
    token.transfer(to, amount);

    // 3. Properti
    assertEq(token.totalSupply(), supplyBefore,           "supply conserved");
    assertEq(token.balanceOf(alice), aliceBefore - amount, "sender debited");
    assertEq(token.balanceOf(to),    toBefore + amount,    "receiver credited");
}
```

## `bound()` vs `vm.assume()`

| | `bound(x, min, max)` | `vm.assume(cond)` |
|---|---|---|
| Cara kerja | Memetakan `x` ke rentang | Membuang run jika `cond` false |
| Efisiensi | Tinggi — tidak ada run terbuang | Rendah jika kondisi jarang terpenuhi |
| Kapan dipakai | Rentang numerik | Kondisi diskrit (bukan address tertentu) |

```solidity
// ❌ Buruk: 99.99% run dibuang → "too many rejects"
vm.assume(amount > 100e18 && amount < 1000e18);

// ✅ Baik
amount = bound(amount, 100e18, 1000e18);
```

## Properti yang Layak Di-fuzz

| Jenis Properti | Contoh |
|---|---|
| **Konservasi** | Transfer tidak mengubah `totalSupply` |
| **Round-trip** | `deposit(x)` lalu `withdraw(x)` → balance kembali seperti semula |
| **Monotonic** | Reward staking tidak pernah turun seiring waktu |
| **Bounded** | Reward ≤ `amount × rate × elapsed / denominator` |
| **Equivalence** | Implementasi gas-optimized == implementasi referensi (differential) |
| **Never-revert** | `getReward()` (view) tidak pernah revert untuk user mana pun |

## Differential Fuzzing

Bandingkan dua implementasi yang seharusnya identik:

```solidity
function testFuzz_SqrtMatchesReference(uint256 x) public pure {
    assertEq(MyMath.sqrt(x), ReferenceMath.sqrt(x));
}
```

Sangat berguna saat Anda melakukan *gas golf* (Phase 8+) — pastikan versi cepat tidak mengubah perilaku.

## Latihan C3: Fuzzing

### Soal 4 — Tulis Properti, Bukan Kode
Untuk `TokenStaking` (Phase 5), tuliskan **dalam bahasa natural** minimal 5 properti yang bisa di-fuzz. Contoh: *"Untuk setiap `amount ≥ MIN_STAKE` dan `elapsed ≤ 365 days`, `getReward()` tidak pernah melebihi …"*. Setelah itu baru implementasikan sebagai `testFuzz_*`.

**✅ Selesai jika:**
- [ ] Minimal 5 properti tertulis dalam bahasa natural sebelum menulis kode
- [ ] Setiap properti menjadi `testFuzz_*` yang hijau dengan `runs = 1000`

<details>
<summary>💡 Contoh 2 properti (sisanya tulis sendiri)</summary>

1. *Untuk setiap `amount ≥ MIN_STAKE` dan `elapsed ≤ 365 days` tanpa claim, `getReward(user) == amount × 100 × elapsed / (10_000 × 86_400)`* — reward tepat sesuai rumus, bukan sekadar `> 0`.
2. *Untuk setiap `amount < MIN_STAKE`, `stake(amount)` selalu revert.*

Arah properti lain: monotonic (reward tidak turun seiring waktu), round-trip (unstake mengembalikan tepat pokok), reset (setelah claim, reward di detik yang sama = 0).

</details>


### Soal 5 — Too Many Rejects
Fuzz test berikut gagal dengan pesan `The fuzz test rejected too many inputs`. Mengapa, dan bagaimana memperbaikinya?

```solidity
function testFuzz_Stake(uint256 amount, uint256 time) public {
    vm.assume(amount >= 100e18 && amount <= 1_000_000e18);
    vm.assume(time > 1 days && time < 30 days);
    // ...
}
```

<details>
<summary>💡 Pembahasan</summary>

Ruang `uint256` adalah 2²⁵⁶. Peluang nilai acak jatuh di rentang `[100e18, 1e24]` mendekati nol; digabung dengan kondisi `time`, hampir semua run dibuang. Ganti `vm.assume` dengan `bound`:

```solidity
amount = bound(amount, 100e18, 1_000_000e18);
time   = bound(time, 1 days + 1, 30 days - 1);
```

</details>

---

---

# C4: Invariant Testing (Stateful Fuzzing)

## Mental Model: "Hukum Fisika Protokol"

Fuzz test menguji **satu call** dengan input acak. Invariant test menguji **urutan call acak** (deposit → withdraw → transfer → deposit …) lalu memeriksa bahwa sebuah *hukum* selalu benar setelah setiap call.

```text
Invariant = pernyataan yang HARUS benar di SETIAP state yang bisa dicapai.

Contoh hukum protokol:
  ERC-20     : totalSupply == Σ balanceOf(semua holder)
  Vault      : totalAssets >= totalShares × minSharePrice
  Lending    : Σ debt ≤ Σ collateral × LTV
  Crowdfund  : address(this).balance >= Σ donasi yang masih bisa di-refund
  Staking    : STAKE_TOKEN.balanceOf(staking) >= totalStaked
```

## Masalah Invariant Naif

Jika Foundry memanggil fungsi target secara acak tanpa arahan, sebagian besar call akan revert (misal `withdraw` tanpa deposit, `transfer` tanpa balance). Hasilnya: test "lulus" padahal tidak menguji apa pun.

## Solusi: Handler Pattern

```text
┌───────────────────┐   memanggil acak   ┌──────────────────┐   memanggil   ┌───────────────┐
│ Foundry Invariant │ ─────────────────▶ │     Handler      │ ────────────▶ │ Target Contract│
│      Engine       │                    │ - bound input    │               │  (ERC20Token)  │
└───────────────────┘                    │ - pilih actor    │               └───────────────┘
         │                               │ - ghost variables│
         │ setelah setiap call            └──────────────────┘
         ▼
  invariant_*() dicek
```

```solidity
// ℹ️ Butuh `ERC20Token` dari Phase 5 (`src/ERC20Token.sol`) dan import forge-std.
// test/invariant/handlers/TokenHandler.sol
contract TokenHandler is Test {
    ERC20Token public token;
    address[] public actors;
    uint256 public ghost_mintedSum;      // ghost variable: dicatat oleh handler

    constructor(ERC20Token _token) {
        token = _token;
        actors.push(makeAddr("a1"));
        actors.push(makeAddr("a2"));
        actors.push(makeAddr("a3"));
    }

    function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[actorSeed % actors.length];
        address to   = actors[toSeed % actors.length];
        amount = bound(amount, 0, token.balanceOf(from));

        vm.prank(from);
        token.transfer(to, amount);
    }

    // TODO (latihan): tambahkan approve, transferFrom, burn dengan pola yang sama
}
```

```solidity
// ℹ️ Butuh `ERC20Token` (Phase 5) dan `TokenHandler` di atas.
// test/invariant/TokenInvariant.t.sol
contract TokenInvariantTest is Test {
    ERC20Token token;
    TokenHandler handler;

    function setUp() public {
        token   = new ERC20Token("T", "T", 0);
        handler = new TokenHandler(token);
        // ... distribusikan saldo awal ke actors ...
        targetContract(address(handler));     // HANYA handler yang di-fuzz
    }

    function invariant_SupplyEqualsSumOfBalances() public view {
        uint256 sum;
        for (uint256 i; i < 3; i++) sum += token.balanceOf(handler.actors(i));
        assertEq(token.totalSupply(), sum);
    }
}
```

## Ghost Variables

Ghost variable adalah state **di dalam handler** yang mencatat apa yang *seharusnya* terjadi, lalu dibandingkan dengan state contract:

```text
ghost_totalDeposited - ghost_totalWithdrawn == vault.totalAssets()
```

Jika keduanya berbeda, ada jalur di contract yang membuat/menghilangkan nilai tanpa tercatat.

## Membaca Hasil Invariant

```bash
forge test --match-contract Invariant -vvv
# [FAIL: invariant_SupplyEqualsSumOfBalances]
# [Sequence]
#   sender=0x... calldata=transfer(1, 1, 5000)
#   sender=0x... calldata=burn(2, 100)
```

Foundry mencetak **sequence** call yang memicu pelanggaran. Ubah sequence itu menjadi unit test regresi agar bug tidak pernah kembali.

## Latihan C4: Invariant Design

### Soal 6 — Temukan Invariant
Tuliskan minimal 3 invariant untuk masing-masing contract Phase 5: `VotingSystem`, `Crowdfunding`, `NFTCollection`, `TokenStaking`.

**✅ Selesai jika:**
- [ ] Minimal 3 invariant per contract, masing-masing sebagai kalimat **dan** rumus
- [ ] Setiap invariant bisa dicek hanya dari state on-chain (tanpa mengandalkan asumsi off-chain)

<details>
<summary>💡 Contoh 1 invariant per contract (lengkapi sisanya)</summary>

- **VotingSystem**: untuk setiap proposal, `voteFor + voteAgainst` = jumlah address dengan `hasVoted(id, addr) == true`.
- **Crowdfunding**: selama belum ada refund/withdraw, `totalRaised == Σ getDonation(donor)`.
- **NFTCollection**: `Σ balanceOf(holder) == totalSupply()` dan setiap `tokenId < totalSupply()` punya `ownerOf != address(0)`.
- **TokenStaking**: `STAKE_TOKEN.balanceOf(staking) >= totalStaked`.

</details>


### Soal 7 — Invariant yang Selalu Lulus
Sebuah invariant test dengan `fail_on_revert = false` selalu lulus, bahkan setelah Anda sengaja menyisipkan bug. Sebutkan tiga kemungkinan penyebabnya.

<details>
<summary>💡 Pembahasan</summary>

1. **Hampir semua call revert** — handler tidak membatasi input sehingga state tidak pernah berubah. Cek dengan `forge test -vvv` dan lihat tabel *calls / reverts* per fungsi; gunakan `bound` dan pilih actor yang punya saldo.
2. **Target salah** — `targetContract` tidak dipanggil atau mengarah ke contract yang tidak relevan, sehingga fuzzer memanggil fungsi yang tidak menyentuh bug.
3. **Invariant terlalu lemah / tautologi** — misalnya `assertGe(token.totalSupply(), 0)` yang selalu benar untuk `uint256`.
Bonus: `depth` terlalu kecil sehingga bug yang butuh banyak langkah tidak tercapai.

</details>

---

---

# C5: Fork Testing terhadap Mainnet State

## Mengapa Fork?

Mock hanya sebaik asumsi Anda. Token nyata punya perilaku "aneh":

| Token | Keanehan |
|---|---|
| USDC | 6 decimals, ada blacklist, proxy upgradeable |
| USDT | `transfer` **tidak me-return `bool`** |
| Fee-on-transfer tokens | Jumlah yang diterima < jumlah yang dikirim |
| Rebasing tokens (stETH) | Balance berubah tanpa transfer |

Fork test menjalankan test Anda di atas **salinan state mainnet** pada block tertentu.

```solidity
// ℹ️ Butuh interface `IERC20` dan `MAINNET_RPC_URL`.
contract USDCForkTest is Test {
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function setUp() public {
        // Pin block number → test reproducible & bisa di-cache
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 19_000_000);
    }

    function testFork_DealUSDC() public {
        address alice = makeAddr("alice");
        deal(address(USDC), alice, 1_000e6);   // forge-std deal() menulis storage balance
        assertEq(USDC.balanceOf(alice), 1_000e6);
    }
}
```

```bash
forge test --match-contract Fork --fork-url $MAINNET_RPC_URL -vvv
```

## Tips Fork Testing

- **Selalu pin block number** — tanpa itu, hasil test berubah setiap hari dan RPC tidak bisa di-cache.
- Simpan RPC URL di `.env`, rujuk via `[rpc_endpoints]` di `foundry.toml`.
- Pisahkan fork test ke file/contract khusus agar unit test tetap cepat & offline.
- `vm.rollFork(blockNumber)` untuk berpindah block di tengah test.

## Latihan C5: Fork

### Soal 8 — Token Aneh
Tulis fork test yang membuktikan bahwa memanggil `IERC20(USDT).transfer(...)` dengan interface standar (yang mengharapkan `returns (bool)`) akan **revert** saat decoding return data. Lalu jelaskan mengapa library `SafeERC20` dibutuhkan. (Tidak ada pembahasan — buktikan sendiri dengan test.)

**✅ Selesai jika:**
- [ ] Fork test dipin ke block tertentu dan hijau
- [ ] Test membuktikan panggilan via interface standar revert, sedangkan via `SafeERC20` berhasil
- [ ] Penjelasan 2–3 kalimat di Notes tentang *mengapa* decoding return data gagal


---

---

# C6: Mengukur Kualitas Test: Coverage, Gas & Mutation

## Coverage

```bash
forge coverage                          # ringkasan per file
forge coverage --report lcov            # untuk VS Code (Coverage Gutters) / CI
forge coverage --report debug           # baris mana yang tidak tersentuh
```

| Metrik | Arti |
|---|---|
| Lines | Baris yang dieksekusi |
| Statements | Pernyataan yang dieksekusi |
| Branches | Setiap cabang `if`/`require` diuji **true dan false** |
| Functions | Fungsi yang dipanggil minimal sekali |

> ⚠️ **100% coverage ≠ bebas bug.** Coverage hanya mengatakan kode *dijalankan*, bukan *diverifikasi*. Test tanpa `assert` tetap menaikkan coverage.

## Gas Snapshot sebagai Regression Test

```bash
forge snapshot                      # buat .gas-snapshot
forge snapshot --check              # gagal jika gas berubah
forge snapshot --diff               # tampilkan perubahan
```

## Mutation Testing: "Testing the Tests"

Mutation testing sengaja **merusak** kode (mengganti `<` menjadi `<=`, menghapus `require`, membalik `+`/`-`) lalu menjalankan test. Jika test tetap lulus, *mutant survived* → test Anda tidak cukup kuat.

```text
Original:  if (block.timestamp >= DEADLINE) revert CampaignEnded();
Mutant 1:  if (block.timestamp >  DEADLINE) revert CampaignEnded();   ← apakah ada test yang gagal?
Mutant 2:  // baris dihapus                                           ← apakah ada test yang gagal?
```

Tools: **Gambit** (Certora), **vertigo-rs**. Mutation score = mutant terbunuh / total mutant.

## Latihan C6: Kualitas

### Soal 9 — Coverage vs Mutation
Jalankan `forge coverage` pada project Phase 5. Pilih satu fungsi dengan coverage 100%, lalu buat 3 mutant **secara manual** (ubah operator, hapus satu baris). Berapa mutant yang tetap lulus test? Tulis hasilnya di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Output `forge coverage` tersimpan di Notes
- [ ] 3 mutant terdokumentasi: perubahan kode + test yang gagal (atau *survived*)
- [ ] Untuk setiap mutant yang *survived*, ada test baru yang membunuhnya


---

---

# C7: Beyond Fuzzing: Symbolic Execution & Formal Verification

## Fuzzing vs Symbolic Execution

```text
Fuzzing:   coba banyak nilai konkret        → "tidak ditemukan bug di 10.000 percobaan"
Symbolic:  perlakukan input sebagai simbol  → "untuk SEMUA input, properti ini benar"
                                               (atau: berikut counterexample-nya)
```

| | Fuzzing (Foundry) | Symbolic (Halmos, hevm) | Formal (Certora) |
|---|---|---|---|
| Jaminan | Probabilistik | Lengkap dalam batas loop/depth | Lengkap terhadap spesifikasi |
| Biaya belajar | Rendah | Sedang | Tinggi (bahasa CVL) |
| Kecepatan | Cepat | Bisa sangat lambat (path explosion) | Bervariasi |

## Halmos: Memakai Ulang Test Foundry

Halmos membaca test Foundry dengan prefix `check_` dan menjalankannya secara simbolik:

```solidity
function check_TransferConservesSupply(address to, uint256 amount) public {
    vm.assume(to != address(0));
    uint256 before = token.totalSupply();
    vm.prank(alice);
    token.transfer(to, amount);
    assert(token.totalSupply() == before);
}
```

```bash
pip install halmos
halmos --function check_
```

## Latihan C7

### Soal 10 — Kapan Formal Verification Layak?
Sebuah tim punya budget terbatas. Untuk contract mana yang formal verification paling layak: (a) NFT PFP collection, (b) lending protocol dengan TVL $200M, (c) DAO voting untuk komunitas kecil? Jelaskan alasan Anda dengan mempertimbangkan biaya, kompleksitas, dan dampak kegagalan.

<details>
<summary>💡 Pembahasan</summary>

**(b) Lending protocol.** Formal verification mahal (waktu & keahlian), jadi diprioritaskan pada kode dengan **dampak kegagalan tertinggi** dan **logika matematis inti** yang bisa dinyatakan sebagai spesifikasi (solvency, health factor, interest accrual). NFT collection dan DAO kecil cukup dengan unit + fuzz + invariant + audit, karena kerugian maksimalnya jauh lebih kecil dan logikanya lebih standar.

</details>

---

---

# 📝 Mini Project: Test Suite Grade-Audit untuk Phase 5

Tingkatkan test suite seluruh contract Phase 5 hingga standar yang layak diserahkan ke auditor.

## Struktur yang Diharapkan

```text
07-smart-contract-testing/lab/
├── src/                         # salinan contract Phase 5 (System Under Test)
├── test/
│   ├── unit/                    # satu file per contract
│   ├── fuzz/                    # properti lokal
│   ├── invariant/
│   │   ├── handlers/            # handler per contract
│   │   └── *.invariant.t.sol
│   └── fork/                    # integrasi dengan token mainnet (opsional)
├── foundry.toml
└── TESTING.md                   # test plan & daftar invariant
```

## Deliverable

- [ ] Setiap fungsi state-changing punya test happy path, revert path (selector spesifik), dan event.
- [ ] Minimal **3 fuzz test** per contract.
- [ ] Minimal **2 invariant** per contract dengan handler + ghost variable.
- [ ] Branch coverage ≥ 95% (sertakan output `forge coverage`).
- [ ] `TESTING.md` berisi: daftar invariant dalam bahasa natural, asumsi, dan apa yang **tidak** diuji.
- [ ] `.gas-snapshot` di-commit.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Unit + fuzz untuk **Crowdfunding** dan **ERC20Token** |
| 🟡 **Extended** — disarankan | Semua contract Phase 5 + 2 invariant per contract dengan handler |
| 🔴 **Stretch** — untuk portfolio | Branch coverage ≥ 95%, mutation testing, fork test, `TESTING.md` |

### ✅ Kriteria Lulus (Core)

- [ ] Tidak ada `vm.expectRevert()` tanpa selector di kedua file test
- [ ] ≥ 3 fuzz test per contract (Core), memakai `bound()` dan lulus dengan `runs = 1000`
- [ ] Output `forge coverage` untuk kedua contract disimpan di Notes
- [ ] Sengaja sisipkan 1 bug (misal hapus satu `require`) → minimal 1 test Anda menjadi merah


---

# 🏆 Challenge: Bug Hunt dengan Invariant

> *Challenge tanpa tutorial. Temukan bug HANYA dengan invariant testing — jangan membaca kode baris per baris dulu.*

## Contract Target

```solidity
// src/BuggyVault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// @notice Vault sederhana berbasis shares. Mengandung bug yang disengaja.
contract BuggyVault {
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    constructor(IERC20 _asset) { asset = _asset; }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets) external returns (uint256 shares) {
        shares = totalShares == 0 ? assets : assets * totalShares / totalAssets();
        sharesOf[msg.sender] += shares;
        totalShares += shares;
        asset.transferFrom(msg.sender, address(this), assets);
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        assets = shares * totalAssets() / totalShares;
        sharesOf[msg.sender] -= shares;
        asset.transfer(msg.sender, assets);
        totalShares -= shares;
    }

    function transferShares(address to, uint256 shares) external {
        uint256 fromBal = sharesOf[msg.sender];
        uint256 toBal   = sharesOf[to];
        sharesOf[msg.sender] = fromBal - shares;
        sharesOf[to]         = toBal + shares;
    }
}
```

## Tugas Challenge

1. Tulis **handler** untuk `deposit`, `withdraw`, `transferShares` dengan 3–5 actor.
2. Definisikan minimal invariant berikut dan jalankan:
   - `Σ sharesOf(actor) == totalShares`
   - Tidak ada actor yang bisa menarik aset lebih dari yang ia deposit + bagian yield yang sah.
   - `totalAssets() >= ` nilai yang masih bisa ditarik oleh semua pemegang shares.
3. Untuk setiap invariant yang gagal, ubah **sequence** dari Foundry menjadi unit test regresi.
4. Tulis laporan singkat per bug: **Invariant yang dilanggar → Root cause → Impact → Rekomendasi fix**.
5. Bonus: apakah ada bug yang **tidak** bisa ditemukan oleh invariant Anda? Apa yang perlu ditambahkan? (Petunjuk: *first depositor / share inflation*, akan dibahas lebih dalam di Phase 8 & 11.)

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Tugas 1–3 untuk invariant `Σ sharesOf == totalShares` |
| 🟡 **Extended** — disarankan | Tugas 2–4 lengkap (ketiga invariant + laporan per bug) |
| 🔴 **Stretch** — untuk portfolio | Tugas 5 (bonus share inflation) + perbandingan dengan `fail_on_revert = true` |

### ✅ Kriteria Lulus (Core)

- [ ] Invariant `Σ sharesOf == totalShares` **gagal** terhadap `BuggyVault` dan Foundry mencetak sequence-nya
- [ ] Sequence tersebut diubah menjadi unit test regresi yang merah pada kode asli
- [ ] Setelah Anda memperbaiki bug, invariant & test regresi hijau
- [ ] Tabel calls/reverts handler menunjukkan sebagian besar call **tidak** revert (handler Anda efektif)


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `The fuzz test rejected too many inputs` | `vm.assume` membuang hampir semua input | Ganti dengan `bound()` (C3 Soal 5) |
| Invariant selalu lulus, bahkan dengan bug | Handler terlalu sering revert / target salah | Cek tabel *calls/reverts* dengan `-vvv`; pastikan `targetContract(address(handler))` |
| Fork test lambat / `429 Too Many Requests` | Tidak mem-pin block, RPC dibatasi | Pin block number agar respons di-cache; kurangi `runs` untuk fork test |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 07-smart-contract-testing/   # path di bawah relatif ke folder fase; kode ada di lab/

git add .
git commit -m "learn: smart contract testing — unit, fuzz, invariant, fork, coverage, symbolic"

git add test/
git commit -m "test: audit-grade test suite for phase 5 contracts (unit, fuzz, invariant)"

git add test/invariant/ src/BuggyVault.sol
git commit -m "test: invariant bug hunt on BuggyVault (Phase 7 challenge)"

git add .gas-snapshot TESTING.md
git commit -m "docs: add test plan, invariant list and gas snapshot"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Mengapa prinsip "test kegagalan sama pentingnya dengan test keberhasilan" lebih krusial di smart contract dibanding aplikasi Web2?
2. Apa perbedaan `vm.expectRevert()` tanpa argumen dan `vm.expectRevert(Error.selector)`? Mengapa yang pertama berbahaya?
3. Kapan Anda memakai `bound()` dan kapan memakai `vm.assume()`? Apa itu "too many rejects"?
4. Apa perbedaan fuzz test (stateless) dan invariant test (stateful)? Berikan satu bug yang hanya bisa ditemukan oleh invariant test.
5. Jelaskan handler pattern. Masalah apa yang diselesaikannya?
6. Apa itu ghost variable? Berikan contoh invariant yang membutuhkannya.
7. Mengapa fork test harus mem-pin block number?
8. Sebutkan tiga perilaku token ERC-20 "non-standar" yang tidak akan tertangkap oleh mock biasa.
9. Mengapa 100% line coverage tidak menjamin contract aman? Bagaimana mutation testing melengkapinya?
10. Apa perbedaan jaminan yang diberikan fuzzing dibanding symbolic execution?

<details>
<summary>🔑 Kunci jawaban Knowledge Check — buka <b>setelah</b> Anda menjawab sendiri</summary>

> Jawaban ringkas sebagai acuan. Jika jawaban Anda berbeda tetapi alasannya benar, itu tetap benar — bandingkan alasannya, bukan kalimatnya.

1. Kode tidak bisa di-patch, aset nyata dipertaruhkan, dan lingkungannya adversarial serta publik. Jalur kegagalan adalah permukaan serangan; di Web2 bug bisa diperbaiki cepat setelah ditemukan.
2. Tanpa argumen, test lolos untuk revert **apa pun** — termasuk revert karena bug lain — sehingga memberi rasa aman palsu. Dengan selector, test memastikan alasan revert yang tepat.
3. `bound` untuk rentang numerik (tidak ada run terbuang). `vm.assume` untuk pengecualian diskrit (misal bukan address tertentu). *Too many rejects*: terlalu banyak input dibuang oleh `assume` sehingga fuzzer menyerah dan test gagal.
4. Fuzz: input acak untuk satu call dari state awal yang sama. Invariant: urutan call acak, sifat global dicek setelah setiap call. Contoh bug yang hanya tertangkap invariant: `transferShares` ke diri sendiri di `BuggyVault` — butuh `deposit` lalu self-transfer.
5. Handler membungkus fungsi target dengan input yang dibatasi dan aktor yang valid, sehingga fuzzer menghasilkan transisi state yang bermakna (bukan revert terus) dan bisa mencatat ghost variable.
6. Variabel di handler yang mencatat apa yang seharusnya terjadi (misal total deposit − total withdraw) untuk dibandingkan dengan state contract, contoh: `vault.totalAssets() == ghost_deposited - ghost_withdrawn`.
7. Agar hasil test reproducible (state mainnet terus berubah) dan respons RPC bisa di-cache sehingga CI cepat & konsisten.
8. Fee-on-transfer (jumlah diterima < dikirim), rebasing (saldo berubah tanpa transfer), tidak me-return `bool` (USDT), blacklist/pausable (USDC), decimals berbeda, dan approve yang harus di-nol-kan dulu.
9. Coverage hanya mengukur baris yang dieksekusi, bukan yang diverifikasi (test tanpa assert tetap menaikkan coverage). Mutation testing sengaja mengubah kode dan memastikan test gagal — mengukur kekuatan test.
10. Fuzzing: probabilistik — hanya sampel input yang dicoba. Symbolic execution: menelusuri semua input untuk setiap jalur (dalam batas loop/depth) — membuktikan properti atau memberi counterexample.

</details>

---

## 📊 Progress Tracker

- [ ] **Setup**: Project init, `foundry.toml` dengan konfigurasi fuzz & invariant
- [ ] **C1**: Testing Philosophy — *test pyramid, konvensi penamaan*
- [ ] **C2**: Unit Testing — *AAA, revert presisi, event, boundary*
- [ ] **C3**: Fuzz Testing — *bound vs assume, properti, differential fuzzing*
- [ ] **C4**: Invariant Testing — *handler, ghost variables, membaca sequence*
- [ ] **C5**: Fork Testing — *createSelectFork, deal, token non-standar*
- [ ] **C6**: Kualitas Test — *coverage, gas snapshot, mutation testing*
- [ ] **C7**: Symbolic Execution — *Halmos, kapan formal verification layak*
- [ ] **Exercise**: Soal 1–10
- [ ] **Mini Project**: Test suite grade-audit untuk Phase 5
- [ ] **Challenge**: Bug hunt BuggyVault dengan invariant
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Foundry Book — Fuzz Testing](https://book.getfoundry.sh/forge/fuzz-testing)
- [Foundry Book — Invariant Testing](https://book.getfoundry.sh/forge/invariant-testing)
- [Foundry Book — Forking](https://book.getfoundry.sh/forge/fork-testing)

### Deep Dive
- [Invariant Testing WETH With Foundry (horsefacts)](https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw)
- [a16z — Halmos: Symbolic Testing](https://github.com/a16z/halmos)
- [Trail of Bits — Building Secure Contracts: Fuzzing](https://secure-contracts.com/program-analysis/index.html)
- [Weird ERC20 Tokens](https://github.com/d-xo/weird-erc20)

### Tools
- [Echidna](https://github.com/crytic/echidna) — Property-based fuzzer dari Trail of Bits
- [Medusa](https://github.com/crytic/medusa) — Parallel fuzzer berbasis go-ethereum
- [Gambit](https://github.com/Certora/gambit) — Mutation testing untuk Solidity

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — terutama invariant yang sulit Anda rumuskan)*
