# Web3 Developer Learning Journey & Portfolio

> Personal learning journal, code experiments, smart contract implementations, and security reviews tracking my transition from **Full-Stack (Web2 / Mobile)** to **Web3 / Smart Contract & Security Engineer**.

---

## 🎯 Learning Principles & Mindset

- **One Topic at a Time**: Deep mastery over superficial skimming.
- **Mental Model First**: Understand the underlying state machine, cryptography, and economics before writing code.
- **Security-First**: Every smart contract is written under the assumption that it will operate in a hostile, adversarial environment.
- **Hands-On & Invariant Testing**: Not just "it works", but proving contract invariants hold under fuzzing and edge cases.
- **Clean Learning Journal**: Every module contains notes, mental models, exercises, and standalone challenges.

---

## 🗺️ Roadmap & Curriculum

Adapted specifically for an experienced Full-Stack Engineer:

| Phase | Topic Directory | Focus Area | Status |
|:---:|---|---|:---:|
| **01** | `01-blockchain-and-crypto-primitives` | Cryptographic Hash (Keccak-256 vs SHA-256), ECC (secp256k1), Keypairs, Digital Signatures, State Machine vs DB | 🟡 *In Progress* |
| **02** | `02-ethereum-and-evm` | EVM Architecture, Accounts (EOA vs Contract), Transactions, Gas Mechanism, Opcodes, State trie | ⚪ *Planned* |
| **03** | `03-solidity-fundamentals` | Syntax, Type system, Storage vs Memory vs Calldata, Visibility, Custom Errors, Revert logic | ⚪ *Planned* |
| **04** | `04-foundry-development` | Modern tooling: `forge`, `cast`, `anvil`, project structure, dependency management | ⚪ *Planned* |
| **05** | `05-testing-and-invariants` | Unit testing, Fuzz testing, Invariant testing, Fork testing with Foundry | ⚪ *Planned* |
| **06** | `06-smart-contract-security` | CEI pattern, Reentrancy, Access Control, Arithmetic, Front-running/MEV, Flash Loans | ⚪ *Planned* |
| **07** | `07-erc-standards` | ERC-20, ERC-721, ERC-1155, ERC-4626 (Tokenized Vaults) from scratch & OpenZeppelin | ⚪ *Planned* |
| **08** | `08-web3-frontend-viem-wagmi` | Connecting React to EVM, Viem, Wagmi, TanStack Query, WalletConnect, Indexing | ⚪ *Planned* |
| **09** | `09-defi-protocols` | AMM (x*y=k), Staking, Lending Pools, Oracle integrations (Chainlink) | ⚪ *Planned* |
| **10** | `10-advanced-evm-and-assembly` | Yul / EVM Assembly, Gas optimization, Diamond standard, Upgradeable Proxies | ⚪ *Planned* |

---

## 📝 Commit Conventions

All commits follow the Conventional Commits specification:

- `learn:` New topic notes, mental models, or conceptual exercises
- `feat:` Implementations of contracts, modules, or features
- `test:` Unit, fuzz, or invariant test suites
- `fix:` Bug fixes or vulnerability mitigations
- `refactor:` Code improvements or gas optimizations
- `docs:` Documentation and README updates
- `security:` Security audits, exploit scenarios, and patches

---

## 🛠️ Tech Stack & Tooling

- **Languages**: Solidity, TypeScript, JavaScript
- **Frameworks & Tooling**: Foundry (`forge`, `cast`, `anvil`), Node.js
- **Frontend / Client**: React, Viem, Wagmi
- **Testing**: Foundry Forge Tests (Unit & Fuzz)
