// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/NFTCollection.sol";

// =========================================================
//      Helper: ERC-721 Receiver (Good and Bad versions)
// =========================================================

contract GoodReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external pure override returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract BadReceiver {
    // Does NOT implement onERC721Received — should block safeTransferFrom
}

// =========================================================
//                   MAIN TEST CONTRACT
// =========================================================

contract NFTCollectionTest is Test {
    NFTCollection public nft;

    address payable public owner = payable(makeAddr("owner"));
    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");
    address public carol = makeAddr("carol");

    uint256 constant MAX_SUPPLY     = 100;
    uint256 constant MINT_PRICE     = 0.05 ether;
    uint256 constant MAX_PER_WALLET = 5;
    uint96  constant ROYALTY_BPS    = 500; // 5%
    string  constant UNREVEALED_URI = "ipfs://QmUnrevealed/hidden.json";
    string  constant BASE_URI       = "ipfs://QmCats/";

    function setUp() public {
        vm.prank(owner);
        nft = new NFTCollection(
            "PixelCats",
            "PCAT",
            MAX_SUPPLY,
            MINT_PRICE,
            MAX_PER_WALLET,
            ROYALTY_BPS,
            UNREVEALED_URI
        );

        vm.deal(alice, 100 ether);
        vm.deal(bob,   100 ether);
        vm.deal(carol, 100 ether);
    }

    // ===== DEPLOYMENT =====

    function test_InitialState() public view {
        assertEq(nft.name(),          "PixelCats");
        assertEq(nft.symbol(),        "PCAT");
        assertEq(nft.MAX_SUPPLY(),    MAX_SUPPLY);
        assertEq(nft.MINT_PRICE(),    MINT_PRICE);
        assertEq(nft.MAX_PER_WALLET(), MAX_PER_WALLET);
        assertEq(nft.royaltyBps(),    ROYALTY_BPS);
        assertEq(nft.totalSupply(),   0);
        assertFalse(nft.revealed());
        assertFalse(nft.publicSaleOpen());
    }

    // ===== MINTING =====

    function test_Mint_Basic() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        nft.mint{value: MINT_PRICE}(1);

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.mintedPerWallet(alice), 1);
    }

    function test_Mint_Multiple() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        nft.mint{value: MINT_PRICE * 3}(3);

        assertEq(nft.totalSupply(), 3);
        assertEq(nft.balanceOf(alice), 3);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), alice);
    }

    function test_Mint_EmitsEvents() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit NFTCollection.Transfer(address(0), alice, 0);
        nft.mint{value: MINT_PRICE}(1);
    }

    function test_RevertWhen_Mint_SaleNotOpen() public {
        vm.prank(alice);
        vm.expectRevert(NFTCollection.SaleNotOpen.selector);
        nft.mint{value: MINT_PRICE}(1);
    }

    function test_RevertWhen_Mint_InsufficientPayment() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            NFTCollection.InsufficientPayment.selector,
            0.04 ether, MINT_PRICE
        ));
        nft.mint{value: 0.04 ether}(1);
    }

    function test_RevertWhen_Mint_MaxPerWallet() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        nft.mint{value: MINT_PRICE * MAX_PER_WALLET}(MAX_PER_WALLET);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            NFTCollection.MaxPerWalletReached.selector, alice, MAX_PER_WALLET
        ));
        nft.mint{value: MINT_PRICE}(1);
    }

    // ===== AIRDROP =====

    function test_Airdrop_ByOwner() public {
        vm.prank(owner);
        nft.airdrop(alice, 3);

        assertEq(nft.totalSupply(), 3);
        assertEq(nft.balanceOf(alice), 3);
    }

    function test_RevertWhen_Airdrop_NonOwner() public {
        vm.prank(alice);
        vm.expectRevert(NFTCollection.NotOwner.selector);
        nft.airdrop(bob, 1);
    }

    // ===== TRANSFER =====

    function test_TransferFrom_Basic() public {
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferFrom_ClearsApproval() public {
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(alice);
        nft.approve(bob, 0);
        assertEq(nft.getApproved(0), bob);

        vm.prank(alice);
        nft.transferFrom(alice, carol, 0);

        assertEq(nft.getApproved(0), address(0)); // Approval cleared
    }

    function test_TransferFrom_Approved() public {
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(alice);
        nft.approve(bob, 0);

        vm.prank(bob); // bob uses alice's approval
        nft.transferFrom(alice, carol, 0);
        assertEq(nft.ownerOf(0), carol);
    }

    function test_TransferFrom_OperatorApproval() public {
        vm.prank(owner);
        nft.airdrop(alice, 3);

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        assertTrue(nft.isApprovedForAll(alice, bob));

        vm.prank(bob);
        nft.transferFrom(alice, carol, 0);
        vm.prank(bob);
        nft.transferFrom(alice, carol, 1);

        assertEq(nft.ownerOf(0), carol);
        assertEq(nft.ownerOf(1), carol);
    }

    function test_RevertWhen_TransferFrom_NotApproved() public {
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(bob); // Not approved
        vm.expectRevert(abi.encodeWithSelector(NFTCollection.NotApproved.selector, bob, 0));
        nft.transferFrom(alice, carol, 0);
    }

    // ===== SAFE TRANSFER =====

    function test_SafeTransferFrom_ToGoodReceiver() public {
        GoodReceiver receiver = new GoodReceiver();
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(alice);
        nft.safeTransferFrom(alice, address(receiver), 0);
        assertEq(nft.ownerOf(0), address(receiver));
    }

    function test_RevertWhen_SafeTransferFrom_ToBadReceiver() public {
        BadReceiver receiver = new BadReceiver();
        vm.prank(owner);
        nft.airdrop(alice, 1);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            NFTCollection.UnsafeRecipient.selector, address(receiver)
        ));
        nft.safeTransferFrom(alice, address(receiver), 0);
    }

    // ===== METADATA & REVEAL =====

    function test_TokenURI_BeforeReveal() public {
        vm.prank(owner);
        nft.airdrop(alice, 1);
        assertEq(nft.tokenURI(0), UNREVEALED_URI);
    }

    function test_TokenURI_AfterReveal() public {
        vm.prank(owner);
        nft.airdrop(alice, 3);

        vm.prank(owner);
        nft.reveal(BASE_URI);

        assertEq(nft.tokenURI(0), "ipfs://QmCats/0.json");
        assertEq(nft.tokenURI(1), "ipfs://QmCats/1.json");
        assertEq(nft.tokenURI(2), "ipfs://QmCats/2.json");
    }

    function test_RevertWhen_TokenURI_NonExistent() public {
        vm.expectRevert(abi.encodeWithSelector(NFTCollection.TokenNotFound.selector, 99));
        nft.tokenURI(99);
    }

    // ===== ROYALTIES (EIP-2981) =====

    function test_RoyaltyInfo() public view {
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(0, salePrice);

        assertEq(receiver, owner);
        assertEq(royaltyAmount, 0.05 ether); // 5% of 1 ETH
    }

    function test_SetRoyalty() public {
        vm.prank(owner);
        nft.setRoyalty(1000); // 10%

        (, uint256 amount) = nft.royaltyInfo(0, 1 ether);
        assertEq(amount, 0.1 ether);
    }

    // ===== INTERFACE SUPPORT (EIP-165) =====

    function test_SupportsInterface_ERC721() public view {
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC-721
    }

    function test_SupportsInterface_ERC721Metadata() public view {
        assertTrue(nft.supportsInterface(0x5b5e139f)); // ERC-721 Metadata
    }

    function test_SupportsInterface_ERC2981() public view {
        assertTrue(nft.supportsInterface(0x2a55205a)); // EIP-2981 Royalty
    }

    function test_SupportsInterface_ERC165() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // EIP-165
    }

    function test_SupportsInterface_Unknown() public view {
        assertFalse(nft.supportsInterface(0xdeadbeef));
    }

    // ===== WITHDRAW =====

    function test_WithdrawFunds() public {
        vm.prank(owner);
        nft.toggleSale();

        vm.prank(alice);
        nft.mint{value: MINT_PRICE * 2}(2);

        assertEq(address(nft).balance, MINT_PRICE * 2);

        uint256 ownerBefore = owner.balance;
        vm.prank(owner);
        nft.withdrawFunds();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBefore + MINT_PRICE * 2);
    }
}
