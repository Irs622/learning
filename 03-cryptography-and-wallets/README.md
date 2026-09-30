# 03 — Cryptography & Wallets

> **Level**: 2 — Technical Fundamentals with Code
> **Phase**: 3 of 13
> **Estimated Time**: 7–10 hari
> **Prerequisite**: [02-ethereum-and-evm](../02-ethereum-and-evm/README.md) ✅

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan sifat-sifat kriptografis **Hash Functions** (Keccak-256 & SHA-256) dan mengapa mereka menjadi fondasi keamanan blockchain.
- Memahami matematika di balik **Elliptic Curve Cryptography (secp256k1)** tanpa perlu menjadi ahli matematika.
- Menelusuri seluruh pipeline: **Entropy → Private Key → Public Key → Ethereum Address** secara programatik.
- Memahami mekanisme **ECDSA Digital Signature** — cara menandatangani dan memverifikasi pesan tanpa berbagi Private Key.
- Menjelaskan arsitektur **HD Wallet** (Hierarchical Deterministic Wallet): dari seed phrase 12 kata hingga ribuan keypair yang bisa di-derive.
- Mengetahui apa yang **sebenarnya terjadi** ketika user menekan "Sign" atau "Confirm" di MetaMask.

---

## 📋 Prerequisites

- [x] Memahami konsep transaksi Ethereum dan field `v`, `r`, `s` dari Phase 1.
- [x] Memahami EOA vs Contract Account dari Phase 2.
- [x] Familiar dengan konsep heksadesimal dan byte operations.

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Hash Functions: Keccak-256 & SHA-256](#c1-hash-functions-keccak-256--sha-256) | ⬜ |
| **C2** | [Elliptic Curve Cryptography (ECC & secp256k1)](#c2-elliptic-curve-cryptography-ecc--secp256k1) | ⬜ |
| **C3** | [Private Key → Public Key → Ethereum Address](#c3-private-key--public-key--ethereum-address) | ⬜ |
| **C4** | [Digital Signatures (ECDSA) & ecrecover](#c4-digital-signatures-ecdsa--ecrecover) | ⬜ |
| **C5** | [HD Wallets, Seed Phrases & BIP Standards](#c5-hd-wallets-seed-phrases--bip-standards) | ⬜ |

---

---

# C1: Hash Functions — Keccak-256 & SHA-256

## Mental Model: Mesin Penghancur Dokumen Ajaib

Bayangkan sebuah mesin penghancur dokumen yang memiliki sifat-sifat magis:

1. **Apapun yang Anda masukkan** — 1 kata, 1 buku, seluruh Wikipedia — mesin selalu menghasilkan output yang **sama persis panjangnya** (32 bytes / 256 bits).
2. **Input yang sama → output selalu sama** (deterministik).
3. **Mengubah 1 karakter saja → output berubah total** (avalanche effect).
4. **Tidak mungkin membalikkan output ke input** (one-way / pre-image resistance).
5. **Tidak mungkin menemukan dua input berbeda yang menghasilkan output sama** (collision resistance).

Ini adalah **cryptographic hash function**.

---

## SHA-256 vs Keccak-256

Kedua fungsi ini digunakan di ekosistem blockchain, tapi untuk tujuan yang berbeda:

| Properti | SHA-256 | Keccak-256 |
|---|---|---|
| **Digunakan oleh** | Bitcoin, TLS/SSL, JWT | Ethereum (hampir segalanya) |
| **Output size** | 256 bits (32 bytes) | 256 bits (32 bytes) |
| **Standar** | NIST FIPS 180-4 | NIST SHA-3 *candidate* (tapi Ethereum pakai versi original pre-NIST!) |
| **Catatan Penting** | — | Keccak-256 di Ethereum ≠ SHA3-256! NIST memodifikasi Keccak sebelum standardisasi, Ethereum pakai versi aslinya |

> **⚠️ Jebakan Umum Developer**: `SHA3-256` di library modern (seperti `crypto` Node.js) menghasilkan output yang BERBEDA dari `keccak256` di Solidity/Ethereum. Selalu gunakan library yang secara eksplisit menyebutkan `keccak256` ketika bekerja dengan Ethereum.

---

## Empat Sifat Kriptografis yang Wajib Dipahami

### 1. Pre-image Resistance (One-Way)

```
Mudah: input → hash(input) = output
Mustahil: output → ??? (tidak bisa menemukan input)

Contoh:
  keccak256("password123") = 0x57091b8b...
  Dari 0x57091b8b... → tidak bisa tahu inputnya "password123"
```

Implikasi di Ethereum: Anda bisa mempublikasikan hash dari sebuah data tanpa mengungkap data aslinya (dipakai untuk commit-reveal schemes).

### 2. Collision Resistance

```
Mustahil: menemukan A ≠ B sehingga hash(A) = hash(B)

Output space: 2^256 kemungkinan nilai
= 115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,936
                               ↑ angka ini lebih besar dari jumlah atom di alam semesta yang diamati

Probabilitas collision acak ≈ 1 / 2^256 ≈ 0 (secara praktis mustahil)
```

Implikasi: Dua transaksi berbeda tidak akan pernah menghasilkan hash yang sama. Kita bisa menggunakan hash sebagai **identifier unik** yang dapat dipercaya.

### 3. Avalanche Effect (Sensitivitas Tinggi)

```javascript
// Perubahan 1 bit pada input → seluruh output berubah
keccak256("Ethereum")  = 0x3b82de92...f3a1
keccak256("ethereum")  = 0x9c22ff5f...4d3b  // lowercase 'e' → SEMUA berubah!
keccak256("Ethereum!") = 0x7c8f4a21...8b90  // tambah '!' → SEMUA berubah!
```

Implikasi: Di blockchain, jika seseorang mengubah satu angka di transaksi lama, hash blok tersebut berubah total, membatalkan seluruh rantai blok berikutnya.

### 4. Deterministic

```javascript
// Hari ini, besok, 10 tahun lagi, di komputer manapun:
keccak256("hello") selalu = 0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8
```

Implikasi: Ribuan node Ethereum bisa memverifikasi hash yang sama secara independen dan mencapai konsensus yang identik.

---

## Keccak-256 di Mana-Mana di Ethereum

```text
PENGGUNAAN KECCAK-256 DI ETHEREUM:

1. Block Hash
   blockHash = keccak256(RLP(blockHeader))

2. Transaction Hash (tx hash yang Anda lihat di Etherscan)
   txHash = keccak256(RLP(signedTransaction))

3. Ethereum Address Derivation
   address = keccak256(publicKey)[12:32]

4. Storage Slot untuk Mapping
   slot = keccak256(abi.encode(key, baseSlot))

5. Function Selector
   selector = bytes4(keccak256("transfer(address,uint256)"))

6. Event Topic
   topic = keccak256("Transfer(address,address,uint256)")

7. Solidity keccak256() built-in
   bytes32 hash = keccak256(abi.encodePacked(a, b, c));

8. Smart Contract Code Identifier
   codeHash = keccak256(contractBytecode)
```

---

## Hands-On: Eksplorasi Hash Function

```javascript
// hash-explorer.js
// Jalankan: node hash-explorer.js

import { createHash } from "crypto";

// PERHATIAN: ini menggunakan SHA3-256 (standar NIST), BUKAN keccak256 Ethereum!
// Untuk keccak256 yang kompatibel dengan Ethereum, gunakan library 'js-sha3' atau 'viem'

function sha256(input) {
  return createHash("sha256").update(input).digest("hex");
}

// Demonstrasi sifat hash
console.log("=== SHA-256 Properties Demo ===\n");

// 1. Deterministic
console.log("Deterministic:");
console.log(`sha256("hello") = ${sha256("hello")}`);
console.log(`sha256("hello") = ${sha256("hello")}`);  // Sama persis!
console.log();

// 2. Avalanche Effect
console.log("Avalanche Effect:");
const h1 = sha256("Ethereum");
const h2 = sha256("ethereum");  // hanya lowercase 'e'
console.log(`sha256("Ethereum") = ${h1}`);
console.log(`sha256("ethereum") = ${h2}`);
// Hitung berapa bit yang berbeda
let diffBits = 0;
for (let i = 0; i < h1.length; i += 2) {
  const b1 = parseInt(h1.slice(i, i + 2), 16);
  const b2 = parseInt(h2.slice(i, i + 2), 16);
  const xor = b1 ^ b2;
  diffBits += xor.toString(2).split("1").length - 1;
}
console.log(`Bits yang berbeda: ${diffBits} dari 256 (${((diffBits/256)*100).toFixed(1)}%)`);
console.log();

// 3. Consistent output length
console.log("Consistent Output Length:");
const inputs = ["a", "Hello World", "X".repeat(10000)];
inputs.forEach(input => {
  const h = sha256(input);
  console.log(`sha256("${input.slice(0,20)}${input.length > 20 ? '...' : ''}") = ${h.length / 2} bytes`);
});
```

---

## Latihan C1: Hash Fundamentals

### Soal 1 — Hash Properties Analysis

Setelah memahami keempat sifat hash, jawab pertanyaan berikut:

```text
Sebuah startup Web3 mau membuat sistem "blind auction" (lelang buta):
- Semua peserta submit bid harga mereka secara rahasia (tidak boleh saling tahu)
- Setelah deadline, semua bid diungkap secara bersamaan
- Smart contract menentukan pemenang berdasarkan bid tertinggi
```

**Pertanyaan**:
- a) Mengapa tidak mungkin menyimpan bid plaintext di smart contract (ingat: storage is public!)?
- b) Bagaimana hash function bisa digunakan untuk menyelesaikan masalah ini? Jelaskan skemanya.
- c) Apa kelemahan jika peserta hanya mengirimkan `keccak256(bidAmount)` tanpa tambahan informasi? (Hint: pikirkan tentang precomputation attack)
- d) Mengapa perlu ditambahkan `nonce` / `salt` ke dalam hash? Tulis formula hash yang lebih aman.

<details>
<summary>💡 Pembahasan</summary>

**a)** Karena semua data di storage bisa dibaca oleh siapapun (termasuk peserta lain) menggunakan `eth_getStorageAt`. Jika bid disimpan plaintext, peserta pertama bisa langsung outbid peserta sebelumnya dengan +1 unit.

