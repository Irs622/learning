# 05 — Smart Contract Development

> **Level**: 3 — Hands-On Implementation
> **Phase**: 5 of 13
> **Estimated Time**: 🚀 Intensif 14–21 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 5–8 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [04-solidity-fundamentals](../04-solidity-fundamentals/README.md) ✅ | [06-foundry-tooling](../06-foundry-tooling/README.md) ✅
> **Status verifikasi**: **Tested** · 9 Okt 2026 · build, format, 97 test referensi, 19 test jawaban, simulasi deploy lulus — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Membangun **5 smart contract** dari nol dengan tingkat kompleksitas yang meningkat.
- Mengimplementasikan dan memahami **ERC-20 token standard** tanpa bergantung pada library.
- Mengimplementasikan dan memahami **ERC-721 NFT standard** dari prinsip pertama.
- Menerapkan **security patterns** (CEI, reentrancy guard, access control) di setiap contract.
- Menulis **test suite lengkap** dengan Foundry untuk setiap contract yang dibangun.
- Membuat **deployment scripts** dan melakukan verifikasi di testnet.
- Mengoptimalkan **gas cost** dengan memahami trade-off setiap pilihan implementation.

---

## 📋 Prerequisites

- [x] Foundry terinstall dan project structure dipahami (Phase 6).
- [x] Memahami semua type system, data locations, dan patterns Solidity (Phase 4).
- [x] Memahami EVM storage layout (Phase 2).

---

## ⚙️ Setup: Dependencies Foundry

Folder ini **sudah berisi** `foundry.toml`, `src/`, `test/`, dan `script/`. Jangan jalankan `forge init .` di sini — perintah itu akan menimpa/bentrok dengan file yang sudah ada. Cukup install dependencies ke `lib/` (folder ini tidak ikut di-commit):

```bash
cd 05-smart-contract-development/

# 1. Install forge-std (wajib — semua test & script import "forge-std/...")
forge install foundry-rs/forge-std@v1.17.0 --no-git

# 2. Install OpenZeppelin (opsional di fase ini — dipakai sebagai PEMBANDING,
#    bukan dependency, karena ERC-20/721 di fase ini ditulis dari nol)
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git

# 3. Cek remappings yang terdeteksi otomatis
forge remappings

# 4. Pastikan semua contract bisa dikompilasi
forge build
# → Compiler run successful
```

Jika import tidak ter-resolve, buat `remappings.txt` (lihat Phase 6 — C2: *Import Paths & Remappings*):

```text
forge-std/=lib/forge-std/src/
@openzeppelin/=lib/openzeppelin-contracts/
```

> 💡 Salin `.env.example` menjadi `.env` hanya ketika Anda masuk ke bab **🚀 Deployment**. Jangan pernah commit `.env`.

---

## 🗺️ Project Roadmap

```text
CONTRACT 1: SimpleStorage
    Konsep: State read/write, events, access control dasar
    Estimasi: 1–2 hari
         │
         ▼
CONTRACT 2: VotingSystem
    Konsep: Structs, mappings, enum phases, time-based logic
    Estimasi: 2–3 hari
         │
         ▼
CONTRACT 3: Crowdfunding
    Konsep: ETH flow, CEI pattern, refund mechanism, timelock
    Estimasi: 2–3 hari
         │
         ▼
CONTRACT 4: ERC-20 Token (From Scratch)
    Konsep: Token standard, allowance mechanism, EIP compliance
    Estimasi: 3–4 hari
         │
         ▼
CONTRACT 5: NFT Collection (ERC-721)
    Konsep: Non-fungible tokens, metadata, minting phases, royalties
    Estimasi: 4–5 hari
         │
         ▼
CHALLENGE: TokenStaking
    Konsep: Integrasi antar-contract, reward berbasis waktu, minting permission
    Estimasi: 2–3 hari
         │
         ▼
DEPLOYMENT: Anvil → Sepolia → Etherscan Verify
    Estimasi: 1 hari
```

---

## 📚 Concepts Overview

| # | Contract | Konsep Inti | Security Pattern | File |
|---|---|---|---|---|
| 1 | SimpleStorage | State read/write, events, ownership, array history | Access control (`onlyOwner`), gas DoS pada `delete` array | `src/SimpleStorage.sol` |
| 2 | VotingSystem | Struct, mapping, lifecycle proposal, time-based logic, quorum | One-address-one-vote, validasi deadline, custom errors | `src/VotingSystem.sol` |
| 3 | Crowdfunding | `payable`, ETH flow, goal & deadline, refund | CEI, reentrancy guard, pull-over-push payment | `src/Crowdfunding.sol` |
| 4 | ERC-20 Token | EIP-20, `allowance`, `transferFrom`, mint/burn | Approval race condition, validasi zero-address | `src/ERC20Token.sol` |
| 5 | NFT Collection | EIP-721, EIP-165, EIP-2981, `tokenURI`, reveal | `safeTransferFrom` + receiver check, trait sniping | `src/NFTCollection.sol` |
| 🏆 | TokenStaking | Integrasi contract, reward per detik, lock period | CEI, reentrancy guard, precision loss, minting authority | `src/TokenStaking.sol` (starter — Anda yang mengisi) |

> **Cara belajar fase ini — Test-Driven:**
> 1. Baca **Objective** & **Spesifikasi** contract.
> 2. **🛠️ Kerjakan**: isi starter di `src/` sampai test di `test/` (yang sudah disediakan sebagai spesifikasi) lulus.
> 3. Buka **Implementation (Pembahasan)** yang tersembunyi dan bandingkan.
> 4. Pelajari **Test Suite** / PoC, lalu kerjakan **Soal Latihan**.
>
> Jawaban lengkap ada di `solutions/` (lihat [`solutions/README.md`](solutions/README.md)) — gunakan hanya sebagai pembanding.

---

---

# Contract 1: SimpleStorage

## Objective
Kontrak "Hello World" yang sesungguhnya — lebih dari sekedar `store()` dan `retrieve()`. Kita tambahkan access control, events, dan history tracking.

---

## Spesifikasi

```
CONTRACT: SimpleStorage

State:
  - value: uint256 (current value)
  - owner: address
  - updateCount: uint256 (berapa kali di-update)
  - history: uint256[] (history semua nilai)

Functions:
  - store(uint256 value) → onlyOwner, emit Updated
  - retrieve() → view, returns current value
  - getHistory() → view, returns semua history
  - getUpdateCount() → view
  - transferOwnership(address newOwner) → onlyOwner
  - resetHistory() → onlyOwner (hapus history, reset counter)

Events:
  - Updated(address indexed by, uint256 oldValue, uint256 newValue, uint256 timestamp)
  - OwnershipTransferred(address indexed oldOwner, address indexed newOwner)
  - HistoryReset(address indexed by, uint256 totalRecordsDeleted)

Custom Errors:
  - NotOwner()
  - ZeroAddress()
  - SameValue(uint256 current)
```

---

## 🛠️ Kerjakan: `src/SimpleStorage.sol`

1. Buka **`src/SimpleStorage.sol`** — starter berisi state, struct, event, error, signature, dan constructor. Semua body fungsi masih `revert NotImplemented()`.
2. Jalankan test sebagai spesifikasi: `forge test --match-contract SimpleStorageTest -vv` → awalnya **merah semua**.
3. Isi fungsi satu per satu sampai **11/11 test hijau**. Mulai dari modifier `onlyOwner`, lalu `store()`, lalu fungsi history.
4. Baru setelah itu buka pembahasan di bawah dan bandingkan dengan implementasi Anda.

**✅ Kriteria lulus:**
- [ ] `forge test --match-contract SimpleStorageTest` → 11 passed, 0 failed
- [ ] Tidak ada `revert NotImplemented()` dan `error NotImplemented()` tersisa di file Anda
- [ ] Setiap fungsi state-changing mengikuti urutan Checks → Effects → Interactions
- [ ] Anda bisa menjelaskan alasan setiap custom error & event tanpa melihat pembahasan

---

## Implementation (Pembahasan)

<details>
<summary>💡 Lihat implementasi referensi — buka <b>setelah</b> test Anda lulus</summary>


```solidity
// src/SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SimpleStorage
 * @author [Nama Anda]
 * @notice A simple storage contract with ownership, history, and events.
 * @dev Phase 5, Contract 1 — Learning Foundry development workflow
 */
contract SimpleStorage {
    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    uint256 private _value;
    address private _owner;
    uint256 private _updateCount;
    uint256[] private _history;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Updated(
        address indexed by,
        uint256 oldValue,
        uint256 newValue,
        uint256 indexed timestamp
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    event HistoryReset(address indexed by, uint256 totalRecordsDeleted);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error NotOwner(address caller, address expectedOwner);
    error ZeroAddress();
    error SameValue(uint256 currentValue);

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner(msg.sender, _owner);
        }
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(uint256 initialValue) {
        _owner = msg.sender;
        _value = initialValue;
        _history.push(initialValue); // Initial value masuk ke history
        emit Updated(msg.sender, 0, initialValue, block.timestamp);
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /**
     * @notice Store a new value. Only callable by owner.
     * @param newValue The new value to store. Cannot be same as current.
     */
    function store(uint256 newValue) external onlyOwner {
        if (newValue == _value) revert SameValue(_value);

        uint256 oldValue = _value;
        _value = newValue;
        _updateCount++;
        _history.push(newValue);

        emit Updated(msg.sender, oldValue, newValue, block.timestamp);
    }

    /**
     * @notice Transfer ownership to a new address.
     * @param newOwner Address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();

        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Clear all history and reset update counter.
     * @dev Deletes the storage array — be mindful of gas cost for large arrays.
     */
    function resetHistory() external onlyOwner {
        uint256 recordsDeleted = _history.length;
        delete _history;
        _updateCount = 0;

        // Re-add current value as starting point
        _history.push(_value);

        emit HistoryReset(msg.sender, recordsDeleted);
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    /// @notice Get the current stored value
    function retrieve() external view returns (uint256) {
        return _value;
    }

    /// @notice Get the full update history
    function getHistory() external view returns (uint256[] memory) {
        return _history;
    }

    /// @notice Get the total number of updates since last reset
    function getUpdateCount() external view returns (uint256) {
        return _updateCount;
    }

    /// @notice Get the owner address
    function owner() external view returns (address) {
        return _owner;
    }
}
```

</details>

---

## Test Suite

> Blok di bawah adalah **contoh ringkas** untuk dibaca. Spesifikasi yang harus Anda loloskan adalah file `test/SimpleStorage.t.sol` (11 test, sebagian dengan nama berbeda).

