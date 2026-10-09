// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ERC20Token
 * @notice ERC-20 compliant token implementation from scratch (no library).
 * @dev Implements EIP-20 fully. Includes mint, burn, and allowance management.
 *      Phase 5 — Contract 4
 */
contract ERC20Token {
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
        if (msg.sender != owner) revert NotOwner();
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
            _mint(msg.sender, initialSupply * 10 ** decimals);
        }
    }

    // =========================================================
    //                  EIP-20 REQUIRED FUNCTIONS
    // =========================================================

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert InsufficientAllowance(from, msg.sender, currentAllowance, amount);
            }
            allowance[from][msg.sender] = currentAllowance - amount;
            emit Approval(from, msg.sender, currentAllowance - amount);
        }

        _transfer(from, to, amount);
        return true;
    }

    // =========================================================
    //                   EXTENDED FUNCTIONS
    // =========================================================

    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        uint256 newAllowance = allowance[msg.sender][spender] + addedAmount;
        allowance[msg.sender][spender] = newAllowance;
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        uint256 current = allowance[msg.sender][spender];
        if (current < subtractedAmount) {
            revert InsufficientAllowance(msg.sender, spender, current, subtractedAmount);
        }
        uint256 newAllowance = current - subtractedAmount;
        allowance[msg.sender][spender] = newAllowance;
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        uint256 current = allowance[from][msg.sender];
        if (current < amount) {
            revert InsufficientAllowance(from, msg.sender, current, amount);
        }
        allowance[from][msg.sender] = current - amount;
        emit Approval(from, msg.sender, current - amount);
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
        if (fromBalance < amount) revert InsufficientBalance(from, fromBalance, amount);

        balanceOf[from] = fromBalance - amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
        emit Minted(to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        if (from == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        uint256 fromBalance = balanceOf[from];
        if (fromBalance < amount) revert InsufficientBalance(from, fromBalance, amount);

        balanceOf[from] = fromBalance - amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
        emit Burned(from, amount);
    }
}