**b)** Skema **Commit-Reveal**:
```
Phase 1 - COMMIT (sebelum deadline):
  Setiap peserta kirim: keccak256(abi.encodePacked(bidAmount, salt, address))
  Contract simpan: {bidder: commitment_hash}

Phase 2 - REVEAL (setelah deadline commit):
  Setiap peserta ungkap: (bidAmount, salt)
  Contract verifikasi: keccak256(abi.encodePacked(bidAmount, salt, msg.sender)) == stored_hash
  Jika valid: catat bid yang sesungguhnya
```

**c)** Tanpa salt, attacker bisa melakukan **rainbow table / precomputation attack**:
- Bid biasanya range terbatas (misal: 0.1 ETH sampai 10 ETH, dengan step 0.001 ETH = ~10,000 kemungkinan)
- Attacker precompute semua kemungkinan: `{keccak256(0.001): "0.001", keccak256(0.002): "0.002", ...}`
- Dengan tabel ini, attacker bisa decode commitment Anda secara instan!

**d)** Salt / nonce yang unik per peserta membuat precomputation tidak praktis karena ruang pencarian menjadi astronomis besar:
```solidity
bytes32 commitment = keccak256(abi.encodePacked(
    bidAmount,
    salt,           // random number yang hanya peserta yang tahu
    msg.sender      // address peserta (mencegah replay dari address lain)
));
```

</details>

---

### Soal 2 — Keccak-256 vs SHA3-256 Gotcha

**Skenario**: Anda membuat backend Node.js yang perlu menghasilkan function selector yang sama dengan Solidity:

```javascript
// Backend Node.js Anda:
import { createHash } from "crypto";

function getFunctionSelector(signature) {
  const hash = createHash("sha3-256").update(signature).digest("hex");
  return "0x" + hash.slice(0, 8);
}

console.log(getFunctionSelector("transfer(address,uint256)"));
// Output: ???
```

```solidity
// Solidity:
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
// Result: 0xa9059cbb
```

**Pertanyaan**:
- a) Apakah output Node.js di atas akan sama dengan `0xa9059cbb` dari Solidity? Mengapa?
- b) Apa library/method JavaScript yang tepat untuk menghasilkan keccak256 yang kompatibel dengan Ethereum?
- c) Jika Anda salah menggunakan `sha3-256` instead of `keccak256` dalam system yang mengandalkan function selector matching, apa yang terjadi?

<details>
<summary>💡 Pembahasan</summary>

**a)** **TIDAK**. `sha3-256` di Node.js menghasilkan output yang berbeda dari `keccak256` di Ethereum. Ini adalah salah satu jebakan yang paling sering membuat developer senior sekalipun bingung. Ethereum menggunakan versi Keccak yang di-submit ke NIST *sebelum* NIST memodifikasinya untuk standardisasi SHA-3. Perbedaannya ada di "padding scheme" — detail kecil yang menghasilkan output berbeda.

**b)** Library yang tepat:
```javascript
// Pilihan 1: gunakan 'viem' (modern, TypeScript-friendly)
import { keccak256, toBytes } from "viem";
const selector = keccak256(toBytes("transfer(address,uint256)")).slice(0, 10);

// Pilihan 2: gunakan 'ethers'
import { ethers } from "ethers";
const hash = ethers.keccak256(ethers.toUtf8Bytes("transfer(address,uint256)"));
const selector = hash.slice(0, 10); // "0xa9059cbb"

// Pilihan 3: gunakan 'js-sha3' (lightweight)
import { keccak256 } from "js-sha3";
const hash = keccak256("transfer(address,uint256)");
const selector = "0x" + hash.slice(0, 8); // "0xa9059cbb"
```

**c)** Seluruh sistem yang bergantung pada selector matching akan **gagal secara silent**. Contoh: jika backend Anda mengira selector `transfer()` adalah `0xXXXXXXXX` (SHA3-256) padahal EVM mengharapkan `0xa9059cbb` (Keccak-256), calldata yang Anda encode tidak akan pernah berhasil route ke fungsi yang benar. Contract akan mengeksekusi fungsi fallback (atau revert jika tidak ada fallback).

</details>

---

---

# C2: Elliptic Curve Cryptography — ECC & secp256k1

> *Anda tidak perlu menjadi mathematician untuk memahami ini. Yang penting adalah memahami properti-propertinya dan implikasinya terhadap keamanan Web3.*

---

## Mental Model: "Aritmetika yang Tidak Bisa Dibalik"

Bayangkan arloji dengan angka 1–12. Jika saya katakan: "Saya mulai dari angka 3, maju 47 langkah searah jarum jam, hasilnya angka berapa?" → Anda bisa jawab: `(3 + 47) mod 12 = 2`.

Sekarang saya balik: "Saya mulai dari angka 3, hasilnya angka 2. Saya maju berapa langkah?" → Ini jauh lebih sulit tanpa tahu jawabannya (`47`), karena bisa saja `47`, atau `59`, atau `71`... (ada banyak kemungkinan!). Ini adalah intuisi dari **discrete logarithm problem**.

Elliptic Curve Cryptography menggunakan prinsip yang sama, tapi dalam ruang matematika yang jauh lebih kompleks.

---

## Apa itu Kurva Eliptis?

Kurva eliptis adalah himpunan titik yang memenuhi persamaan:

```
y² = x³ + ax + b

Untuk secp256k1 (yang digunakan Ethereum & Bitcoin):
y² = x³ + 7
```

*Catatan: ini kurva eliptis dalam bidang prima (finite field Fp), bukan kurva kontinu di real number. Visualisasi di bawah ini adalah kurva kontinu untuk intuisi.*

```
y² = x³ + 7 (bentuk kontinu untuk visualisasi):

        y
        │    .'''.
        │  .'     '.
    ----│-----------'----. x
        │               |
        │             .'
        │           .'
        └──────────'
```

---

## secp256k1: Parameter Kurva yang Digunakan Ethereum

Nama `secp256k1` terdiri dari:
- `sec` → Standards for Efficient Cryptography
- `p` → Prime field (finite field berbasis bilangan prima)
- `256` → 256-bit
- `k` → Koblitz curve (optimasi khusus)
- `1` → Versi pertama

