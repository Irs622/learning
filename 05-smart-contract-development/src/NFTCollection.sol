// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ⚠️ STARTER — Phase 5, Contract 5.
// Antarmuka (state, struct, event, error, signature, constructor) sudah disediakan agar
// test di test/ bisa di-compile. Tugas Anda: isi setiap body yang berisi TODO sampai
// `forge test` lulus. Warning compiler (unused parameter, restrict to pure/view) normal
// selama fungsi masih kerangka. Referensi: solutions/src/ — buka setelah selesai.

/**
 * @title NFTCollection
 * @notice ERC-721 NFT collection with phased minting, reveal, and EIP-2981 royalties.
 * @dev Implements EIP-721, EIP-721 Metadata, EIP-2981, EIP-165.
 *      Phase 5 — Contract 5
 */
contract NFTCollection {
    /// @dev Dipakai oleh kerangka starter. Hapus setelah semua fungsi diimplementasikan.
    error NotImplemented();

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
        // TODO: implementasikan pengecekan modifier ini
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
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                   EIP-721 CORE FUNCTIONS
    // =========================================================

    function balanceOf(address _owner) external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function approve(address to, uint256 tokenId) external {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function setApprovalForAll(address operator, bool approved) external {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                    METADATA FUNCTIONS
    // =========================================================

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function totalSupply() external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                    EIP-2981 ROYALTIES
    // =========================================================

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                   EIP-165 INTERFACE SUPPORT
    // =========================================================

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                  OWNER ADMIN FUNCTIONS
    // =========================================================

    function toggleSale() external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function reveal(string calldata _baseURI) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function setRoyalty(uint96 newBps) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function withdrawFunds() external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                    INTERNAL FUNCTIONS
    // =========================================================

    function _mint(address to, uint256 tokenId) internal {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function _checkApprovedOrOwner(address spender, uint256 tokenId) internal view {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // TODO: implementasikan (lihat README → Contract 5 → Spesifikasi)
        revert NotImplemented();
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
