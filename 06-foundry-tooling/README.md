# 06 — Foundry Tooling

> **Level**: 2–3 (Hands-On Tooling Mastery)
> **Phase**: 6 of 13
> **Estimated Time**: 🚀 Intensif 7–10 hari kerja (Core + Extended, ~6 jam/hari) · 🐢 Paruh waktu 3–4 minggu (Core, ~10 jam/minggu)
> **Prerequisite**: [04-solidity-fundamentals](../04-solidity-fundamentals/README.md) ✅
> **Status verifikasi**: **Tested** · 9 Okt 2026 · setup lab & contoh MyToken (12/12 test) lulus dari README — lihat definisi status di [README utama](../README.md)

---

## 🎯 Objective

Setelah menyelesaikan fase ini, Anda akan mampu:

- Menginstall dan mengkonfigurasi **Foundry** sebagai primary smart contract development toolkit.
- Menggunakan **`forge`** untuk build, test, deploy, dan debug smart contract.
- Menggunakan **`cast`** untuk berinteraksi langsung dengan blockchain via CLI.
- Menggunakan **`anvil`** sebagai local EVM testnet yang ultra-cepat.
- Menulis **Foundry test** menggunakan Forge Standard Library (`Test`, `vm` cheatcodes).
- Membuat **deployment scripts** yang reproducible dan bisa dijalankan di berbagai network.
- Mengelola **dependencies** menggunakan Git submodules.
- Membaca dan men-debug **stack traces** dari failed transactions.

---

## 📋 Prerequisites

- [x] Memahami Solidity fundamentals (Phase 4).
- [x] Familiar dengan Git dan CLI terminal.
- [x] Node.js terinstall (untuk beberapa tooling supplement).

---

## 📚 Concepts Overview