```solidity
// test/SimpleStorage.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public storage_;
    
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    
    uint256 constant INITIAL_VALUE = 42;

    function setUp() public {
        vm.prank(owner);
        storage_ = new SimpleStorage(INITIAL_VALUE);
    }

    // ===== DEPLOYMENT TESTS =====

    function test_InitialState() public view {
        assertEq(storage_.retrieve(), INITIAL_VALUE);
        assertEq(storage_.getUpdateCount(), 0);
        assertEq(storage_.owner(), owner);
        
        uint256[] memory history = storage_.getHistory();
        assertEq(history.length, 1);
        assertEq(history[0], INITIAL_VALUE);
    }

    // ===== STORE TESTS =====

    function test_Store_UpdatesValue() public {
        vm.prank(owner);
        storage_.store(100);
        assertEq(storage_.retrieve(), 100);
    }

    function test_Store_IncrementsCounter() public {
        vm.prank(owner);
        storage_.store(100);
        assertEq(storage_.getUpdateCount(), 1);
        
        vm.prank(owner);
        storage_.store(200);
        assertEq(storage_.getUpdateCount(), 2);
    }

    function test_Store_AppendsToHistory() public {
        vm.prank(owner);
        storage_.store(100);
        
        vm.prank(owner);
        storage_.store(200);
        
        uint256[] memory history = storage_.getHistory();
        assertEq(history.length, 3); // initial + 100 + 200
        assertEq(history[0], INITIAL_VALUE);
        assertEq(history[1], 100);
        assertEq(history[2], 200);
    }

    function test_Store_EmitsUpdatedEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit SimpleStorage.Updated(owner, INITIAL_VALUE, 100, block.timestamp);
        storage_.store(100);
    }

    // ===== REVERT TESTS =====

    function test_RevertWhen_NonOwnerStores() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleStorage.NotOwner.selector,
                alice,
                owner
            )
        );
        storage_.store(100);
    }

    function test_RevertWhen_StoringSameValue() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleStorage.SameValue.selector,
                INITIAL_VALUE
            )
        );
        storage_.store(INITIAL_VALUE);
    }

    // ===== OWNERSHIP TESTS =====

    function test_TransferOwnership() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit SimpleStorage.OwnershipTransferred(owner, alice);
        storage_.transferOwnership(alice);
        
        assertEq(storage_.owner(), alice);
        
        // alice sekarang bisa store
        vm.prank(alice);
        storage_.store(999);
        assertEq(storage_.retrieve(), 999);
        
        // owner lama tidak bisa store lagi
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleStorage.NotOwner.selector,
                owner,
                alice
            )
        );
        storage_.store(123);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(SimpleStorage.ZeroAddress.selector);
        storage_.transferOwnership(address(0));
    }

    // ===== RESET HISTORY TESTS =====

    function test_ResetHistory_ClearsHistory() public {
        vm.startPrank(owner);
        storage_.store(100);
        storage_.store(200);
        storage_.store(300);
        assertEq(storage_.getUpdateCount(), 3);
        assertEq(storage_.getHistory().length, 4);
        
        storage_.resetHistory();
        vm.stopPrank();
        
        assertEq(storage_.getUpdateCount(), 0);
        uint256[] memory history = storage_.getHistory();
        assertEq(history.length, 1); // hanya current value
        assertEq(history[0], 300);  // current value tetap
    }

    function test_ResetHistory_EmitsEvent() public {
        vm.startPrank(owner);
        storage_.store(100);
        storage_.store(200);
        // History sekarang: [42, 100, 200] = 3 records
        
        vm.expectEmit(true, false, false, true);
        emit SimpleStorage.HistoryReset(owner, 3);
        storage_.resetHistory();
        vm.stopPrank();
    }

    // ===== FUZZ TESTS =====

    function testFuzz_Store_AnyValue(uint256 value) public {
        // Exclude nilai sama dengan initial value untuk menghindari SameValue revert
        vm.assume(value != INITIAL_VALUE);
        
        vm.prank(owner);
        storage_.store(value);
        
        assertEq(storage_.retrieve(), value);
    }
}
```

---

## Soal Latihan Contract 1

### Soal 1 — Gas Optimization
`resetHistory()` menggunakan `delete _history` yang di-loop untuk setiap element. Berapa gas yang dikonsumsi untuk history dengan 1000 entri? Bagaimana Anda bisa membuat operasi ini lebih gas-efisien tanpa mengorbankan functionality?

<details>
<summary>💡 Hint & Pembahasan</summary>

`delete _history` berbiaya sekitar `5.000 gas × N` (satu SSTORE cold nonzero → 0 per slot; sebagian dikembalikan sebagai refund, maksimal 1/5 gas transaksi). Untuk 1.000 entri ≈ 5 juta gas — mahal; untuk ~10.000 entri sudah mendekati/melampaui block gas limit, sehingga `resetHistory()` tidak bisa dipanggil lagi (DoS).

Solusi: Gunakan "virtual reset" dengan pointer:
```solidity
uint256 private _historyStartIndex; // Pointer ke awal "aktif" history

function resetHistory() external onlyOwner {
    _historyStartIndex = _history.length; // Semua sebelumnya dianggap "terhapus"
    _updateCount = 0;
    _history.push(_value);
}

function getHistory() external view returns (uint256[] memory) {
    uint256 start = _historyStartIndex;
    uint256 len = _history.length - start;
    uint256[] memory result = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
        result[i] = _history[start + i];
    }
    return result;
}
```
Gas cost reset: O(1) — hanya satu SSTORE untuk `_historyStartIndex`!

</details>

---

---

# Contract 2: VotingSystem

## Objective
Sistem voting on-chain dengan proposal management, time-based phases, dan quorum — mirip DAO governance sederhana.

---

## Spesifikasi

```
CONTRACT: VotingSystem

Phases: Registration → Voting → Ended

Struct Proposal:
  - id: uint256
  - description: string
  - creator: address
  - voteFor: uint256
  - voteAgainst: uint256
  - deadline: uint256 (timestamp)
  - executed: bool

Functions:
  - createProposal(description, durationSeconds) → proposalId (onlyOwner)
  - vote(proposalId, support) → support=true/false
  - executeProposal(proposalId) → onlyOwner, setelah deadline, cek quorum
  - cancelProposal(proposalId) → onlyOwner, hanya jika belum ada vote
  - getProposal(proposalId) → view
  - hasVoted(proposalId, voter) → view, returns bool
  - getResult(proposalId) → view, returns (passed, forVotes, againstVotes)

Rules:
  - Satu address hanya bisa vote sekali per proposal
  - Vote hanya bisa dilakukan sebelum deadline
  - Quorum: minimal 3 vote total untuk bisa dieksekusi
  - Hasil: FOR > AGAINST = passed
  - Hanya owner yang bisa create & execute proposal
  
Events:
  - ProposalCreated(uint256 indexed id, string description, uint256 deadline)
  - Voted(uint256 indexed proposalId, address indexed voter, bool support)
  - ProposalExecuted(uint256 indexed id, bool passed)
  - ProposalCancelled(uint256 indexed id)
  
Custom Errors:
  - NotOwner()
  - ProposalNotFound(uint256 proposalId)
  - VotingEnded(uint256 proposalId, uint256 deadline)
  - VotingNotEnded(uint256 proposalId, uint256 deadline)
  - AlreadyVoted(address voter, uint256 proposalId)
  - AlreadyExecuted(uint256 proposalId)
  - QuorumNotMet(uint256 totalVotes, uint256 required)
  - HasVotes(uint256 proposalId)
```

---

## 🛠️ Kerjakan: `src/VotingSystem.sol`

1. Buka **`src/VotingSystem.sol`** — starter berisi state, struct, event, error, signature, dan constructor. Semua body fungsi masih `revert NotImplemented()`.
2. Jalankan test sebagai spesifikasi: `forge test --match-contract VotingSystemTest -vv` → awalnya **merah semua**.
3. Isi fungsi satu per satu sampai **14/14 test hijau**. Mulai dari `createProposal()` & modifier `proposalExists`, lalu `vote()`, lalu `executeProposal()`. Setelah semua lulus, tulis test TODO di `test/VotingSystem.t.sol` (Test Suite di bawah).
4. Baru setelah itu buka pembahasan di bawah dan bandingkan dengan implementasi Anda.

**✅ Kriteria lulus:**
- [ ] `forge test --match-contract VotingSystemTest` → 14 passed, 0 failed
- [ ] Tidak ada `revert NotImplemented()` dan `error NotImplemented()` tersisa di file Anda
- [ ] Setiap fungsi state-changing mengikuti urutan Checks → Effects → Interactions
- [ ] Anda bisa menjelaskan alasan setiap custom error & event tanpa melihat pembahasan

---

## Implementation (Pembahasan)

<details>
<summary>💡 Lihat implementasi referensi — buka <b>setelah</b> test Anda lulus</summary>


```solidity
// src/VotingSystem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VotingSystem
 * @notice Simple on-chain governance voting with proposals and quorum.
 * @dev Phase 5, Contract 2
 */
contract VotingSystem {
    // =========================================================
    //                      TYPE DEFINITIONS
    // =========================================================

    struct Proposal {
        uint256  id;
        string   description;
        address  creator;
        uint256  voteFor;
        uint256  voteAgainst;
        uint256  deadline;
        bool     executed;
        bool     exists;    // Untuk membedakan proposal yang tidak ada vs proposal 0
    }

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    address private _owner;
    uint256 private _nextProposalId;
    uint256 public  quorumThreshold;

    mapping(uint256 => Proposal)                    private _proposals;
    mapping(uint256 => mapping(address => bool))    private _hasVoted;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event ProposalCreated(
        uint256 indexed id,
        address indexed creator,
        string description,
        uint256 deadline
    );
    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint256 indexed id, bool passed);
    event ProposalCancelled(uint256 indexed id);
    event QuorumUpdated(uint256 oldThreshold, uint256 newThreshold);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error NotOwner();
    error ProposalNotFound(uint256 proposalId);
    error VotingEnded(uint256 proposalId, uint256 deadline);
    error VotingNotEnded(uint256 proposalId, uint256 deadline);
    error AlreadyVoted(address voter, uint256 proposalId);
    error AlreadyExecuted(uint256 proposalId);
    error QuorumNotMet(uint256 totalVotes, uint256 required);
    error HasVotes(uint256 proposalId);
    error InvalidDuration();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        if (!_proposals[proposalId].exists) revert ProposalNotFound(proposalId);
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(uint256 _quorumThreshold) {
        _owner = msg.sender;
        quorumThreshold = _quorumThreshold;
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /**
     * @notice Create a new proposal.
     * @param description Human-readable description of the proposal.
     * @param durationSeconds Voting window in seconds.
     * @return proposalId The ID of the newly created proposal.
     */
    function createProposal(
        string calldata description,
        uint256 durationSeconds
    ) external onlyOwner returns (uint256 proposalId) {
        if (durationSeconds == 0) revert InvalidDuration();

        proposalId = _nextProposalId++;

        _proposals[proposalId] = Proposal({
            id:          proposalId,
            description: description,
            creator:     msg.sender,
            voteFor:     0,
            voteAgainst: 0,
            deadline:    block.timestamp + durationSeconds,
            executed:    false,
            exists:      true
        });

        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp + durationSeconds);
    }

    /**
     * @notice Cast a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True = vote for, False = vote against.
     */
    function vote(uint256 proposalId, bool support)
        external
        proposalExists(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];

        if (block.timestamp >= proposal.deadline) {
            revert VotingEnded(proposalId, proposal.deadline);
        }
        if (_hasVoted[proposalId][msg.sender]) {
            revert AlreadyVoted(msg.sender, proposalId);
        }

        // CEI: Effects before Interactions
        _hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Execute a proposal after voting has ended.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId)
        external
        onlyOwner
        proposalExists(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.executed) revert AlreadyExecuted(proposalId);
        if (block.timestamp < proposal.deadline) {
            revert VotingNotEnded(proposalId, proposal.deadline);
        }

        uint256 totalVotes = proposal.voteFor + proposal.voteAgainst;
        if (totalVotes < quorumThreshold) {
            revert QuorumNotMet(totalVotes, quorumThreshold);
        }

        proposal.executed = true;
        bool passed = proposal.voteFor > proposal.voteAgainst;

        emit ProposalExecuted(proposalId, passed);
    }

    /**
     * @notice Cancel a proposal. Only if no votes have been cast yet.
     */
    function cancelProposal(uint256 proposalId)
        external
        onlyOwner
        proposalExists(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];

        uint256 totalVotes = proposal.voteFor + proposal.voteAgainst;
        if (totalVotes > 0) revert HasVotes(proposalId);

        delete _proposals[proposalId];

        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice Update the quorum threshold.
     */
    function setQuorum(uint256 newThreshold) external onlyOwner {
        uint256 old = quorumThreshold;
        quorumThreshold = newThreshold;
        emit QuorumUpdated(old, newThreshold);
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function getProposal(uint256 proposalId)
        external
        view
        proposalExists(proposalId)
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    function hasVoted(uint256 proposalId, address voter)
        external
        view
        returns (bool)
    {
        return _hasVoted[proposalId][voter];
    }

    function getResult(uint256 proposalId)
        external
        view
        proposalExists(proposalId)
        returns (bool passed, uint256 forVotes, uint256 againstVotes)
    {
        Proposal storage p = _proposals[proposalId];
        forVotes     = p.voteFor;
        againstVotes = p.voteAgainst;
        passed       = forVotes > againstVotes;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function nextProposalId() external view returns (uint256) {
        return _nextProposalId;
    }
}
```

