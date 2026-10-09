// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SimpleStorage
 * @author Learning Web3
 * @notice A storage contract with ownership, update history, and events.
 * @dev Phase 5 — Contract 1
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
        if (msg.sender != _owner) revert NotOwner(msg.sender, _owner);
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
        if (newValue == _value) revert SameValue(_value);

        uint256 oldValue = _value;
        _value = newValue;
        _updateCount++;
        _history.push(newValue);

        emit Updated(msg.sender, oldValue, newValue, block.timestamp);
    }

    /**
     * @notice Transfer ownership to a new address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Clear history and reset update counter.
     */
    function resetHistory() external onlyOwner {
        uint256 recordsDeleted = _history.length;
        delete _history;
        _updateCount = 0;
        _history.push(_value);
        emit HistoryReset(msg.sender, recordsDeleted);
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function retrieve() external view returns (uint256) {
        return _value;
    }

    function getHistory() external view returns (uint256[] memory) {
        return _history;
    }

    function getUpdateCount() external view returns (uint256) {
        return _updateCount;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}
