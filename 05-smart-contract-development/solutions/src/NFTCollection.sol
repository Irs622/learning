// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title NFTCollection
 * @notice ERC-721 NFT collection with phased minting, reveal, and EIP-2981 royalties.
 * @dev Implements EIP-721, EIP-721 Metadata, EIP-2981, EIP-165.
 *      Phase 5 — Contract 5
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
    uint256 public immutable MINT_PRICE;
    uint256 public immutable MAX_PER_WALLET;

    address payable public owner;
    uint96 public royaltyBps;

    bool public revealed;
    bool public publicSaleOpen;
    string public baseURI;
    string public unrevealedURI;
    uint256 private _nextTokenId;

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => uint256) public mintedPerWallet;

    // =========================================================
    //                   INTERFACE IDs (EIP-165)
    // =========================================================

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_META = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
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
        uint96 _royaltyBps,
        string memory _unrevealedURI
    ) {
        name = _name;
        symbol = _symbol;
        MAX_SUPPLY = maxSupply;
        MINT_PRICE = mintPrice;
        MAX_PER_WALLET = maxPerWallet;
        royaltyBps = _royaltyBps;
        unrevealedURI = _unrevealedURI;
        owner = payable(msg.sender);
    }

    // =========================================================
    //                    MINTING FUNCTIONS
    // =========================================================

    function mint(uint256 quantity) external payable {
        if (!publicSaleOpen) revert SaleNotOpen();
        if (_nextTokenId + quantity > MAX_SUPPLY) revert MaxSupplyReached(MAX_SUPPLY);
        if (mintedPerWallet[msg.sender] + quantity > MAX_PER_WALLET) {
            revert MaxPerWalletReached(msg.sender, MAX_PER_WALLET);
        }
        if (msg.value < MINT_PRICE * quantity) {
            revert InsufficientPayment(msg.value, MINT_PRICE * quantity);
        }

        mintedPerWallet[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _mint(msg.sender, tokenId);
        }
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (_nextTokenId + quantity > MAX_SUPPLY) revert MaxSupplyReached(MAX_SUPPLY);

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
        if (!revealed) return unrevealedURI;
        return string.concat(baseURI, _toString(tokenId), ".json");
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // =========================================================
    //                    EIP-2981 ROYALTIES
    // =========================================================

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner;
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    // =========================================================
    //                   EIP-165 INTERFACE SUPPORT
    // =========================================================

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 || interfaceId == _INTERFACE_ID_ERC721_META
            || interfaceId == _INTERFACE_ID_ERC2981 || interfaceId == _INTERFACE_ID_ERC165;
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
        baseURI = _baseURI;
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
        if (ownerOf(tokenId) != from) revert NotApproved(from, tokenId);
        if (to == address(0)) revert ZeroAddress();

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
        if (spender != tokenOwner && !_operatorApprovals[tokenOwner][spender] && _tokenApprovals[tokenId] != spender) {
            revert NotApproved(spender, tokenId);
        }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
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

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