Parameter kunci:
```
p  = 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1
   = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
   (Bilangan prima yang menentukan ukuran finite field)

G  = (0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
       0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8)
   (Generator point — titik awal, sudah ditentukan oleh standar secp256k1)

n  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
   (Order dari G — berapa kali Anda bisa "tambahkan" G ke dirinya sendiri
    sebelum kembali ke titik tak terhingga)
```

---

## Operasi Point Addition: Matematika di Balik Kunci

Di atas kurva eliptis, kita mendefinisikan operasi **"penjumlahan titik" (point addition)**:

```text
Jika P dan Q adalah titik di kurva, maka P + Q adalah:
1. Tarik garis melalui P dan Q
2. Garis ini memotong kurva di titik ketiga, R'
3. Refleksikan R' terhadap sumbu-x → hasilnya adalah R = P + Q

Special case (Point Doubling: P + P = 2P):
1. Tarik garis tangen di P
2. Garis ini memotong kurva di R'
3. Refleksikan → R = 2P
```

---

## Scalar Multiplication: Operasi Inti ECC

**Scalar multiplication** adalah operasi fundamental ECC:

```
k × G = G + G + G + ... + G  (sebanyak k kali)
      = titik baru di kurva

Dimana:
  k = Private Key (bilangan bulat, 256-bit)
  G = Generator Point (titik tetap, sudah ditentukan standar)
  k × G = Public Key (titik di kurva = pasangan koordinat x, y)
```

**Mengapa aman?**

```
MUDAH: k × G = PublicKey
  (Scalar multiplication: bisa dihitung dalam milidetik bahkan untuk k 256-bit,
   menggunakan "double-and-add" algorithm — analog dengan fast exponentiation)

MUSTAHIL: PublicKey → k
  (Discrete Logarithm Problem: tidak ada algoritma yang efisien untuk
   menemukan k ketika hanya tahu PublicKey dan G)

Waktu komputasi terbaik yang diketahui: O(√n) ≈ O(2^128)
Dengan komputer tercepat sekarang: membutuhkan lebih dari usia alam semesta
```

Ini adalah **asimetri komputasi** yang menjadi fondasi keamanan seluruh sistem kriptografi Ethereum.

---

## Intuisi: Kenapa Aman? (Analogi Warna Cat)

Bayangkan Private Key sebagai "warna rahasia" Anda dan Public Key sebagai "warna campuran" yang Anda bagikan:

```
ALICE:
  Private Key (Warna Rahasia)    = Biru Tua    (hanya Alice yang tahu)
  Generator Point G (Warna Umum) = Kuning      (semua orang tahu)
  
  Public Key = Alice mencampur Biru Tua + Kuning = Warna Hijau Spesifik
               (Alice bagikan Warna Hijau ini ke semua orang)

BOB:
  Private Key (Warna Rahasia) = Merah          (hanya Bob yang tahu)
  
  Public Key = Bob mencampur Merah + Kuning = Warna Oranye Spesifik
               (Bob bagikan Warna Oranye ini ke semua orang)

KEAMANAN:
  Dari Warna Hijau + Kuning → tidak bisa menebak Biru Tua (Private Key Alice)
  Dari Warna Oranye + Kuning → tidak bisa menebak Merah (Private Key Bob)
  
  Mencampur warna mudah (P = k × G)
  "Un-mixing" warna mustahil (k = P / G — Discrete Log Problem)
```

---

## Latihan C2: ECC Mental Models

### Soal 3 — Keamanan Kunci

Private Key Ethereum adalah bilangan integer **acak** antara 1 dan `n-1` dimana `n ≈ 2^256`.

**Pertanyaan**:
- a) Berapa banyak kemungkinan Private Key yang valid?
- b) Jika sebuah komputer bisa menghasilkan dan memeriksa 1 quadrillion (10^15) Private Key per detik, berapa lama waktu yang dibutuhkan untuk memeriksa semua kemungkinan?
- c) Jika seseorang tahu **semua transaksi** yang pernah Anda lakukan (termasuk Public Key Anda), apakah mereka bisa menemukan Private Key Anda?
- d) Apa implikasi jika seseorang menggunakan bilangan yang tidak benar-benar random untuk Private Key mereka? (Hint: pikirkan tentang private key "lemah")

<details>
<summary>💡 Pembahasan</summary>

**a)** Jumlah kemungkinan Private Key ≈ 2^256 ≈ 1.16 × 10^77 (sedikit lebih kecil karena n < 2^256, tapi praktis sama).

**b)** Waktu = 2^256 / 10^15 detik
= 1.16 × 10^77 / 10^15 
= 1.16 × 10^62 detik
= **3.7 × 10^54 TAHUN**

Sebagai perbandingan: usia alam semesta adalah ~1.38 × 10^10 tahun. Jadi bruteforce Private Key Ethereum membutuhkan waktu ~10^44 kali usia alam semesta. Seluruh kekuatan komputasi yang ada di Bumi pun tidak akan mampu.

**c)** Tidak. Mengetahui Public Key tidak membantu. Untuk menemukan Private Key dari Public Key memerlukan memecahkan **Elliptic Curve Discrete Logarithm Problem (ECDLP)** — yang saat ini tidak ada algoritma efisien untuk memecahkannya (bahkan dengan quantum computer terkuat yang ada saat ini).

*Catatan*: Quantum computing (Shor's algorithm) secara teoritis bisa memecahkan ECDLP di masa depan — ini adalah mengapa komunitas kriptografi sedang mengerjakan **post-quantum cryptography**. Ethereum kemungkinan akan perlu migrasi ke algoritma baru dalam beberapa dekade.

**d)** Private Key yang tidak benar-benar random adalah **sangat berbahaya**. Contoh nyata:
- **"Brain wallet"**: beberapa orang pakai keccak256("my password") sebagai Private Key. Attacker melakukan dictionary attack dengan hashing jutaan kata umum.
- **Weak RNG (Random Number Generator)**: Android wallet apps di 2013 punya bug RNG — menghasilkan Private Key yang tidak random, menyebabkan Bitcoin senilai jutaan dolar dicuri.
- **Duplicate nonce di ECDSA**: Jika nonce `k` yang sama dipakai dua kali dalam signing, Private Key bisa diderivasi secara matematis dari dua signature. Sony PS3 kehilangan seluruh sistem DRM-nya karena bug ini.

</details>

---

---

# C3: Private Key → Public Key → Ethereum Address

## Pipeline Lengkap: Dari Entropy ke Address

```text
[1] ENTROPY (Sumber Keacakan)
    │  256 bit random dari Cryptographically Secure RNG
    │  (OS-level: /dev/urandom di Linux, CryptGenRandom di Windows)
    ▼
[2] PRIVATE KEY
    │  Bilangan integer: 1 ≤ k < n  (n = order kurva secp256k1)
    │  Representasi: 32 bytes hex
    │  Contoh: 0x1e99423a4ed27608...
    ▼
[3] PUBLIC KEY (Scalar Multiplication)
    │  K = k × G
    │  Uncompressed: 0x04 + x (32 bytes) + y (32 bytes) = 65 bytes
    │  Compressed:   0x02/0x03 + x (32 bytes)          = 33 bytes
    │  (Ethereum pakai Uncompressed untuk address derivation)
    ▼
[4] KECCAK-256 HASH
    │  hash = keccak256(PublicKey_without_04_prefix)
    │       = keccak256(x_coordinate + y_coordinate)
    │       = 32 bytes
    ▼
[5] AMBIL 20 BYTES TERAKHIR
    │  raw_address = hash[12:32]  (20 bytes = 40 hex chars)
    ▼
[6] EIP-55 CHECKSUM (Mixed-case)
    │  checksummed = applyEIP55(raw_address)
    │  Contoh: "0x5aAeb6053F3E94C9b9A09f33669435E7EF1BeAed"
    ▼
[7] ETHEREUM ADDRESS (FINAL)
    0x5aAeb6053F3E94C9b9A09f33669435E7EF1BeAed
```

---

## Step-by-Step Code Implementation

