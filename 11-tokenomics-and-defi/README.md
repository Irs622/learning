# 11 — Tokenomics & DeFi

> **Level**: 4 — Financial Protocol Engineering
> **Phase**: 11 of 13
> **Estimated Time**: 🚀 Intensif 21–30 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 8–11 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [08-smart-contract-security](../08-smart-contract-security/README.md) ✅ | [07-smart-contract-testing](../07-smart-contract-testing/README.md) ✅
> **Status verifikasi**: **Reviewed (parsial)** · 9 Okt 2026 · contoh numerik dihitung ulang; kode belum diuji — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menganalisis **tokenomics**: supply, emisi, vesting, utilitas, dan mekanisme *value accrual*.
- Menurunkan dan mengimplementasikan **Automated Market Maker** constant product (`x · y = k`), termasuk fee, price impact, dan LP token.
- Menjelaskan arsitektur **Uniswap V2** (Factory, Pair, Router, flash swap, TWAP) dan perbedaan inti **V3** (concentrated liquidity).
- Menghitung dan menjelaskan **impermanent loss**.
- Mengimplementasikan **staking reward** yang efisien dengan pola akumulator `rewardPerToken`.
- Merancang **lending protocol**: overcollateralization, LTV, health factor, likuidasi, dan interest rate model.
- Mengintegrasikan **Chainlink** dan standar vault **ERC-4626** dengan aman.
- **Mengidentifikasi** minimal tiga risiko composability (depeg, read-only reentrancy, token non-standar) pada sebuah integrasi DeFi.

---

## 📋 Prerequisites

- [x] Exploit lab Phase 8 selesai (terutama C4 arithmetic, C5 oracle & flash loan).
- [x] Mampu menulis invariant test dengan handler (Phase 7 C4).
- [x] ERC-20 dari nol (Phase 5) dan memahami allowance.
- [x] Matematika SMA: fungsi, akar kuadrat, persentase, bunga majemuk.

---

## ⚙️ Setup

```bash
cd 11-tokenomics-and-defi/
forge init lab --no-git
cd lab
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-git   # interface AggregatorV3
```

> ⚠️ Kode fase ini ditempatkan di subfolder **`lab/`**. Jangan `forge init .` di folder fase — folder ini sudah berisi `README.md` materi, dan `forge init --force` akan **menimpanya**. Semua path `src/`, `test/`, `script/`, `audits/` di fase ini relatif terhadap `lab/`. `forge init` sudah memasang `forge-std`; hapus contoh `Counter*.sol` bawaan.