</details>

---

## Test Suite (Partial — Lengkapi sendiri!)

> Blok di bawah adalah **contoh ringkas** untuk dibaca. File `test/VotingSystem.t.sol` berisi suite yang **lebih lengkap** (14 test, sebagian dengan nama berbeda) — itulah spesifikasi yang harus Anda loloskan — **tanpa** test pada daftar TODO. Tulis test TODO tersebut di file itu. Referensi jawaban: `solutions/test/VotingSystem.t.sol` (lihat [`solutions/README.md`](solutions/README.md)) — buka hanya setelah test Anda lulus.

```solidity
// test/VotingSystem.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VotingSystem.sol";

contract VotingSystemTest is Test {
    VotingSystem public voting;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public dave  = makeAddr("dave");

    uint256 constant QUORUM   = 3;
    uint256 constant DURATION = 7 days;

    function setUp() public {
        vm.prank(owner);
        voting = new VotingSystem(QUORUM);
    }

    // Helper: Buat proposal dan return ID-nya
    function _createProposal(string memory desc) internal returns (uint256) {
        vm.prank(owner);
        return voting.createProposal(desc, DURATION);
    }

    function test_CreateProposal() public {
        uint256 id = _createProposal("Proposal 1: Increase reward");
        assertEq(id, 0);
        assertEq(voting.nextProposalId(), 1);

        VotingSystem.Proposal memory p = voting.getProposal(0);
        assertEq(p.description, "Proposal 1: Increase reward");
        assertEq(p.voteFor, 0);
        assertEq(p.voteAgainst, 0);
        assertFalse(p.executed);
        assertApproxEqAbs(p.deadline, block.timestamp + DURATION, 1);
    }

    function test_Vote_ForAndAgainst() public {
        _createProposal("Test proposal");

        vm.prank(alice); voting.vote(0, true);   // FOR
        vm.prank(bob);   voting.vote(0, false);  // AGAINST
        vm.prank(carol); voting.vote(0, true);   // FOR

        VotingSystem.Proposal memory p = voting.getProposal(0);
        assertEq(p.voteFor, 2);
        assertEq(p.voteAgainst, 1);
    }

    function test_ExecuteProposal_Passed() public {
        _createProposal("Passing proposal");

        vm.prank(alice); voting.vote(0, true);
        vm.prank(bob);   voting.vote(0, true);
        vm.prank(carol); voting.vote(0, true);
        vm.prank(dave);  voting.vote(0, false);

        // Lewati waktu voting
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VotingSystem.ProposalExecuted(0, true); // passed = true
        voting.executeProposal(0);

        (bool passed,,) = voting.getResult(0);
        assertTrue(passed);
    }

    function test_RevertWhen_DoubleVote() public {
        _createProposal("Test");
        vm.prank(alice);
        voting.vote(0, true);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(VotingSystem.AlreadyVoted.selector, alice, 0)
        );
        voting.vote(0, true);
    }

    function test_RevertWhen_VoteAfterDeadline() public {
        _createProposal("Test");
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingSystem.VotingEnded.selector, 0, block.timestamp - 1
            )
        );
        // Note: deadline sudah lewat
        voting.vote(0, true);
    }

    function test_RevertWhen_QuorumNotMet() public {
        _createProposal("Low turnout proposal");

        vm.prank(alice); voting.vote(0, true);
        vm.prank(bob);   voting.vote(0, true);
        // Hanya 2 votes, quorum = 3

        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(VotingSystem.QuorumNotMet.selector, 2, QUORUM)
        );
        voting.executeProposal(0);
    }

    // TODO: Lengkapi test berikut:
    // - test_CancelProposal_NoVotes()
    // - test_RevertWhen_CancelWithVotes()
    // - test_RevertWhen_ExecuteBeforeDeadline()
    // - test_RevertWhen_ExecuteTwice()
    // - test_MultipleProposals_IndependentState()
    // - testFuzz_VoteCount(uint8 forVotes, uint8 againstVotes)
}
```

---

## Soal Latihan Contract 2

### Soal 2 — Governance Attack Surface

```text
VotingSystem dipakai sebuah komunitas untuk memutuskan penggunaan dana kas.
Aturan: 1 address = 1 suara, quorumThreshold = 3, owner yang mengeksekusi proposal.
```

**Pertanyaan**:
- a) Membuat address baru di Ethereum gratis. Jelaskan bagaimana satu orang bisa memenangkan proposal sendirian (Sybil attack). Mengapa ini tidak terjadi di sistem voting Web2 berbasis akun login?
- b) Owner bisa memanggil `setQuorum()` kapan saja. Skenario apa yang membuat hal ini berbahaya bagi proposal yang **sedang berjalan**?
- c) Seorang developer ingin menambahkan fungsi `getActiveProposals()` yang me-loop seluruh array proposal. Apa risikonya ketika jumlah proposal mencapai puluhan ribu, dan apakah risiko itu berbeda untuk fungsi `view` vs fungsi yang mengubah state?

<details>
<summary>💡 Pembahasan</summary>

**a) Sybil Attack**:
Di Web2, identitas dijaga oleh server (email, nomor HP, KYC). Di Ethereum, address hanyalah hasil derivasi private key (Phase 3) — siapa pun bisa membuat ribuan address dalam hitungan detik tanpa biaya. Karena VotingSystem menghitung `1 address = 1 suara`, satu orang cukup membuat 3 wallet, mengisi sedikit ETH untuk gas, lalu memenuhi quorum sendirian.

Mitigasi umum:
- **Token-weighted voting**: bobot suara = jumlah token yang dimiliki (membuat address baru tidak menambah kekuatan).
- **Snapshot balance**: bobot diambil dari balance di block tertentu (mencegah pinjam token/flash loan lalu vote).
- **Allowlist / proof-of-personhood**: hanya address terverifikasi yang boleh vote.

**b) Mengubah Aturan di Tengah Permainan**:
Jika owner menurunkan quorum setelah melihat proposal yang ia sukai kekurangan suara (atau menaikkan quorum untuk menggagalkan proposal yang tidak ia sukai), hasil voting bisa dimanipulasi tanpa satu pun suara berubah. Solusinya: simpan nilai quorum **di dalam struct proposal saat proposal dibuat**, sehingga perubahan `setQuorum()` hanya berlaku untuk proposal berikutnya. Pola yang sama berlaku untuk parameter governance lain → biasanya dibungkus *timelock* (Phase 13).

**c) Unbounded Loop**:
- Untuk fungsi yang **mengubah state**, loop atas array yang terus bertambah akan suatu saat melebihi block gas limit → fungsi tidak bisa dipanggil sama sekali (DoS permanen).
- Untuk fungsi **`view`** yang dipanggil off-chain via `eth_call`, tidak ada biaya gas bagi user, tetapi RPC node tetap punya batas gas/timeout sehingga panggilan bisa gagal. Dan jika fungsi `view` itu dipanggil oleh contract lain di dalam transaksi, gas-nya tetap dibayar.
- Solusi: pagination (`getProposals(offset, limit)`) atau biarkan indexer off-chain (Phase 10) membaca event `ProposalCreated`.

</details>

---

---

# Contract 3: Crowdfunding

## Objective
Contract untuk menghimpun dana ETH dengan goal tertentu dan timelock. Jika goal tercapai → dana ditransfer ke creator. Jika tidak → semua donatur bisa refund.

---

## Spesifikasi

```
CONTRACT: Crowdfunding

State:
  - creator: address
  - goalAmount: uint256 (dalam wei)
  - deadline: uint256 (timestamp)
  - totalRaised: uint256
  - finalized: bool
  - succeeded: bool
  - donations: mapping(address => uint256)

Functions:
  - donate() → payable, sebelum deadline
  - finalize() → setelah deadline, siapapun bisa panggil (public)
  - refund() → hanya jika gagal dan finalized
  - getProgress() → view, returns (totalRaised, goal, percentage, timeLeft)
  - withdraw() → hanya creator, hanya jika succeeded dan finalized

Events:
  - Donated(address indexed donor, uint256 amount, uint256 totalRaised)
  - Finalized(bool succeeded, uint256 totalRaised)
  - Refunded(address indexed donor, uint256 amount)
  - Withdrawn(address indexed creator, uint256 amount)

Security Requirements:
  - CEI pattern untuk refund dan withdraw
  - Reentrancy guard
  - Tidak ada donation setelah deadline
  - Creator tidak bisa refund (tidak masuk akal semantically)
```

---

## 🛠️ Kerjakan: `src/Crowdfunding.sol`