```javascript
// keypair-generator.js
// Menggunakan 'noble-secp256k1' (library ringan & diaudit)
// Install: npm install @noble/secp256k1

import * as secp256k1 from "@noble/secp256k1";
import { createHash } from "crypto";

// === STEP 1: Generate Private Key ===
function generatePrivateKey() {
  // Gunakan secp256k1.utils.randomPrivateKey() yang pakai CSPRNG OS
  const privateKey = secp256k1.utils.randomPrivateKey();
  return privateKey; // Uint8Array (32 bytes)
}

// === STEP 2: Derive Public Key ===
function getPublicKey(privateKey) {
  // compressed: false → uncompressed public key (65 bytes: 04 + x + y)
  const publicKey = secp256k1.getPublicKey(privateKey, false);
  return publicKey; // Uint8Array (65 bytes)
}

// === STEP 3: Derive Ethereum Address ===
function getEthereumAddress(publicKey) {
  // Hilangkan prefix 0x04 (1 byte pertama), ambil hanya x dan y
  const pubKeyWithoutPrefix = publicKey.slice(1); // 64 bytes (x + y)
  
  // Keccak256 hash dari public key (tanpa prefix)
  // PENTING: gunakan keccak256, bukan sha3-256!
  const hash = keccak256(pubKeyWithoutPrefix); // 32 bytes
  
  // Ambil 20 bytes TERAKHIR (bukan 20 bytes pertama!)
  const rawAddress = hash.slice(-20); // 20 bytes
  
  return "0x" + Buffer.from(rawAddress).toString("hex");
}

// === STEP 4: EIP-55 Checksum ===
function toChecksumAddress(address) {
  address = address.toLowerCase().replace("0x", "");
  const hash = keccak256(Buffer.from(address, "ascii")); // hash dari address string
  const hashHex = Buffer.from(hash).toString("hex");
  
  let checksummed = "0x";
  for (let i = 0; i < address.length; i++) {
    // Jika bit ke-i dari hash adalah 1 → uppercase
    // Jika bit ke-i dari hash adalah 0 → lowercase
    if (parseInt(hashHex[i], 16) >= 8) {
      checksummed += address[i].toUpperCase();
    } else {
      checksummed += address[i];
    }
  }
  return checksummed;
}

// === HELPER: Keccak-256 ===
// Menggunakan noble/hashes karena Node.js crypto.sha3 ≠ keccak256!
import { keccak_256 } from "@noble/hashes/sha3";
function keccak256(data) {
  return keccak_256(data); // Uint8Array → Uint8Array
}

// === DEMO: Generate Complete Keypair ===
const privateKey = generatePrivateKey();
const publicKey = getPublicKey(privateKey);
const rawAddress = getEthereumAddress(publicKey);
const checksumAddress = toChecksumAddress(rawAddress);

console.log("=== Generated Ethereum Keypair ===");
console.log(`Private Key:       0x${Buffer.from(privateKey).toString("hex")}`);
console.log(`Public Key (full): 0x${Buffer.from(publicKey).toString("hex")}`);
console.log(`Public Key X:      0x${Buffer.from(publicKey.slice(1, 33)).toString("hex")}`);
console.log(`Public Key Y:      0x${Buffer.from(publicKey.slice(33)).toString("hex")}`);
console.log(`Address (raw):     ${rawAddress}`);
console.log(`Address (EIP-55):  ${checksumAddress}`);
```

---

## EIP-55: Mixed-Case Checksum Address

Sebelum EIP-55, Ethereum address adalah all-lowercase (atau all-uppercase):
`0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed`

Jika terjadi typo dalam satu karakter, tidak ada cara untuk mendeteksinya secara otomatis.

EIP-55 menambahkan checksum melalui kapitalisasi:
`0x5aAeb6053F3E94C9b9A09f33669435E7EF1BeAed`

```text
Cara kerja EIP-55:
1. Ambil address lowercase: "5aaeb6053f3e..."
2. Hitung keccak256 dari string tersebut
3. Untuk setiap karakter hex a-f:
   - Jika bit di hash = 1 → UPPERCASE
   - Jika bit di hash = 0 → lowercase
4. Karakter 0-9 tidak berubah
```

**Validasi**: Jika Anda mengetik address yang salah, probabilitas deteeksi typo ~99.986% karena kapitalisasi harus pas persis.

---

## Latihan C3: Keypair Engineering

### Soal 4 — Address Derivation Verification

Ethereum Private Key berikut diketahui (ini adalah Private Key test, JANGAN GUNAKAN DI MAINNET):

```
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Ini adalah Private Key pertama yang di-generate oleh Foundry/Anvil (local testnet) — sudah diketahui publik, tidak aman.

**Tugas**:
- a) Gunakan tool atau library untuk menghitung Public Key dari Private Key di atas.
- b) Hitung Ethereum Address yang sesuai.
- c) Verifikasi: address yang Anda hasilkan seharusnya adalah `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (address pertama Anvil). Apakah sesuai?

*Hint*: Gunakan script `keypair-generator.js` di atas, atau gunakan Foundry CLI: `cast wallet address --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

---

### Soal 5 — "Vanity Address" Analysis

Beberapa orang membuat **"vanity address"** — address dengan pola tertentu, misalnya:

```
0x00000000219ab540356cBB839Cbe05303d7705Fa  (Ethereum 2.0 Deposit Contract)
0x0000000000000000000000000000000000000000  (Zero/Null Address — tidak ada Private Key!)
```

**Pertanyaan**:
- a) Bagaimana cara menghasilkan vanity address (misalnya yang dimulai dengan `0x1337...`)?
- b) Berapa rata-rata percobaan yang dibutuhkan untuk menemukan address dengan 4 karakter hex yang ditentukan di awal?
- c) Adakah risiko keamanan dari vanity address? Bagaimana dengan address `0x00...00` (null address)?

<details>
<summary>💡 Pembahasan</summary>

**a)** Vanity address dibuat dengan cara **brute force**:
```
loop:
  1. Generate random private key
  2. Derive address dari private key tersebut
  3. Cek apakah address match pattern
  4. Jika match → selesai!
  5. Jika tidak → ulang dari step 1
```
Tool populer: `vanity-eth`, `profanity2` (tapi WASPADA — lihat poin c!)

**b)** Setiap karakter hex memiliki 16 kemungkinan (0-9, a-f). Untuk 4 karakter yang ditentukan:
- Probabilitas match = (1/16)^4 = 1/65,536
- Rata-rata percobaan = 65,536 kali
- Dengan komputer modern yang bisa menghasilkan jutaan keypair/detik: dalam hitungan milidetik.
- Untuk 8 karakter: 16^8 = 4,294,967,296 percobaan → mungkin hitungan jam/hari.

**c)** **YA, ada risiko signifikan!**
- Tool `profanity` (bukan `profanity2`) punya vulnerability: karena menggunakan 32-bit seed untuk inisialisasi random, ruang pencarian sebenarnya hanya 2^32 ≈ 4 miliar kemungkinan — jauh lebih kecil dari 2^256. Attacker bisa brute force semua kemungkinan seed dan mencuri dana dari vanity address yang di-generate oleh tool ini. **Lebih dari $160 juta hilang** akibat bug ini.
- `0x00...00` (null address) adalah address "dead" — tidak ada Private Key yang valid untuk address ini (karena derivation memerlukan langkah matematika yang tidak mungkin menghasilkan address ini secara natural). Token yang dikirim ke null address hilang selamanya.

</details>

---

---

# C4: Digital Signatures (ECDSA) & ecrecover

> *Ini adalah mekanisme fundamental yang membuktikan kepemilikan tanpa mengungkap Private Key. Ini menggantikan seluruh sistem password, session, dan JWT di Web3.*

---

## Mental Model: Amplop Tersegel dengan Cap Pribadi

Bayangkan Anda adalah bangsawan di abad ke-17:
- Anda menulis surat perintah kerajaan.
- Anda leleh lilin di atas amplop dan cap dengan **cincin kerajaan pribadi** Anda (Private Key).
- Siapapun yang menerima surat bisa memeriksa cap tersebut menggunakan **gambar cap resmi** Anda yang sudah dipublikasikan (Public Key).
- Tidak ada yang bisa memalsukan cap Anda tanpa memiliki cincin fisik Anda.
- Bahkan Anda pun tidak bisa menyangkal bahwa Anda yang menandatangani surat tersebut.

ECDSA adalah versi matematika dari sistem cap ini.

---

## ECDSA Signing Algorithm

Ketika Anda menekan "Confirm" di MetaMask, ini yang terjadi secara matematis:

```text
INPUT:
  m = pesan (dalam transaksi: RLP(txFields))
  k_private = Private Key Anda
  G = Generator Point (konstan)

