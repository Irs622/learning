# 01 - Blockchain Fundamentals

## Objective
Menguasai cara berpikir dan model komputasi blockchain serta mampu menjelaskan secara rinci bagaimana sebuah transaksi berpindah dari wallet sampai tersimpan secara permanen di dalam block:
- Memahami pergeseran arsitektur Web2 (Client -> Server -> Database) ke Web3 (User -> Wallet -> RPC -> State Machine).
- Memahami konsep Distributed Ledger, P2P Network, Nodes, dan Consensus.
- Menguasai komponen transaksi: sender, recipient, value, data/payload, nonce, gas, dan digital signature.
- Memahami siklus hidup transaksi (Transaction Lifecycle): Mempool -> Validator/Miner -> Block -> Confirmation -> Finality.
- Memahami isu-isu jaringan terdistribusi: Chain Reorganization (Reorg) dan Blockchain Trilemma (Decentralization, Security, Scalability).

---

## Prerequisites
- Konsep dasar jaringan komputer (Client-Server, Request-Response, Latency).
- Pemahaman dasar arsitektur Web2 (Frontend, Backend, Database Relasional/ACID).

---

## Concepts
1. **Web2 vs Web3 Architecture**: Trust model, Database vs State Machine, dan pergeseran wewenang otentikasi.
2. **Distributed Ledger & P2P Network**: Mengapa tidak ada central server, dan bagaimana ribuan node menyimpan salinan state yang identik.
3. **Anatomy of a Transaction**: Apa saja isi payload transaksi (nonce, gasLimit, gasPrice/maxFee, to, value, data, signature).
4. **Transaction Lifecycle**: Perjalanan transaksi dari wallet -> RPC node -> mempool -> validator -> inklusi ke dalam block -> finality.
5. **Consensus & State Finality**: Cara jaringan menyepakati urutan transaksi yang sah dan apa yang terjadi jika terjadi chain reorg.

---

## What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan topik ini)*

---

## Exercises
- [ ] **Exercise 1: Web2 vs Web3 Architecture Mapping**: Memetakan alur fitur "Transfer Saldo User A ke User B" versi Laravel + MySQL vs versi Web3 DApp.
- [ ] **Exercise 2: Transaction Anatomy Breakdown**: Menganalisis payload transaksi nyata dari block explorer (Etherscan) dan mengidentifikasi fungsi setiap field.

---

## Mini Project
- **Transaction Flow Simulator / Tracer**: Membuat diagram alur lengkap atau script visualisasi siklus hidup transaksi (State Diagram) dari status *Unsigned*, *Broadcasted (Mempool)*, *Pending*, *Included (1 confirmation)*, hingga *Finalized*.

---

## Challenges
- **Scenario Debugging (Challenge Tanpa Tutorial)**: Menyelesaikan 2 skenario masalah jaringan nyata:
  1. Mengapa transaksi user "stuck / macet" berjam-jam di mempool dan bagaimana cara mengatasinya tanpa membuat akun baru?
  2. Mengapa e-commerce Web3 harus menunggu beberapa *block confirmations* sebelum mengirim barang fisik ke pembeli?

---

## Resources
- [Ethereum.org: Introduction to Blockchain](https://ethereum.org/en/developers/docs/intro-to-ethereum/)
- [Ethereum.org: Transactions](https://ethereum.org/en/developers/docs/transactions/)
- [Vitalik Buterin: The Meaning of Decentralization](https://medium.com/@VitalikButerin/the-meaning-of-decentralization-a0c92b76a274)
- [Blockchain Trilemma Explained](https://vitalik.eth.limo/general/2021/05/23/scaling.html)

---

## Notes
*(Catatan belajar pribadi)*

---

## Progress
- [ ] Concept 1: Web2 vs Web3 Architecture
- [ ] Concept 2: Distributed Ledger & P2P Network
- [ ] Concept 3: Anatomy of a Transaction (Nonce, Gas, Payload)
- [ ] Concept 4: Transaction Lifecycle (Mempool to Block)
- [ ] Concept 5: Consensus, Finality & Reorg
- [ ] Exercise 1: Web2 vs Web3 Mapping
- [ ] Exercise 2: Etherscan Transaction Breakdown
- [ ] Mini Project: Transaction Flow Simulator
- [ ] Challenge: Stuck Transaction & Confirmation Security
- [ ] Review
