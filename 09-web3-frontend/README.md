# 09 — Web3 Frontend

> **Level**: 3 — Full-Stack DApp
> **Phase**: 9 of 13
> **Estimated Time**: 🚀 Intensif 14–21 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 5–8 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [05-smart-contract-development](../05-smart-contract-development/README.md) ✅ | [08-smart-contract-security](../08-smart-contract-security/README.md) ✅

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menjelaskan arsitektur **DApp**: browser → wallet (EIP-1193) → RPC node → smart contract.
- Menggunakan **Viem** untuk membaca state, mengirim transaksi, encode/decode ABI, dan menangani unit (`wei`, `gwei`, decimals).
- Menggunakan **Wagmi** + **TanStack Query** untuk state management Web3 di React/Next.js.
- Mengintegrasikan **wallet connection** (RainbowKit/WalletConnect, EIP-6963 multi-injected provider).
- Mendesain **transaction UX** yang jujur: simulasi, pending, konfirmasi, error yang bisa dibaca manusia.
- Mengimplementasikan **message signing**: Sign-In with Ethereum (EIP-4361) dan EIP-712 typed data.
- Menerapkan **frontend security**: approval yang aman, chain mismatch, env variable, dan anti-phishing.

---

## 📋 Prerequisites

- [x] React + TypeScript + Next.js (Phase 0 — Web2 baseline).
- [x] Contract Phase 5 sudah bisa di-deploy ke anvil & Sepolia.
- [x] Memahami ABI, function selector, dan event topic (Phase 2 & 6).
- [x] Memahami ECDSA & EIP-712 (Phase 3).

---

## ⚙️ Setup

```bash
cd 09-web3-frontend/

# Next.js App Router + TypeScript
npx create-next-app@latest dapp --typescript --app --eslint --src-dir

cd dapp
npm install viem wagmi @tanstack/react-query @rainbow-me/rainbowkit
```

Environment (`.env.local` — **jangan commit**):

```bash
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id   # dari cloud.reown.com
NEXT_PUBLIC_SEPOLIA_RPC_URL=https://...
```

> ⚠️ Semua variabel berprefix `NEXT_PUBLIC_` **dikirim ke browser**. Jangan pernah menaruh private key atau API key rahasia di sana.