| # | Konsep | Status |
|:---:|---|:---:|
| **C1** | [Foundry Architecture & Installation](#c1-foundry-architecture--installation) | ⬜ |
| **C2** | [forge — Build, Compile & Project Structure](#c2-forge--build-compile--project-structure) | ⬜ |
| **C3** | [Writing Tests dengan Forge](#c3-writing-tests-dengan-forge) | ⬜ |
| **C4** | [VM Cheatcodes — Superpower Testing](#c4-vm-cheatcodes--superpower-testing) | ⬜ |
| **C5** | [cast — CLI untuk Blockchain Interaction](#c5-cast--cli-untuk-blockchain-interaction) | ⬜ |
| **C6** | [anvil — Local EVM Testnet](#c6-anvil--local-evm-testnet) | ⬜ |
| **C7** | [Deployment Scripts & Multi-Network Workflow](#c7-deployment-scripts--multi-network-workflow) | ⬜ |

---

---

# C1: Foundry Architecture & Installation

## Mental Model: Foundry = Solidity-Native Toolchain

Di Web2, Anda mungkin menggunakan toolchain seperti:
- **Laravel**: `php artisan` untuk scaffolding, testing, migration
- **Node.js**: `npm`, `jest` untuk testing, `ts-node` untuk execution

Di smart contract development, ada dua toolchain utama:

| | **Hardhat** | **Foundry** |
|---|---|---|
| **Bahasa Test** | JavaScript/TypeScript | Solidity (native!) |
| **Kecepatan** | Lambat (JS overhead) | **Sangat cepat** (native Rust) |
| **Dependency** | Node.js ecosystem (npm) | Git submodules |
| **Debug** | Console.log style | Stack traces + vm cheatcodes |
| **Fuzzing** | Manual / external tools | **Built-in fuzz testing** |
| **Popularitas saat ini** | Masih sangat banyak dipakai (Hardhat 3 kini juga mendukung test Solidity) | **Standar de facto untuk audit & security research** |

**Kita pilih Foundry** karena:
1. Test ditulis dalam Solidity — Anda berpikir dalam bahasa contract langsung.
2. Jauh lebih cepat (~10-100x).
3. Built-in fuzzing adalah game-changer untuk security.
4. Industry standard untuk audit dan serious development.

---

## Komponen Foundry

```text
FOUNDRY TOOLCHAIN
│
├── forge    ← Build + Test + Deploy tool (seperti "artisan" di Laravel)
├── cast     ← CLI untuk interact dengan chain (seperti curl untuk blockchain)
├── anvil    ← Local EVM node/testnet (seperti Docker container lokal untuk DB)
└── chisel   ← Solidity REPL (interactive playground)
```

---

## Instalasi

```bash
# === INSTALASI (Mac/Linux) ===

# 1. Download dan install foundryup (installer manager)
# ⚠️ `curl ... | bash` menjalankan script dari internet tanpa Anda baca. Untuk mesin penting,
#    unduh dulu, baca isinya, lalu jalankan:
#      curl -L https://foundry.paradigm.xyz -o foundryup-install.sh && less foundryup-install.sh
# && bash foundryup-install.sh
curl -L https://foundry.paradigm.xyz | bash

# 2. Restart terminal atau source shell config
source ~/.bashrc   # atau ~/.zshrc

# 3. Install foundry tools
foundryup             # versi stabil terbaru
# Untuk hasil yang identik dengan materi ini, pin ke versi yang diverifikasi:
# foundryup -i v1.7.1

# 4. Verifikasi instalasi
forge --version    # forge Version: 1.x.x (stable sejak 2025)
cast --version
anvil --version
chisel --version

# === UPDATE FOUNDRY ===
foundryup  # Jalankan lagi kapan saja untuk update ke versi terbaru

# === TROUBLESHOOTING (jika path tidak ditemukan) ===
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Membuat Project Baru

```bash
# Init project kosong
forge init my-project
cd my-project

# Atau init di current directory (hanya jika folder KOSONG;
# --force pada folder berisi file akan MENIMPA README.md Anda!)
forge init .

# Atau init dengan template
forge init --template https://github.com/foundry-rs/forge-template my-project
```

---

## Struktur Project Default

```
my-project/
│
├── foundry.toml          ← File konfigurasi utama Foundry
├── .gitignore
├── .gitmodules           ← Git submodules untuk dependencies
│
├── src/                  ← Smart contract source files
│   └── Counter.sol       ← Contoh contract default
│
├── test/                 ← Test files (*.t.sol)
│   └── Counter.t.sol     ← Contoh test default
│
├── script/               ← Deployment dan interaction scripts (*.s.sol)
│   └── Counter.s.sol     ← Contoh script default
│
└── lib/                  ← Dependencies (git submodules)
    └── forge-std/        ← Foundry Standard Library (auto-included)
```

---

## `foundry.toml` — Konfigurasi Proyek

```toml
[profile.default]
src = "src"                    # Lokasi source contracts
out = "out"                    # Hasil kompilasi (bytecode, ABI)
libs = ["lib"]                 # Lokasi dependencies
test = "test"                  # Lokasi test files
script = "script"              # Lokasi script files

# Solidity compiler settings
solc_version = "0.8.24"        # Pin versi compiler (SANGAT DISARANKAN!)
optimizer = true               # Aktifkan optimizer
optimizer_runs = 200           # 200 = balance antara deploy cost dan call cost
                               # Tinggi (100000) = murah saat dipanggil, mahal saat deploy
                               # Rendah (200) = sebaliknya

# Gas reporting
gas_reports = ["*"]            # Report gas usage untuk semua contract saat test
gas_price = 20000000000        # Default gas price untuk test (20 gwei)

# EVM version
evm_version = "paris"          # Default Foundry terbaru mengikuti hard fork terkini (misal "prague"/"osaka");
                               # pin ke versi yang didukung SEMUA chain target Anda (L2 kadang
                               # tertinggal)

# Verbosity level test output
verbosity = 2                  # 0=minimal, 1=print test names, 2=print logs, 3=traces, 4=full traces

[profile.ci]
# Settings khusus untuk CI pipeline
fuzz = { runs = 10000 }        # Lebih banyak fuzz runs di CI

[rpc_endpoints]
# RPC URLs untuk berbagai network (bisa pakai environment variables)
mainnet   = "${MAINNET_RPC_URL}"
sepolia   = "${SEPOLIA_RPC_URL}"
arbitrum  = "${ARBITRUM_RPC_URL}"
base      = "${BASE_RPC_URL}"
anvil     = "http://localhost:8545"

[etherscan]
# API keys untuk verifikasi contract di Etherscan
mainnet  = { key = "${ETHERSCAN_API_KEY}" }   # format wajib: tabel { key = ... }
sepolia  = { key = "${ETHERSCAN_API_KEY}" }
```

---

---

# C2: forge — Build, Compile & Project Structure

## Perintah `forge` yang Wajib Dikuasai

```bash
# ===== BUILD & COMPILE =====

forge build
# Kompilasi semua contract di src/
# Output: out/ folder (bytecode + ABI + metadata)

forge build --sizes
# Kompilasi + tampilkan ukuran bytecode setiap contract
# ⚠️ Max contract size: 24KB (EIP-170) — penting untuk production!

forge build --force
# Force rebuild dari awal (hapus cache dulu)

forge inspect MyContract abi
# Lihat ABI dari contract tertentu (JSON format)

forge inspect MyContract bytecode
# Lihat CREATION bytecode (kode deploy, termasuk constructor)

forge inspect MyContract deployedBytecode
# Lihat RUNTIME bytecode (kode yang tersimpan di chain)

forge inspect MyContract storage-layout
# Lihat storage layout (SANGAT BERGUNA untuk debugging storage bugs!)

# ===== DEPENDENCY MANAGEMENT =====

forge install OpenZeppelin/openzeppelin-contracts
# Install OpenZeppelin sebagai git submodule
# → Ditambahkan ke lib/ dan .gitmodules

forge install OpenZeppelin/openzeppelin-contracts@v5.6.1
# Install versi spesifik (best practice: pin ke versi!)

forge install foundry-rs/forge-std
# Install atau update forge-std library

forge update
# Update semua dependencies ke versi terbaru

forge remove OpenZeppelin/openzeppelin-contracts
# Hapus dependency

# ===== SETELAH INSTALL OPENZEPPELIN =====
# Tambahkan remapping ke foundry.toml agar import bekerja:
# [profile.default]
# remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]

# Atau buat file remappings.txt:
# @openzeppelin/=lib/openzeppelin-contracts/
# forge-std/=lib/forge-std/src/

forge remappings
# Lihat semua remappings yang aktif

# ===== FORMAT & LINT =====

forge fmt
# Format semua Solidity files (seperti prettier untuk Solidity)

forge fmt --check
# Check format tanpa mengubah file (untuk CI)

# ===== SNAPSHOT =====

forge snapshot
# Buat/update gas snapshot (file .gas-snapshot)
# Berguna untuk melacak gas regression antar commit

forge snapshot --diff
# Bandingkan gas usage saat ini vs snapshot sebelumnya
```

---

## Import Paths & Remappings

```solidity
// TANPA remapping (path absolut ke lib):
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// DENGAN remapping "@openzeppelin/=lib/openzeppelin-contracts/":
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Jauh lebih bersih dan portable!

// Import dari forge-std (sudah tersedia secara default):
import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";  // Untuk debug logging

// Import relative (dari dalam project):
import "./interfaces/IVault.sol";
import "../lib/Math.sol";
```

---

## Anatomy of a Compiled Contract (Out Folder)

```bash
# Setelah forge build:
out/
└── Counter.sol/
    └── Counter.json   ← Berisi:
        ├── abi          (ABI: array of function/event/error definitions)
        ├── bytecode     (Creation bytecode: kode untuk deploy)
        ├── deployedBytecode (Runtime bytecode: kode yang ada di chain)
        ├── methodIdentifiers  (function selectors)
        ├── storageLayout      (storage slot mapping)
        └── metadata     (compiler info, source hash)

# Cara baca ABI dari CLI:
cat out/Counter.sol/Counter.json | python3 -m json.tool | grep '"abi"'
# Atau:
forge inspect Counter abi
```

---

## Exercise C2: Project Setup

```bash
# Buat project untuk Phase 6 learning (di subfolder lab/ agar README materi aman):
cd 06-foundry-tooling/
forge init lab --no-git
cd lab

# Install OpenZeppelin:
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.6.1 --no-git

# Update foundry.toml:
# Tambahkan remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]
# Dan solc_version = "0.8.24"

# Test bahwa setup bekerja:
forge build
# → Should output: Compiler run successful
```

---

---

# C3: Writing Tests dengan Forge

> *Ini adalah area dimana Foundry benar-benar unggul. Test ditulis dalam Solidity sendiri — tidak ada konteks switching ke JavaScript.*

---

## Anatomy of a Forge Test

```solidity
// test/Counter.t.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// [1] Import forge-std Test base contract
import "forge-std/Test.sol";

// [2] Import contract yang akan ditest
import "../src/Counter.sol";

// [3] Test contract harus inherit dari Test
contract CounterTest is Test {
    
    // [4] State variables untuk test
    Counter public counter;
    address public alice = makeAddr("alice");  // Generate address deterministik
    address public bob   = makeAddr("bob");
    
    // [5] setUp() — Dijalankan SEBELUM setiap test function
    // Equivalent dengan @BeforeEach di JUnit / beforeEach() di Jest
    function setUp() public {
        counter = new Counter();  // Deploy fresh contract setiap test
    }
    
    // [6] Test functions — HARUS dimulai dengan prefix "test"
    // Setiap test berjalan dengan state segar dari setUp()
    
    // Test normal flow (happy path)
    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }
    
    // Test bahwa fungsi revert ketika kondisi tidak valid
    // Prefix: test_RevertIf_ atau test_RevertWhen_
    function test_RevertIf_NumberIsZero() public {
        vm.expectRevert();  // Ekspektasi bahwa call berikutnya akan revert
        counter.decrement();
    }
    
    // Test dengan custom error yang spesifik
    function test_RevertWhen_NotOwner() public {
        vm.prank(alice);  // Simulasikan bahwa alice yang memanggil
        vm.expectRevert(Counter.NotOwner.selector);  // Ekspektasi custom error spesifik
        counter.adminReset();
    }
    
    // [7] Fungsi helper (bukan test) — tidak dimulai dengan "test"
    function _deployAndFund() internal returns (Counter) {
        Counter c = new Counter();
        vm.deal(address(c), 10 ether);  // Beri ETH ke contract
        return c;
    }
}
```

---

## Menjalankan Tests

```bash
# Jalankan semua test
forge test

# Verbose output — tampilkan nama test yang pass/fail
forge test -v     # atau --verbosity 1

# Sangat verbose — tampilkan logs dan traces
forge test -vvv   # Tiga v = trace level

# Sangat sangat verbose — tampilkan semua detail
forge test -vvvv

# Jalankan test tertentu saja (by name pattern)
forge test --match-test test_Increment
forge test --match-test "test_Revert"  # Semua test yang mengandung "test_Revert"

# Jalankan test dari contract tertentu
forge test --match-contract CounterTest

# Jalankan test dari file tertentu
forge test --match-path test/Counter.t.sol

# Jalankan dengan gas report
forge test --gas-report

# Contoh output:
# [PASS] test_Increment() (gas: 28334)
# [PASS] test_RevertIf_NumberIsZero() (gas: 10247)
# [FAIL] test_RevertWhen_NotOwner() (gas: 15432)
#   Error: custom error
```

---

## Assert Functions dari forge-std

```solidity
// EQUALITY CHECKS
assertEq(a, b);                  // a == b
assertEq(a, b, "Error message"); // dengan custom message
assertNotEq(a, b);               // a != b

// NUMERIC COMPARISONS
assertGt(a, b);    // a > b
assertGe(a, b);    // a >= b
assertLt(a, b);    // a < b
assertLe(a, b);    // a <= b

// BOOLEAN CHECKS
assertTrue(condition);
assertFalse(condition);

// APPROXIMATE EQUALITY (untuk floating point approximations)
assertApproxEqAbs(a, b, delta);  // |a - b| <= delta
assertApproxEqRel(a, b, maxPercentDelta); // |a - b| / b <= maxPercentDelta, skala 1e18 = 100%
                                          // contoh: 0.01e18 = 1%

// ADDRESS CHECKS
assertEq(addr1, addr2);

// BYTES/STRING CHECKS
assertEq(bytes1, bytes2);   // byte-for-byte comparison

// ARRAY CHECKS
assertEq(arr1, arr2);  // forge-std mendukung array comparison

// REVERT CHECKS
vm.expectRevert();                           // Ekspektasi revert (apapun)
vm.expectRevert("Error message");           // Ekspektasi revert dengan string
vm.expectRevert(MyContract.MyError.selector); // Ekspektasi custom error
vm.expectRevert(abi.encodeWithSelector(
    MyContract.MyError.selector, arg1, arg2  // Custom error dengan arguments
));
```

---

## console.log untuk Debugging

```solidity
// ℹ️ Ilustrasi — fungsi test di bawah seharusnya berada di dalam contract test (lihat C3).
import "forge-std/console.sol";

contract MyContract {
    function complexCalculation(uint256 input) external returns (uint256) {
        console.log("Input:", input);  // Hanya terlihat saat forge test -vv
        
        uint256 step1 = input * 2;
        console.log("After step 1:", step1);
        
        uint256 result = step1 + 100;
        console.log("Final result:", result);
        
        return result;
    }
}

// Di test:
function test_ComplexCalc() public {
    // forge test -vv akan menampilkan semua console.log
    uint256 result = calc.complexCalculation(42);  // `calc` = instance MyContract
                                                   // (`contract` adalah keyword — tidak bisa
                                                   // jadi nama variabel)
    assertEq(result, 184);
}
```

> **⚠️ Penting**: `console.log` harus DIHAPUS sebelum production deployment. Ia menambahkan gas cost dan tidak diperlukan di mainnet. Beberapa tim menggunakan conditional: `if (block.chainid == 31337) console.log(...)` untuk development-only.

---

## Complete Example: Testing a Token Contract

```solidity
// src/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MyToken {
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    error InsufficientBalance(uint256 available, uint256 requested);
    error InsufficientAllowance(uint256 available, uint256 requested);
    error ZeroAddress();
    error NotOwner();
    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        owner = msg.sender;
        
        _mint(msg.sender, _initialSupply);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance(currentAllowance, amount);
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        if (msg.sender != owner) revert NotOwner();
        _mint(to, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        if (balanceOf[from] < amount) revert InsufficientBalance(balanceOf[from], amount);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
```

```solidity
// test/MyToken.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    
    address public owner  = makeAddr("owner");
    address public alice  = makeAddr("alice");
    address public bob    = makeAddr("bob");
    address public carol  = makeAddr("carol");
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    
    // Dijalankan sebelum setiap test
    function setUp() public {
        vm.prank(owner);  // owner yang deploy
        token = new MyToken("MyToken", "MTK", INITIAL_SUPPLY);
    }
    
    // ===== HAPPY PATH TESTS =====
    
    function test_InitialState() public view {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);
    }
    
    function test_Transfer() public {
        uint256 amount = 100 * 1e18;
        
        vm.prank(owner);  // owner yang transfer
        vm.expectEmit(true, true, false, true);  // Expect event Transfer
        emit MyToken.Transfer(owner, alice, amount);
        
        token.transfer(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }
    
    function test_Approve_And_TransferFrom() public {
        uint256 amount = 500 * 1e18;
        
        // Owner approve alice untuk menggunakan 500 token
        vm.prank(owner);
        token.approve(alice, amount);
        assertEq(token.allowance(owner, alice), amount);
        
        // Alice transfer dari owner ke bob
        vm.prank(alice);
        token.transferFrom(owner, bob, amount);
        
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(owner, alice), 0);  // Allowance habis
    }
    
    function test_Mint() public {
        uint256 mintAmount = 1000 * 1e18;
        
        vm.prank(owner);
        token.mint(alice, mintAmount);
        
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }
    
    // ===== REVERT TESTS =====
    
    function test_RevertWhen_TransferExceedsBalance() public {
        uint256 tooMuch = INITIAL_SUPPLY + 1;
        
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                MyToken.InsufficientBalance.selector,
                INITIAL_SUPPLY,   // available
                tooMuch           // requested
            )
        );
        token.transfer(alice, tooMuch);
    }
    
    function test_RevertWhen_TransferFromExceedsAllowance() public {
        uint256 allowanceAmount = 100 * 1e18;
        uint256 overAmount = 101 * 1e18;
        
        vm.prank(owner);
        token.approve(alice, allowanceAmount);
        
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                MyToken.InsufficientAllowance.selector,
                allowanceAmount,
                overAmount
            )
        );
        token.transferFrom(owner, bob, overAmount);
    }
    
    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(MyToken.ZeroAddress.selector);
        token.transfer(address(0), 100);
    }
    
    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(alice);
        vm.expectRevert(MyToken.NotOwner.selector);
        token.mint(alice, 1000 * 1e18);
    }
    
    // ===== EVENT TESTS =====
    
    function test_EmitsTransferEvent() public {
        uint256 amount = 100 * 1e18;
        
        vm.prank(owner);
        // expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData)
        vm.expectEmit(true, true, false, true);
        emit MyToken.Transfer(owner, alice, amount);
        
        token.transfer(alice, amount);
    }
    
    function test_EmitsApprovalEvent() public {
        uint256 amount = 500 * 1e18;
        
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit MyToken.Approval(owner, alice, amount);
        
        token.approve(alice, amount);
    }
    
    // ===== EDGE CASE TESTS =====
    
    function test_TransferZeroAmount() public {
        vm.prank(owner);
        token.transfer(alice, 0);  // Harus berhasil (transfer 0 valid)
        assertEq(token.balanceOf(alice), 0);
    }
    
    function test_SelfTransfer() public {
        uint256 balanceBefore = token.balanceOf(owner);
        
        vm.prank(owner);
        token.transfer(owner, 100 * 1e18);  // Transfer ke diri sendiri
        
        // Balance harusnya sama (dikurangi lalu ditambah)
        assertEq(token.balanceOf(owner), balanceBefore);
    }
}
```

---

---

# C4: VM Cheatcodes — Superpower Testing

> *Cheatcodes adalah fitur paling powerful di Foundry. Mereka memungkinkan Anda memanipulasi state EVM secara arbitrary dalam test — hal yang tidak mungkin dilakukan di blockchain nyata.*

---

## Identity & Authorization Cheatcodes

```solidity
// vm.prank(address) — Simulasikan bahwa address tertentu yang memanggil
// HANYA berlaku untuk SATU call berikutnya
vm.prank(alice);
contract.someFunction();  // Dipanggil oleh alice
contract.someFunction();  // Dipanggil oleh address(this) lagi!

