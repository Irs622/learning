# 🌐 Web3 Developer Learning Journey & Security Portfolio

> Dokumentasi pembelajaran personal, jurnal teknis, implementasi smart contract, pengujian invarian (*fuzzing/testing*), dan audit keamanan (*security exploit lab*) dalam transisi dari **Full-Stack Engineer (Web2 / Mobile)** menuju **Web3 Security & Smart Contract Engineer**.

---

## 👤 Developer Profile & Focus

- **Background**: Full-Stack Software Engineer (Laravel, React, Mobile, Docker, Linux, Relational DB, Distributed Systems).
- **Target Specialization**: **Web3 Security / Smart Contract Security & Blockchain Infrastructure**.
- **Hardware Profile**: MacBook M3 (8 GB Unified Memory) — *Dioptimalkan untuk tooling ultra-ringan: Foundry (`forge`, `cast`, `anvil`) tanpa beban full node lokal.*

---

## 🧠 The Paradigm Shift: Web2 vs Web3 Architecture

Perbedaan paling krusial bagi seorang Full-Stack Engineer adalah pergeseran dari **Centralized Trust (Server/Database)** ke **Trustless Deterministic State Machine (Blockchain/EVM)**:

```text
WEB2 ARCHITECTURE (Centralized Trust)
User
 │
 ▼ (HTTPS / REST / GraphQL)
Frontend (React / Next.js / Mobile)
 │
 ▼ (JWT / Session Cookie)
Backend Server (Laravel / Node.js)
 │
 ▼ (SQL Queries - Read/Write/Delete)
Database (PostgreSQL / MySQL)  <--- Single Point of Failure & Absolute Admin Power
```

```text
WEB3 ARCHITECTURE (Trustless / Cryptographic Verification)
User
 │
 ▼ (Private Key Signature)
Wallet (MetaMask / Rabby / Hardware)
 │
 ▼ (JSON-RPC)
Frontend DApp (Next.js + Viem + Wagmi)
 │
 ▼ (Gossip Protocol / Mempool)
RPC Node Gateway
 │
 ▼ (Consensus & Execution)
Smart Contract on EVM
 │
 ▼ (Append-Only Replicated State)
Blockchain (Ethereum / Layer 2) <--- Immutable, No Admin Master Key, Publicly Auditable
```

---

## 🗺️ Master Curriculum (13 Phases)

```text
WEB2 FUNDAMENTAL (Laravel, React, Mobile, DevOps)
       │
       ▼
1. Blockchain Fundamentals
       │
       ▼
2. Ethereum & EVM
       │
       ▼
3. Cryptography & Wallet
       │
       ▼
4. Solidity
       │
       ▼
5. Smart Contract Development
       │
       ▼
6. Tooling (Foundry)
       │
       ▼
7. Smart Contract Testing
       │
       ▼
8. Smart Contract Security
       │
       ▼
9. Web3 Frontend (Viem, Wagmi)
       │
       ▼
10. Web3 Backend & Indexing
       │
       ▼
11. Tokenomics & DeFi
       │
       ▼
12. Layer 2 & Scaling
       │
       ▼
13. Advanced Web3 (AA, MEV, ZK)
       │
       ▼
WEB3 / SECURITY ENGINEER
```

---

### Detailed Phase Breakdown

#### Phase 0: Web2 Baseline Validation
- [x] JavaScript / TypeScript proficiency
- [x] HTTP / HTTPS, REST API, WebSockets
- [x] Relational Database (PostgreSQL/MySQL), ACID properties, indexing
- [x] Backend architecture, authentication (JWT, OAuth, Sessions)
- [x] Git, Docker, Linux, CI/CD, and basic security hygiene

#### Phase 1: Blockchain Fundamentals
- **Core Concepts**: Distributed ledger, P2P networking, Consensus mechanisms (PoW vs PoS), Blockchain Trilemma, Immutability, Permissionless vs Permissioned.
- **Transaction Flow**: `User -> Wallet -> RPC -> Mempool -> Validator -> Block -> Confirmation -> Finality`.
- **Key Mechanics**: Block anatomy, transaction payload, nonce, gas economics, chain reorganization (reorg).
- **Target**: Mampu menjelaskan secara presisi bagaimana transaksi berpindah dari wallet hingga terkonfirmasi di block.

#### Phase 2: Ethereum & EVM
- **Core Concepts**: Ethereum as a World Computer, EVM Architecture, Deterministic State Transition.
- **Account Model**: EOA (*Externally Owned Account*) vs Contract Account.
- **EVM Internals**: Opcodes, Bytecode, Stack, Memory, Storage (slot layout), Calldata.
- **Economic Model**: Gas limit, gas price, base fee (EIP-1559), priority fee, out of gas reverts.

