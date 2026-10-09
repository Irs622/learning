// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ⚠️ STARTER — Phase 5, Contract 1.
// Antarmuka (state, struct, event, error, signature, constructor) sudah disediakan agar
// test di test/ bisa di-compile. Tugas Anda: isi setiap body yang berisi TODO sampai
// `forge test` lulus. Warning compiler (unused parameter, restrict to pure/view) normal
// selama fungsi masih kerangka. Referensi: solutions/src/ — buka setelah selesai.

/**
 * @title SimpleStorage
 * @author Learning Web3
 * @notice A storage contract with ownership, update history, and events.
 * @dev Phase 5 — Contract 1
 */
contract SimpleStorage {
    /// @dev Dipakai oleh kerangka starter. Hapus setelah semua fungsi diimplementasikan.
    error NotImplemented();

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

    event Updated(address indexed by, uint256 oldValue, uint256 newValue, uint256 indexed timestamp);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
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
        // TODO: implementasikan pengecekan modifier ini
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(uint256 initialValue) {
        _owner = msg.sender;
        _value = initialValue;
        _history.push(initialValue);
        emit Updated(msg.sender, 0, initialValue, block.timestamp);
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /**
     * @notice Store a new value. Only callable by owner.
     * @param newValue The new value. Cannot be same as current.
     */
    function store(uint256 newValue) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    /**
     * @notice Transfer ownership to a new address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    /**
     * @notice Clear history and reset update counter.
     */
    function resetHistory() external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function retrieve() external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    function getHistory() external view returns (uint256[] memory) {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    function getUpdateCount() external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }

    function owner() external view returns (address) {
        // TODO: implementasikan (lihat README → Contract 1 → Spesifikasi)
        revert NotImplemented();
    }
}