// vm.startPrank(address) / vm.stopPrank()
// Berlaku untuk SEMUA call sampai stopPrank() dipanggil
vm.startPrank(alice);
contract.function1();  // alice
contract.function2();  // alice
contract.function3();  // alice
vm.stopPrank();
contract.function4();  // address(this) kembali

// vm.prank(caller, origin) — Set both msg.sender dan tx.origin
vm.prank(alice, alice);  // msg.sender = alice, tx.origin = alice

// Contoh praktis: test access control
function test_OnlyOwner() public {
    vm.prank(alice);  // alice bukan owner
    vm.expectRevert(MyContract.NotOwner.selector);
    myContract.ownerFunction();
    
    vm.prank(owner);  // owner
    myContract.ownerFunction();  // Harus berhasil
}
```

---

## ETH Balance & Time Manipulation

```solidity
// vm.deal(address, uint256) — Set ETH balance address tertentu
vm.deal(alice, 10 ether);
assertEq(alice.balance, 10 ether);

// hoax(address, uint256) — helper forge-std (bukan vm.*): deal + prank dalam satu call
// Setara: vm.deal(alice, amount); vm.prank(alice);
hoax(alice, 5 ether);
payableContract.deposit{value: 1 ether}();

// vm.warp(uint256) — Set block.timestamp
vm.warp(block.timestamp + 7 days);  // Maju waktu 7 hari
assertGt(block.timestamp, 0);

