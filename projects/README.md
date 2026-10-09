# 🏆 Portfolio Projects — Indeks (L1–L10)

Project portfolio dikerjakan **di dalam fase masing-masing**. Folder ini hanya indeks agar semua milestone mudah ditemukan dari satu tempat. Centang status setelah project memenuhi seluruh deliverable di README fasenya.

| Level | Project | Dikerjakan di | Bagian | Status |
|:---:|---|---|---|:---:|
| **L1** | Simple Storage DApp | [Phase 5](../05-smart-contract-development/README.md) + [Phase 9](../09-web3-frontend/README.md) | Contract 1 + Mini Project `/storage` | ⬜ |
| **L2** | Decentralized Voting System | [Phase 5](../05-smart-contract-development/README.md) | Contract 2 (+ Challenge Phase 9: gasless voting) | ⬜ |
| **L3** | Crowdfunding Protocol | [Phase 5](../05-smart-contract-development/README.md) | Contract 3 | ⬜ |
| **L4** | ERC-20 Token Suite | [Phase 5](../05-smart-contract-development/README.md) | Contract 4 + Challenge TokenStaking | ⬜ |
| **L5** | NFT Marketplace | [Phase 5](../05-smart-contract-development/README.md) → dikembangkan sendiri | Contract 5 + spesifikasi **L5** di bawah | ⬜ |
| **L6** | DAO | [Phase 13](../13-advanced-web3/README.md) | Mini Project: Full-Stack DAO | ⬜ |
| **L7** | Mini DEX (Uniswap V2 style) | [Phase 11](../11-tokenomics-and-defi/README.md) | Mini Project | ⬜ |
| **L8** | Lending & Borrowing Protocol | [Phase 11](../11-tokenomics-and-defi/README.md) | Challenge | ⬜ |
| **L9** | Real-Time Blockchain Indexer | [Phase 10](../10-web3-backend-and-indexing/README.md) | Mini Project | ⬜ |
| **L10** | Security & Exploit Lab | [Phase 8](../08-smart-contract-security/README.md) | Mini Project + Challenge (audit report) | ⬜ |

## Capstone

| Project | Dikerjakan di | Status |
|---|---|:---:|
| Gasless Smart Account (ERC-4337) untuk protokol Anda | [Phase 13 — Challenge](../13-advanced-web3/README.md) | ⬜ |

---

## 📐 Spesifikasi L5 — NFT Marketplace

> **Prasyarat:** Phase 5 (NFTCollection), Phase 7 (testing), Phase 8 (security). Kerjakan di `projects/nft-marketplace/` dengan `forge init nft-marketplace --no-git`.

```text
CONTRACT: NFTMarketplace (non-custodial — NFT tetap di wallet penjual sampai terjual)

STATE
  - listings[nft][tokenId] → { seller, priceWei, expiresAt }
  - proceeds[seller]       → ETH hasil penjualan yang belum ditarik (pull payment)

FUNGSI
  - list(nft, tokenId, price, expiresAt)    hanya pemilik; marketplace sudah di-approve; price > 0
  - cancel(nft, tokenId)                     hanya seller listing tersebut
  - updatePrice(nft, tokenId, newPrice)      hanya seller
  - buy(nft, tokenId) payable                msg.value == price; listing belum kedaluwarsa;
                                             bayar royalti EIP-2981 jika didukung; sisanya ke proceeds[seller]
  - withdrawProceeds()                       pull payment, CEI, nonReentrant

EVENTS
  - Listed, Cancelled, PriceUpdated, Sold(buyer, seller, nft, tokenId, price, royalty), ProceedsWithdrawn

SECURITY
  - Listing basi: penjual sudah memindahkan NFT / mencabut approval → buy harus revert
  - Royalti dibatasi (misal ≤ 10% harga) agar NFT jahat tidak bisa menguras pembayaran
  - safeTransferFrom ke pembeli; reentrancy guard pada buy & withdraw
  - Tidak ada ETH yang tertahan tanpa pemilik (invariant)
```

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** | list, cancel, buy (tanpa royalti), withdrawProceeds + unit test |
| 🟡 **Extended** | Royalti EIP-2981 dengan batas, updatePrice, kedaluwarsa, invariant test |
| 🔴 **Stretch** | Offer/bid dengan signature EIP-712 (gasless listing), frontend (Phase 9), indexer (Phase 10) |

**✅ Kriteria Lulus (Core):**
- [ ] `forge test` hijau; setiap fungsi punya test happy path + revert dengan custom error
- [ ] Buy pada listing yang NFT-nya sudah dipindahkan penjual → revert
- [ ] Pembayaran memakai pull pattern; test reentrancy pada `withdrawProceeds` gagal menguras contract
- [ ] Invariant: `address(this).balance == Σ proceeds[seller]` setelah urutan aksi acak