1. Buka **`src/Crowdfunding.sol`** — starter berisi state, struct, event, error, signature, dan constructor. Semua body fungsi masih `revert NotImplemented()`.
2. Jalankan test sebagai spesifikasi: `forge test --match-contract CrowdfundingTest -vv` → awalnya **merah semua**.
3. Isi fungsi satu per satu sampai **19/19 test hijau**. Mulai dari `donate()`, lalu `finalize()`, lalu `refund()`/`withdraw()` dengan modifier `noReentrant`. Test `test_ReentrancyAttack_IsBlocked` baru lulus jika CEI Anda benar.
4. Baru setelah itu buka pembahasan di bawah dan bandingkan dengan implementasi Anda.

**✅ Kriteria lulus:**
- [ ] `forge test --match-contract CrowdfundingTest` → 19 passed, 0 failed
- [ ] Tidak ada `revert NotImplemented()` dan `error NotImplemented()` tersisa di file Anda
- [ ] Setiap fungsi state-changing mengikuti urutan Checks → Effects → Interactions
- [ ] Anda bisa menjelaskan alasan setiap custom error & event tanpa melihat pembahasan

---

## Implementation (Pembahasan)

<details>
<summary>💡 Lihat implementasi referensi — buka <b>setelah</b> test Anda lulus</summary>


```solidity
// src/Crowdfunding.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Crowdfunding
 * @notice A trustless crowdfunding contract with refund mechanism.
 * @dev Implements CEI pattern and reentrancy guard for security.
 *      Phase 5, Contract 3
 */
contract Crowdfunding {
    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    address payable public immutable CREATOR;
    uint256 public immutable GOAL;         // Target dalam wei
    uint256 public immutable DEADLINE;     // Unix timestamp

    uint256 public totalRaised;
    bool    public finalized;
    bool    public succeeded;

    // Reentrancy lock
    bool private _locked;

    mapping(address => uint256) private _donations;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Donated(
        address indexed donor,
        uint256 amount,
        uint256 newTotal
    );
    event Finalized(bool indexed succeeded, uint256 totalRaised);
    event Refunded(address indexed donor, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error CampaignEnded();
    error CampaignNotEnded();
    error CampaignNotFinalized();
    error AlreadyFinalized();
    error NoDonation(address donor);
    error NotCreator();
    error CampaignFailed();
    error CampaignSucceeded();
    error ZeroAmount();
    error ReentrantCall();
    error CreatorCannotRefund();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier noReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    modifier isFinalized() {
        if (!finalized) revert CampaignNotFinalized();
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    /**
     * @param goal The funding goal in wei.
     * @param durationSeconds Duration of the campaign in seconds.
     */
    constructor(uint256 goal, uint256 durationSeconds) {
        if (goal == 0) revert ZeroAmount();
        if (durationSeconds == 0) revert ZeroAmount();

        CREATOR  = payable(msg.sender);
        GOAL     = goal;
        DEADLINE = block.timestamp + durationSeconds;
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /**
     * @notice Donate ETH to the campaign.
     */
    function donate() external payable {
        if (block.timestamp >= DEADLINE) revert CampaignEnded();
        if (msg.value == 0) revert ZeroAmount();

        // Effects
        _donations[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit Donated(msg.sender, msg.value, totalRaised);
    }

    /**
     * @notice Finalize the campaign after the deadline.
     *         Anyone can call this — no centralized finalization.
     */
    function finalize() external {
        if (block.timestamp < DEADLINE) revert CampaignNotEnded();
        if (finalized) revert AlreadyFinalized();

        // Effects first
        finalized = true;
        succeeded = totalRaised >= GOAL;

        emit Finalized(succeeded, totalRaised);
    }

    /**
     * @notice Withdraw funds if campaign succeeded. Only creator.
     */
    function withdraw() external noReentrant isFinalized {
        if (msg.sender != CREATOR) revert NotCreator();
        if (!succeeded) revert CampaignFailed();

        uint256 amount = address(this).balance;

        // CEI: Effects before Interaction
        // Note: amount bisa 0 jika sudah ditarik, tapi tidak masalah
        // karena sudah ada check succeeded

        emit Withdrawn(CREATOR, amount);

        // Interaction
        (bool ok,) = CREATOR.call{value: amount}("");
        require(ok, "Withdraw failed");
    }

    /**
     * @notice Refund your donation if campaign failed.
     */
    function refund() external noReentrant isFinalized {
        if (succeeded) revert CampaignSucceeded();
        if (msg.sender == CREATOR) revert CreatorCannotRefund();

        uint256 amount = _donations[msg.sender];
        if (amount == 0) revert NoDonation(msg.sender);

        // CEI: Effects BEFORE Interaction
        _donations[msg.sender] = 0; // Zero out SEBELUM transfer!

        emit Refunded(msg.sender, amount);

        // Interaction
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Refund failed");
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    /**
     * @notice Get campaign progress details.
     */
    function getProgress() external view returns (
        uint256 raised,
        uint256 goal,
        uint256 percentageWei, // percentage * 1e18 (untuk presisi)
        uint256 timeLeft
    ) {
        raised     = totalRaised;
        goal       = GOAL;
        percentageWei = GOAL > 0 ? (totalRaised * 1e18) / GOAL : 0;
        timeLeft   = block.timestamp >= DEADLINE ? 0 : DEADLINE - block.timestamp;
    }

    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }

    function isActive() external view returns (bool) {
        return !finalized && block.timestamp < DEADLINE;
    }
}
```

</details>

---

## Test: Reentrancy Attack PoC

```solidity
// test/Crowdfunding.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";

// Attacker contract yang mencoba reentrancy
contract ReentrancyAttacker {
    Crowdfunding public target;
    uint256 public attackCount;
    
    constructor(address _target) {
        target = Crowdfunding(_target);
    }
    
    function attack() external payable {
        target.donate{value: msg.value}();
    }
    
    // Receive ETH + coba reenter
    receive() external payable {
        attackCount++;
        if (attackCount < 5 && address(target).balance > 0) {
            // Coba panggil refund lagi!
            try target.refund() {
                // Berhasil reenter — ini adalah bug!
            } catch {
                // Revert — reentrancy guard bekerja!
            }
        }
    }
}

contract CrowdfundingTest is Test {
    Crowdfunding public cf;

    address payable public creator = payable(makeAddr("creator"));
    address public alice  = makeAddr("alice");
    address public bob    = makeAddr("bob");
    address public carol  = makeAddr("carol");

    uint256 constant GOAL     = 10 ether;
    uint256 constant DURATION = 30 days;

    function setUp() public {
        vm.prank(creator);
        cf = new Crowdfunding(GOAL, DURATION);

        // Fund test addresses
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
    }

    // ===== DONATION TESTS =====

    function test_Donate_UpdatesState() public {
        vm.prank(alice);
        cf.donate{value: 3 ether}();

        assertEq(cf.totalRaised(), 3 ether);
        assertEq(cf.getDonation(alice), 3 ether);
    }

    function test_Donate_EmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Crowdfunding.Donated(alice, 3 ether, 3 ether);
        cf.donate{value: 3 ether}();
    }

    function test_RevertWhen_DonateAfterDeadline() public {
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(alice);
        vm.expectRevert(Crowdfunding.CampaignEnded.selector);
        cf.donate{value: 1 ether}();
    }

    // ===== SUCCESS SCENARIO =====

    function test_SuccessfulCampaign_CreatorWithdraws() public {
        // Semua donate sampai goal tercapai
        vm.prank(alice); cf.donate{value: 5 ether}();
        vm.prank(bob);   cf.donate{value: 5 ether}();

        assertEq(cf.totalRaised(), 10 ether);

        // Lewati deadline
        vm.warp(block.timestamp + DURATION + 1);

        // Finalize
        cf.finalize();
        assertTrue(cf.succeeded());
        assertTrue(cf.finalized());

        // Creator withdraw
        uint256 creatorBalanceBefore = creator.balance;
        vm.prank(creator);
        cf.withdraw();
        assertEq(creator.balance, creatorBalanceBefore + 10 ether);
        assertEq(address(cf).balance, 0);
    }

    // ===== FAILURE SCENARIO =====

    function test_FailedCampaign_DonorsRefund() public {
        vm.prank(alice); cf.donate{value: 2 ether}();
        vm.prank(bob);   cf.donate{value: 3 ether}();
        // Total: 5 ETH < 10 ETH goal → FAIL

        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();
        assertFalse(cf.succeeded());

        // Alice refund
        uint256 aliceBalanceBefore = alice.balance;
        vm.prank(alice);
        cf.refund();
        assertEq(alice.balance, aliceBalanceBefore + 2 ether);
        assertEq(cf.getDonation(alice), 0);

        // Bob refund
        uint256 bobBalanceBefore = bob.balance;
        vm.prank(bob);
        cf.refund();
        assertEq(bob.balance, bobBalanceBefore + 3 ether);
    }

    // ===== REENTRANCY ATTACK TEST =====

    function test_ReentrancyAttack_IsBlocked() public {
        // Deploy attacker
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(cf));
        vm.deal(address(attacker), 10 ether);

        // Attacker donate
        attacker.attack{value: 1 ether}();

        // Alice juga donate (agar ada dana untuk dicuri)
        vm.prank(alice);
        cf.donate{value: 5 ether}();

        // Campaign gagal
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        // Attacker coba reentrancy attack — harus diblokir!
        uint256 contractBalanceBefore = address(cf).balance;
        vm.prank(address(attacker));
        cf.refund(); // Attack dilakukan di sini via receive()

        // Attacker hanya berhasil ambil 1 ETH (bukan lebih)
        assertEq(cf.getDonation(address(attacker)), 0);
        // Contract masih punya 5 ETH milik alice
        assertEq(address(cf).balance, contractBalanceBefore - 1 ether);
        // Reentrancy counter: seharusnya hanya 1 (tidak ada multiple reentry)
        assertEq(attacker.attackCount(), 1);
    }

    // ===== REVERT TESTS =====

    function test_RevertWhen_NonCreatorWithdraws() public {
        vm.prank(alice); cf.donate{value: 10 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.prank(alice);
        vm.expectRevert(Crowdfunding.NotCreator.selector);
        cf.withdraw();
    }

    function test_RevertWhen_RefundOnSuccess() public {
        vm.prank(alice); cf.donate{value: 10 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.prank(alice);
        vm.expectRevert(Crowdfunding.CampaignSucceeded.selector);
        cf.refund();
    }

    function test_RevertWhen_FinalizeBeforeDeadline() public {
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        cf.finalize();
    }

    function test_RevertWhen_FinalizeMultipleTimes() public {
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.expectRevert(Crowdfunding.AlreadyFinalized.selector);
        cf.finalize();
    }
}
```

---

## Soal Latihan Contract 3

### Soal 3 — ETH Accounting & Refund Design

```text
Campaign: goal = 10 ETH, deadline = 30 hari.
Saat deadline: totalRaised = 9 ETH, tetapi address(this).balance = 10.5 ETH.
```