// vm.roll(uint256) — Set block.number
vm.roll(block.number + 100);  // Maju 100 blok

// Contoh praktis: test timelock
function test_CanWithdrawAfterTimelock() public {
    uint256 lockDuration = 7 days;
    
    vm.prank(alice);
    vault.lockFunds{value: 1 ether}(lockDuration);
    
    // Belum waktunya
    vm.expectRevert(Vault.NotYet.selector);
    vm.prank(alice);
    vault.withdraw();
    
    // Maju waktu melewati timelock
    vm.warp(block.timestamp + lockDuration + 1);
    
    vm.prank(alice);
    vault.withdraw();  // Sekarang harus berhasil
    assertEq(alice.balance, 1 ether);
}
```

---

## Storage Manipulation Cheatcodes

```solidity
// vm.store(address, bytes32 slot, bytes32 value)
// Set nilai storage slot secara langsung (bypass logic contract!)
// Sangat berguna untuk setup test state tanpa memanggil banyak fungsi

function test_DirectStorageManipulation() public {
    // Mapping `balanceOf` di MyToken (C3) berada di SLOT 5 — cek dengan:
    //   forge inspect MyToken storage-layout
    // (slot 0–4: name, symbol, decimals, totalSupply, owner)
    vm.store(
        address(token),
        keccak256(abi.encode(alice, uint256(5))),  // Slot balanceOf[alice]
        bytes32(uint256(1000 * 1e18))     // Set ke 1000 token
    );
    
    assertEq(token.balanceOf(alice), 1000 * 1e18);
}

// vm.load(address, bytes32 slot) — Baca raw storage slot
bytes32 rawValue = vm.load(address(token), bytes32(uint256(0)));
console.logBytes32(rawValue);

// Contoh: bypass access control untuk setup test
// Daripada menjalankan chain panjang fungsi untuk setup state kompleks,
// langsung manipulasi storage untuk test yang fokus pada logika spesifik.
// 💡 Untuk balance ERC-20, lebih mudah & aman pakai helper forge-std:
//    deal(address(token), alice, 1000e18);   // mencari slot secara otomatis
// ⚠️ vm.store melewati semua invariant contract (misal totalSupply TIDAK ikut berubah).
```

---

## Recording & Expectation Cheatcodes

```solidity
// vm.expectEmit — Verifikasi event yang di-emit
function test_EmitsCorrectEvent() public {
    // Parameter: (checkTopic1, checkTopic2, checkTopic3, checkData, emitter)
    vm.expectEmit(true, true, false, true, address(token));
    emit IERC20.Transfer(alice, bob, 100 ether);
    
    vm.prank(alice);
    token.transfer(bob, 100 ether);
}

// vm.recordLogs() + vm.getRecordedLogs() — Ambil semua event yang di-emit
function test_MultipleLogs() public {
    vm.recordLogs();
    
    token.transfer(alice, 100 ether);
    token.transfer(bob, 200 ether);
    
    Vm.Log[] memory logs = vm.getRecordedLogs();
    assertEq(logs.length, 2);
    // logs[0].topics[0] = keccak256("Transfer(address,address,uint256)")
    // logs[0].data = abi.encode(100 ether)
}

// vm.expectCall — Verifikasi bahwa contract A memanggil contract B
function test_CallsExternalContract() public {
    vm.expectCall(
        address(externalContract),     // Target yang harus dipanggil
        abi.encodeWithSelector(IERC20.transfer.selector, alice, 100 ether)
    );
    
    myContract.triggerExternalTransfer(alice, 100 ether);
}
```

---

## Fork Testing: Test terhadap Live Mainnet State

```solidity
// ℹ️ Ilustrasi — butuh interface `IERC20`, variabel `alice`, dan RPC mainnet (`MAINNET_RPC_URL`).
// Foundry bisa fork state mainnet/testnet untuk test!
// Ini sangat powerful untuk:
// - Test integrasi dengan protocol DeFi yang sudah ada
// - Verify bahwa contract Anda bekerja dengan USDC nyata, Uniswap nyata, dll

contract ForkTest is Test {
    // Fork di block nomor tertentu (reproducible!)
    uint256 mainnetFork;
    
    function setUp() public {
        // Butuh MAINNET_RPC_URL di .env
        mainnetFork = vm.createFork("mainnet", 18500000);
        vm.selectFork(mainnetFork);
    }
    
    function test_USDCBalanceOnMainnet() public {
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address BINANCE = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Binance hot wallet
        
        // Ini adalah balance USDC nyata Binance di block 18500000!
        uint256 balance = IERC20(USDC).balanceOf(BINANCE);
        assertGt(balance, 0);
        console.log("Binance USDC balance:", balance / 1e6, "USDC");
    }
    
    function test_SwapOnFork() public {
        address USDC  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address WETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        
        // Deal USDC ke test address (bypass transfer)
        deal(USDC, alice, 10000 * 1e6);  // 10,000 USDC
        
        // Swap USDC → WETH menggunakan Uniswap V2 yang nyata di fork
        vm.prank(alice);
        IERC20(USDC).approve(UNISWAP_ROUTER, type(uint256).max);
        
        // ... call Uniswap router
        
        assertGt(IERC20(WETH).balanceOf(alice), 0);
    }
}
```

---

## Latihan C4: Cheatcode Mastery

### Soal 1 — Cheatcode Chain Test
Buat test untuk contract `TimeLock` berikut menggunakan kombinasi cheatcodes:

```solidity
// src/TimeLock.sol
contract TimeLock {
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) public lockedAmount;
    
    error NothingLocked();
    error NotYet(uint256 currentTime, uint256 unlockTime);
    
    event Locked(address indexed user, uint256 amount, uint256 unlockAt);
    event Released(address indexed user, uint256 amount);
    
    function lock(uint256 duration) external payable {
        require(msg.value > 0, "Must send ETH");
        lockedAmount[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + duration;
        emit Locked(msg.sender, msg.value, lockTime[msg.sender]);
    }
    
    function release() external {
        uint256 amount = lockedAmount[msg.sender];
        if (amount == 0) revert NothingLocked();
        if (block.timestamp < lockTime[msg.sender]) {
            revert NotYet(block.timestamp, lockTime[msg.sender]);
        }
        
        lockedAmount[msg.sender] = 0;
        lockTime[msg.sender] = 0;
        
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
        
        emit Released(msg.sender, amount);
    }
}
```

**Tulis test yang mencakup**:
- Happy path: lock → warp time → release
- Revert: release sebelum waktunya
- Revert: release tanpa lock
- Event verification: emit `Locked` dan `Released` dengan benar
- Balance verification: ETH benar-benar berpindah

**✅ Selesai jika:**
- [ ] `forge test --match-contract TimeLock` hijau dengan minimal 5 test sesuai daftar
- [ ] Setiap revert diuji dengan selector **dan argumen** (`abi.encodeWithSelector(TimeLock.NotYet.selector, ...)`)
- [ ] Ubah sementara `<` menjadi `<=` di `release()` → minimal satu test Anda menjadi merah


---

---

# C5: cast — CLI untuk Blockchain Interaction

> *`cast` adalah Swiss Army knife untuk berinteraksi dengan blockchain. Sangat berguna untuk debugging, querying, dan scripting.*

---

## Konversi & Encoding

```bash
# ===== UNIT CONVERSION =====

