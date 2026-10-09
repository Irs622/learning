// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ⚠️ STARTER — Phase 5, Contract 4.
// Antarmuka (state, struct, event, error, signature, constructor) sudah disediakan agar
// test di test/ bisa di-compile. Tugas Anda: isi setiap body yang berisi TODO sampai
// `forge test` lulus. Warning compiler (unused parameter, restrict to pure/view) normal
// selama fungsi masih kerangka. Referensi: solutions/src/ — buka setelah selesai.

/**
 * @title ERC20Token
 * @notice ERC-20 compliant token implementation from scratch (no library).
 * @dev Implements EIP-20 fully. Includes mint, burn, and allowance management.
 *      Phase 5 — Contract 4
 */
contract ERC20Token {
    /// @dev Dipakai oleh kerangka starter. Hapus setelah semua fungsi diimplementasikan.
    error NotImplemented();

    // =========================================================
    //                      METADATA
    // =========================================================

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // TODO: implementasikan pengecekan modifier ini
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    /**
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param initialSupply Initial supply in whole tokens (multiplied by 10^18 internally).
     */
    constructor(string memory _name, string memory _symbol, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;

        if (initialSupply > 0) {
            // 👉 MULAI DARI SINI: implementasikan `_mint` lebih dulu.
            //    Selama `_mint` masih kosong, setUp() di test/ERC20Token.t.sol gagal
            //    dengan NotImplemented() dan SEMUA test ERC-20 ikut gagal.
            _mint(msg.sender, initialSupply * 10 ** decimals);
        }
    }

    // =========================================================
    //                  EIP-20 REQUIRED FUNCTIONS
    // =========================================================

    function transfer(address to, uint256 amount) external returns (bool) {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                   EXTENDED FUNCTIONS
    // =========================================================

    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool) {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool) {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function burn(uint256 amount) external {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function burnFrom(address from, uint256 amount) external {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                     INTERNAL FUNCTIONS
    // =========================================================

    function _transfer(address from, address to, uint256 amount) internal {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function _mint(address to, uint256 amount) internal {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }

    function _burn(address from, uint256 amount) internal {
        // TODO: implementasikan (lihat README → Contract 4 → Spesifikasi)
        revert NotImplemented();
    }
}