Untuk fork test (Uniswap, Aave, Chainlink asli), siapkan `MAINNET_RPC_URL` di `.env` (Phase 7 C5).

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Tokenomics Fundamentals](#c1-tokenomics-fundamentals) | ⬜ |
| **C2** | [AMM: Constant Product Market Maker](#c2-amm-constant-product-market-maker) | ⬜ |
| **C3** | [Uniswap V2 Architecture & V3 Concentrated Liquidity](#c3-uniswap-v2-architecture--v3-concentrated-liquidity) | ⬜ |
| **C4** | [Liquidity Provision & Impermanent Loss](#c4-liquidity-provision--impermanent-loss) | ⬜ |
| **C5** | [Staking & Reward Distribution](#c5-staking--reward-distribution) | ⬜ |
| **C6** | [Lending & Borrowing](#c6-lending--borrowing) | ⬜ |
| **C7** | [Oracles, Vaults (ERC-4626) & Composability Risk](#c7-oracles-vaults-erc-4626--composability-risk) | ⬜ |

---

---

# C1: Tokenomics Fundamentals

## Mental Model: Token = Kebijakan Moneter yang Ditulis dalam Kode

Di Web2, kebijakan harga diatur oleh perusahaan dan bisa diubah kapan saja. Di Web3, aturan supply dan distribusi **di-hardcode** dan bisa diverifikasi siapa pun — termasuk kesalahan desainnya.

## Lima Pertanyaan Tokenomics

```text
1. SUPPLY      → Fixed cap? Inflasi? Siapa yang bisa mint?
2. DISTRIBUSI  → Tim, investor, komunitas, treasury — berapa %?
3. VESTING     → Kapan token yang dialokasikan bisa dijual? (cliff + linear)
4. UTILITAS    → Untuk apa token dipakai? (gas, governance, collateral, akses, diskon fee)
5. VALUE ACCRUAL → Mengapa token bernilai? (fee sharing, buyback & burn, staking yield nyata)
```

## Jenis Supply

| Model | Contoh | Risiko |
|---|---|---|
| **Fixed supply** | BTC (21M) | Deflasi; tidak ada dana untuk insentif jangka panjang |
| **Inflationary** | Emisi reward farming | Tekanan jual dari penerima reward |
| **Burn mechanism** | ETH (EIP-1559 base fee burn) | Bergantung pada aktivitas jaringan |
| **Elastic / rebase** | Algorithmic stablecoin | Spiral kematian jika kepercayaan hilang (UST/LUNA 2022) |

## Vesting Schedule

```text
Allocation: Tim 20% (dari 1.000.000.000)
Cliff 12 bulan, lalu linear 36 bulan

bulan  0–12: 0 token dapat diklaim
bulan 13   : 200M × 1/36 ≈ 5.55M
bulan 48   : 200M (seluruhnya)
```

## Real Yield vs Emission Yield

| | Emission Yield | Real Yield |
|---|---|---|
| Sumber | Token baru dicetak | Fee nyata yang dibayar pengguna protokol |
| Contoh | "APR 1000%!" dari farming | Bagian swap fee DEX, bunga pinjaman |
| Keberlanjutan | Berakhir saat emisi habis; mendilusi holder | Berkelanjutan selama ada pengguna |

> Hubungkan dengan Challenge Phase 5: `TokenStaking` memberi **1% per hari** dengan **minting tanpa batas** → ~3.678% per tahun (1.01³⁶⁵ ≈ 37.8×) jika di-compound. Itu emission yield murni.

## Latihan C1

### Soal 1 — Audit Tokenomics
Sebuah proyek: supply 1B, 40% tim & investor (cliff 3 bulan, vesting 6 bulan), 10% likuiditas, 50% "ecosystem rewards" yang dibagikan dalam 12 bulan lewat farming APR 800%. Token tidak punya utilitas selain governance. Identifikasi minimal 4 red flag.

<details>
<summary>💡 Pembahasan</summary>

1. **Alokasi insider sangat besar (40%)** dengan **vesting sangat pendek** (habis di bulan 9) → tekanan jual besar dalam waktu singkat.
2. **Emisi 50% dalam 12 bulan** → inflasi masif; farmer menjual reward → harga turun → APR (dalam USD) turun → farmer pergi.
3. **APR 800% dari emisi**, bukan real yield → tidak berkelanjutan.
4. **Utilitas hanya governance** tanpa value accrual (tidak ada fee sharing) → tidak ada alasan fundamental untuk memegang token.
5. **Likuiditas hanya 10%** dibandingkan supply yang akan beredar → slippage besar saat penjualan, harga mudah jatuh.

</details>

---

---

# C2: AMM: Constant Product Market Maker

## Dari Order Book ke Rumus

Bursa Web2 memakai **order book** (mencocokkan pembeli dan penjual). Di chain, order book mahal (setiap order = tx). AMM menggantinya dengan **pool** dan **rumus**:

```text
x · y = k

x = reserve token A, y = reserve token B, k = konstan (sebelum fee)
Harga marginal A dalam B = y / x
```

## Menurunkan Rumus Swap

User memasukkan `Δx` token A, menerima `Δy` token B, dan `k` harus tetap:

```text
(x + Δx) · (y − Δy) = x · y
               Δy  = y · Δx / (x + Δx)
```

Dengan fee 0.3% (hanya 99.7% dari input yang "dihitung"):

```text
Δx_eff = Δx · 997 / 1000
Δy     = (Δx · 997 · y) / (x · 1000 + Δx · 997)
```

Inilah `getAmountOut` di Uniswap V2. Fee tetap tinggal di pool → `k` **naik** setelah setiap swap → LP mendapatkan fee melalui kenaikan nilai share-nya.

## Contoh Numerik

```text
Pool: 100 ETH (x) & 200.000 USDC (y)   → harga marginal 2.000 USDC/ETH, k = 20.000.000

Swap 10 ETH → USDC (abaikan fee):
  Δy = 200.000 · 10 / (100 + 10) = 18.181,8 USDC
  Harga efektif = 1.818,2 USDC/ETH      ← lebih buruk dari 2.000
  Price impact ≈ 9,1%
  Harga marginal baru = 181.818,2 / 110 ≈ 1.652,9 USDC/ETH
```

**Price impact** membesar seiring rasio `Δx / x`. Pool dalam (reserve besar) → impact kecil.

## Arbitrase Menjaga Harga

Jika harga pool berbeda dari pasar, arbitrageur membeli di tempat murah dan menjual di tempat mahal sampai harga sama. AMM **tidak tahu harga dunia luar** — ia mengandalkan arbitrase. Konsekuensinya: harga spot AMM **bisa dimanipulasi sementara** (Phase 8 C5).

## Latihan C2

### Soal 2 — Hitung Manual
Pool 1.000 TOKEN / 1.000 USDC, fee 0.3%. (a) Berapa USDC yang didapat saat menjual 100 TOKEN? (b) Berapa price impact-nya? (c) Berapa `k` sebelum dan sesudah swap?

<details>
<summary>💡 Pembahasan</summary>

(a) `Δy = 100 · 997 · 1000 / (1000 · 1000 + 100 · 997) = 99.700.000 / 1.099.700 ≈ 90,66 USDC`.

(b) Harga marginal awal 1 USDC/TOKEN; harga efektif ≈ 0,9066 → price impact (termasuk fee) ≈ **9,34%**.

(c) `k_sebelum = 1.000.000`. Setelah swap: reserve TOKEN = 1.100, USDC ≈ 909,34 → `k_sesudah ≈ 1.000.274` — naik karena fee 0,3 TOKEN tetap di pool.

</details>

### Soal 3 — Implementasi (Hands-On)
Tulis library `AMMMath.sol` dengan `getAmountOut`, `getAmountIn`, dan `quote` (rasio proporsional untuk add liquidity). Uji dengan **fuzz test**: untuk semua input valid, `k` setelah swap ≥ `k` sebelum swap (Phase 7 C3).

**✅ Selesai jika:**
- [ ] `getAmountOut` mereproduksi angka contoh C2 dan Soal 2 secara eksak
- [ ] Fuzz `k_sesudah ≥ k_sebelum` hijau dengan `runs = 10000`
- [ ] Fuzz round-trip: `getAmountIn(getAmountOut(x)) ≤ x`


---

---

# C3: Uniswap V2 Architecture & V3 Concentrated Liquidity

## Komponen V2

```text
┌───────────────┐ createPair(A,B) ┌───────────────────────────────┐
│   Factory     │ ───────────────▶│ Pair (A/B)  — juga ERC-20 LP   │
│ getPair[A][B] │   CREATE2       │  reserve0, reserve1            │
└───────────────┘                 │  mint() / burn() / swap()      │
                                  │  price0CumulativeLast (TWAP)   │
        ┌───────────────┐         └───────────────────────────────┘
User ──▶│    Router     │──transferFrom token ke Pair──▶ Pair.swap()
        │ slippage,     │
        │ deadline, path│
        └───────────────┘
```

| Komponen | Tanggung Jawab | Catatan Keamanan |
|---|---|---|
| **Pair** | Core logic minimal: menyimpan reserve, menegakkan `k` | Tidak memeriksa slippage — itu tugas Router |
| **Router** | UX: `amountOutMin`, `deadline`, multi-hop | Contract periphery; bisa diganti |
| **Factory** | Satu pair per pasangan token, address deterministik (CREATE2) | |

## Detail Penting di `Pair`

- **Pola "transfer dulu, lalu panggil"**: token dikirim ke Pair, lalu `swap()` menghitung input dari selisih `balance − reserve`. Tidak ada `transferFrom` di Pair.
- **LP pertama**: `liquidity = √(x · y) − MINIMUM_LIQUIDITY (1000)`; 1000 unit pertama di-*mint* ke `address(0)` (dikunci permanen). Ini mitigasi share inflation (Phase 8 C4).
- **LP berikutnya**: `liquidity = min(Δx · totalSupply / x, Δy · totalSupply / y)` — kelebihan di salah satu sisi menjadi "donasi".
- **Flash swap**: `swap()` mengirim token **dulu**, memanggil `uniswapV2Call` pada penerima, lalu memeriksa `k` di akhir. Peminjam boleh membayar dengan token mana pun asalkan `k` terpenuhi.
- **`lock` modifier** (reentrancy guard) pada semua fungsi state-changing.

## TWAP Oracle

Di setiap block pertama yang menyentuh pair, V2 mengakumulasi `price × Δtime`:

```text
TWAP(t1, t2) = (priceCumulative(t2) − priceCumulative(t1)) / (t2 − t1)
```

Manipulasi TWAP membutuhkan mempertahankan harga palsu **selama banyak block**, jauh lebih mahal daripada manipulasi spot satu transaksi.

## V3: Concentrated Liquidity (Gambaran)

```text
V2: likuiditas tersebar di harga 0 → ∞     (sebagian besar tidak pernah terpakai)
V3: LP memilih rentang [P_a, P_b]           (modal jauh lebih efisien di rentang aktif)
    - Posisi = NFT (karena tiap posisi unik)
    - Harga dibagi dalam "tick" (1 tick = 0,01%)
    - Di luar rentang: posisi 100% satu token, tidak mendapat fee
    - Fee tier: 0,01% / 0,05% / 0,3% / 1%
```

V3 membuat LP menjadi *aktif* — keuntungan lebih tinggi, tetapi impermanent loss di dalam rentang juga lebih besar.

## V4: Singleton & Hooks (Gambaran)

Uniswap V4 aktif di mainnet sejak **akhir Januari 2025**. Matematika swap di dalam pool tetap memakai concentrated liquidity seperti V3; yang berubah adalah arsitekturnya:

| Fitur | V2/V3 | V4 |
|---|---|---|
| Lokasi pool | Satu contract per pool (dibuat Factory) | Semua pool di satu contract **`PoolManager`** (*singleton*) → membuat pool & multi-hop jauh lebih murah |
| Akuntansi | Token dipindahkan di setiap langkah | **Flash accounting**: perubahan saldo dicatat selama transaksi (memakai *transient storage*, EIP-1153) dan hanya selisih bersih yang dipindahkan di akhir |
| Kustomisasi | Tidak ada (fee tier tetap) | **Hooks**: contract eksternal yang dipanggil sebelum/sesudah inisialisasi, add/remove liquidity, swap, dan donate → dynamic fee, limit order on-chain, TWAMM, dll. |
| ETH | Harus dibungkus WETH | Mendukung ETH native |

> ⚠️ Hooks adalah kode pihak ketiga yang ikut berjalan di setiap swap pada pool tersebut. Saat berinteraksi dengan pool V4, audit hook-nya sama seriusnya dengan audit protokol (lihat Phase 8). Detail resmi: [Uniswap v4 — Architecture](https://developers.uniswap.org/docs/protocols/v4/concepts/architecture).

Untuk latihan di fase ini, **V2 tetap menjadi fondasi** karena matematikanya paling mudah diturunkan dan diimplementasikan sendiri.

## Latihan C3

### Soal 4 — Mengapa Router Terpisah?
Uniswap V2 sengaja tidak memasukkan pengecekan slippage dan deadline ke dalam Pair. Apa keuntungan desain ini? Apa yang terjadi jika user memanggil `Pair.swap()` langsung dari EOA tanpa Router?

<details>
<summary>💡 Pembahasan</summary>

**Keuntungan**: core contract (yang memegang dana) dibuat sekecil dan sesederhana mungkin → lebih mudah diaudit dan immutable selamanya. Fitur UX bisa diperbarui dengan men-deploy Router baru tanpa memindahkan likuiditas.

**Memanggil Pair langsung dari EOA**: user harus mentransfer token ke Pair di **satu transaksi** lalu memanggil `swap()` di **transaksi lain**. Di antara keduanya, siapa pun bisa memanggil `swap()` dan "mengklaim" token yang sudah ada di Pair (karena input dihitung dari `balance − reserve`). Karena itu, interaksi ke Pair harus dilakukan secara atomik oleh contract (Router atau contract Anda sendiri) dengan proteksi slippage sendiri.

</details>

---

---

# C4: Liquidity Provision & Impermanent Loss

## Apa yang Dimiliki LP

LP token = klaim proporsional atas **kedua** reserve + fee yang terakumulasi.

```text
Nilai posisi = (LP_balance / LP_totalSupply) × (reserveA × priceA + reserveB × priceB)
```

## Impermanent Loss (IL)

Saat harga relatif berubah, arbitrase menggeser komposisi pool: LP otomatis **menjual aset yang naik** dan **membeli aset yang turun**. Dibandingkan sekadar *holding* kedua aset:

```text
r  = harga_baru / harga_awal
IL = 2·√r / (1 + r) − 1
```

| Perubahan harga (r) | IL |
|---|---|
| 1,25× | −0,6% |
| 1,5× | −2,0% |
| 2× | −5,7% |
| 4× | −20,0% |
| 0,5× (turun 50%) | −5,7% |

"Impermanent" karena kerugian hilang jika harga kembali ke titik awal — tetapi menjadi permanen saat LP menarik likuiditas di harga berbeda. LP untung hanya jika **fee yang terkumpul > IL**.

## Latihan C4

### Soal 5 — Turunkan Rumus IL
Mulai dari pool `x · y = k` dengan harga awal `P = y/x`. Jika harga menjadi `r·P`, tunjukkan bahwa reserve baru adalah `x' = x/√r` dan `y' = y·√r`, lalu turunkan rumus IL di atas. Tulis penurunannya di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Penurunan lengkap tertulis di Notes, lalu dicocokkan dengan pembahasan
- [ ] Rumus Anda menghasilkan nilai tabel IL (1,25× → −0,6%; 2× → −5,7%; 4× → −20%)

<details>
<summary>💡 Pembahasan</summary>

Harga awal `P = y / x`, dan `x · y = k`. Setelah arbitrase, harga pool menjadi `rP`:

```text
y' / x' = rP   dan   x' · y' = k = x · y = x² · P
⇒ x'² · rP = x² · P  ⇒  x' = x / √r,   y' = rP · x' = y · √r
```

Nilai (dalam token B) jika menjadi LP vs hanya *holding*:

```text
V_LP   = x' · rP + y' = (x/√r) · rP + y√r = y√r + y√r = 2y√r      (karena xP = y)
V_hold = x · rP + y   = yr + y          = y(1 + r)

IL = V_LP / V_hold − 1 = 2√r / (1 + r) − 1
```

</details>


### Soal 6 — Break-even
Pool ETH/USDC menghasilkan fee 0,3% dari volume harian sebesar 20% TVL. Berapa hari LP butuh untuk menutup IL jika harga ETH naik 2×? (Abaikan compounding.)

<details>
<summary>💡 Pembahasan</summary>

Fee harian untuk LP = 0,3% × 20% = **0,06% TVL per hari**. IL pada 2× ≈ **5,7%**. Break-even ≈ 5,7 / 0,06 ≈ **95 hari**. Catatan: dalam praktiknya volume tinggi justru sering terjadi saat harga bergerak tajam, dan sebagian volume adalah arbitrase yang mengekstraksi nilai dari LP (konsep *LVR — loss-versus-rebalancing*).

</details>

---

---

# C5: Staking & Reward Distribution

## Masalah: Loop atas Semua Staker

```solidity
// ❌ Tidak skalabel: gas O(n), akhirnya DoS (Phase 8 C7)
function distribute(uint256 reward) external {
    for (uint256 i; i < stakers.length; i++) {
        rewards[stakers[i]] += reward * balance[stakers[i]] / totalStaked;
    }
}
```

## Solusi: Akumulator `rewardPerToken` (Pola Synthetix StakingRewards)

Simpan **satu angka global**: berapa reward yang sudah diperoleh oleh **1 token** sejak awal.

```text
rewardPerToken(t) = rewardPerTokenStored + (t − lastUpdate) × rewardRate × 1e18 / totalStaked

earned(user) = balance(user) × (rewardPerToken − userRewardPerTokenPaid[user]) / 1e18
             + rewards[user]
```

Setiap kali user stake/withdraw/claim:
1. Update `rewardPerTokenStored` dan `lastUpdate` (global).
2. Simpan `rewards[user] = earned(user)` dan `userRewardPerTokenPaid[user] = rewardPerTokenStored`.
3. Baru ubah balance.

Semua operasi menjadi **O(1)** berapa pun jumlah staker.

```text
Contoh: rewardRate = 10 token/detik
t=0   Alice stake 100         rpt = 0
t=10  Bob stake 100           rpt = 0 + 10×10/100 = 1,0    (Alice earned 100)
t=20  —                       rpt = 1,0 + 10×10/200 = 1,5
      Alice earned = 100 × (1,5 − 0) = 150
      Bob   earned = 100 × (1,5 − 1,0) = 50                Total = 200 = 20 detik × 10 ✔
```

## Bandingkan dengan TokenStaking Phase 5

| | TokenStaking (Phase 5) | StakingRewards |
|---|---|---|
| Sumber reward | Mint tanpa batas (1%/hari per user) | Budget tetap dibagi rata per detik |
| Total emisi | Tidak terbatas, tumbuh dengan TVL | Terbatas & dapat diprediksi |
| APR | Konstan | Turun saat lebih banyak orang stake |

## Latihan C5

### Soal 7 — Precision & Edge Case
Apa yang terjadi pada rumus `rewardPerToken` saat `totalStaked == 0`? Dan jika token reward punya 6 decimals sementara `totalStaked` sangat besar, mengapa reward bisa "hilang"? Bagaimana memitigasi keduanya?

<details>
<summary>💡 Pembahasan</summary>

- **`totalStaked == 0`**: pembagian dengan nol → revert. Implementasi Synthetix mengembalikan `rewardPerTokenStored` tanpa perubahan saat `totalSupply == 0` — konsekuensinya, reward untuk periode tanpa staker **tidak dibagikan ke siapa pun** (terkunci di contract). Desain alternatif: tunda periode reward sampai ada staker pertama, atau sediakan fungsi recover sisa reward.
- **Precision loss**: `(Δt × rewardRate × 1e18) / totalStaked` bisa dibulatkan menjadi 0 jika `rewardRate` kecil (token 6 decimals) dan `totalStaked` besar → update yang sering membuat reward per update selalu 0 → reward hilang. Mitigasi: gunakan faktor presisi lebih besar (misal `1e36`), atau simpan sisa pembulatan.

</details>

### Soal 8 — Implementasi (Hands-On)
Implementasikan `StakingRewards.sol` versi Anda (stake token A, reward token B, periode reward dengan `notifyRewardAmount`). Tulis **invariant**: `Σ earned(user) + Σ claimed ≤ total reward yang dinotifikasi`.

**✅ Selesai jika:**
- [ ] Contoh numerik C5 (Alice 150, Bob 50 setelah 20 detik) direproduksi dalam test
- [ ] Invariant reward hijau
- [ ] Kasus `totalStaked == 0` diuji (tidak revert, perilaku terdokumentasi)


---

---

# C6: Lending & Borrowing

## Mental Model: Pegadaian Tanpa Petugas

```text
User deposit collateral (ETH $10.000)
    │
    ▼
Pinjam stablecoin hingga LTV (misal 75% → maks $7.500)
    │
    ▼
Harga ETH turun → nilai collateral turun
    │
    ▼
Health Factor < 1 → SIAPA PUN bisa melikuidasi:
  bayar sebagian hutang user, ambil collateral + bonus (misal 5%)
```

Tidak ada credit score; keamanan protokol sepenuhnya bergantung pada **overcollateralization** + **likuidasi tepat waktu** + **oracle yang benar**.

## Parameter Inti

| Parameter | Arti | Contoh |
|---|---|---|
| **LTV (Loan-to-Value)** | Maks pinjaman saat membuka posisi | 75% |
| **Liquidation Threshold** | Batas di mana posisi bisa dilikuidasi | 80% |
| **Liquidation Bonus** | Insentif bagi liquidator | 5% |
| **Close Factor** | Maks % hutang yang bisa dilunasi per likuidasi | 50% |
| **Reserve Factor** | Bagian bunga untuk treasury protokol | 10% |

## Health Factor

```text
            Σ (collateral_i × price_i × liquidationThreshold_i)
HF  =  ───────────────────────────────────────────────────────
                       Σ (debt_j × price_j)

HF ≥ 1 → aman,   HF < 1 → bisa dilikuidasi
```

```text
Contoh: collateral 10 ETH @ $2.000, threshold 80%, hutang 12.000 USDC
HF = 10 × 2.000 × 0,8 / 12.000 = 1,33
ETH turun ke $1.500 → HF = 10 × 1.500 × 0,8 / 12.000 = 1,0  → di ambang likuidasi
```

## Interest Rate Model (Kinked)

```text
Utilization U = totalBorrows / totalDeposits

jika U ≤ U_opt:   rate = base + (U / U_opt) × slope1
jika U >  U_opt:  rate = base + slope1 + ((U − U_opt) / (1 − U_opt)) × slope2      (slope2 >> slope1)

Supply rate = borrowRate × U × (1 − reserveFactor)
```

Lonjakan tajam di atas `U_opt` (misal 80%) memaksa peminjam melunasi dan menarik deposan baru, agar likuiditas selalu tersedia untuk withdraw.

## Akuntansi Bunga: Index, Bukan Loop

Seperti `rewardPerToken`, bunga dihitung dengan **borrow index** global yang terus tumbuh:

```text
borrowIndex_baru = borrowIndex_lama × (1 + rate × Δt)
debt(user)       = scaledDebt(user) × borrowIndex
```

## Risiko Khas Lending

- **Bad debt**: harga jatuh terlalu cepat (atau likuidasi macet karena gas mahal/oracle stale) → collateral < hutang.
- **Oracle manipulation** (Phase 8 C5) → borrow berlebihan dengan collateral yang "dinaikkan".
- **Collateral tidak likuid**: liquidator tidak bisa menjual collateral tanpa slippage besar → likuidasi tidak menguntungkan → tidak terjadi.
- **Pembulatan**: hutang harus dibulatkan **ke atas**, collateral ke **bawah** (Phase 8 C4).

## Latihan C6

### Soal 9 — Simulasi Likuidasi
Alice: collateral 5 ETH @ $3.000, liquidation threshold 82,5%, bonus 5%, close factor 50%, hutang 10.000 USDC. (a) Hitung HF. (b) Di harga ETH berapa Alice bisa dilikuidasi? (c) Jika ETH = $2.400, liquidator melunasi hutang maksimum yang diizinkan — berapa ETH yang ia terima dan berapa HF Alice setelahnya?

<details>
<summary>💡 Pembahasan</summary>

(a) `HF = 5 × 3.000 × 0,825 / 10.000 = 1,2375`.

(b) `HF = 1` saat `5 × P × 0,825 = 10.000` → **P ≈ $2.424,24**.

(c) Di $2.400: `HF = 5 × 2.400 × 0,825 / 10.000 = 0,99` → bisa dilikuidasi. Close factor 50% → liquidator melunasi **5.000 USDC**. Collateral yang diterima = `5.000 × 1,05 / 2.400 ≈ 2,1875 ETH`.
Sisa Alice: collateral `2,8125 ETH`, hutang `5.000`. HF baru = `2,8125 × 2.400 × 0,825 / 5.000 ≈ 1,114` → posisi kembali sehat, tetapi Alice kehilangan bonus 5% (~$250).

</details>

---

---

# C7: Oracles, Vaults (ERC-4626) & Composability Risk

## Chainlink dalam Protokol DeFi

```solidity
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

function _price(AggregatorV3Interface feed) internal view returns (uint256) {
    (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
    // TODO (latihan): validasi sesuai Phase 8 Soal 6 (answer > 0, staleness, decimals)
    return uint256(answer);
}
```

Untuk testing gunakan `MockV3Aggregator` agar bisa mensimulasikan crash harga dan feed stale.

## ERC-4626: Tokenized Vault Standard

Antarmuka standar untuk vault berbasis shares (yield aggregator, lending deposit token, LST):

| Fungsi | Arti |
|---|---|
| `deposit(assets, receiver)` → shares | Masukkan aset |
| `mint(shares, receiver)` → assets | Minta jumlah shares tertentu |
| `withdraw(assets, receiver, owner)` → shares | Tarik jumlah aset tertentu |
| `redeem(shares, receiver, owner)` → assets | Tukar shares |
| `convertToShares` / `convertToAssets` | Kurs (tanpa fee/slippage) |
| `previewDeposit/Mint/Withdraw/Redeem` | Simulasi **termasuk** fee & pembulatan |

Aturan pembulatan ERC-4626: setiap konversi dibulatkan **menguntungkan vault** (user menerima sedikit lebih sedikit / membayar sedikit lebih banyak). Ingat **share inflation** (Phase 8 C4) — gunakan virtual shares/offset.

## Money Legos & Risiko Composability

```text
User ─deposit ETH─▶ Lido (stETH) ─collateral─▶ Aave ─borrow USDC─▶ Curve LP ─stake─▶ Convex
         ▲                                                                              │
         └────────────── setiap lapisan menambah risiko: smart contract, oracle, depeg ──┘
```

| Risiko | Contoh Kelas Kejadian |
|---|---|
| **Depeg** | Aset "setara" (stETH/ETH, stablecoin) kehilangan paritas → likuidasi berantai |
| **Read-only reentrancy** | Protokol membaca harga LP saat pool sedang di tengah eksekusi (Phase 8 C2) |
| **Governance attack** | Flash loan token governance untuk meloloskan proposal jahat |
| **Upgrade risk** | Protokol dasar di-upgrade dengan perilaku berbeda |
| **Token non-standar** | Fee-on-transfer/rebasing merusak akuntansi (Phase 7 C5) |

## Latihan C7

### Soal 10 — Mock Oracle Crash (Hands-On)
Dengan `MockV3Aggregator`, tulis test untuk lending protocol Anda (Challenge di bawah) yang mensimulasikan: (a) harga turun 40% dalam satu update, (b) feed berhenti update selama 2 jam, (c) harga 0. Tuliskan perilaku yang **seharusnya** terjadi sebelum Anda menulis test-nya.

**✅ Selesai jika:**
- [ ] Perilaku yang diharapkan untuk ketiga skenario ditulis **sebelum** test
- [ ] Feed stale & harga 0 → aksi yang bergantung pada harga revert; crash 40% → posisi bisa dilikuidasi


---

---

# 📝 Mini Project: Mini DEX — Uniswap V2 Style (Portfolio L7)

## Spesifikasi

```text
CONTRACTS:
  - MiniFactory  : createPair(tokenA, tokenB) via CREATE2, getPair, allPairs
  - MiniPair     : ERC-20 LP, mint/burn/swap, reserve, MINIMUM_LIQUIDITY, lock, TWAP cumulative
  - MiniRouter   : addLiquidity, removeLiquidity, swapExactTokensForTokens (multi-hop),
                   amountOutMin & deadline

FEE: 0,3% untuk LP

SECURITY:
  - Reentrancy lock di Pair
  - Validasi k setelah swap (dengan fee)
  - Tidak ada pembulatan yang menguntungkan user
```

## Deliverable

- [ ] Unit test semua fungsi Router & Pair.
- [ ] Fuzz test: `k` tidak pernah turun setelah swap; add→remove liquidity tidak menghasilkan profit.
- [ ] Invariant test dengan handler (swap, add, remove, donasi token langsung ke pair).
- [ ] Fork test: bandingkan `getAmountOut` Anda dengan Uniswap V2 Router asli untuk pair yang sama.
- [ ] Frontend sederhana (Phase 9) untuk swap & add liquidity.
- [ ] `DESIGN.md`: penjelasan rumus, keputusan desain, perbedaan dari Uniswap V2.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | `MiniFactory` + `MiniPair` (mint/burn/swap) dengan unit & fuzz test `k` |
| 🟡 **Extended** — disarankan | `MiniRouter` multi-hop + invariant test + fork test vs Uniswap V2 |
| 🔴 **Stretch** — untuk portfolio | TWAP oracle, frontend swap, `DESIGN.md` |

### ✅ Kriteria Lulus (Core)

- [ ] Fuzz: `k` setelah swap ≥ `k` sebelum swap (`runs = 10000`)
- [ ] Fuzz: add → remove liquidity tidak pernah menghasilkan token lebih banyak dari yang dimasukkan
- [ ] LP pertama menerima `√(x·y) − 1000` dan 1000 unit terkunci di `address(0)`
- [ ] Swap yang melanggar `k` (input kurang) → revert


---

# 🏆 Challenge: Overcollateralized Lending Protocol (Portfolio L8)

> *Challenge tanpa tutorial. Bangun protokol pinjaman minimal yang aman.*

## Spesifikasi

```text
ASET:
  - Collateral: WETH (mock), harga dari Chainlink (MockV3Aggregator di test)
  - Borrow    : USDC (mock, 6 decimals!)

FUNGSI:
  - deposit(amount) / withdraw(amount)   → withdraw ditolak jika HF < 1 setelahnya
  - borrow(amount) / repay(amount)       → borrow ditolak jika melebihi LTV
  - liquidate(user, repayAmount)         → hanya jika HF < 1, close factor 50%, bonus 5%
  - healthFactor(user) view

BUNGA:
  - Kinked interest rate model (C6), akuntansi via borrowIndex

PARAMETER:
  LTV 75%, Liquidation Threshold 80%, Bonus 5%, Close Factor 50%, U_opt 80%

SECURITY:
  - Validasi oracle (staleness, answer > 0, decimals)
  - Pembulatan berpihak ke protokol
  - CEI + reentrancy guard
  - Tangani perbedaan decimals WETH (18) vs USDC (6)
```

## Tugas Challenge

1. Implementasi + unit test + fuzz test.
2. **Invariant wajib**:
   - Total hutang ≤ total deposit USDC + bunga yang belum dibayar.
   - Tidak ada user dengan HF < 1 yang bisa `borrow` atau `withdraw`.
   - Setelah likuidasi, HF user meningkat (atau posisi tertutup).
3. Skenario stres: crash harga 50% dalam satu block dengan 20 user acak — hitung **bad debt** yang tersisa.
4. Tulis `RISK.md`: asumsi oracle, skenario bad debt, parameter yang paling sensitif, dan apa yang terjadi jika liquidator tidak ada.
5. Jalankan Slither + lakukan self-audit dengan template Phase 8 C8.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | deposit/withdraw/borrow/repay/liquidate + health factor + validasi oracle (bunga boleh 0 dulu) |
| 🟡 **Extended** — disarankan | Kinked interest rate + `borrowIndex` + 3 invariant wajib |
| 🔴 **Stretch** — untuk portfolio | Stress test bad debt (20 user, crash 50%) + `RISK.md` + self-audit |

### ✅ Kriteria Lulus (Core)

- [ ] Borrow melebihi LTV dan withdraw yang membuat HF < 1 → revert
- [ ] Likuidasi hanya mungkin saat HF < 1, dibatasi close factor, dan memberi bonus tepat 5%
- [ ] Contoh numerik C6 Soal 9 (Alice) direproduksi dalam test dengan angka yang sama
- [ ] Harga 0 / feed stale → aksi yang bergantung pada harga revert
- [ ] Perbedaan decimals WETH (18) vs USDC (6) diuji eksplisit


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `k` turun setelah swap di test | Fee dihitung salah atau pembulatan berpihak ke user | Bandingkan dengan rumus `getAmountOut` di C2 dan contoh numerik Soal 2 |
| Health factor/likuidasi meleset jauh | Decimals WETH (18) vs USDC (6) vs oracle (8) tercampur | Normalisasi semua nilai ke satu skala (misal 18 decimals) sebelum dibandingkan |
| `panic: division or modulo by zero (0x12)` | `totalStaked`/`totalSupply` masih 0 | Tangani kasus kosong secara eksplisit (C5 Soal 7) |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 11-tokenomics-and-defi/   # path di bawah relatif ke folder fase; kode ada di lab/

git add .
git commit -m "learn: tokenomics & defi — amm math, uniswap v2, impermanent loss, staking, lending"

git add src/dex/ test/dex/
git commit -m "feat: mini dex uniswap v2 style with factory, pair, router (L7)"

git add src/staking/ test/staking/
git commit -m "feat: staking rewards with rewardPerToken accumulator"

git add src/lending/ test/lending/ RISK.md
git commit -m "feat: overcollateralized lending protocol with kinked rate model (L8)"
```

---

## 🧠 Knowledge Check (12 Pertanyaan)

1. Apa perbedaan emission yield dan real yield? Mengapa yang pertama tidak berkelanjutan?
2. Turunkan rumus `getAmountOut` untuk AMM constant product dengan fee 0,3%.
3. Mengapa `k` naik setelah setiap swap, dan bagaimana LP mendapatkan fee?
4. Apa fungsi `MINIMUM_LIQUIDITY` di Uniswap V2? Serangan apa yang dicegahnya?
5. Bagaimana flash swap bekerja tanpa collateral, dan bagaimana Pair memastikan pinjaman dibayar?
6. Mengapa TWAP lebih sulit dimanipulasi daripada spot price? Apa kelemahannya?
7. Jelaskan impermanent loss dan hitung IL saat harga naik 4×.
8. Mengapa pola `rewardPerToken` skalabel dibanding loop atas semua staker?
9. Definisikan LTV, liquidation threshold, dan health factor. Mengapa threshold > LTV?
10. Mengapa interest rate model punya "kink"? Apa yang terjadi jika utilization mendekati 100%?
11. Ke arah mana konversi ERC-4626 harus dibulatkan, dan mengapa?
12. Berikan dua contoh risiko composability dan bagaimana protokol Anda bisa terdampak.

---

## 📊 Progress Tracker

- [ ] **Setup**: Foundry project, OpenZeppelin, Chainlink interfaces, mainnet RPC untuk fork
- [ ] **C1**: Tokenomics — *supply, distribusi, vesting, utilitas, value accrual*
- [ ] **C2**: AMM — *x·y=k, getAmountOut, price impact, arbitrase*
- [ ] **C3**: Uniswap V2/V3 — *factory/pair/router, MINIMUM_LIQUIDITY, flash swap, TWAP, concentrated liquidity*
- [ ] **C4**: Impermanent Loss — *penurunan rumus, break-even fee*
- [ ] **C5**: Staking — *rewardPerToken accumulator, precision*
- [ ] **C6**: Lending — *LTV, HF, likuidasi, kinked rate, borrow index*
- [ ] **C7**: Oracles, ERC-4626, Composability — *validasi feed, vault standard, money legos*
- [ ] **Exercise**: Soal 1–10
- [ ] **Mini Project**: Mini DEX (L7)
- [ ] **Challenge**: Lending protocol (L8)
- [ ] **Knowledge Check**: 12 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca (Source Code)
- [Uniswap V2 Core](https://github.com/Uniswap/v2-core) · [V2 Periphery](https://github.com/Uniswap/v2-periphery)
- [Uniswap V2 Whitepaper](https://app.uniswap.org/whitepaper.pdf)
- [Staking Rewards — pola Synthetix (Solidity by Example)](https://solidity-by-example.org/defi/staking-rewards/) *(repo Synthetix v2 asli sudah tidak tersedia publik)*
- [Aave V3 Core](https://github.com/aave/aave-v3-core) · [Compound V2](https://github.com/compound-finance/compound-protocol)
- [EIP-4626: Tokenized Vaults](https://eips.ethereum.org/EIPS/eip-4626)

### Konsep & Matematika
- [Uniswap V3 Whitepaper](https://uniswap.org/whitepaper-v3.pdf)
- [Chainlink Data Feeds Docs](https://docs.chain.link/data-feeds)
- [RareSkills — Uniswap V2 Book](https://www.rareskills.io/uniswap-v2-book)

### Analitik
- [DefiLlama](https://defillama.com/) — TVL, fee, revenue per protokol
- [Token Unlocks](https://token.unlocks.app/) — jadwal vesting proyek nyata

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk penurunan rumus IL dari Soal 5)*