**Pertanyaan**:
- a) Bagaimana mungkin `address(this).balance` lebih besar dari `totalRaised`, padahal `Crowdfunding` tidak punya fungsi `receive()` atau `fallback()`? Sebutkan minimal dua cara.
- b) Seorang developer mengusulkan `succeeded = address(this).balance >= GOAL` agar "lebih akurat". Mengapa ini justru membuka celah?
- c) Bandingkan desain `refund()` (setiap donor menarik dananya sendiri) dengan desain `refundAll()` yang me-loop semua donor dan mengirim ETH satu per satu. Apa yang bisa dilakukan satu donor jahat terhadap desain kedua?
- d) Apa yang terjadi jika tidak ada seorang pun yang memanggil `finalize()` setelah deadline? Apakah dana terkunci selamanya?

<details>
<summary>💡 Pembahasan</summary>

**a) Forced ETH**:
ETH bisa masuk ke contract **tanpa** melewati fungsi apa pun:
1. `selfdestruct(payable(target))` dari contract lain — ETH dipaksa terkirim. (Sejak EIP-6780/Cancun, `selfdestruct` tidak lagi menghapus contract kecuali di transaksi yang sama dengan pembuatannya, tetapi **pengiriman ETH-nya tetap terjadi**.)
2. Address contract dijadikan penerima *block reward / priority fee* (coinbase) oleh validator.
3. ETH dikirim ke address tersebut **sebelum** contract di-deploy (address contract bisa diprediksi dari deployer + nonce, atau via `CREATE2`).

**b) Jangan Gunakan `address(this).balance` untuk Logika Bisnis**:
Karena balance bisa dimanipulasi dari luar, siapa pun bisa "mendorong" campaign menjadi sukses dengan mengirim paksa ETH, lalu creator menarik seluruh dana — termasuk donasi user yang seharusnya di-refund. Gunakan **internal accounting** (`totalRaised`) sebagai sumber kebenaran; balance hanya boleh dipakai untuk transfer sisa saldo.

**c) Pull over Push**:
Pada `refundAll()`, jika satu donor adalah contract yang `receive()`-nya selalu `revert`, seluruh loop gagal → **tidak ada satu donor pun yang bisa refund** (DoS). Loop juga bisa melebihi block gas limit jika donor banyak. Desain pull (`refund()` per donor) mengisolasi kegagalan: donor jahat hanya merugikan dirinya sendiri.

**d) Liveness**:
Dana tidak hilang, tetapi `refund()` dan `withdraw()` dilindungi modifier `isFinalized`, jadi keduanya menunggu `finalize()`. Karena `finalize()` bisa dipanggil **siapa saja** setelah deadline, donor yang ingin refund cukup memanggilnya sendiri. Ini contoh desain yang tidak bergantung pada satu pihak (owner) untuk menjaga dana tetap bisa diakses. Bandingkan jika `finalize()` diberi `onlyCreator` — creator yang kampanyenya gagal bisa menyandera dana donor.

</details>

---

---

# Contract 4: ERC-20 Token (From Scratch)

> 🛑 **Untuk belajar, bukan untuk produksi.** Contract ini ditulis dari nol agar Anda memahami cara kerja standar secara mendalam. Untuk token yang akan memegang nilai nyata, gunakan implementasi yang sudah diaudit dan dipakai luas seperti [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/) (`ERC20`, `ERC721`, `ERC2981`), lalu audit integrasinya. Setelah Anda menyelesaikan bagian ini, bandingkan implementasi Anda dengan kode OpenZeppelin v5.6.1 di `lib/openzeppelin-contracts/` dan catat minimal 3 perbedaan di **🗒️ Notes**.

## Objective
Implement ERC-20 standard **dari nol** sesuai [EIP-20](https://eips.ethereum.org/EIPS/eip-20). Ini adalah cara terbaik untuk benar-benar memahami bagaimana token bekerja.

---

## EIP-20 Standard: Apa yang Wajib Diimplementasikan?

```
WAJIB (MUST):
  - name()              → string
  - symbol()            → string
  - decimals()          → uint8 (biasanya 18)
  - totalSupply()       → uint256
  - balanceOf(address)  → uint256
  - transfer(address, uint256) → bool
  - allowance(address, address) → uint256
  - approve(address, uint256)   → bool
  - transferFrom(address, address, uint256) → bool

WAJIB emit EVENT:
  - Transfer(address indexed from, address indexed to, uint256 value)
    ← termasuk saat mint (from = 0x0) dan burn (to = 0x0)
  - Approval(address indexed owner, address indexed spender, uint256 value)

TIDAK WAJIB (tapi best practice):
  - mint() — untuk token dengan supply yang bisa bertambah
  - burn() — untuk token yang bisa dibakar
  - permit() — EIP-2612 gasless approval
```

---

## 🛠️ Kerjakan: `src/ERC20Token.sol`

1. Buka **`src/ERC20Token.sol`** — starter berisi state, struct, event, error, signature, dan constructor. Semua body fungsi masih `revert NotImplemented()`.
2. Jalankan test sebagai spesifikasi: `forge test --match-contract ERC20TokenTest -vv` → awalnya **merah semua**.
3. Isi fungsi satu per satu sampai **26/26 test hijau**. **Implementasikan `_mint` lebih dulu** — constructor memanggilnya, sehingga `setUp()` gagal dan seluruh suite merah sampai `_mint` selesai. Lalu `transfer`, `approve`, `transferFrom`, `burn`.
4. Baru setelah itu buka pembahasan di bawah dan bandingkan dengan implementasi Anda.

**✅ Kriteria lulus:**
- [ ] `forge test --match-contract ERC20TokenTest` → 26 passed, 0 failed
- [ ] Tidak ada `revert NotImplemented()` dan `error NotImplemented()` tersisa di file Anda
- [ ] Setiap fungsi state-changing mengikuti urutan Checks → Effects → Interactions
- [ ] Anda bisa menjelaskan alasan setiap custom error & event tanpa melihat pembahasan

---

## Implementation (Pembahasan)

<details>
<summary>💡 Lihat implementasi referensi — buka <b>setelah</b> test Anda lulus</summary>


```solidity
// src/ERC20Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ERC20Token
 * @notice ERC-20 token implementation from scratch (no library dependencies).
 * @dev Implements EIP-20 standard. Includes mint and burn capabilities.
 *      Phase 5, Contract 4
 */
contract ERC20Token {
    // =========================================================
    //                      METADATA
    // =========================================================

    string  public name;
    string  public symbol;
    uint8   public constant decimals = 18;

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256)                     public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // =========================================================
    //                         EVENTS
    // =========================================================

    // EIP-20 required events
    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender,  uint256 value);

    // Extra events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error ZeroAddress();
    error InsufficientBalance(address account, uint256 available, uint256 needed);
    error InsufficientAllowance(address owner, address spender, uint256 available, uint256 needed);
    error NotOwner();
    error ZeroAmount();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    /**
     * @param _name Token name (e.g., "Wrapped Ether")
     * @param _symbol Token symbol (e.g., "WETH")
     * @param initialSupply Initial tokens minted to deployer (in whole tokens, not wei)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) {
        name   = _name;
        symbol = _symbol;
        owner  = msg.sender;

        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply * 10 ** decimals);
        }
    }

    // =========================================================
    //                  EIP-20 REQUIRED FUNCTIONS
    // =========================================================

    /**
     * @notice Transfer tokens from caller to recipient.
     * @param to Recipient address.
     * @param amount Amount in smallest unit (wei equivalent).
     * @return True on success (always, reverts on failure).
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Approve spender to use caller's tokens.
     * @param spender Address allowed to spend.
     * @param amount Maximum amount allowed.
     * @return True on success.
     *
     * @dev ⚠️ SECURITY NOTE: This is subject to approval race condition.
     *      To change allowance from N to M, first set to 0, then to M.
     *      See: https://eips.ethereum.org/EIPS/eip-20#approve
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another (using allowance).
     * @param from Source address.
     * @param to Recipient address.
     * @param amount Amount to transfer.
     * @return True on success.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];

        // Check allowance (unless using infinite approval)
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert InsufficientAllowance(from, msg.sender, currentAllowance, amount);
            }
            // Effects: decrease allowance
            allowance[from][msg.sender] = currentAllowance - amount;
            emit Approval(from, msg.sender, currentAllowance - amount);
        }

        _transfer(from, to, amount);
        return true;
    }

    // =========================================================
    //                   EXTENDED FUNCTIONS
    // =========================================================

    /**
     * @notice Increase allowance by a delta. Safer than approve for changes.
     */
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        uint256 newAllowance = allowance[msg.sender][spender] + addedAmount;
        allowance[msg.sender][spender] = newAllowance;
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Decrease allowance by a delta.
     */
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        uint256 currentAllowance = allowance[msg.sender][spender];
        if (currentAllowance < subtractedAmount) {
            revert InsufficientAllowance(msg.sender, spender, currentAllowance, subtractedAmount);
        }
        uint256 newAllowance = currentAllowance - subtractedAmount;
        allowance[msg.sender][spender] = newAllowance;
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Mint new tokens. Only owner.
     * @param to Recipient of new tokens.
     * @param amount Amount in wei (smallest unit).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens from caller's balance.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Burn tokens from an allowance.
     */
    function burnFrom(address from, uint256 amount) external {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance < amount) {
            revert InsufficientAllowance(from, msg.sender, currentAllowance, amount);
        }
        allowance[from][msg.sender] = currentAllowance - amount;
        emit Approval(from, msg.sender, currentAllowance - amount);
        _burn(from, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address old = owner;
        owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }

    // =========================================================
    //                     INTERNAL FUNCTIONS
    // =========================================================

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        uint256 fromBalance = balanceOf[from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, fromBalance, amount);
        }

        // Effects
        balanceOf[from] = fromBalance - amount;
        balanceOf[to]  += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        totalSupply    += amount;
        balanceOf[to]  += amount;

        // EIP-20: mint is Transfer from address(0)
        emit Transfer(address(0), to, amount);
        emit Minted(to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        if (from == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        uint256 fromBalance = balanceOf[from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, fromBalance, amount);
        }

        balanceOf[from] = fromBalance - amount;
        totalSupply    -= amount;

        // EIP-20: burn is Transfer to address(0)
        emit Transfer(from, address(0), amount);
        emit Burned(from, amount);
    }
}
```

</details>

---

## Soal Latihan Contract 4

### Soal 4 — Approval Race Condition

```text
Skenario: Alice memberikan Bob allowance 100 token untuk spend.
Kemudian Alice ingin ubah allowance menjadi 50 token.
```

**Pertanyaan**:
- a) Jelaskan secara step-by-step bagaimana Bob bisa exploit race condition untuk menggunakan 150 token total (bukan 50).
- b) Mengapa fungsi `increaseAllowance()` dan `decreaseAllowance()` menyelesaikan masalah ini?
- c) EIP-20 sendiri mengakui masalah ini — apa yang direkomendasikan oleh spec asli untuk mitigasi?

<details>
<summary>💡 Pembahasan</summary>