cast to-wei 1.5 ether          # → 1500000000000000000
cast from-wei 1500000000000000000  # → 1.5 (ETH)

cast to-wei 20 gwei             # → 20000000000
cast from-wei 20000000000 gwei  # → 20 (gwei)

# ===== HEX CONVERSION =====

cast to-hex 255                # → 0xff
cast to-dec 0xff               # → 255
cast to-ascii 0x48656c6c6f     # → Hello

# ===== ABI ENCODING =====

# Encode function call
cast calldata "transfer(address,uint256)" 0xAlice 1000000000000000000
# → 0xa9059cbb000000000000000000000000[Alice]0000...de0b6b3a7640000

# Decode calldata
cast calldata-decode "transfer(address,uint256)" 0xa9059cbb000...

# Compute function selector
cast sig "transfer(address,uint256)"
# → 0xa9059cbb

# Compute event topic
cast sig-event "Transfer(address,address,uint256)"
# → 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

# ===== ADDRESS UTILITIES =====

cast to-check-sum-address 0xabcdef1234567890abcdef1234567890abcdef12
# → 0xabCDEF1234567890ABcDEF1234567890aBCDeF12  (EIP-55 checksum)

cast address-zero
# → 0x0000000000000000000000000000000000000000
```

---

## Query Chain State

```bash
# Butuh RPC URL — set di environment atau langsung di flag

export RPC_URL="https://ethereum-rpc.publicnode.com"

# ===== BLOCK INFO =====

cast block-number --rpc-url $RPC_URL
# → 18542000

cast block latest --rpc-url $RPC_URL
# Tampilkan info block terbaru (hash, number, timestamp, gas, transactions)

cast block 18000000 --rpc-url $RPC_URL
# Info block spesifik

# ===== ACCOUNT INFO =====

cast balance 0xYourAddress --rpc-url $RPC_URL
# Balance dalam wei

cast balance 0xYourAddress --rpc-url $RPC_URL --ether
# Balance dalam ETH

cast nonce 0xYourAddress --rpc-url $RPC_URL
# Nonce (jumlah transaksi yang sudah dikirim)

cast code 0xContractAddress --rpc-url $RPC_URL
# Bytecode deployed di address tersebut

# ===== STORAGE READING =====

cast storage 0xContractAddress 0 --rpc-url $RPC_URL
# Baca slot 0 dari storage contract

cast storage 0xUSDC 2 --rpc-url $RPC_URL
# Baca slot 2 dari USDC — apa isinya? (USDC adalah proxy; layout-nya tidak
# sama dengan ERC-20 sederhana. Ini justru inti Soal 2 Q4 di bawah.)

# ===== CALL CONTRACT FUNCTION =====

# Read-only call (view/pure function)
cast call 0xContractAddress "balanceOf(address)(uint256)" 0xUserAddress --rpc-url $RPC_URL
# → 1000000000000000000

# Multiple return values
cast call 0xUniswapPair "getReserves()(uint112,uint112,uint32)" --rpc-url $RPC_URL

# ===== TRANSACTION INFO =====

cast tx 0xTxHash --rpc-url $RPC_URL
# Info transaksi (from, to, value, gas, data, dll)

cast receipt 0xTxHash --rpc-url $RPC_URL
# Receipt (status, gasUsed, logs, block)
```

---

## Send Transaction via cast

```bash
# ===== SEND TRANSACTION =====

# Butuh private key! Simpan di .env, JANGAN hardcode!
export PRIVATE_KEY="0x..."

# Kirim ETH
cast send 0xRecipient --value 0.1ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Panggil fungsi contract
cast send 0xTokenContract "transfer(address,uint256)" 0xAlice 1000000000000000000 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Dengan gas price eksplisit
cast send 0xContract "function()" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --gas-price 30gwei \
    --gas-limit 100000

# ===== DECODE TRANSACTION =====

# Decode calldata dari tx
cast calldata-decode "transfer(address,uint256)" 0xa9059cbb...

# Pretty-print transaction data
cast pretty-calldata 0xa9059cbb...
```

---

## cast untuk Investigasi dan Debugging

```bash
# ===== REAL-WORLD DEBUGGING WORKFLOW =====

# Skenario: Anda menerima laporan bahwa transaksi 0xABC... gagal.
# Investigasi menggunakan cast:

# 1. Cek info transaksi
cast tx 0xABC... --rpc-url $RPC_URL

# 2. Cek receipt (apakah success atau failed?)
cast receipt 0xABC... --rpc-url $RPC_URL
# Cari: "status" : "0x0" = failed, "0x1" = success

# 3. Decode calldata untuk tau fungsi apa yang dipanggil
cast 4byte 0xa9059cbb  # Lookup function selector di database
# → transfer(address,uint256)

# 4. Simulate/replay transaksi untuk lihat error detail
cast run 0xABC... --rpc-url $RPC_URL -v
# Menampilkan full execution trace!

# 5. Cek state contract pada saat transaksi terjadi
cast storage 0xContract 0 --rpc-url $RPC_URL --block 18500000
# Baca storage di block tertentu (sebelum/sesudah transaksi)

# ===== GAS ESTIMATION =====

cast estimate 0xContract "transfer(address,uint256)" 0xAlice 1000 \
    --rpc-url $RPC_URL
# Estimasi gas untuk call ini

# ===== ENS RESOLUTION =====
cast resolve-name "vitalik.eth" --rpc-url $RPC_URL
# → 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
```

---

## Latihan C5: Blockchain Investigation

### Soal 2 — On-Chain Detective Challenge

Gunakan `cast` untuk menjawab pertanyaan berikut (gunakan Ethereum Mainnet via public RPC):

```bash
RPC_URL="https://ethereum-rpc.publicnode.com"

# Target: USDC Contract
USDC="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

# Q1: Berapa total supply USDC saat ini? (dalam USDC, bukan raw wei — USDC punya 6 decimals)
# Hint: fungsi totalSupply() returns uint256

# Q2: Berapa nonce dari Vitalik's wallet? (0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
# Artinya: berapa banyak transaksi yang sudah dia kirim?

# Q3: Decode function selector 0x095ea7b3 — fungsi apa ini?
# Hint: cast 4byte

# Q4: Baca raw storage slot 2 dari USDC contract
# Coba interpret apa yang ada di sana