PROSES SIGNING:
  1. Hitung message hash:
     z = keccak256(m)  [32 bytes]
  
  2. Generate random nonce (PENTING: harus unik setiap signing!):
     k_nonce = secure_random()  [1 ≤ k_nonce < n]
  
  3. Hitung point R = k_nonce × G:
     R = (R_x, R_y)
  
  4. Hitung r:
     r = R_x mod n
     (Jika r = 0, ulangi dari step 2)
  
  5. Hitung s:
     s = k_nonce_inverse × (z + r × k_private) mod n
     (Jika s = 0, ulangi dari step 2)
  
  6. Hitung v (recovery id):
     v = parity dari R_y (0 atau 1), plus 27 (atau chainId-based untuk EIP-155)

OUTPUT SIGNATURE:
  (v, r, s) — tiga angka ini adalah tanda tangan Anda
```

---

## ECDSA Verification (ecrecover)

Siapapun yang menerima pesan dan signature bisa memverifikasi:

```text
INPUT:
  z = keccak256(pesan)
  (v, r, s) = signature
  G = Generator Point

PROSES VERIFY:
  1. Hitung u1 = z × s_inverse mod n
  2. Hitung u2 = r × s_inverse mod n
  3. Hitung point X = u1 × G + u2 × PublicKey
  4. Jika X_x mod n == r → signature VALID

ATAU (pendekatan ecrecover):
  Dari (v, r, s) dan z, recover Public Key:
  → Derive Address dari Public Key tersebut
  → Bandingkan dengan expected signer address
```

**Di Solidity**, `ecrecover` adalah built-in function:

```solidity
function verifySignature(
    bytes32 messageHash,
    bytes memory signature
) external pure returns (address signer) {
    // Decode signature menjadi v, r, s
    bytes32 r;
    bytes32 s;
    uint8 v;
    
    assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := byte(0, mload(add(signature, 96)))
    }
    
    // Recover signer address dari signature
    signer = ecrecover(messageHash, v, r, s);
    // Jika invalid: mengembalikan address(0)
}
```

---

## Ethereum Personal Sign: EIP-191

Ketika DApp meminta Anda menandatangani pesan (bukan transaksi), Ethereum menggunakan prefix khusus untuk mencegah serangan tertentu:

```text
TANPA prefix (berbahaya!):
  sign(keccak256("Transfer 100 ETH to attacker"))
  → Bisa disalahgunakan untuk mensimulasikan calldata transaksi!

DENGAN EIP-191 prefix (aman):
  prefixedMessage = "\x19Ethereum Signed Message:\n" + len(message) + message
  sign(keccak256(prefixedMessage))
  → Prefix memastikan pesan ini tidak bisa dikonfusikan dengan transaksi Ethereum
```

```javascript
// Di MetaMask / ethers.js:
const message = "Sign in to MyDApp at nonce: 4829abc";

// ethers.js otomatis menambahkan EIP-191 prefix:
const signature = await signer.signMessage(message);

// Verify di backend:
const recoveredAddress = ethers.verifyMessage(message, signature);
console.log(recoveredAddress === expectedUserAddress); // true
```

---

## EIP-712: Typed Data Signing

EIP-712 adalah evolution dari EIP-191 yang membuat pesan yang ditandatangani lebih readable dan structured:

```text
EIP-191 (unstructured):
  User melihat di MetaMask: "Kamu menandatangani teks acak: 0x1a2b3c..."
  → User tidak tahu apa yang dia tandatangani!

EIP-712 (typed/structured):
  User melihat di MetaMask:
  ┌─────────────────────────────────────┐
  │ Sign in to CoolDApp                 │
  │ Domain: app.cooldapp.com            │
  │ Version: 1                          │
  │ Wallet: 0xYourAddress               │
  │ Nonce: 4829abc                      │
  │ Expiry: Dec 31, 2026                │
  └─────────────────────────────────────┘
  → User tahu persis apa yang ditandatangani!
```

EIP-712 sangat penting untuk **gasless transactions** (meta-transactions), **Permit (EIP-2612)** di ERC-20, dan **NFT marketplace** (sign offer tanpa on-chain transaction).

---

## ⚠️ Critical Security: Signature Replay Attack

Ini adalah salah satu vulnerability paling berbahaya yang berhubungan dengan signatures.

**Skenario**:
```text
1. Aplikasi Anda meminta user menandatangani pesan "Claim 100 USDC reward"
2. User menandatangani → Anda kirim 100 USDC ke user
3. ??? Attacker mengambil signature yang sama dan mengirimnya kembali ke contract!
4. Contract memverifikasi signature → Valid! → Mengirim 100 USDC lagi!
5. Attacker terus replay sampai treasury kosong.
```

**Mengapa ini terjadi?** Karena signature valid selamanya, dan contract tidak "ingat" bahwa signature ini sudah pernah digunakan.

**Solusi**:
```solidity
contract SafeRewardClaimer {
    mapping(bytes32 => bool) public usedSignatures;  // Track used signatures
    uint256 public chainId;
    address public signer;
    
    function claimReward(
        uint256 amount,
        uint256 nonce,          // Unique per claim
        bytes memory signature
    ) external {
        // Konstruksi message hash (termasuk chainId dan contract address!)
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            nonce,
            chainId,            // Cegah cross-chain replay
            address(this)       // Cegah cross-contract replay
        ));
        
        bytes32 ethSignedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        // Cek signature belum pernah digunakan
        require(!usedSignatures[ethSignedHash], "Signature already used");
        
        // Verify signer
        address recovered = ecrecover(ethSignedHash, v, r, s);
        require(recovered == signer, "Invalid signature");
        
        // Mark sebagai used (sebelum transfer — CEI pattern!)
        usedSignatures[ethSignedHash] = true;
        
        // Transfer reward
        IERC20(token).transfer(msg.sender, amount);
    }
}
```

---

## Latihan C4: Signature Engineering

### Soal 6 — Sign and Verify Flow

**Tugas**: Buat script Node.js yang mengimplementasikan sistem sign-in sederhana:

```text
FLOW:
1. "Server" generate nonce random untuk user
2. User menandatangani: "Sign in as [address] with nonce: [nonce]"
3. Server verify signature dan recover address
4. Jika address match → "Login successful!"
```

**Requirements**:
- Gunakan `ethers.js` atau `viem` untuk signing dan verification
- Simulate seluruh flow (signer dan verifier) dalam satu script
- Tampilkan `v`, `r`, `s` dari signature secara terpisah
- Buktikan bahwa signature dari Private Key yang berbeda akan menghasilkan address yang berbeda

*Ini adalah dasar dari sistem "Sign in with Ethereum" (SIWE / EIP-4361) yang dipakai oleh banyak DApp untuk menggantikan email/password login.*

<details>
<summary>Hint 1: Struktur dasar dengan ethers.js</summary>

```javascript
import { ethers } from "ethers";

// Generate wallet untuk demo
const wallet = ethers.Wallet.createRandom();
console.log("Address:", wallet.address);
console.log("Private Key:", wallet.privateKey);

// Server: generate nonce
const nonce = Math.floor(Math.random() * 1000000).toString();
const message = `Sign in as ${wallet.address} with nonce: ${nonce}`;

// User: sign message
const signature = await wallet.signMessage(message);
console.log("Signature:", signature);

// Server: verify signature
const recoveredAddress = ethers.verifyMessage(message, signature);
console.log("Recovered:", recoveredAddress);
console.log("Match:", recoveredAddress.toLowerCase() === wallet.address.toLowerCase());
```

</details>

<details>
<summary>Hint 2: Extract v, r, s dari signature</summary>

```javascript
// Signature adalah 65 bytes (130 hex chars + "0x" prefix)
// Format: r (32 bytes) + s (32 bytes) + v (1 byte)