**a) Race Condition Attack**:
```
1. Alice: approve(Bob, 100)          → tx masuk mempool
   Bob monitor mempool, lihat txA pending

2. Alice: approve(Bob, 50)           → txB masuk mempool (intended change)
   Bob juga lihat txB pending

3. Bob front-run: transferFrom(Alice, Bob, 100) → txC dengan higher gas
   Urutan eksekusi: txA (approve 100) → txC (spend 100) → txB (approve 50)
   
4. Hasil: Bob sudah spend 100, allowance sekarang 50
   Bob: transferFrom(Alice, Bob, 50) → spend 50 lagi!
   TOTAL: Bob mengambil 150 token dari Alice!
```

**b)** `increaseAllowance(Bob, -50)` tidak mengganti nilai absolut — ia mengurangi dari nilai saat ini. Race condition tidak mungkin terjadi karena:
```
Alice: decreaseAllowance(Bob, 50)
  → allowance[Alice][Bob] = currentAllowance - 50

Bahkan jika Bob front-run dan spend dulu:
  → currentAllowance sudah berkurang setelah Bob spend
  → decreaseAllowance akan beroperasi pada nilai yang sudah benar
```

**c)** EIP-20 spec asli merekomendasikan: "To avoid this, clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender." Ini adalah rekomendasi di level UI/UX, bukan di level protocol.

</details>

---

---

# Contract 5: NFT Collection (ERC-721)

> 🛑 **Untuk belajar, bukan untuk produksi.** Contract ini ditulis dari nol agar Anda memahami cara kerja standar secara mendalam. Untuk token yang akan memegang nilai nyata, gunakan implementasi yang sudah diaudit dan dipakai luas seperti [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/) (`ERC20`, `ERC721`, `ERC2981`), lalu audit integrasinya. Setelah Anda menyelesaikan bagian ini, bandingkan implementasi Anda dengan kode OpenZeppelin v5.6.1 di `lib/openzeppelin-contracts/` dan catat minimal 3 perbedaan di **🗒️ Notes**.

## Objective
Implementasi NFT collection dengan minting phases, metadata on-chain dan off-chain, royalties (EIP-2981), dan reveal mechanism.

---

## EIP-721 Standard: Apa yang Wajib Diimplementasikan?

```
WAJIB:
  - balanceOf(address) → uint256 (berapa NFT dimiliki address ini)
  - ownerOf(uint256 tokenId) → address (siapa owner NFT ini)
  - safeTransferFrom(address from, address to, uint256 tokenId)
  - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
  - transferFrom(address from, address to, uint256 tokenId)
  - approve(address to, uint256 tokenId)
  - getApproved(uint256 tokenId) → address
  - setApprovalForAll(address operator, bool approved)
  - isApprovedForAll(address owner, address operator) → bool
  - supportsInterface(bytes4 interfaceId) → bool (EIP-165)

WAJIB emit EVENT:
  - Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
  - Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
  - ApprovalForAll(address indexed owner, address indexed operator, bool approved)

METADATA EXTENSION (EIP-721 Metadata):
  - name() → string
  - symbol() → string
  - tokenURI(uint256 tokenId) → string

EIP-2981 Royalty Standard:
  - royaltyInfo(uint256 tokenId, uint256 salePrice) → (address receiver, uint256 royaltyAmount)
```

---

## 🛠️ Kerjakan: `src/NFTCollection.sol`

1. Buka **`src/NFTCollection.sol`** — starter berisi state, struct, event, error, signature, dan constructor. Semua body fungsi masih `revert NotImplemented()`.
2. Jalankan test sebagai spesifikasi: `forge test --match-contract NFTCollectionTest -vv` → awalnya **merah semua**.
3. Isi fungsi satu per satu sampai **27/27 test hijau**. Mulai dari `balanceOf`/`ownerOf` & mint internal, lalu `mint()`, approval, `transferFrom`, `safeTransferFrom` (receiver check), `tokenURI`/reveal, `supportsInterface`, `royaltyInfo`.
4. Baru setelah itu buka pembahasan di bawah dan bandingkan dengan implementasi Anda.

**✅ Kriteria lulus:**
- [ ] `forge test --match-contract NFTCollectionTest` → 27 passed, 0 failed
- [ ] Tidak ada `revert NotImplemented()` dan `error NotImplemented()` tersisa di file Anda
- [ ] Setiap fungsi state-changing mengikuti urutan Checks → Effects → Interactions
- [ ] Anda bisa menjelaskan alasan setiap custom error & event tanpa melihat pembahasan

---

## Implementation (Pembahasan)

<details>
<summary>💡 Lihat implementasi referensi — buka <b>setelah</b> test Anda lulus</summary>


```solidity
// src/NFTCollection.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title NFTCollection
 * @notice ERC-721 NFT collection with phased minting, royalties, and reveal.
 * @dev Implements EIP-721, EIP-721 Metadata, EIP-2981, EIP-165
 *      Phase 5, Contract 5
 */
contract NFTCollection {
    // =========================================================
    //                      METADATA
    // =========================================================

    string public name;
    string public symbol;

    // =========================================================
    //                   COLLECTION CONFIG
    // =========================================================

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MINT_PRICE;        // ETH price per NFT
    uint256 public immutable MAX_PER_WALLET;    // Max NFTs per wallet

    address payable public owner;
    uint96  public royaltyBps; // Basis points (1% = 100 bps, 5% = 500 bps)

    // Minting state
    bool    public revealed;       // Apakah metadata sudah di-reveal?
    bool    public publicSaleOpen; // Apakah public sale aktif?
    string  public baseURI;        // URI metadata prefix
    string  public unrevealedURI;  // URI sebelum reveal
    uint256 private _nextTokenId;

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    // EIP-721 core state
    mapping(uint256 => address) private _owners;         // tokenId → owner
    mapping(address => uint256) private _balances;        // owner → count
    mapping(uint256 => address) private _tokenApprovals;  // tokenId → approved address
    // owner → operator → approved
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Collection specific
    mapping(address => uint256) public mintedPerWallet;   // wallet → amount minted

    // =========================================================
    //                   INTERFACE IDs (EIP-165)
    // =========================================================

    bytes4 private constant _INTERFACE_ID_ERC721        = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_META   = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC2981       = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC165        = 0x01ffc9a7;

    // =========================================================
    //                         EVENTS
    // =========================================================

    // EIP-721 required events
    event Transfer(address indexed from,  address indexed to,       uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved,  uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Collection-specific events
    event Minted(address indexed to, uint256 indexed tokenId);
    event Revealed(string baseURI);
    event SaleToggled(bool isOpen);
    event Withdrawn(address indexed to, uint256 amount);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error NotOwner();
    error ZeroAddress();
    error TokenNotFound(uint256 tokenId);
    error NotTokenOwner(address caller, address actualOwner);
    error NotApproved(address caller, uint256 tokenId);
    error SaleNotOpen();
    error MaxSupplyReached(uint256 maxSupply);
    error MaxPerWalletReached(address wallet, uint256 max);
    error InsufficientPayment(uint256 sent, uint256 required);
    error UnsafeRecipient(address recipient);
    error SelfApproval();
    error WithdrawFailed();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 maxPerWallet,
        uint96  _royaltyBps,
        string memory _unrevealedURI
    ) {
        name           = _name;
        symbol         = _symbol;
        MAX_SUPPLY     = maxSupply;
        MINT_PRICE     = mintPrice;
        MAX_PER_WALLET = maxPerWallet;
        royaltyBps     = _royaltyBps;
        unrevealedURI  = _unrevealedURI;
        owner          = payable(msg.sender);
    }

    // =========================================================
    //                    MINTING FUNCTIONS
    // =========================================================

    /**
     * @notice Mint NFTs in public sale.
     * @param quantity Number of NFTs to mint.
     */
    function mint(uint256 quantity) external payable {
        if (!publicSaleOpen) revert SaleNotOpen();
        if (_nextTokenId + quantity > MAX_SUPPLY) {
            revert MaxSupplyReached(MAX_SUPPLY);
        }
        if (mintedPerWallet[msg.sender] + quantity > MAX_PER_WALLET) {
            revert MaxPerWalletReached(msg.sender, MAX_PER_WALLET);
        }
        if (msg.value < MINT_PRICE * quantity) {
            revert InsufficientPayment(msg.value, MINT_PRICE * quantity);
        }

        // Effects
        mintedPerWallet[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @notice Owner can airdrop NFTs (e.g., for team allocation, giveaways).
     */
    function airdrop(address to, uint256 quantity) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (_nextTokenId + quantity > MAX_SUPPLY) {
            revert MaxSupplyReached(MAX_SUPPLY);
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _mint(to, tokenId);
        }
    }

    // =========================================================
    //                   EIP-721 CORE FUNCTIONS
    // =========================================================

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert ZeroAddress();
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert TokenNotFound(tokenId);
        return tokenOwner;
    }

    function approve(address to, uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        if (to == tokenOwner) revert SelfApproval();
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender]) {
            revert NotApproved(msg.sender, tokenId);
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        if (_owners[tokenId] == address(0)) revert TokenNotFound(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert SelfApproval();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _checkApprovedOrOwner(msg.sender, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _checkApprovedOrOwner(msg.sender, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    // =========================================================
    //                    METADATA FUNCTIONS
    // =========================================================

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert TokenNotFound(tokenId);

        if (!revealed) {
            return unrevealedURI;
        }

        return string.concat(baseURI, _toString(tokenId), ".json");
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // =========================================================
    //                    EIP-2981 ROYALTIES
    // =========================================================

    /**
     * @notice Get royalty info for a token sale.
     * @param salePrice The sale price of the token.
     * @return receiver The royalty recipient (owner).
     * @return royaltyAmount The royalty amount to pay.
     */
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver      = owner;
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    // =========================================================
    //                   EIP-165 INTERFACE SUPPORT
    // =========================================================

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ERC721     ||
            interfaceId == _INTERFACE_ID_ERC721_META ||
            interfaceId == _INTERFACE_ID_ERC2981    ||
            interfaceId == _INTERFACE_ID_ERC165;
    }

    // =========================================================
    //                  OWNER ADMIN FUNCTIONS
    // =========================================================

    function toggleSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
        emit SaleToggled(publicSaleOpen);
    }

    function reveal(string calldata _baseURI) external onlyOwner {
        revealed = true;
        baseURI  = _baseURI;
        emit Revealed(_baseURI);
    }

    function setRoyalty(uint96 newBps) external onlyOwner {
        royaltyBps = newBps;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        emit Withdrawn(owner, balance);

        (bool ok,) = owner.call{value: balance}("");
        if (!ok) revert WithdrawFailed();
    }

    // =========================================================
    //                    INTERNAL FUNCTIONS
    // =========================================================

    function _mint(address to, uint256 tokenId) internal {
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
        emit Minted(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotTokenOwner(from, ownerOf(tokenId));
        if (to == address(0)) revert ZeroAddress();

        // Clear approval on transfer
        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function _checkApprovedOrOwner(address spender, uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId);
        if (
            spender != tokenOwner &&
            !_operatorApprovals[tokenOwner][spender] &&
            _tokenApprovals[tokenId] != spender
        ) {
            revert NotApproved(spender, tokenId);
        }
    }

    /**
     * @dev Check if recipient contract can handle ERC-721 tokens.
     *      Prevents tokens from being locked in non-compatible contracts.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 retval
            ) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert UnsafeRecipient(to);
                }
            } catch {
                revert UnsafeRecipient(to);
            }
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// Minimal IERC721Receiver interface
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```