# Q5: Apa bytecode length dari Uniswap V2 Router? (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
# Hint: cast code | wc -c
```

*Tulis perintah yang Anda gunakan dan hasilnya di Notes section.*

**✅ Selesai jika:**
- [ ] Setiap Q dijawab dengan perintah `cast` yang dipakai + output mentahnya
- [ ] Q1 dikonversi memakai 6 decimals (cek: `cast from-wei` tidak tepat untuk USDC — mengapa?)
- [ ] Q3 diverifikasi dua arah: hasil `cast 4byte` di-hash ulang dengan `cast sig` dan harus kembali ke selector yang sama


---

---

# C6: anvil — Local EVM Testnet

> *Anvil adalah local blockchain yang berjalan di komputer Anda. Jauh lebih cepat dan fleksibel dari testnet publik.*

---

## Menjalankan anvil

```bash
# Start anvil dengan default settings
anvil

# Output:
# Available Accounts
# ==================
# (0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
# (1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
# ...
# (9) 0x...
#
# Private Keys
# ============
# (0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# ...
#
# Chain ID: 31337
# RPC URL:  http://127.0.0.1:8545

# Dengan konfigurasi custom
#   --block-time 12  → block setiap 12 detik (realistis seperti Ethereum)
#   --accounts 20    → generate 20 akun
#   --balance 100    → 100 ETH per akun
#   --chain-id 1337  → chain ID custom
#   --port 8546      → port custom
#   --fork-url       → fork dari mainnet!
# (⚠️ Di bash, komentar TIDAK boleh diletakkan setelah \ penyambung baris)
anvil \
    --block-time 12 \
    --accounts 20 \
    --balance 100 \
    --chain-id 1337 \
    --port 8546 \
    --fork-url $MAINNET_RPC

# Fork mainnet di block tertentu (reproducible)
anvil --fork-url $MAINNET_RPC --fork-block-number 18500000

# Anvil dengan state persistence (simpan state ke file)
anvil --state anvil-state.json
```

---

## Anvil vs Public Testnet

| Aspek | Anvil (Local) | Sepolia (Public Testnet) |
|---|---|---|
| **Speed** | Instan (< 1 ms per block) | ~12 detik per block |
| **Faucet** | Pre-funded 10,000 ETH otomatis | Butuh faucet (sering kosong/lambat) |
| **Reset** | Kapan saja, gratis | Tidak bisa di-reset |
| **Fork** | Bisa fork mainnet state | Tidak bisa fork mainnet |
| **Manipulasi state** | RPC khusus `anvil_*` / `evm_*` (set balance, impersonate, mine, snapshot) — cheatcode `vm.*` hanya ada di `forge test`/`forge script` | Tidak bisa |
| **Privacy** | Lokal (tidak ada orang lain yang lihat) | Semua orang bisa lihat |
| **Use case** | Development & unit testing | Final integration testing sebelum mainnet |

---

## Tips Workflow dengan Anvil

```bash
# Terminal 1: Jalankan anvil
anvil

# Terminal 2: Interact dengan anvil menggunakan cast
export ANVIL_RPC="http://localhost:8545"
export ALICE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
# (Ini adalah default private key anvil account 0 — JANGAN gunakan di mainnet!)

# Deploy contract ke anvil
# (Foundry 1.x: tanpa --broadcast, forge create hanya simulasi;
#  --constructor-args diletakkan PALING AKHIR karena menerima banyak nilai)
forge create src/MyToken.sol:MyToken \
    --rpc-url $ANVIL_RPC \
    --private-key $ALICE_KEY \
    --broadcast \
    --constructor-args "MyToken" "MTK" 1000000000000000000000000

# Interact dengan contract yang sudah deploy
cast call 0xDeployedAddress "totalSupply()(uint256)" --rpc-url $ANVIL_RPC

# Anvil special RPC methods untuk manipulation:
cast rpc anvil_impersonateAccount 0xVitalikAddress --rpc-url $ANVIL_RPC
# Set balance 100 ETH
cast rpc anvil_setBalance 0xAddress 100000000000000000000 --rpc-url $ANVIL_RPC
cast rpc anvil_mine 10 --rpc-url $ANVIL_RPC  # Mine 10 blocks sekaligus
cast rpc evm_snapshot --rpc-url $ANVIL_RPC       # Snapshot state → mengembalikan id, misal "0x0"
cast rpc evm_revert 0x0 --rpc-url $ANVIL_RPC     # Revert ke snapshot dengan id tersebut
```

---

---

# C7: Deployment Scripts & Multi-Network Workflow

## Anatomy of a Foundry Script

```solidity
// script/DeployMyToken.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    
    // Configuration (bisa dibaca dari environment variables)
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    
    function run() external returns (MyToken token) {
        // Semua yang di dalam startBroadcast/stopBroadcast
        // akan dikirim sebagai actual transaction
        
        // Ambil private key dari .env (JANGAN hardcode!)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying as:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contract
        token = new MyToken(
            "MyToken",
            "MTK",
            INITIAL_SUPPLY
        );
        
        vm.stopBroadcast();
        
        // Log informasi setelah deployment (tidak dibrodcast, hanya output)
        console.log("MyToken deployed at:", address(token));
        console.log("Total supply:", token.totalSupply());
        
        return token;
    }
}
```

---

## Menjalankan Script

```bash
# ===== DRY RUN (Simulate, tidak benar-benar deploy) =====
forge script script/DeployMyToken.s.sol:DeployMyToken \
    --rpc-url $ANVIL_RPC

# ===== DEPLOY KE ANVIL =====
# --private-key: default private key anvil account #0 (publik — hanya untuk lokal!)
forge script script/DeployMyToken.s.sol:DeployMyToken \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast

# ===== DEPLOY KE SEPOLIA TESTNET =====
# Butuh SEPOLIA_RPC_URL dan PRIVATE_KEY di .env
# --verify → verifikasi source code di Etherscan; -vvvv → output verbose
source .env
forge script script/DeployMyToken.s.sol:DeployMyToken \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

# ===== DEPLOY KE MAINNET (HATI-HATI!) =====
# ⚠️ Untuk mainnet, jangan pakai --private-key mentah: gunakan hardware wallet
#    (--ledger / --trezor) atau keystore terenkripsi (cast wallet import + --account).
# (Flag --legacy hanya untuk chain yang belum mendukung EIP-1559 — bukan Ethereum mainnet.)
forge script script/DeployMyToken.s.sol:DeployMyToken \
    --rpc-url $MAINNET_RPC_URL \
    --ledger \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

---

## .env Setup (WAJIB untuk keamanan)

```bash
# .env (JANGAN commit file ini ke Git!)
PRIVATE_KEY=0x...your_private_key_here...
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# .gitignore — Pastikan .env ada di sini!
.env
broadcast/
cache/
out/
```

```solidity
// Di script, akses dengan:
uint256 key = vm.envUint("PRIVATE_KEY");
string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
uint256 optionalVar = vm.envOr("OPTIONAL_VAR", uint256(42)); // Dengan default value
```

---

## Multi-Network Deployment Pattern

```solidity
// ℹ️ Template — isi address WETH tiap network (`0x...`) dan definisikan `MockWETH`/`MyProtocol`
// sebelum di-compile.
// script/Deploy.s.sol — Script yang bisa jalan di network manapun
contract Deploy is Script {
    // Addresses berbeda per network
    mapping(uint256 => address) public WETH;
    
    function setUp() public {
        WETH[1]     = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet
        WETH[11155111] = 0x...;   // Sepolia
        WETH[42161]  = 0x...;    // Arbitrum
        WETH[8453]   = 0x...;    // Base
        WETH[31337]  = address(0); // Anvil local (akan deploy sendiri)
    }
    
    function run() external {
        uint256 chainId = block.chainid;
        address wethAddress = WETH[chainId];
        
        // Deploy WETH mock jika di local
        if (wethAddress == address(0)) {
            vm.broadcast();
            MockWETH weth = new MockWETH();
            wethAddress = address(weth);
            console.log("Deployed mock WETH at:", wethAddress);
        }
        
        vm.startBroadcast();
        
        // Deploy main protocol menggunakan correct WETH per network
        MyProtocol protocol = new MyProtocol(wethAddress);
        
        vm.stopBroadcast();
        
        console.log("Deployed MyProtocol at:", address(protocol));
        console.log("Chain:", chainId);
        console.log("WETH:", wethAddress);
    }
}
```