const sig = ethers.Signature.from(signature);
console.log("v:", sig.v);      // 27 atau 28
console.log("r:", sig.r);      // 32 bytes hex
console.log("s:", sig.s);      // 32 bytes hex
```

</details>

---

### Soal 7 — Signature Replay Vulnerability

**Skenario**: Anda menemukan smart contract DeFi berikut yang memiliki bug:

```solidity
contract VulnerableAirdrop {
    address public owner;
    IERC20 public token;
    
    // ❌ VULNERABLE: tidak ada proteksi replay!
    function claimAirdrop(
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 ethMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        
        address recovered = ecrecover(ethMessage, v, r, s);
        require(recovered == owner, "Invalid signature");
        
        token.transfer(msg.sender, amount);
    }
}
```

**Pertanyaan**:
- a) Identifikasi secara spesifik mengapa contract ini vulnerable.
- b) Jelaskan langkah-langkah eksploit yang akan dilakukan attacker (tanpa perlu menulis kode exploit — cukup narasi langkah demi langkah).
- c) Tulis versi yang sudah diperbaiki dari fungsi `claimAirdrop` yang aman dari replay attack.
- d) Apakah ada vulnerabilitas lain yang Anda lihat di contract ini selain replay attack?

<details>
<summary>💡 Pembahasan</summary>

**a)** Dua masalah utama:
1. **Tidak ada nonce/used-signature tracking**: Signature yang sama bisa disubmit berkali-kali karena contract tidak menyimpan signature yang sudah dipakai.
2. **Tidak ada chainId**: Signature valid di semua EVM-compatible chains. Jika token yang sama ada di Ethereum dan Polygon, signature untuk Polygon bisa di-replay ke Ethereum.

**b)** Langkah eksploit:
1. Alice mengirim claim yang sah: `claimAirdrop(100e18, r, s, v)` → contract transfer 100 token ke Alice.
2. Alice (atau attacker yang mengamati mempool/blockchain) menyimpan signature `(r, s, v)` yang valid.
3. Alice/attacker mengirimkan `claimAirdrop(100e18, r, s, v)` lagi → contract memeriksa: `ecrecover` mengembalikan `owner` → valid! → Transfer 100 token lagi!
4. Ulangi sampai treasury kosong.

**c)** Versi yang aman:
```solidity
contract SafeAirdrop {
    address public owner;
    IERC20 public token;
    
    mapping(address => bool) public hasClaimed; // Track per user
    uint256 public chainId;
    
    constructor() {
        chainId = block.chainid;
    }
    
    function claimAirdrop(
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        // Cek: user belum pernah claim
        require(!hasClaimed[msg.sender], "Already claimed");
        
        // Masukkan chainId dan contract address ke message
        bytes32 message = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            chainId,        // Cegah cross-chain replay
            address(this)   // Cegah cross-contract replay
        ));
        bytes32 ethMessage = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", message
        ));
        
        address recovered = ecrecover(ethMessage, v, r, s);
        require(recovered == owner, "Invalid signature");
        
        // EFFECTS sebelum INTERACTION (CEI pattern!)
        hasClaimed[msg.sender] = true;
        
        token.transfer(msg.sender, amount);
    }
}
```

**d)** Vulnerabilitas tambahan:
- **`ecrecover` tidak revert pada input invalid** — jika signature malformed, `ecrecover` mengembalikan `address(0)`. Jika `owner` entah bagaimana adalah `address(0)`, semua claim akan berhasil tanpa signature valid.  Tambahkan: `require(recovered != address(0), "Invalid signature format");`
- **Tidak ada event logging**: Tidak ada `emit AirdropClaimed(msg.sender, amount)` — membuat audit dan indexing sulit.

</details>

---

---

# C5: HD Wallets, Seed Phrases & BIP Standards

> *Bagaimana MetaMask menghasilkan ratusan keypair berbeda dari satu seed phrase 12 kata? Ini adalah arsitektur yang sangat elegan.*

---

## Masalah yang Dipecahkan

Tanpa HD Wallet, setiap address Ethereum memerlukan Private Key yang **terpisah dan independen**:

```text
ADDRESS 1 → Private Key A (harus di-backup secara terpisah)
ADDRESS 2 → Private Key B (harus di-backup secara terpisah)
ADDRESS 3 → Private Key C (harus di-backup secara terpisah)
...
ADDRESS N → Private Key N (harus di-backup secara terpisah)
```

Jika Anda punya 50 address untuk privacy, Anda harus menyimpan 50 Private Key! Ini adalah nightmare UX dan security.

**HD Wallet solution**: Dari **satu seed** → derive **semua** keypair secara deterministik.

```text
SEED (satu backup)
    │
    ├── Address 1 → Private Key 1 (m/44'/60'/0'/0/0)
    ├── Address 2 → Private Key 2 (m/44'/60'/0'/0/1)
    ├── Address 3 → Private Key 3 (m/44'/60'/0'/0/2)
    │   ...
    └── Address N → Private Key N (m/44'/60'/0'/0/N)
```

Backup seed = backup semua address.

---

## BIP Standards

### BIP-39: Mnemonic Phrase (Seed Words)

**Masalah**: 32 bytes random = angka hex yang panjang dan sulit diingat manusia.
**Solusi BIP-39**: Encode entropy sebagai kata-kata bahasa Inggris yang mudah diingat.

```text
PROSES BIP-39:

1. Generate Entropy (128 bit untuk 12 kata, 256 bit untuk 24 kata):
   entropy = 0x7f2aa4b32c1d... (128 bits random)

2. Hitung checksum:
   checksum_bits = SHA256(entropy)[0:4]  (4 bit pertama dari SHA256)

3. Gabungkan:
   data = entropy + checksum_bits = 132 bits total

4. Bagi menjadi 11-bit chunks:
   132 bits / 11 bits = 12 chunks

5. Map setiap 11-bit chunk ke kata dari wordlist BIP-39 (2048 kata):
   chunk 0x7F2 (decimal: 2034) → "zoo"
   chunk 0x2AA (decimal: 682)  → "jacket"
   ...

6. Hasilnya: 12 seed words
   "zoo jacket nature thunder ..."
```

**BIP-39 Wordlist**: 2048 kata Inggris yang dipilih dengan seksama (mudah dibedakan satu sama lain, tidak ambigu saat dibaca).

---

### BIP-32: Hierarchical Deterministic Wallets

BIP-32 mendefinisikan bagaimana cara men-*derive* keypair anak (child) dari keypair induk (parent):

```text
MASTER KEY DERIVATION:
  mnemonic + passphrase
      │
      │ PBKDF2 (512 bit, 2048 rounds, salt="mnemonic" + passphrase)
      ▼
  512-bit seed
      │
      │ HMAC-SHA512 dengan key "Bitcoin seed"
      ▼
  ┌─────────────────────────────────┐
  │  Master Private Key (256 bits)  │   [kiri 256 bit]
  │  Master Chain Code  (256 bits)  │   [kanan 256 bit]
  └─────────────────────────────────┘

CHILD KEY DERIVATION (dari parent):
  parent_private_key + parent_chain_code + index
      │
      │ HMAC-SHA512
      ▼
  ┌─────────────────────────────────┐
  │  Child Private Key  (256 bits)  │
  │  Child Chain Code   (256 bits)  │
  └─────────────────────────────────┘
```

---

### BIP-44: Derivation Path Standard

BIP-44 standardisasi format "jalan" untuk derive keypair dari HD master key:

```
m / purpose' / coin_type' / account' / change / address_index

Dimana:
  m           = master key
  '           = hardened derivation (lebih aman)
  purpose     = 44 (BIP-44)
  coin_type   = 60 (Ethereum) | 0 (Bitcoin) | 195 (TRON) | ...
  account     = nomor akun (0, 1, 2, ...)
  change      = 0 (external/receiving) | 1 (internal/change)
  address_index = nomor address (0, 1, 2, 3, ...)

CONTOH:
  m/44'/60'/0'/0/0  → Ethereum Account 0, Address 0 (Address PERTAMA MetaMask)
  m/44'/60'/0'/0/1  → Ethereum Account 0, Address 1 (Address KEDUA MetaMask)
  m/44'/60'/1'/0/0  → Ethereum Account 1, Address 0
```

**Inilah kenapa MetaMask bisa menghasilkan address baru dari "Create Account" tanpa meminta Anda backup lagi** — semua address baru adalah derivasi dari seed yang sama dengan index yang berbeda.

---

## Full HD Wallet Architecture

```text
SEED PHRASE (12/24 kata)
    │
    │ BIP-39: PBKDF2 (2048 rounds)
    ▼
MASTER SEED (512 bits)
    │
    │ BIP-32: HMAC-SHA512 ("Bitcoin seed")
    ▼
MASTER KEY + CHAIN CODE
    │
    ├─ m/44'/60'/0'/0/0  ──→  Private Key 1  ──→  Public Key 1  ──→  Address 1
    ├─ m/44'/60'/0'/0/1  ──→  Private Key 2  ──→  Public Key 2  ──→  Address 2
    ├─ m/44'/60'/0'/0/2  ──→  Private Key 3  ──→  Public Key 3  ──→  Address 3
    ├─ m/44'/60'/1'/0/0  ──→  Private Key 4  ──→  Public Key 4  ──→  Address 4
    └─ ...
```

---

## Apa yang Terjadi Saat Anda Klik "Sign" di MetaMask?

```text
USER: Klik "Confirm Transaction" di MetaMask

METAMASK:
1. Ambil unsigned transaction dari DApp
2. Tentukan Private Key untuk address yang aktif:
   → HD derive: m/44'/60'/0'/0/[active_account_index]
3. Bentuk message hash:
   → z = keccak256(RLP(nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0))
4. ECDSA Sign:
   → Generate ephemeral nonce k
   → (v, r, s) = ECDSA.sign(z, privateKey)
5. Attach signature ke transaction
6. RLP-encode signed transaction
7. eth_sendRawTransaction(signedTx) ke RPC

YANG TIDAK PERNAH TERJADI:
❌ Private Key tidak pernah meninggalkan MetaMask
❌ DApp tidak bisa mengakses Private Key
❌ RPC provider tidak pernah melihat Private Key
```

---

## Security: Seed Phrase vs Private Key

| Aspek | Seed Phrase (12/24 words) | Private Key (32 bytes hex) |
|---|---|---|
| **Apa yang dikontrol** | SEMUA address dalam HD wallet | Hanya 1 address |
| **Backup priority** | 🔴 SANGAT KRITIS | 🟡 Penting untuk address tersebut |
| **Jika bocor** | Semua dana di semua address hilang | Hanya dana di 1 address hilang |
| **Representasi** | 12-24 kata bahasa Inggris | 64 karakter hex |
| **Passphrase** | Bisa ditambahkan passphrase 25th word | N/A |
| **Dimana disimpan** | Terenkripsi di MetaMask storage | Bisa export dari MetaMask |

**Best Practices Seed Phrase**:
- ✅ Tulis di kertas fisik (2-3 salinan di lokasi berbeda)
- ✅ Simpan di tempat aman (safe, deposit box)
- ✅ Pertimbangkan metal backup (tahan api/air)
- ❌ JANGAN foto di HP (cloud sync = exposed!)
- ❌ JANGAN kirim via email/chat/screenshot
- ❌ JANGAN ketik di website apapun (termasuk yang mengaku MetaMask support)

---

## Latihan C5: HD Wallet Engineering

### Soal 8 — Seed to Address Derivation

**Tugas**: Buat script yang mengimplementasikan seluruh pipeline HD wallet:

```text
INPUT:  Mnemonic phrase (12 kata)
OUTPUT: List 5 address Ethereum pertama (m/44'/60'/0'/0/0 sampai m/44'/60'/0'/0/4)
```

**Gunakan library**:
```javascript
// Install: npm install @scure/bip39 @scure/bip32 @noble/secp256k1 @noble/hashes
import * as bip39 from "@scure/bip39";
import { wordlist } from "@scure/bip39/wordlists/english";
import { HDKey } from "@scure/bip32";
```

**Test dengan mnemonic Anvil (sudah diketahui publik)**:
```
test test test test test test test test test test test junk
```

Address pertama yang seharusnya dihasilkan: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`

<details>
<summary>Hint: Struktur dasar script</summary>

```javascript
import * as bip39 from "@scure/bip39";
import { wordlist } from "@scure/bip39/wordlists/english";
import { HDKey } from "@scure/bip32";
import { keccak_256 } from "@noble/hashes/sha3";

const mnemonic = "test test test test test test test test test test test junk";

// Validasi mnemonic
console.log("Valid:", bip39.validateMnemonic(mnemonic, wordlist));

// Mnemonic → Seed (512 bit)
const seed = await bip39.mnemonicToSeed(mnemonic); // passphrase = ""

// Seed → HD Master Key
const hdKey = HDKey.fromMasterSeed(seed);

// Derive 5 address pertama
for (let i = 0; i < 5; i++) {
  const path = `m/44'/60'/0'/0/${i}`;
  const childKey = hdKey.derive(path);
  
  // Child private key → public key → address
  const privateKey = childKey.privateKey;
  // ... lanjutkan derivasi address
  console.log(`${path}: [address]`);
}
```

</details>

---

### Soal 9 — Security Analysis: Real-World Hack Scenario

Pada tahun 2022, seorang developer kehilangan $120,000 karena:

```text
1. Developer menemukan script Python di GitHub untuk generate "high-speed" Ethereum vanity address
2. Script tampak legitimate dan mendapat banyak stars
3. Developer menjalankan script tersebut
4. Script menghasilkan address dengan prefix cantik seperti "0x1337..."
5. Developer mentransfer seluruh savings ke address tersebut
6. Keesokan harinya: DANA HILANG SEMUA
```

**Pertanyaan**:
- a) Apa yang mungkin dilakukan script berbahaya tersebut?
- b) Kenapa developer tidak bisa langsung sadar bahwa address tersebut sudah dikompromikan?
- c) Bagaimana cara yang aman untuk generate vanity address?
- d) Apa aturan keamanan umum yang seharusnya diikuti saat mengelola Private Key?

<details>
<summary>💡 Pembahasan</summary>

**a)** Script berbahaya kemungkinan melakukan salah satu dari:
1. **Mengirimkan Private Key ke server attacker**: Script generate keypair valid (address cantik), tapi sebelum menampilkan ke user, ia silently kirim Private Key via HTTP request ke server attacker.
2. **Menggunakan Private Key yang sudah attacker ketahui**: Script tidak benar-benar random — ia memilih dari pool address yang Private Key-nya sudah attacker simpan sebelumnya.
3. **Weak RNG**: Menggunakan random seed yang bisa di-brute-force oleh attacker kemudian.

**b)** Address Ethereum adalah public — tidak ada cara untuk melihat "apakah orang lain tahu Private Key untuk address ini?" dari address itu sendiri. Developer tidak bisa tahu bahwa attacker memiliki Private Key yang sama kecuali setelah uangnya dicuri.

**c)** Cara aman generate vanity address:
- Gunakan **open-source tool yang sudah diaudit** dan diverifikasi oleh komunitas (bukan random GitHub repo)
- Lakukan **offline** (disconnect dari internet) saat generate
- **Baca source code** sebelum menjalankan
- Gunakan tool yang menunjukkan Private Key langsung di terminal (Anda bisa verifikasi tidak ada network request)
- **Jangan gunakan** tool yang "generate di server mereka" untuk Anda

**d)** Aturan keamanan Private Key:
1. **Never share**: Private Key tidak boleh dibagikan ke siapapun, termasuk support MetaMask, auditor, atau "trusted" teammate.
2. **Air-gap generation**: Generate keypair penting di komputer yang tidak pernah terhubung ke internet.
3. **Verify source code**: Selalu baca kode tool sebelum menjalankan, terutama yang berhubungan dengan key generation.
4. **Hardware wallet untuk production/mainnet**: Ledger atau Trezor menjaga Private Key tetap di device fisik, tidak pernah exposed ke komputer host.
5. **Test di testnet dulu**: Selalu test dengan dana kecil atau testnet ETH sebelum menggunakan dengan dana nyata.
6. **Seed phrase ≠ Private Key**: Seed phrase memberikan akses ke SEMUA address — bahkan lebih sensitif.

</details>

---

---

# 📝 Mini Project: Personal Crypto Toolkit

Buat sebuah CLI toolkit yang mengimplementasikan semua konsep yang telah dipelajari:

## Modules yang Harus Dibuat

### Module 1: `hash-tools.js`
```text
Commands:
  node hash-tools.js keccak256 "hello world"    → 0x47173285...
  node hash-tools.js sha256 "hello world"        → 0xb94f6f12...
  node hash-tools.js compare "string1" "string2" → bit difference: 127/256 (49.6%)
  node hash-tools.js selector "transfer(address,uint256)" → 0xa9059cbb
```

### Module 2: `wallet-tools.js`
```text
Commands:
  node wallet-tools.js generate          → Generate fresh keypair (NEVER use on mainnet!)
  node wallet-tools.js from-mnemonic [words...] → Derive address dari seed phrase
  node wallet-tools.js derive-addresses [mnemonic] [count] → Tampilkan N addresses HD wallet
  node wallet-tools.js is-contract [address] → EOA atau Contract?
  node wallet-tools.js checksum [address]   → Convert ke EIP-55 checksum format
```

### Module 3: `signature-tools.js`
```text
Commands:
  node signature-tools.js sign [private-key] [message]  → Output signature (v, r, s)
  node signature-tools.js verify [message] [signature]  → Recover signer address
  node signature-tools.js decode-sig [hex-signature]    → Split menjadi v, r, s
```

## Constraints
- Pure Node.js (no TypeScript compilation required)
- Boleh menggunakan: `@noble/secp256k1`, `@noble/hashes`, `@scure/bip39`, `@scure/bip32`, `ethers`
- Semua operasi kriptografi harus menggunakan library yang sudah diaudit
- Tambahkan warning jelas: "⚠️ FOR EDUCATIONAL USE ONLY - DO NOT USE GENERATED KEYS ON MAINNET"

---

# 🏆 Challenge: "Commit-Reveal Scheme" Implementation

> *Challenge ini tanpa tutorial. Gunakan semua yang Anda pelajari dari C1–C5.*

## Deskripsi
Implementasikan skema **blind auction** (lelang buta) yang aman menggunakan Commit-Reveal pattern.

**Requirements**:

### Part A: Smart Contract
Buat contract `BlindAuction.sol` dengan:
- Phase 1 (COMMIT): Bidder submit `keccak256(bid_amount, salt, bidder_address)`. Durasi commit dapat dikonfigurasi.
- Phase 2 (REVEAL): Bidder ungkap `bid_amount` dan `salt`. Contract verifikasi dan catat bid yang valid.
- Phase 3 (FINALIZE): Pemenang (highest bidder) bisa claim aset/NFT. Bidder yang kalah bisa withdraw ETH mereka.
- Security: Cegah front-running reveal, pastikan tidak ada griefing attack, handle edge case (tidak ada yang reveal).

### Part B: Test
Tulis test menggunakan Foundry (setelah Phase 6) atau JavaScript dengan `ethers`:
- Commit phase: Pastikan commitment disimpan dengan benar.
- Reveal phase: Verifikasi bahwa commitment yang salah di-revert.
- Winner determination: Pastikan highest bidder menang.
- Withdrawal: Semua bidder yang kalah bisa withdraw.
- Edge case: Apa yang terjadi jika pemenang tidak pernah reveal?

---

## 📁 GitHub Task

```bash
cd 03-cryptography-and-wallets/

# Commit materi belajar
git add .
git commit -m "learn: cryptography and wallets — hash functions, ECC, keypairs, ECDSA, HD wallets"

# Commit toolkit
git add .
git commit -m "feat: add personal crypto toolkit CLI (Phase 3 mini project)"

# Commit challenge
git add .
git commit -m "feat: implement blind auction commit-reveal scheme (Phase 3 challenge)"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Apa perbedaan kritis antara `sha3-256` di Node.js standard library dengan `keccak256` yang digunakan Ethereum? Mengapa ini sering menjadi sumber bug?
2. Sebutkan keempat sifat hash function kriptografis. Untuk setiap sifat, berikan satu contoh penggunaannya di Ethereum.
3. Mengapa Private Key Ethereum tidak mungkin di-brute-force meskipun dengan komputer tercepat di dunia?
4. Jelaskan pipeline: `entropy → private key → public key → ethereum address`. Operasi apa yang terjadi di setiap langkah?
5. Apa itu "ephemeral nonce k" dalam ECDSA signing? Apa yang terjadi jika nonce k yang sama digunakan dua kali?
6. Kenapa DApp perlu menambahkan EIP-191 prefix (`"\x19Ethereum Signed Message:\n"`) ketika meminta user menandatangani pesan?
7. Apa perbedaan BIP-39, BIP-32, dan BIP-44? Apa peran masing-masing dalam arsitektur HD Wallet?
8. Derivation path `m/44'/60'/0'/0/3` mengacu ke address apa di MetaMask? Jelaskan setiap komponen path tersebut.
9. Jelaskan Signature Replay Attack. Sebutkan tiga informasi yang sebaiknya dimasukkan ke dalam message hash untuk mencegahnya.
10. Anda menemukan sebuah "Ethereum private key generator tool" open-source di GitHub dengan 500 stars. Jelaskan proses due-diligence yang seharusnya Anda lakukan sebelum menggunakannya.

---

## 📊 Progress Tracker

- [ ] **C1**: Hash Functions — *Keccak-256, SHA-256, 4 sifat kriptografis*
- [ ] **C2**: ECC & secp256k1 — *Scalar multiplication, Discrete log, Security basis*
- [ ] **C3**: Private Key → Address Pipeline — *Derivation, EIP-55 checksum*
- [ ] **C4**: ECDSA Signatures — *Sign, Verify, ecrecover, EIP-191, EIP-712, Replay Attack*
- [ ] **C5**: HD Wallets & BIPs — *BIP-39/32/44, Seed phrase, Derivation paths*
- [ ] **Exercise**: Soal 1–9 (termasuk kode implementasi)
- [ ] **Mini Project**: Personal Crypto Toolkit CLI
- [ ] **Challenge**: Blind Auction Commit-Reveal Contract
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Mastering Ethereum: Chapter 4 — Keys & Addresses](https://github.com/ethereumbook/ethereumbook/blob/develop/04keys-addresses.asciidoc)
- [Ethereum.org: Accounts](https://ethereum.org/en/developers/docs/accounts/)
- [EIP-55: Checksum Address Encoding](https://eips.ethereum.org/EIPS/eip-55)
- [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191)
- [EIP-712: Typed Structured Data Hashing](https://eips.ethereum.org/EIPS/eip-712)
- [BIP-39: Mnemonic Code for Generating Deterministic Keys](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [BIP-44: Multi-Account Hierarchy for Deterministic Wallets](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)

### Tools
- [Ethereum Signature Database](https://www.4byte.directory/)
- [Ian Coleman BIP-39 Tool](https://iancoleman.io/bip39/) *(pakai offline untuk keamanan!)*
- [Vanity ETH Address Generator](https://vanity-eth.tk/) *(open source, cek source code-nya!)*

### Libraries (Audit-Friendly, Digunakan di Production)
- [`@noble/secp256k1`](https://github.com/paulmillr/noble-secp256k1) — ECC operations
- [`@noble/hashes`](https://github.com/paulmillr/noble-hashes) — Keccak-256, SHA-256
- [`@scure/bip39`](https://github.com/paulmillr/scure-bip39) — BIP-39 mnemonic
- [`@scure/bip32`](https://github.com/paulmillr/scure-bip32) — BIP-32 HD wallet

### Security Deep-Dive
- [Profanity Tool Vulnerability Analysis](https://blog.1inch.io/a-vulnerability-disclosed-in-profanity-an-ethereum-vanity-address-tool/)
- [ECDSA Nonce Reuse Attack (Sony PS3 Case)](https://fahrplan.events.ccc.de/congress/2010/Fahrplan/attachments/1780_27c3_console_hacking_2010.pdf)
- [Sign In With Ethereum (EIP-4361)](https://eips.ethereum.org/EIPS/eip-4361)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi)*