</details>

---

## Soal Latihan Contract 5

### Soal 5 — Metadata & Reveal Mechanism

```text
NFT project "PixelCats" menggunakan reveal mechanism:
- Pre-reveal: semua NFT tampil gambar kotak misterius
- Post-reveal: setiap tokenId punya gambar kucing unik

tokenURI(0) sebelum reveal → "ipfs://QmUnrevealed/unrevealed.json"
tokenURI(0) setelah reveal → "ipfs://QmCats/0.json"
tokenURI(99) setelah reveal → "ipfs://QmCats/99.json"
```

**Pertanyaan**:
- a) Apa kelemahan dari menyimpan metadata on-chain (dalam contract storage) dibanding IPFS?
- b) Mengapa attacker bisa tahu trait rarity setiap NFT SEBELUM reveal, meskipun gambar disembunyikan? (Hint: blockchain is transparent)
- c) Bagaimana cara yang lebih baik untuk mencegah trait sniping sebelum reveal?

<details>
<summary>💡 Pembahasan</summary>

**a) On-chain metadata vs IPFS**:
- **On-chain**: Metadata permanen (tidak bisa berubah/hilang), tapi sangat mahal: di storage ±690 gas per byte (22.100 gas per slot 32 byte); sebagai bytecode contract (pola *SSTORE2*) ±200 gas per byte. Untuk SVG sederhana mungkin OK. Untuk gambar kompleks: jutaan gas.
- **IPFS**: Murah (hanya simpan CID hash), tapi bergantung pada IPFS gateway yang masih aktif. Jika tidak ada yang pin file tersebut, data bisa hilang. Solusi: gunakan `ipfs://` bukan `https://ipfs.io/ipfs/` agar client memilih gateway sendiri.

**b) Trait Sniping Attack**:
Bahkan jika gambar disembunyikan, trait rarity biasanya ditentukan saat minting berdasarkan token ID dan seed random. Attacker bisa:
1. Lihat seed random yang dipakai (biasanya `block.timestamp`, `block.number`, atau `prevrandao`)
2. Simulasikan algoritma trait assignment untuk setiap tokenId
3. Tahu beforehand bahwa tokenId 42 = "Legendary tier" sebelum reveal
4. Mint atau beli tokenId tersebut sebelum orang lain tahu

**c) Solusi untuk mencegah trait sniping**:
- **Chainlink VRF**: Gunakan verifiable random number yang tidak bisa diprediksi dari on-chain data
- **Commit-Reveal**: Tentukan seed setelah semua mint selesai, bukan saat minting
- **Delayed Trait Assignment**: Trait tidak di-assign saat mint, tapi saat reveal menggunakan external randomness yang baru tersedia setelah semua mint
- **Metatransaction-based reveal**: Reveal dilakukan oleh server off-chain setelah verifikasi bahwa seluruh mint selesai

</details>

---

---

# 🏆 Challenge: DeFi Mini-Protocol

> *Integrasikan semua 5 contract yang Anda buat ke dalam satu protokol.*

## Deskripsi

Buat `TokenStaking.sol` yang mengintegrasikan `ERC20Token` dan memberikan reward:

```
PROTOCOL:
  - User stake ERC20Token (reward token = token yang sama, dengan minting)
  - Reward dihitung berdasarkan: jumlah staked × rate × waktu
  - Rate: 1% per hari (100 bps)
  - Minimum stake: 100 token
  - Lock period: 7 hari

FUNCTIONS:
  - stake(uint256 amount) → transfer token dari user ke contract
  - unstake() → setelah 7 hari, kembalikan token + reward
  - claimReward() → claim reward tanpa unstake (setelah 1 hari)
  - getReward(address user) → view, hitung pending reward
  - getStakeInfo(address user) → view, returns (amount, since, lockEnd)

SECURITY:
  - Reentrancy guard
  - CEI pattern
  - Tidak bisa unstake sebelum lock period
```

---

## Tugas Challenge

> *`src/TokenStaking.sol` berisi **starter** (signature fungsi + parameter dari spesifikasi, semua fungsi masih `revert NotImplemented()`). Implementasi referensi ada di `solutions/src/TokenStaking.sol` — buka hanya setelah Anda selesai.*

1. **Implementasi**: lengkapi `src/TokenStaking.sol` sesuai spesifikasi di atas (struct, custom errors, events, NatSpec seperti contract 1–5).
2. **Test suite** `test/TokenStaking.t.sol` (buat sendiri — file ini sengaja belum ada) yang mencakup minimal skenario berikut:

| Kategori | Skenario yang wajib di-test |
|---|---|
| Stake | stake berhasil & token pindah ke contract; revert jika di bawah `MIN_STAKE`; revert jika sudah punya posisi stake; revert jika `approve` belum dilakukan |
| Reward | `getReward()` bernilai 0 tepat setelah stake; reward setelah 1 hari = 1% dari amount; reward setelah ½ hari (reward per detik, bukan per hari penuh) |
| Claim | revert jika claim < 1 hari sejak claim terakhir; claim berhasil setelah 1 hari & timer `lastClaim` ter-reset |
| Unstake | revert sebelum `LOCK_PERIOD`; unstake setelah 7 hari mengembalikan pokok + reward; `totalStaked` berkurang dengan benar |
| Integrasi | reward gagal di-mint jika `TokenStaking` tidak punya izin `mint` di `ERC20Token` |
| Fuzz | `testFuzz_RewardNeverExceedsFormula(uint256 amount, uint256 elapsed)` dengan `bound()` |

3. **Review keamanan** — tulis jawaban Anda di bagian **🗒️ Notes**:
   - Siapa yang berhak memanggil `mint()` di `ERC20Token`? Bagaimana `TokenStaking` mendapatkan hak itu, dan apa risikonya jika caranya adalah *transfer ownership*?
   - `unstake()` mengembalikan pokok **dan** me-mint reward dalam satu transaksi. Jika `mint` gagal, apa yang terjadi pada **pokok** milik user? Bagaimana desain yang memisahkan keduanya agar pokok selalu bisa ditarik? (Kaitkan dengan prinsip *isolasi kegagalan* di Phase 8 C7.)
   - Apakah nilai return `bool` dari `transfer`/`transferFrom` sudah diperiksa? Token apa di dunia nyata yang tidak me-revert saat gagal?
   - Reward di-*mint* tanpa batas. Apa dampaknya terhadap supply & harga token jika banyak user stake dalam jangka panjang? (Pemanasan untuk Phase 11 — Tokenomics.)

<details>
<summary>💡 Hint 1 — Rumus Reward</summary>

Rate 1% per hari = `100` basis points dari `10_000`. Agar reward bertambah **per detik**:

```text
reward = amount × REWARD_RATE × elapsedSeconds / (BASIS_POINTS × 1 days)
```

Perhatikan **urutan operasi**: Solidity tidak punya desimal, pembagian membulatkan ke bawah. Selalu **kalikan dulu, bagi terakhir**. Coba hitung manual apa yang terjadi jika Anda menulis `amount × (REWARD_RATE / BASIS_POINTS)`.

</details>

<details>
<summary>💡 Hint 2 — Mengetes Waktu</summary>

Gunakan cheatcode `vm.warp(block.timestamp + 1 days)` untuk memajukan waktu, dan `vm.prank(user)` + `token.approve(address(staking), amount)` sebelum `stake()`. Lihat Phase 6 — C4: *ETH Balance & Time Manipulation*.

</details>

<details>
<summary>💡 Hint 3 — Minting Authority</summary>

Baca kembali modifier pada fungsi `mint()` di `src/ERC20Token.sol`, lalu baca `script/Deploy.s.sol` bagian Challenge. Apakah setelah deploy, `TokenStaking` benar-benar bisa mint reward? Pikirkan pola yang lebih aman daripada memindahkan ownership penuh (petunjuk: *role-based access control*).

</details>

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Implementasi `src/TokenStaking.sol` + test kategori **Stake, Reward, Claim, Unstake** |
| 🟡 **Extended** — disarankan | Test kategori **Integrasi** & **Fuzz** + jawab 4 pertanyaan *Review keamanan* |
| 🔴 **Stretch** — untuk portfolio | Perbaiki desain (role minter terpisah, pokok tetap bisa ditarik walau mint gagal) dan buktikan dengan test |

### ✅ Kriteria Lulus (Core)

- [ ] `forge test --match-contract TokenStaking` hijau dengan minimal 1 test per baris tabel kategori Core
- [ ] Reward setelah tepat 1 hari = 1% dari pokok (assert nilai eksak, bukan `> 0`)
- [ ] Unstake sebelum `LOCK_PERIOD` dan claim < 1 hari → revert dengan custom error Anda
- [ ] Tidak ada `NotImplemented` tersisa di `src/TokenStaking.sol`

---

---

# 🚀 Deployment: Anvil → Sepolia

> *Prasyarat: Phase 6 — C6 (anvil) dan C7 (Deployment Scripts). Semua contract & test harus sudah lulus `forge test`.*

Script deployment sudah tersedia di `script/Deploy.s.sol` (contract `DeployAll`). Tugas Anda adalah **menjalankannya sendiri** dan memahami setiap langkah.

> ⚠️ Script men-deploy kode di `src/` — yaitu **implementasi Anda**. Selama masih ada `NotImplemented()`, deployment akan gagal (`ERC20Token` memanggil `_mint` di constructor). Selesaikan contract 1–5 dulu. Untuk sekadar mencoba alur deployment dengan implementasi referensi: `FOUNDRY_PROFILE=solutions forge script ...`.

## Langkah 1 — Konfigurasi `.env`

```bash
cp .env.example .env
# Isi SEPOLIA_RPC_URL dan ETHERSCAN_API_KEY.
# PRIVATE_KEY di .env.example adalah key default anvil account #0 — PUBLIK, hanya untuk lokal!
# Untuk Sepolia gunakan wallet KHUSUS testnet, jangan wallet utama Anda.

source .env
```

## Langkah 2 — Dry Run & Deploy ke Anvil

```bash
# Terminal 1
anvil

# Terminal 2 — simulasi tanpa broadcast
forge script script/Deploy.s.sol:DeployAll --rpc-url anvil

# Deploy sungguhan ke anvil
forge script script/Deploy.s.sol:DeployAll --rpc-url anvil --broadcast
```

## Langkah 3 — Deploy ke Sepolia + Verify