---

## Foundry Gas Reporting & Snapshots

```bash
# Gas report saat testing
forge test --gas-report

# Output contoh:
# | Contract        | Deployment Cost | Deployment Size |
# |-----------------|-----------------|-----------------|
# | MyToken         | 812,432         | 3,156           |
#
# | Function Name   | min   | avg   | median | max    | # calls |
# |-----------------|-------|-------|--------|--------|---------|
# | transfer        | 34521 | 45231 | 45231  | 56789  | 12      |
# | approve         | 24312 | 24312 | 24312  | 24312  | 5       |

# Buat gas snapshot (simpan benchmark)
forge snapshot

# Cek apakah ada gas regression
forge snapshot --diff
# Jika gas naik: ⛽ WARN atau ERROR sesuai setting
```

---

## Latihan C7: Full Deployment Workflow

### Soal 3 — Deploy, Verify, Interact

Buat script deployment lengkap untuk `MyToken`:

1. **Setup**: Konfigurasi `.env` dengan Sepolia RPC URL (gunakan Alchemy/Infura gratis).
2. **Script**: Buat `script/DeployMyToken.s.sol` yang:
   - Deploy `MyToken` dengan initial supply 1 juta token
   - Mint 1000 token ke address hardcoded (address Anda)
   - Log semua info deployment