#### Phase 3: Cryptography & Wallets
- **Hashing**: SHA-256 vs Keccak-256, pre-image resistance, collision resistance, avalanche effect.
- **Asymmetric Cryptography**: Elliptic Curve Cryptography (`secp256k1`), Private Key $\rightarrow$ Public Key $\rightarrow$ Ethereum Address derivation.
- **Digital Signatures**: ECDSA signing, verifying, parameter $(r, s, v)$, and `ecrecover`.
- **Wallet Architecture**: Mnemonic seeds (BIP-39), Hierarchical Deterministic (HD) wallets (BIP-32/BIP-44), derivation paths, MetaMask, Hardware wallets.

#### Phase 4: Solidity Fundamentals
- **Language Primitives**: Types (`uint`, `int`, `address`, `bool`, `bytes`), State variables, Functions, Visibility (`public`, `external`, `internal`, `private`).
- **Data Structures**: Structs, Enums, Arrays, Mappings (hash-table on storage slots).
- **Control & Logic**: Modifiers, Custom Errors (`error Unauthorized()`), Events, Revert semantics.
- **Data Locations**: `storage` (persistent, expensive) vs `memory` (temporary) vs `calldata` (immutable read-only payload).

#### Phase 5: Smart Contract Development
- **Project 1**: *Simple Storage* — State reading and writing mechanics.
- **Project 2**: *Decentralized Voting* — Proposals, voter mapping, access control, state transitions.
- **Project 3**: *Crowdfunding* — `payable`, ETH transfers, `msg.sender`, `msg.value`, withdrawal pattern.
- **Project 4**: *ERC-20 Token* — Fungible standard, `totalSupply`, `balanceOf`, `transfer`, `approve`, `allowance`.
- **Project 5**: *NFT (ERC-721 / 1155)* — Non-fungible standard, metadata JSON, IPFS, `tokenURI`.

#### Phase 6: Tooling (Foundry)
- **Framework**: Foundry (`forge`, `cast`, `anvil`) over heavy local stacks.
- **CLI Workflows**:
  - `forge init`, `forge build`, `forge test`
  - `cast call`, `cast send`, `cast balance`, `cast to-hex`
  - `anvil` (instant local EVM testnet)
- **Dependency Management**: Git submodules (`forge install OpenZeppelin/openzeppelin-contracts`).

#### Phase 7: Smart Contract Testing
- **Philosophy**: Testing bukan sekadar "apakah fungsi jalan", tapi "apakah fungsi gagal dengan benar ketika diserang".
- **Test Categories**:
  - Unit Tests: Isolation of individual functions.
  - Integration Tests: Multi-contract interactions.
  - Revert & Access Control Tests: Expecting specific reverts (`vm.expectRevert`).
  - Fuzz Testing: Generating pseudo-random inputs to find edge cases.
  - Invariant Testing: Proving global protocol truths (e.g. `totalShares <= totalAssets`).
  - Fork Testing: Running tests against live mainnet state.

#### Phase 8: Smart Contract Security
- **Core Principles**: Checks-Effects-Interactions (CEI), Pull over Push payments, Principle of Least Privilege.
- **Classic Vulnerabilities**:
  - Reentrancy (Single-function, Cross-function, Read-only)
  - Access Control breakdowns & `tx.origin` phishing
  - Integer arithmetic & precision loss
  - Oracle Manipulation & Flash Loan exploits
  - Front-running & Maximal Extractable Value (MEV)
  - Denial of Service (DoS via block gas limit or unexpected revert)
  - Signature replay & malleability
- **Tooling**: Slither (static analysis), Foundry fuzzing, Echidna.

#### Phase 9: Web3 Frontend
- **Stack**: Next.js, React, TypeScript, TailwindCSS / Vanilla CSS.
- **Web3 Layer**: Viem (lightweight Ethereum interface), Wagmi (React hooks for Ethereum), WalletConnect / RainbowKit.
- **Key Flows**: Wallet connection, reading on-chain state, preparing and signing transactions, optimistic UI updates, transaction receipts.

#### Phase 10: Web3 Backend & Indexing
- **Real-World Architecture**: Web3 apps still need backends for performance, search, and analytics.
- **Components**:
  - JSON-RPC event listeners & polling
  - Custom Event Indexer using Node.js & PostgreSQL
  - The Graph / Subgraphs
  - Database caching with Redis

#### Phase 11: Tokenomics & DeFi
- **Primitives**: Automated Market Makers (AMM: $x \times y = k$), Liquidity Pools, Impermanent Loss.
- **Money Legos**: Staking contracts, Lending & Borrowing (Overcollateralized debt, health factor, liquidations).
- **Price Feeds**: Chainlink Decentralized Oracle Networks.