```bash
forge script script/Deploy.s.sol:DeployAll \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

> Butuh Sepolia ETH dari faucet. Hasil broadcast tersimpan di `broadcast/` (sudah di-`.gitignore`).

## Langkah 4 — Catat Hasil Deployment

Buat `deployments/sepolia.md` (atau `.json`) berisi: nama contract, address, tx hash, block number, dan link Etherscan. Folder ini **yang** di-commit — bukan `broadcast/`.

## Latihan Deployment

1. Gunakan `cast call` untuk membaca `retrieve()` dari SimpleStorage dan `totalSupply()` dari ERC20Token yang sudah Anda deploy. Apakah nilainya sesuai parameter constructor di `Deploy.s.sol`?
2. *(Setelah Challenge TokenStaking selesai dan di-deploy ulang)* Gunakan `cast send` untuk memanggil `stake()` di TokenStaking (jangan lupa `approve` dulu). Lalu tunggu, dan panggil `claimReward()`. Apakah berhasil? Jika gagal, baca revert reason-nya dengan `cast run <txhash>` dan hubungkan dengan **Hint 3** di Challenge.
3. Berapa total gas yang dihabiskan untuk deploy semua contract? Contract mana yang paling mahal dan mengapa? (Petunjuk: `forge build --sizes`.)

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Langkah 1–2: deploy ke anvil + Latihan Deployment no. 1 |
| 🟡 **Extended** — disarankan | Langkah 3–4: deploy & verify di Sepolia + catatan `deployments/` |
| 🔴 **Stretch** — untuk portfolio | Latihan Deployment no. 2–3 + deploy ke satu L2 testnet (preview Phase 12) |

### ✅ Kriteria Lulus (Core)

- [ ] `forge script ... --rpc-url anvil --broadcast` sukses untuk implementasi **Anda**
- [ ] `cast call` membaca `retrieve()` dan `totalSupply()` dengan nilai sesuai parameter constructor
- [ ] `.env` tidak ter-commit (`git status` bersih dari `.env`)


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `[FAIL: NotImplemented()] setUp()` di semua test ERC-20 | `_mint` dipanggil constructor tetapi belum diisi | Implementasikan `_mint` lebih dulu |
| `Source "forge-std/Test.sol" not found` | Dependencies belum di-install | Jalankan langkah Setup (`forge install foundry-rs/forge-std@v1.17.0 --no-git`) |
| Ratusan *warning* saat build | Starter masih berupa kerangka (parameter belum dipakai) | Normal — warning hilang setelah fungsi diimplementasikan |
| Test gagal dan tidak tahu kenapa | Perilaku berbeda dari spesifikasi | `forge test --match-test <nama> -vvvv`, lalu bandingkan dengan `FOUNDRY_PROFILE=solutions forge test --match-test <nama> -vvvv` |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 05-smart-contract-development/

# Setup dependencies (lihat ⚙️ Setup — jangan forge init di folder ini)
forge install foundry-rs/forge-std@v1.17.0 --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git

# Setelah implement semua contract dan test:

git add .
git commit -m "learn: smart contract development — 5 contracts from scratch"

git add test/
git commit -m "test: add comprehensive test suites for all 5 contracts"

git add script/
git commit -m "feat: add deployment scripts for all contracts"

# Setelah deploy ke Sepolia:
git add deployments/
git commit -m "deploy: deploy all contracts to Sepolia testnet"
```

---

## 🧠 Knowledge Check (12 Pertanyaan)

1. Apa perbedaan antara `uint256[] storage arr` dan `uint256[] memory arr` saat di-return dari fungsi? Kapan masing-masing tepat digunakan?
2. Mengapa `delete _array` di dalam kontrak bisa menjadi operasi yang sangat mahal? Apa alternatifnya?
3. Dalam VotingSystem, mengapa kita menggunakan `bool exists` dalam struct alih-alih memeriksa apakah deadline == 0?
4. Apa itu CEI (Checks-Effects-Interactions) pattern? Tunjukkan dengan kode contoh konkret mengapa urutan ini kritis untuk mencegah reentrancy.
5. Dalam ERC-20, mengapa `transferFrom` mengecek allowance terlebih dahulu baru melakukan transfer, bukan sebaliknya?
6. Apa itu "infinite approval" (`type(uint256).max`)? Apa keuntungan dan risiko keamanannya?
7. Mengapa `safeTransferFrom` di ERC-721 lebih aman dari `transferFrom`? Apa yang bisa terjadi jika NFT dikirim ke contract biasa dengan `transferFrom`?
8. Jelaskan peran `supportsInterface()` (EIP-165) dalam ekosistem NFT. Mengapa marketplace seperti OpenSea butuh ini?
9. Apa itu EIP-2981 (royalty standard)? Apakah royalty di-enforce secara on-chain?
10. Dalam Crowdfunding, apa yang terjadi jika `finalize()` tidak pernah dipanggil setelah deadline? Bagaimana ini mempengaruhi user yang ingin refund?
11. Mengapa `immutable` digunakan untuk `CREATOR`, `GOAL`, dan `DEADLINE` di Crowdfunding? Apa benefit-nya?
12. Seorang user minta Anda menambahkan "emergency pause" pada VotingSystem. Bagaimana Anda mengimplementasikannya tanpa melanggar decentralization principle?

<details>
<summary>🔑 Kunci jawaban Knowledge Check — buka <b>setelah</b> Anda menjawab sendiri</summary>

> Jawaban ringkas sebagai acuan. Jika jawaban Anda berbeda tetapi alasannya benar, itu tetap benar — bandingkan alasannya, bukan kalimatnya.

1. Fungsi `external`/`public` tidak bisa mengembalikan referensi `storage` — data dikembalikan sebagai salinan `memory` (ABI-encoded). Return `storage` hanya untuk fungsi `internal`/`private`, berguna untuk mendapat pointer yang bisa dimodifikasi.
2. `delete` pada dynamic array meng-nol-kan setiap elemen (satu SSTORE per slot) → biaya O(n) yang bisa melampaui block gas limit. Alternatif: "virtual reset" dengan indeks awal (Soal 1), mapping ber-versi, atau penghapusan bertahap.
3. `exists` membedakan "proposal belum pernah dibuat" dari "proposal ada" secara eksplisit. Mengandalkan `deadline == 0` mencampur dua makna dalam satu field dan rapuh jika aturan durasi berubah.
4. Lihat pola `withdrawVulnerable` vs `withdrawSafe` di Phase 4 C5: jika saldo baru di-nol-kan setelah `call`, `receive()` attacker bisa memanggil `withdraw()` lagi dan menguras contract. Meng-nol-kan saldo sebelum `call` menutup celah itu.
5. Mengikuti CEI: semua pengecekan (allowance & saldo) dilakukan sebelum state berubah, sehingga kegagalan terjadi dengan error yang tepat dan tidak ada perubahan setengah jalan.
6. Approve sebesar `type(uint256).max` sekali saja agar tidak perlu approve lagi (UX & hemat gas). Risikonya: jika spender di-exploit atau jahat, seluruh token Anda — sekarang dan nanti — bisa diambil. Mitigasi: approve sejumlah yang dibutuhkan, rutin revoke, atau permit dengan kedaluwarsa.
7. `safeTransferFrom` memeriksa penerima: jika contract, ia harus mengimplementasikan `onERC721Received` dan mengembalikan selector yang benar. Dengan `transferFrom` ke contract yang tidak bisa mengelola NFT, NFT terkunci selamanya.
8. `supportsInterface(interfaceId)` memberi tahu standar apa yang didukung (ERC-721, Metadata, ERC-2981, dll). Marketplace memakainya untuk mendeteksi jenis token, metadata, dan royalti secara otomatis.
9. Standar untuk *menanyakan* info royalti (penerima & jumlah) untuk harga jual tertentu. Royalti **tidak** dipaksakan on-chain — marketplace yang memilih menghormatinya. Memaksanya butuh pembatasan transfer dengan trade-off sendiri.
10. Dana tetap aman di contract, tetapi `refund()` dan `withdraw()` menunggu status final. Karena `finalize()` bisa dipanggil siapa saja setelah deadline, donor yang ingin refund cukup memanggilnya sendiri.
11. Nilainya diset sekali di constructor dan tidak bisa diubah — jaminan bagi donor bahwa aturan main tetap. Juga lebih murah dibaca karena tertanam di bytecode (tanpa SLOAD).
12. Batasi kekuasaannya: pause dipegang multisig/timelock atau governance, hanya menghentikan aksi baru (misal pembuatan proposal/vote) tanpa bisa mengubah suara yang ada, dibatasi waktu (auto-unpause), dan setiap pemakaian di-emit sebagai event yang transparan.

</details>

---

## 📊 Progress Tracker

- [ ] **Setup**: forge-std + OpenZeppelin terinstall, remappings configured, `forge build` sukses
- [ ] **Contract 1**: SimpleStorage — *Ownership, history, events, fuzz test*
- [ ] **Contract 2**: VotingSystem — *Struct, mapping, time-based logic, quorum*
- [ ] **Contract 3**: Crowdfunding — *ETH flow, CEI, reentrancy guard, PoC test*
- [ ] **Contract 4**: ERC-20 Token — *EIP-20 standard, allowance, race condition*
- [ ] **Contract 5**: NFT Collection (ERC-721) — *EIP-721/2981/165, reveal, royalties*
- [ ] **Exercise**: Soal 1–5
- [ ] **Challenge**: TokenStaking DeFi integration + `test/TokenStaking.t.sol` + review keamanan
- [ ] **Deployment**: Semua contract di-deploy ke Sepolia dan verified di Etherscan
- [ ] **Latihan Deployment**: 3 soal `cast` di bab Deployment
- [ ] **Knowledge Check**: 12 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### EIP Standards (Baca Sumbernya Langsung!)
- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-721: Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)
- [EIP-2981: NFT Royalty Standard](https://eips.ethereum.org/EIPS/eip-2981)
- [EIP-165: Standard Interface Detection](https://eips.ethereum.org/EIPS/eip-165)
- [EIP-2612: Permit Extension (Gasless Approval)](https://eips.ethereum.org/EIPS/eip-2612)

### Reference Implementations
- [OpenZeppelin ERC20 Source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.6.1/contracts/token/ERC20/ERC20.sol)
- [OpenZeppelin ERC721 Source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.6.1/contracts/token/ERC721/ERC721.sol)
- [Solmate (Ultra gas-efficient implementations)](https://github.com/transmissions11/solmate)

### Security
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107) *(SWC Registry tidak lagi diperbarui sejak 2020 — tetap berguna sebagai klasifikasi dasar)*
- [SWC-114: Transaction Order Dependence (Race Condition)](https://swcregistry.io/docs/SWC-114)
- [Consensys Best Practices: Known Attacks](https://consensysdiligence.github.io/smart-contract-best-practices/attacks/)

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri setelah menyelesaikan semua contract)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi — khususnya tentang pattern yang tidak dipahami)*