3. **Dry run**: Test script dengan `--rpc-url http://localhost:8545` (Anvil) terlebih dahulu.
4. **Deploy**: Deploy ke Sepolia dengan `--broadcast --verify`.
5. **Verify**: Cek di [sepolia.etherscan.io](https://sepolia.etherscan.io) bahwa contract terverifikasi.
6. **Interact**: Gunakan `cast call` untuk verifikasi state contract di Sepolia.

**✅ Selesai jika:**
- [ ] Dry-run di anvil berhasil sebelum broadcast ke Sepolia
- [ ] Contract terverifikasi (centang hijau) di Sepolia Etherscan — link disimpan di Notes
- [ ] `cast call <token> "balanceOf(address)(uint256)" <address-anda>` = `1000e18`
- [ ] `git status` tidak menampilkan `.env`


---

---

# 📝 Mini Project: Foundry-Powered Development Workflow

## Tujuan
Setup workflow development yang profesional untuk semua phase berikutnya.

## Checklist Setup

```bash
# 1. Init project (lewati jika lab/ sudah dibuat di Exercise C2)
cd 06-foundry-tooling/
forge init lab --no-git
cd lab

# 2. Install dependencies
forge install OpenZeppelin/openzeppelin-contracts@v5.6.1 --no-git

# 3. Konfigurasi foundry.toml
cat > foundry.toml << 'EOF'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
script = "script"
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
gas_reports = ["*"]
verbosity = 2
remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]

[profile.ci]
fuzz = { runs = 10000 }

[rpc_endpoints]
anvil = "http://localhost:8545"
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
EOF

# 4. Buat .env template
cat > .env.example << 'EOF'
PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_KEY
EOF

# 5. Setup .gitignore
cat > .gitignore << 'EOF'
.env
cache/
out/
broadcast/
.DS_Store
EOF
```

## Deliverable

Sebuah project Foundry yang berisi:
1. `src/MyToken.sol` — Contract ERC-20 sederhana dengan fitur:
   - Mint (onlyOwner)
   - Transfer, Approve, TransferFrom
   - Custom errors (bukan string)
   - Events (Transfer, Approval)

2. `test/MyToken.t.sol` — Test suite dengan:
   - Minimal 15 test functions
   - Happy path tests
   - Revert/access control tests
   - Event verification tests
   - Edge case tests

3. `script/DeployMyToken.s.sol` — Deployment script

4. Gas snapshot (`forge snapshot`)

5. `README.md` update dengan instruksi cara run test

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Deliverable 1–2: `MyToken` + minimal 15 test |
| 🟡 **Extended** — disarankan | Deliverable 3–4: deployment script + gas snapshot |
| 🔴 **Stretch** — untuk portfolio | Deliverable 5 + fuzz test untuk `transfer` dan `transferFrom` |

### ✅ Kriteria Lulus (Core)

- [ ] `forge test` hijau dengan ≥ 15 test, termasuk ≥ 3 test revert dan ≥ 2 test event
- [ ] Mint oleh non-owner → revert dengan custom error (bukan string)
- [ ] `forge script` berhasil dry-run di anvil
- [ ] `.gas-snapshot` ada dan `forge snapshot --check` lulus


---

# 🏆 Challenge: Foundry Debugging Challenge

> *Anda diberikan sebuah contract yang "broken". Gunakan Foundry tools untuk debug dan fix.*

## Broken Contract

```solidity
// src/BrokenVault.sol — Contract ini punya beberapa bug tersembunyi
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract BrokenVault {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lockEnd;
    uint256 public totalDeposited;
    address public owner;
    bool private locked;
    
    event Deposited(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0);
        deposits[msg.sender] += msg.value;
        lockEnd[msg.sender] = block.number + lockDuration;  // Bug?
        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw() external {
        require(!locked);
        locked = true;
        
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No deposit");
        require(block.timestamp >= lockEnd[msg.sender], "Still locked");  // Bug?
        
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
        
        deposits[msg.sender] = 0;  // CEI violation?
        totalDeposited -= amount;
        locked = false;
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function emergencyWithdraw(address to) external {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
        totalDeposited = 0;
    }
}
```

## Tugas Challenge

1. **Buat test suite** untuk `BrokenVault` yang mengekspos semua bug.
2. **Identifikasi** minimum 3 bug/issue menggunakan test failures dan traces.
3. **Fix** setiap bug dan jelaskan root cause-nya.
4. **Tulis exploit PoC** (Proof of Concept) untuk bug paling kritis menggunakan Foundry.
5. **Tulis laporan** singkat: Bug, Impact, Fix, Test.

### 🎚️ Tingkat

| Tingkat | Cakupan |
|---|---|
| 🟢 **Core** — wajib sebelum lanjut fase | Tugas 1–2: test suite yang mengekspos minimal 3 bug |
| 🟡 **Extended** — disarankan | Tugas 3–4: fix setiap bug + exploit PoC untuk bug paling kritis |
| 🔴 **Stretch** — untuk portfolio | Tugas 5: laporan Bug/Impact/Fix/Test dengan format template audit Phase 8 C8 |

### ✅ Kriteria Lulus (Core)

- [ ] Minimal 3 test **merah** terhadap `BrokenVault` asli, masing-masing untuk bug berbeda
- [ ] Test yang sama **hijau** terhadap versi yang sudah Anda perbaiki
- [ ] PoC membuktikan dana bisa diambil melebihi deposit (atau terkunci) pada versi asli
- [ ] Setiap bug dijelaskan root cause-nya dalam 1–2 kalimat


---

## 🆘 Jika Anda Stuck

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `forge: command not found` | `~/.foundry/bin` belum di PATH | Lihat bagian TROUBLESHOOTING instalasi di C1 |
| `forge create` tidak men-deploy apa pun | Foundry 1.x: tanpa `--broadcast` hanya simulasi | Tambahkan `--broadcast` |
| `invalid type: found string ... expected struct EtherscanConfig` | Format `[etherscan]` lama | `sepolia = { key = "${ETHERSCAN_API_KEY}" }` |
| `environment variable "PRIVATE_KEY" not found` | `.env` belum dimuat | `source .env` atau ekspor variabel sebelum `forge script` |

**Langkah umum saat buntu:** (1) baca pesan error lengkap — jalankan ulang dengan `-vvvv` untuk trace; (2) ulangi contoh terkecil yang masih gagal; (3) cek versi tool sesuai bagian Setup; (4) cari pesan error persisnya di [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) atau GitHub Issues tool terkait; (5) tulis apa yang sudah dicoba di **🗒️ Notes** — sering kali jawabannya muncul saat menuliskannya.

---

## 📁 GitHub Task

```bash
cd 06-foundry-tooling/

git add .
git commit -m "learn: foundry tooling — forge, cast, anvil, test cheatcodes, deployment scripts"

git add test/
git commit -m "test: add comprehensive MyToken test suite with cheatcodes (Phase 6 mini project)"

git add script/
git commit -m "feat: add multi-network deployment script for MyToken"

git add .gas-snapshot
git commit -m "chore: add initial gas snapshot baseline"
```

---

## 🧠 Knowledge Check (10 Pertanyaan)

1. Apa perbedaan utama antara Foundry dan Hardhat? Mengapa kita memilih Foundry untuk serious smart contract development?
2. Jelaskan perbedaan antara `vm.prank()` dan `vm.startPrank()`. Kapan menggunakan masing-masing?
3. Apa yang dilakukan `vm.warp()` dan `vm.roll()`? Berikan contoh use case konkret untuk setiap cheatcode.
4. Bagaimana cara menulis test yang memverifikasi bahwa sebuah custom error di-emit dengan argumen yang benar?
5. Apa itu fork testing? Apa keuntungannya dibanding mocking dependencies secara manual?
6. Apa fungsi `vm.expectEmit(true, true, false, true)`? Apa arti dari keempat parameter boolean tersebut?
7. Apa perbedaan antara `forge test` dan `forge script`? Kapan menggunakan masing-masing?
8. Mengapa `.env` file harus selalu ada di `.gitignore`? Apa konsekuensi jika private key masuk ke repository public?
9. Jelaskan perbedaan antara `vm.store()` dan memanggil fungsi setter biasa untuk setup test state. Kapan `vm.store()` lebih berguna?
10. Apa itu gas snapshot dan mengapa penting dalam CI/CD pipeline untuk smart contract development?

<details>
<summary>🔑 Kunci jawaban Knowledge Check — buka <b>setelah</b> Anda menjawab sendiri</summary>

> Jawaban ringkas sebagai acuan. Jika jawaban Anda berbeda tetapi alasannya benar, itu tetap benar — bandingkan alasannya, bukan kalimatnya.

1. Hardhat: ekosistem JS/TS dan plugin (Hardhat 3 juga mendukung test Solidity). Foundry: toolchain berbasis Rust, test ditulis dalam Solidity, sangat cepat, dengan fuzz/invariant testing dan cheatcodes bawaan, plus `cast`/`anvil`. Dipilih karena kecepatan, fuzzing bawaan, satu bahasa, dan lazim di industri audit.
2. `vm.prank` hanya berlaku untuk **satu** call berikutnya; `vm.startPrank` berlaku untuk semua call sampai `vm.stopPrank`. Gunakan `prank` untuk satu aksi, `startPrank` untuk rangkaian aksi oleh aktor yang sama.
3. `vm.warp` mengatur `block.timestamp` (uji deadline, vesting, timelock). `vm.roll` mengatur `block.number` (uji logika berbasis nomor block, misal snapshot voting atau delay dalam block).
4. Sebelum call: `vm.expectRevert(abi.encodeWithSelector(MyContract.MyError.selector, arg1, arg2));` — revert dengan argumen berbeda akan membuat test gagal.
5. Test dijalankan terhadap salinan state mainnet pada block tertentu. Keuntungannya: berinteraksi dengan contract & token asli beserta perilaku anehnya (decimals, tanpa return bool, blacklist), bukan asumsi di dalam mock.
6. Mengharapkan event berikutnya cocok: parameter 1–3 = cek topic1/topic2/topic3 (argumen `indexed`), parameter 4 = cek data (argumen non-indexed). Topic0 (signature event) selalu dicek. Setelahnya `emit` event yang diharapkan, lalu lakukan call.
7. `forge test` menjalankan contract test di EVM lokal dengan cheatcodes, tanpa pernah mengirim transaksi. `forge script` menjalankan script deployment/interaksi — mensimulasikan, dan dengan `--broadcast` mengirim transaksi sungguhan.
8. `.env` berisi private key & API key. Begitu ter-push ke repo publik, bot memindainya dalam hitungan menit dan menguras dana. Key itu harus dianggap bocor selamanya (tetap ada di riwayat git) — pindahkan dana dan ganti key.
9. `vm.store` menulis slot mentah, melewati semua logika & validasi — cepat untuk mencapai state yang sulit dibuat (misal di fork) tetapi bisa merusak invariant (misal `totalSupply` tidak ikut berubah). Setter melewati logika contract sehingga state tetap konsisten.
10. Rekaman gas per test (`.gas-snapshot`). Di CI, `forge snapshot --check`/`--diff` mendeteksi regresi gas pada setiap perubahan sebelum di-merge.

</details>

---

## 📊 Progress Tracker

- [ ] **Setup**: Foundry terinstall, project init, dependencies terpasang
- [ ] **C1**: Foundry Architecture — *forge, cast, anvil, chisel overview*
- [ ] **C2**: forge Build & Compile — *perintah-perintah penting, foundry.toml config*
- [ ] **C3**: Forge Testing — *Test anatomy, assert functions, console.log debugging*
- [ ] **C4**: VM Cheatcodes — *prank, deal, warp, roll, expectEmit, expectRevert, fork testing*
- [ ] **C5**: cast CLI — *konversi, query chain, decode calldata, blockchain investigation*
- [ ] **C6**: anvil Local Testnet — *setup, fork mainnet, anvil RPC methods*
- [ ] **C7**: Deployment Scripts — *.env setup, forge script, multi-network, verifikasi Etherscan*
- [ ] **Exercise**: Soal 1-3 (TimeLock test, blockchain investigation, deployment workflow)
- [ ] **Mini Project**: Full Foundry project (MyToken + 15 tests + deploy script + gas snapshot)
- [ ] **Challenge**: BrokenVault debugging + exploit PoC + laporan
- [ ] **Knowledge Check**: 10 Questions
- [ ] **Review**: Self-assessment

---

## 🔗 Resources

### Wajib Baca
- [Foundry Book (Dokumentasi Resmi)](https://book.getfoundry.sh/) ← **Baca ini secara menyeluruh**
- [forge-std Cheatcodes Reference](https://github.com/foundry-rs/forge-std/blob/v1.17.0/src/Vm.sol)
- [Foundry Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

### Tools
- [Alchemy](https://www.alchemy.com/) — RPC Provider gratis terbaik (100M requests/bulan gratis)
- [Etherscan API](https://etherscan.io/apis) — Daftar gratis untuk API key verifikasi
- [Sepolia Faucet](https://sepoliafaucet.com/) — Testnet ETH gratis

### Contoh Project di GitHub (Baca source code-nya!)
- [Foundry Template by PaulRBerg](https://github.com/PaulRBerg/foundry-template) — Best practice template
- [OpenZeppelin Contracts Tests](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v5.6.1/test) — Cara OZ menulis test

---

## 📝 What I Learned
*(Tulis ringkasan pemahaman Anda sendiri)*

---

## 🗒️ Notes
*(Catatan dan pertanyaan pribadi)*