Untuk pengembangan lokal jalankan `anvil` dan deploy contract Phase 5 ke sana (lihat Phase 5 — 🚀 Deployment).

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Arsitektur DApp & Wallet Provider](#c1-arsitektur-dapp--wallet-provider) | ⬜ |
| **C2** | [Viem: Client, ABI & Units](#c2-viem-client-abi--units) | ⬜ |
| **C3** | [Wagmi: React Hooks untuk Ethereum](#c3-wagmi-react-hooks-untuk-ethereum) | ⬜ |
| **C4** | [Transaction Lifecycle & UX](#c4-transaction-lifecycle--ux) | ⬜ |
| **C5** | [Message Signing: SIWE & EIP-712](#c5-message-signing-siwe--eip-712) | ⬜ |
| **C6** | [Events, Real-Time Update & Multicall](#c6-events-real-time-update--multicall) | ⬜ |
| **C7** | [Frontend Security](#c7-frontend-security) | ⬜ |

---

---

# C1: Arsitektur DApp & Wallet Provider

## Mental Model: Frontend Tidak Punya Database

```text
WEB2                                       WEB3
──────────────────────────────             ───────────────────────────────────────
Browser ──REST──▶ Backend ──SQL──▶ DB      Browser ──JSON-RPC (read)──▶ RPC Node ──▶ EVM state
         ◀──JSON──                                  │
Auth: session/JWT                                   └─EIP-1193 request──▶ Wallet ──signed tx──▶ RPC Node
Write: POST /api/...                       Auth: kepemilikan private key (signature)
                                            Write: transaksi yang ditandatangani user
```

- **Read** (gratis): frontend memanggil RPC node langsung (`eth_call`, `eth_getLogs`).
- **Write** (bayar gas): frontend **meminta** wallet menandatangani transaksi. Frontend tidak pernah melihat private key.

## EIP-1193: Interface Standar Wallet

Setiap wallet injected (MetaMask, Rabby, Coinbase) mengekspos objek provider:

```ts
const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
const chainId  = await window.ethereum.request({ method: "eth_chainId" });

window.ethereum.on("accountsChanged", (accs) => { /* user ganti akun */ });
window.ethereum.on("chainChanged",    (id)   => { /* user ganti network */ });
```

## EIP-6963: Banyak Wallet, Satu Browser

Dulu setiap wallet berebut `window.ethereum` (yang terakhir di-load "menang"). EIP-6963 membuat wallet **mengumumkan diri** lewat event, sehingga DApp bisa menampilkan daftar semua wallet yang terpasang. Wagmi/RainbowKit menangani ini secara otomatis.

## Jenis Koneksi Wallet

| Jenis | Cara Kerja | Contoh |
|---|---|---|
| **Injected** | Extension menyuntikkan provider ke halaman | MetaMask, Rabby |
| **WalletConnect** | QR code / deep link, relay terenkripsi ke mobile wallet | Trust Wallet, Rainbow |
| **Smart wallet / embedded** | Wallet berbasis passkey/email, sering ERC-4337 (Phase 13) | Coinbase Smart Wallet |

## Latihan C1

### Soal 1 — Siapa Melakukan Apa?
Untuk aksi "user menekan tombol **Donate 0.1 ETH**" di DApp Crowdfunding, urutkan langkah berikut dan tandai komponen yang menjalankannya (Frontend / Wallet / RPC Node / Validator / Contract): estimasi gas, menampilkan popup konfirmasi, menandatangani tx, broadcast ke mempool, eksekusi `donate()`, emit event `Donated`, frontend menampilkan "Success".

<details>
<summary>💡 Pembahasan</summary>

1. **Frontend** menyusun calldata `donate()` + `value`, (opsional) simulasi via RPC.
2. **Frontend → Wallet**: `eth_sendTransaction` (EIP-1193).
3. **Wallet** meminta estimasi gas & fee ke **RPC Node**, menampilkan **popup konfirmasi**.
4. **Wallet** menandatangani tx dengan private key setelah user setuju.
5. **Wallet → RPC Node**: `eth_sendRawTransaction` → mempool (Phase 1).
6. **Validator** memasukkan tx ke block; **Contract** mengeksekusi `donate()` dan **emit `Donated`**.
7. **Frontend** polling receipt via RPC (`eth_getTransactionReceipt`), lalu menampilkan **Success** dan me-refresh data.

Perhatikan: frontend hanya mendapatkan **tx hash** di langkah 5 — bukan hasil eksekusi.

</details>

---

---

# C2: Viem: Client, ABI & Units

## Dua Jenis Client

```ts
import { createPublicClient, createWalletClient, custom, http } from "viem";
import { sepolia } from "viem/chains";

// Public client: READ — tidak butuh wallet
export const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL),
});

// Wallet client: WRITE — butuh signer (wallet user)
export const walletClient = createWalletClient({
  chain: sepolia,
  transport: custom(window.ethereum!),
});
```

## ABI dengan Type Safety

```ts
// abi/crowdfunding.ts — `as const` membuat TypeScript tahu nama fungsi & tipe argumen
export const crowdfundingAbi = [
  { type: "function", name: "donate", stateMutability: "payable", inputs: [], outputs: [] },
  { type: "function", name: "totalRaised", stateMutability: "view", inputs: [],
    outputs: [{ type: "uint256" }] },
  { type: "event", name: "Donated", inputs: [
      { name: "donor", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "newTotal", type: "uint256", indexed: false } ] },
] as const;
```

> 💡 Jangan menulis ABI manual untuk project nyata. Ambil dari `out/Crowdfunding.sol/Crowdfunding.json` hasil `forge build`, atau gunakan `@wagmi/cli` dengan plugin Foundry untuk generate otomatis.

## Read & Write

```ts
const raised = await publicClient.readContract({
  address: CROWDFUNDING_ADDRESS,
  abi: crowdfundingAbi,
  functionName: "totalRaised",
});                                   // bigint — BUKAN number!

// Simulasi dulu: menangkap revert SEBELUM user membayar gas
const { request } = await publicClient.simulateContract({
  account,
  address: CROWDFUNDING_ADDRESS,
  abi: crowdfundingAbi,
  functionName: "donate",
  value: parseEther("0.1"),
});
const hash    = await walletClient.writeContract(request);
const receipt = await publicClient.waitForTransactionReceipt({ hash });
```

## Units: Sumber Bug Nomor Satu di Frontend

```ts
import { parseEther, formatEther, parseUnits, formatUnits } from "viem";

parseEther("1.5")             // 1500000000000000000n (wei)
formatEther(1500000000000000000n) // "1.5"
parseUnits("100", 6)          // USDC: 100000000n
formatUnits(100000000n, 6)    // "100"
```

| ❌ Jangan | ✅ Lakukan |
|---|---|
| `Number(balance) / 1e18` | `formatUnits(balance, decimals)` |
| Asumsikan semua token 18 decimals | Baca `decimals()` dari contract |
| Simpan amount sebagai `number` | Gunakan `bigint` sampai tampil ke UI |

`Number` di JavaScript hanya presisi sampai 2⁵³ (~9×10¹⁵). `1 ETH = 10¹⁸ wei` sudah melewati batas itu.

## Latihan C2

### Soal 2 — Script Viem (Hands-On)
Tanpa React, tulis script Node (`scripts/read.ts`) yang menggunakan Viem untuk: (a) membaca `totalSupply`, `decimals`, `symbol` ERC20Token Anda di Sepolia, (b) memformat supply ke angka yang bisa dibaca manusia, (c) mencari 10 event `Transfer` terakhir dengan `getLogs`. Jalankan dengan `npx tsx scripts/read.ts`.

**✅ Selesai jika:**
- [ ] Script berjalan tanpa error terhadap Sepolia (`npx tsx scripts/read.ts`)
- [ ] Total supply tampil presisi penuh dan sama dengan `cast call <token> "totalSupply()(uint256)"`
- [ ] 10 event `Transfer` tampil dengan `from`, `to`, `value` ter-decode


### Soal 3 — Bug Presisi
Mengapa kode berikut menampilkan angka yang salah untuk balance besar, dan apa perbaikannya?

```ts
const display = (Number(balance) / 10 ** 18).toFixed(4);
```

<details>
<summary>💡 Pembahasan</summary>

`Number(balance)` mengonversi `bigint` ke float 64-bit yang hanya presisi ~15–16 digit signifikan. Balance seperti `123456789012345678901234n` kehilangan digit terakhir sebelum dibagi. Selain itu, token dengan decimals ≠ 18 akan salah total. Perbaikan: `formatUnits(balance, decimals)` (menghasilkan string presisi penuh), lalu format tampilan (pembulatan, pemisah ribuan) **setelahnya** di level string/`Intl.NumberFormat` dengan kesadaran bahwa itu hanya untuk tampilan.

</details>

---

---

# C3: Wagmi: React Hooks untuk Ethereum

## Konfigurasi

```tsx
// src/app/providers.tsx
"use client";
import { WagmiProvider, http } from "wagmi";
import { sepolia, anvil } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { RainbowKitProvider, getDefaultConfig } from "@rainbow-me/rainbowkit";
import "@rainbow-me/rainbowkit/styles.css";

const config = getDefaultConfig({
  appName: "Phase 5 DApp",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains: [anvil, sepolia],
  transports: {
    [anvil.id]: http("http://127.0.0.1:8545"),
    [sepolia.id]: http(process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL),
  },
  ssr: true,
});

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>{children}</RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

## Hooks Inti

| Hook | Fungsi |
|---|---|
| `useAccount()` | Address, status koneksi, chain aktif |
| `useBalance({ address })` | Saldo ETH/token |
| `useReadContract({...})` | Panggil fungsi `view` (cache + refetch otomatis via TanStack Query) |
| `useReadContracts({ contracts })` | Banyak read sekaligus (multicall) |
| `useSimulateContract({...})` | Simulasi write sebelum dikirim |
| `useWriteContract()` | Kirim transaksi → mengembalikan `hash` |
| `useWaitForTransactionReceipt({ hash })` | Status konfirmasi |
| `useWatchContractEvent({...})` | Subscribe event |
| `useSwitchChain()` | Minta wallet pindah network |

## Contoh Komponen: Read + Write

```tsx
"use client";
import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatEther, parseEther } from "viem";

export function DonateCard() {
  const { data: raised, refetch } = useReadContract({
    address: CROWDFUNDING_ADDRESS, abi: crowdfundingAbi, functionName: "totalRaised",
  });

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // TODO (latihan): panggil refetch() ketika isSuccess berubah menjadi true

  return (
    <div>
      <p>Raised: {raised !== undefined ? formatEther(raised) : "…"} ETH</p>
      <button
        disabled={isPending || isConfirming}
        onClick={() => writeContract({
          address: CROWDFUNDING_ADDRESS, abi: crowdfundingAbi,
          functionName: "donate", value: parseEther("0.01"),
        })}
      >
        {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : "Donate 0.01 ETH"}
      </button>
      {error && <p role="alert">{error.message}</p>}
    </div>
  );
}
```

## SSR & Hydration

Next.js merender di server, di mana **tidak ada wallet**. Akibatnya status `connected` di server ≠ di browser → *hydration mismatch*. Solusi: `ssr: true` di config wagmi, render komponen wallet hanya di client (`"use client"`), dan hindari menampilkan data akun sebelum komponen ter-mount.

## Latihan C3

### Soal 4 — Hooks (Hands-On)
Buat halaman `/token` yang menampilkan nama, simbol, total supply, dan saldo user untuk ERC20Token Phase 5, menggunakan **satu** `useReadContracts` (bukan empat `useReadContract`). Tambahkan form `transfer(to, amount)` dengan validasi address (`isAddress`) dan amount (`parseUnits`).

**✅ Selesai jika:**
- [ ] Tab Network: data token dimuat dengan **satu** request multicall
- [ ] Address tidak valid / amount > saldo ditolak **sebelum** wallet terbuka
- [ ] Saldo ter-refresh otomatis setelah transfer terkonfirmasi


---

---

# C4: Transaction Lifecycle & UX

## State Machine Sebuah Transaksi

```text
 idle ──klik──▶ simulating ──ok──▶ awaiting-signature ──sign──▶ pending (hash) ──mined──▶ confirmed
                    │                     │                         │                      │
                    ▼                     ▼                         ▼                      ▼
              revert terdeteksi     user reject              dropped / replaced       reverted on-chain
              (tampilkan alasan)   (bukan error!)           (speed-up / cancel)       (status = 0)
```

Setiap state butuh UI yang berbeda. Kesalahan UX umum: menganggap "user menolak di wallet" sebagai error merah, atau menampilkan "Success" saat baru mendapat tx hash.

## Decode Error dari Contract

Custom error (Phase 4) bisa di-decode jika ABI-nya menyertakan definisi error:

```ts
import { BaseError, ContractFunctionRevertedError, UserRejectedRequestError } from "viem";

function toUserMessage(err: unknown): string {
  if (err instanceof BaseError) {
    if (err.walk((e) => e instanceof UserRejectedRequestError)) return "Transaksi dibatalkan.";
    const revert = err.walk((e) => e instanceof ContractFunctionRevertedError);
    if (revert instanceof ContractFunctionRevertedError) {
      switch (revert.data?.errorName) {
        case "CampaignEnded": return "Kampanye sudah berakhir.";
        case "ZeroAmount":    return "Jumlah donasi tidak boleh 0.";
        // TODO (latihan): petakan seluruh custom error Crowdfunding
      }
    }
  }
  return "Terjadi kesalahan. Coba lagi.";
}
```

## Konfirmasi & Reorg

`waitForTransactionReceipt({ hash, confirmations: n })`. Di L1, 1 konfirmasi biasanya cukup untuk UX, tetapi untuk nilai besar tunggu lebih banyak atau sampai *finalized* (Phase 1 — finality). Di L2 (Phase 12), "confirmed" oleh sequencer berbeda dengan "final di L1".

## Optimistic UI

Menampilkan hasil sebelum konfirmasi membuat aplikasi terasa cepat, tetapi **harus bisa di-rollback** jika tx revert/dropped. Tandai data optimistic secara visual (misal: abu-abu + spinner) sampai receipt diterima.

## Latihan C4

### Soal 5 — Matriks UX
Buat tabel untuk setiap state di diagram di atas: **Teks tombol**, **Tombol disabled?**, **Pesan ke user**, **Aksi yang tersedia** (retry, lihat di explorer, dsb).

**✅ Selesai jika:**
- [ ] Tabel mencakup semua state di diagram (termasuk *user reject*, *dropped/replaced*, *reverted on-chain*)
- [ ] *User reject* tidak diperlakukan sebagai error merah; *confirmed* hanya setelah receipt `status = success`


### Soal 6 — Approve + Action
Untuk men-stake di `TokenStaking`, user butuh dua transaksi: `approve` lalu `stake`. Rancang alur UI-nya: kapan memeriksa allowance, bagaimana menampilkan progres "1/2" dan "2/2", dan apa yang terjadi jika user menutup tab di antara keduanya.

<details>
<summary>💡 Pembahasan</summary>

- Baca `allowance(user, staking)` saat amount diisi. Jika `allowance >= amount`, **lewati** langkah approve.
- Tampilkan stepper: `① Approve LRN` → `② Stake`. Langkah ② disabled sampai receipt approve sukses (bukan hanya hash).
- Approve **sebesar `amount`** secara default, bukan `maxUint256`. Jika ingin menawarkan "unlimited", jadikan opsi eksplisit dengan peringatan (lihat C7).
- Jika tab ditutup setelah approve: saat kembali, allowance sudah cukup → UI langsung menampilkan langkah ②. Karena state berasal dari chain, bukan dari memori frontend, alur ini otomatis tahan terhadap refresh.
- Alternatif lebih baik: **EIP-2612 `permit`** (signature off-chain + satu transaksi) jika token mendukungnya.

</details>

---

---

# C5: Message Signing: SIWE & EIP-712

## Kapan Signature, Kapan Transaksi?

| | Transaksi | Signature (off-chain) |
|---|---|---|
| Biaya | Gas | Gratis |
| Mengubah state on-chain | Ya | Tidak (kecuali di-submit oleh contract) |
| Contoh | `donate()`, `stake()` | Login, `permit`, order di marketplace off-chain, gasless voting (Snapshot) |

## Sign-In with Ethereum (EIP-4361)

Login tanpa password: user menandatangani pesan terstruktur, backend memverifikasi signature.

```text
example.com wants you to sign in with your Ethereum account:
0xAbC...123

Sign in to Phase 9 DApp

URI: https://example.com
Version: 1
Chain ID: 11155111
Nonce: 8f3a9c21d7         ← dibuat server, sekali pakai (anti-replay)
Issued At: 2026-01-01T00:00:00Z
Expiration Time: 2026-01-01T00:10:00Z
```

Alur: `GET /nonce` → frontend membentuk pesan → `signMessage` → `POST /verify {message, signature}` → backend memverifikasi (domain, nonce, expiry, address) → set session cookie. Backend-nya dibangun di Phase 10.

## EIP-712 Typed Data

```ts
const signature = await signTypedDataAsync({
  domain: { name: "LearningToken", version: "1", chainId: 11155111, verifyingContract: TOKEN },
  types: {
    Permit: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  },
  primaryType: "Permit",
  message: { owner, spender, value, nonce, deadline },
});
```

Wallet menampilkan field secara terstruktur sehingga user tahu apa yang ditandatangani — jauh lebih aman daripada `personal_sign` atas hex yang tidak terbaca. Hubungkan dengan Phase 8 C6: domain + nonce + deadline mencegah replay.

## Latihan C5

### Soal 7 — Bahaya Blind Signing
Mengapa phishing "permit drainer" sangat efektif dibanding phishing yang meminta transaksi `approve`? Apa yang bisa dilakukan frontend dan wallet untuk melindungi user?

<details>
<summary>💡 Pembahasan</summary>

Signature `permit` **gratis** dan **tidak mengirim transaksi**, sehingga user merasa "hanya login/verifikasi". Tidak ada gas, tidak muncul di riwayat transaksi, dan banyak user tidak membaca isi typed data. Attacker kemudian men-submit signature itu sendiri (`permit` + `transferFrom`) dan menguras token.

Perlindungan: wallet menampilkan simulasi dampak ("Anda mengizinkan X menghabiskan SEMUA USDC Anda"), frontend tidak pernah meminta permit untuk aksi yang tidak membutuhkannya, nilai `value` & `deadline` dibuat minimal, dan edukasi bahwa signature bisa sama berbahayanya dengan transaksi.

</details>

---

---

# C6: Events, Real-Time Update & Multicall

## Tiga Cara Mendapatkan Data Terbaru

| Cara | Mekanisme | Cocok untuk |
|---|---|---|
| **Polling** | `refetchInterval` di TanStack Query | Data sederhana, RPC HTTP |
| **Watch event** | `useWatchContractEvent` (polling `eth_getFilterChanges` atau WebSocket) | Feed aktivitas, notifikasi |
| **Indexer** | Query ke backend/subgraph (Phase 10) | Riwayat, pencarian, agregasi |

```tsx
useWatchContractEvent({
  address: CROWDFUNDING_ADDRESS,
  abi: crowdfundingAbi,
  eventName: "Donated",
  onLogs(logs) {
    // TODO (latihan): tambahkan ke feed "Donasi terbaru" & invalidate query totalRaised
  },
});
```

> ⚠️ Mengambil riwayat event lengkap dengan `getLogs` dari block 0 di frontend itu lambat dan sering terkena limit RPC (rentang block maksimum). Riwayat adalah tugas **indexer** (Phase 10).

## Multicall

Membaca 20 nilai = 20 request RPC. **Multicall3** (deployed di alamat sama di hampir semua chain) membungkus banyak `eth_call` menjadi satu. `useReadContracts` dan `publicClient.multicall` memakai ini otomatis.

## Latihan C6

### Soal 8 — Feed Aktivitas (Hands-On)
Tampilkan 5 event `Donated` terakhir (dari `getLogs` dengan rentang block terbatas) lalu tambahkan event baru secara real-time. Pastikan tidak ada duplikasi saat event yang sama muncul dari kedua sumber (petunjuk: kunci unik `transactionHash + logIndex`).

**✅ Selesai jika:**
- [ ] Tidak ada duplikasi saat event datang dari `getLogs` **dan** watcher (kunci `transactionHash + logIndex`)
- [ ] Event baru muncul beberapa detik setelah `cast send ... donate()`
- [ ] Rentang `getLogs` dibatasi (tidak dari block 0)


---

---

# C7: Frontend Security

## Ancaman yang Spesifik untuk DApp Frontend

| Ancaman | Contoh | Mitigasi |
|---|---|---|
| **Frontend compromise** | DNS hijack / dependency berbahaya mengganti address contract | Address contract hardcode & diverifikasi, lockfile, review dependency, SRI, IPFS hosting + ENS |
| **Unlimited approval** | `approve(spender, maxUint256)` ke contract yang nanti di-exploit | Approve sejumlah yang dibutuhkan; tampilkan opsi revoke |
| **Wrong chain** | User di mainnet, DApp mengira Sepolia → tx ke address yang salah | Selalu cek `chainId`; tawarkan `switchChain` |
| **Address poisoning** | Riwayat transfer palsu dengan address mirip | Tampilkan address lengkap/ENS, peringatan untuk address baru |
| **Secret di bundle** | Private key / API key rahasia di `NEXT_PUBLIC_*` | Rahasia hanya di server (Route Handler / backend) |
| **XSS** | Nama token / metadata NFT berisi HTML | Jangan `dangerouslySetInnerHTML` untuk data on-chain; sanitasi URL gambar |
| **Mengandalkan validasi frontend** | Contract tidak memvalidasi karena "frontend sudah cek" | Contract adalah sumber kebenaran; frontend hanya UX |

> **Prinsip**: anggap frontend Anda **bisa** di-compromise. Keamanan dana harus dijamin oleh contract dan wallet, bukan oleh UI.

## Latihan C7

### Soal 9 — Threat Model Frontend
Gunakan template threat model Phase 8 C1 untuk DApp Mini Project di bawah. Tuliskan minimal 5 ancaman beserta mitigasinya di **🗒️ Notes**.

**✅ Selesai jika:**
- [ ] Minimal 5 ancaman, masing-masing dengan aset, skenario, dan mitigasi
- [ ] Minimal satu ancaman *supply chain* (dependency/CDN) dan satu ancaman signature/approval


---

---

# 📝 Mini Project: Phase 5 DApp Dashboard

Satu aplikasi Next.js yang mengoperasikan seluruh contract Phase 5 di **anvil** dan **Sepolia**.

## Halaman

| Route | Fitur |
|---|---|
| `/` | Connect wallet, info network, saldo ETH & LRN |
| `/storage` | Baca/tulis `SimpleStorage`, tampilkan history |
| `/voting` | Daftar proposal, vote, status quorum & deadline (countdown) |
| `/crowdfunding` | Progress bar, donate, finalize, refund/withdraw sesuai state |
| `/token` | Info token, transfer, approve dengan nilai eksak |
| `/nft` | Mint, galeri NFT milik user (`tokenURI` → metadata → gambar IPFS) |
| `/staking` | Alur approve → stake, pending reward real-time, claim, unstake |

## Persyaratan

- [ ] ABI di-generate dari output Foundry (bukan ditulis manual).
- [ ] Semua write di-simulasi dulu; custom error ditampilkan dalam bahasa manusia.
- [ ] Setiap tx menampilkan state lengkap (C4) dan link ke block explorer.
- [ ] Network guard: tampilkan banner + tombol switch jika chain tidak didukung.
- [ ] Tidak ada `Number()` untuk nilai token; semua lewat `formatUnits`/`parseUnits`.
- [ ] Responsive (mobile) dan bisa dipakai lewat WalletConnect.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Halaman `/`, `/token`, `/crowdfunding` di **anvil** |
| 🟡 **Extended** — disarankan | Semua halaman + Sepolia + decode custom error + network guard |
| 🔴 **Stretch** — untuk portfolio | WalletConnect mobile, responsive, ABI di-generate dengan `@wagmi/cli` |

### ✅ Kriteria Lulus (Core)

- [ ] Connect/disconnect wallet dan ganti akun ter-refleksi di UI tanpa reload
- [ ] Donate & transfer menampilkan state: *confirm in wallet → pending → confirmed* dengan link explorer
- [ ] Menolak di wallet ditampilkan sebagai pembatalan, bukan error merah
- [ ] Revert contract (misal donate setelah deadline) tampil sebagai pesan manusia dari custom error
- [ ] `grep -r "Number(" src/` tidak menemukan konversi nilai token


---

# 🏆 Challenge: Gasless Voting dengan EIP-712

> *Challenge tanpa tutorial.*

## Spesifikasi

```text
TUJUAN:
  User memberikan suara TANPA membayar gas. Relayer (siapa pun) men-submit suara ke chain.

CONTRACT (tambahan dari VotingSystem):
  - voteBySig(proposalId, support, voter, nonce, deadline, signature)
  - Signature EIP-712 dengan domain (name, version, chainId, verifyingContract)
  - nonces[voter] untuk mencegah replay
  - Revert jika deadline lewat atau signer != voter

FRONTEND:
  - Tombol "Vote (gasless)" → signTypedData
  - Kirim signature ke relayer (Route Handler Next.js yang memegang key relayer DI SERVER)
  - Tampilkan status: signed → relayed (tx hash) → confirmed

SECURITY:
  - Key relayer tidak boleh ada di bundle client
  - Relayer membatasi rate per address
  - Test Foundry: replay, wrong chainId, expired deadline, signer palsu
```

## Tugas Challenge

1. Tambahkan `voteBySig` + test Foundry lengkap (lihat Phase 7 & 8 C6).
2. Implementasikan alur frontend + relayer.
3. Dokumentasikan di `09-web3-frontend/CHALLENGE.md`: diagram alur, keputusan desain, dan risiko yang tersisa.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | `voteBySig` + test Foundry (replay, chainId salah, deadline lewat, signer palsu) |
| 🟡 **Extended** — disarankan | Frontend `signTypedData` + relayer di Route Handler |
| 🔴 **Stretch** — untuk portfolio | Rate limiting relayer + `CHALLENGE.md` + deploy ke Sepolia |

### ✅ Kriteria Lulus (Core)

- [ ] Keempat test negatif Foundry hijau (masing-masing revert dengan error yang tepat)
- [ ] Signature yang sama tidak bisa dipakai dua kali (nonce bertambah)
- [ ] *(Extended)* Key relayer tidak muncul di bundle client (`grep` di `.next/static` kosong)


---

## 📁 GitHub Task

```bash
cd 09-web3-frontend/

git add .
git commit -m "learn: web3 frontend — viem, wagmi, wallet connection, tx lifecycle, signing"

git add dapp/
git commit -m "feat: phase 5 dapp dashboard with next.js, wagmi and rainbowkit"

git add .
git commit -m "feat: gasless voting with eip-712 signatures and relayer (Phase 9 challenge)"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Apa peran RPC node dan peran wallet dalam DApp? Mengapa frontend tidak pernah memegang private key?
2. Apa masalah yang diselesaikan EIP-6963 dibanding `window.ethereum`?
3. Apa perbedaan `publicClient` dan `walletClient` di Viem?
4. Mengapa nilai token harus disimpan sebagai `bigint`? Apa yang terjadi jika memakai `Number`?
5. Mengapa `simulateContract` sebaiknya dipanggil sebelum `writeContract`?
6. Jelaskan perbedaan "tx hash diterima" dan "tx confirmed". Bagaimana UI seharusnya memperlakukan keduanya?
7. Bagaimana cara men-decode custom error contract di frontend?
8. Kapan menggunakan signature off-chain dibanding transaksi? Berikan dua contoh.
9. Elemen apa saja dalam pesan SIWE yang mencegah replay dan phishing lintas domain?
10. Sebutkan tiga ancaman keamanan yang spesifik untuk frontend DApp beserta mitigasinya.

---

## 📊 Progress Tracker

- [ ] **Setup**: Next.js + viem + wagmi + RainbowKit, `.env.local`
- [ ] **C1**: Arsitektur DApp — *EIP-1193, EIP-6963, jenis koneksi wallet*
- [ ] **C2**: Viem — *public/wallet client, ABI typing, units*
- [ ] **C3**: Wagmi — *config, hooks inti, SSR & hydration*
- [ ] **C4**: Transaction UX — *state machine, decode error, konfirmasi, optimistic UI*
- [ ] **C5**: Signing — *SIWE, EIP-712, permit phishing*
- [ ] **C6**: Real-time — *watch event, polling, multicall*
- [ ] **C7**: Frontend Security — *approval, chain guard, secret, XSS*
- [ ] **Exercise**: Soal 1–9
- [ ] **Mini Project**: Phase 5 DApp Dashboard (anvil + Sepolia)
- [ ] **Challenge**: Gasless voting EIP-712 + relayer
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Viem Docs](https://viem.sh/)
- [Wagmi Docs](https://wagmi.sh/)
- [RainbowKit Docs](https://rainbowkit.com/docs/introduction)
- [EIP-1193: Ethereum Provider JavaScript API](https://eips.ethereum.org/EIPS/eip-1193)
- [EIP-6963: Multi Injected Provider Discovery](https://eips.ethereum.org/EIPS/eip-6963)
- [EIP-4361: Sign-In with Ethereum](https://eips.ethereum.org/EIPS/eip-4361)

### Tools
- [@wagmi/cli](https://wagmi.sh/cli/getting-started) — generate typed hooks dari ABI Foundry
- [Revoke.cash](https://revoke.cash/) — melihat & mencabut approval
- [Multicall3](https://www.multicall3.com/)

### Security
- [MetaMask eth-phishing-detect](https://github.com/MetaMask/eth-phishing-detect) — daftar domain phishing yang diblokir wallet
- Studi kasus (cari post-mortem-nya): *Ledger Connect Kit supply-chain attack (Des 2023)*, *BadgerDAO frontend injection (Des 2021)*

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua konsep)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — termasuk threat model frontend dari Soal 9)*