#### Phase 12: Layer 2 & Scaling
- **Rollups**: Optimistic Rollups (Arbitrum, Optimism, Base) vs Zero-Knowledge (ZK) Rollups (zkSync, Scroll).
- **Mechanics**: Sequencers, Fraud Proofs vs Validity Proofs, Bridges, L1 Data Availability.

#### Phase 13: Advanced Web3
- **Account Abstraction (ERC-4337)**: Smart Contract Wallets, UserOperations, Paymasters (gasless transactions), Bundlers.
- **Institutional Infra**: Multisig wallets (Safe), Timelocks, DAO Governance contracts.

---

## 🏆 Portfolio Projects (Level 1 — 10)

| Level | Project | Key Concepts Mastered |
|:---:|---|---|
| **L1** | **Simple Storage DApp** | State variables, getters, setters, gas cost awareness. |
| **L2** | **Decentralized Voting System** | Mappings, structs, authorization, election finality. |
| **L3** | **Crowdfunding Protocol** | `payable`, pull-payment pattern, deadline checks, refund mechanics. |
| **L4** | **ERC-20 Token Suite** | Token standard, minting, burning, transfer fee logic, allowances. |
| **L5** | **NFT Marketplace** | ERC-721, custody escrow, buy/sell orders, royalties (EIP-2981). |
| **L6** | **Decentralized Autonomous Org (DAO)** | Proposal creation, timelock, voting quorum, on-chain execution. |
| **L7** | **Mini DEX (Uniswap v2 Style AMM)** | Constant product formula ($x \cdot y = k$), LP tokens, swap fees. |
| **L8** | **Lending & Borrowing Protocol** | Collateral ratios, liquidation incentives, interest rate curve. |
| **L9** | **Real-Time Blockchain Indexer** | Node.js worker, PostgreSQL, RPC event polling, REST/GraphQL API. |
| **L10** | **Smart Contract Security & Exploit Lab** | Vulnerable CTF contracts, written exploit scripts in Foundry, audit reports. |

---

## 📅 Timeline (6 - 9 Months Framework)

- **Month 1**: Blockchain Fundamentals, Ethereum & EVM Internals, Cryptography & Wallets.
- **Month 2**: Solidity Language Mastery, EVM Storage Layout, Basic Smart Contracts (Projects L1-L4).
- **Month 3**: Foundry Deep Dive, Unit & Fuzz Testing, OpenZeppelin, Smart Contract Security Fundamentals.
- **Month 4**: Web3 Frontend (Viem, Wagmi, Next.js, RainbowKit), Building Full DApps.
- **Month 5**: Web3 Backend, RPC Listeners, Event Indexing, The Graph, PostgreSQL.
- **Month 6**: DeFi Mechanics, DEX/AMM, Lending, Chainlink Oracles, Flash Loans.
- **Month 7+**: Layer 2 (Base/Arbitrum), Account Abstraction (ERC-4337), MEV, Security Auditing.

---

## 📝 Commit Conventions

Repository ini menerapkan **Conventional Commits**:

- `learn:` Catatan konsep, ringkasan teori, dan latihan pemahaman.
- `feat:` Implementasi smart contract, modul frontend, atau service backend.
- `test:` Test suite (Unit, Fuzz, Invariant, Fork tests) di Foundry.
- `fix:` Bug fix atau mitigasi celah keamanan.
- `refactor:` Optimasi gas (*gas golf*) atau perapian arsitektur kode.
- `docs:` Pembaruan README dan dokumentasi teknis.
- `security:` Script exploit CTF, simulasi serangan, atau audit report.

---

## 📂 Repository Structure

```text
.
├── README.md                           # Master Roadmap & Learning Journal Index
├── 01-blockchain-fundamentals/         # Phase 1
├── 02-ethereum-and-evm/                # Phase 2
├── 03-cryptography-and-wallets/        # Phase 3
├── 04-solidity-fundamentals/           # Phase 4
├── 05-smart-contract-development/      # Phase 5
├── 06-foundry-tooling/                 # Phase 6
├── 07-smart-contract-testing/          # Phase 7
├── 08-smart-contract-security/         # Phase 8
├── 09-web3-frontend/                   # Phase 9
├── 10-web3-backend-and-indexing/       # Phase 10
├── 11-tokenomics-and-defi/             # Phase 11
├── 12-layer-2/                         # Phase 12
├── 13-advanced-web3/                   # Phase 13
└── projects/                           # Milestone Projects (L1 - L10)
```
