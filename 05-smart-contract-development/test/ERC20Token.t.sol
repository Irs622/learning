// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Token.sol";

contract ERC20TokenTest is Test {
    ERC20Token public token;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");
    address public carol = makeAddr("carol");

    uint256 constant INITIAL_SUPPLY = 1_000_000; // 1M tokens (whole units)
    uint256 constant INITIAL_WEI    = INITIAL_SUPPLY * 1e18;

    function setUp() public {
        vm.prank(owner);
        token = new ERC20Token("TestToken", "TST", INITIAL_SUPPLY);
    }

    // ===== DEPLOYMENT =====

    function test_InitialState() public view {
        assertEq(token.name(),        "TestToken");
        assertEq(token.symbol(),      "TST");
        assertEq(token.decimals(),    18);
        assertEq(token.totalSupply(), INITIAL_WEI);
        assertEq(token.balanceOf(owner), INITIAL_WEI);
        assertEq(token.owner(),       owner);
    }

    // ===== TRANSFER =====

    function test_Transfer_Basic() public {
        uint256 amount = 100 * 1e18;

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_WEI - amount);
    }

    function test_Transfer_EmitsEvent() public {
        uint256 amount = 50 * 1e18;
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit ERC20Token.Transfer(owner, alice, amount);
        token.transfer(alice, amount);
    }

    function test_Transfer_ZeroAmount() public {
        vm.prank(owner);
        token.transfer(alice, 0); // Should not revert
        assertEq(token.balanceOf(alice), 0);
    }

    function test_Transfer_SelfTransfer() public {
        uint256 before = token.balanceOf(owner);
        vm.prank(owner);
        token.transfer(owner, 100 * 1e18);
        assertEq(token.balanceOf(owner), before);
    }

    function test_Revert_Transfer_InsufficientBalance() public {
        uint256 tooMuch = INITIAL_WEI + 1;
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            ERC20Token.InsufficientBalance.selector,
            owner, INITIAL_WEI, tooMuch
        ));
        token.transfer(alice, tooMuch);
    }

    function test_Revert_Transfer_ToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(ERC20Token.ZeroAddress.selector);
        token.transfer(address(0), 100);
    }

    // ===== APPROVE & ALLOWANCE =====

    function test_Approve_SetsAllowance() public {
        uint256 amount = 500 * 1e18;
        vm.prank(owner);
        token.approve(alice, amount);
        assertEq(token.allowance(owner, alice), amount);
    }

    function test_Approve_EmitsEvent() public {
        uint256 amount = 500 * 1e18;
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit ERC20Token.Approval(owner, alice, amount);
        token.approve(alice, amount);
    }

    function test_Approve_OverwriteAllowance() public {
        vm.prank(owner);
        token.approve(alice, 1000 * 1e18);
        vm.prank(owner);
        token.approve(alice, 50 * 1e18); // Overwrite
        assertEq(token.allowance(owner, alice), 50 * 1e18);
    }

    // ===== TRANSFER FROM =====

    function test_TransferFrom_Basic() public {
        uint256 amount = 300 * 1e18;

        vm.prank(owner);
        token.approve(alice, amount);

        vm.prank(alice);
        token.transferFrom(owner, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(owner, alice), 0); // Spent
    }

    function test_TransferFrom_PartialAllowance() public {
        uint256 approved = 500 * 1e18;
        uint256 spent    = 200 * 1e18;

        vm.prank(owner);
        token.approve(alice, approved);

        vm.prank(alice);
        token.transferFrom(owner, bob, spent);

        assertEq(token.allowance(owner, alice), approved - spent);
    }

    function test_TransferFrom_InfiniteApproval() public {
        // Approve max uint256 → allowance should NOT decrease
        vm.prank(owner);
        token.approve(alice, type(uint256).max);

        vm.prank(alice);
        token.transferFrom(owner, bob, 100 * 1e18);

        assertEq(token.allowance(owner, alice), type(uint256).max);
    }

    function test_Revert_TransferFrom_ExceedsAllowance() public {
        uint256 approved = 100 * 1e18;
        uint256 over     = 101 * 1e18;

        vm.prank(owner);
        token.approve(alice, approved);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            ERC20Token.InsufficientAllowance.selector,
            owner, alice, approved, over
        ));
        token.transferFrom(owner, bob, over);
    }

    // ===== INCREASE / DECREASE ALLOWANCE =====

    function test_IncreaseAllowance() public {
        vm.prank(owner);
        token.approve(alice, 100 * 1e18);
        vm.prank(owner);
        token.increaseAllowance(alice, 50 * 1e18);
        assertEq(token.allowance(owner, alice), 150 * 1e18);
    }

    function test_DecreaseAllowance() public {
        vm.prank(owner);
        token.approve(alice, 100 * 1e18);
        vm.prank(owner);
        token.decreaseAllowance(alice, 40 * 1e18);
        assertEq(token.allowance(owner, alice), 60 * 1e18);
    }

    function test_Revert_DecreaseAllowance_BelowZero() public {
        vm.prank(owner);
        token.approve(alice, 100 * 1e18);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            ERC20Token.InsufficientAllowance.selector,
            owner, alice, 100 * 1e18, 200 * 1e18
        ));
        token.decreaseAllowance(alice, 200 * 1e18);
    }

    // ===== MINT =====

    function test_Mint_IncreasesSupplyAndBalance() public {
        uint256 mintAmt = 1000 * 1e18;
        vm.prank(owner);
        token.mint(alice, mintAmt);

        assertEq(token.balanceOf(alice), mintAmt);
        assertEq(token.totalSupply(), INITIAL_WEI + mintAmt);
    }

    function test_Mint_EmitsTransferFromZero() public {
        uint256 mintAmt = 500 * 1e18;
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit ERC20Token.Transfer(address(0), alice, mintAmt);
        token.mint(alice, mintAmt);
    }

    function test_Revert_NonOwnerMint() public {
        vm.prank(alice);
        vm.expectRevert(ERC20Token.NotOwner.selector);
        token.mint(alice, 1000 * 1e18);
    }

    // ===== BURN =====

    function test_Burn_DecreasesSupplyAndBalance() public {
        uint256 burnAmt = 500 * 1e18;
        vm.prank(owner);
        token.burn(burnAmt);

        assertEq(token.totalSupply(), INITIAL_WEI - burnAmt);
        assertEq(token.balanceOf(owner), INITIAL_WEI - burnAmt);
    }

    function test_Burn_EmitsTransferToZero() public {
        uint256 burnAmt = 100 * 1e18;
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit ERC20Token.Transfer(owner, address(0), burnAmt);
        token.burn(burnAmt);
    }

    function test_BurnFrom_UsesAllowance() public {
        uint256 burnAmt = 200 * 1e18;
        vm.prank(owner);
        token.approve(alice, burnAmt);

        vm.prank(alice);
        token.burnFrom(owner, burnAmt);

        assertEq(token.totalSupply(), INITIAL_WEI - burnAmt);
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_Revert_Burn_InsufficientBalance() public {
        vm.prank(alice); // alice has 0 balance
        vm.expectRevert(abi.encodeWithSelector(
            ERC20Token.InsufficientBalance.selector,
            alice, 0, 1
        ));
        token.burn(1);
    }

    // ===== OWNERSHIP =====

    function test_TransferOwnership() public {
        vm.prank(owner);
        token.transferOwnership(alice);
        assertEq(token.owner(), alice);

        // alice can now mint
        vm.prank(alice);
        token.mint(bob, 1000 * 1e18);
        assertEq(token.balanceOf(bob), 1000 * 1e18);
    }

    // ===== FUZZ =====

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_WEI);
        vm.prank(owner);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_WEI - amount);
        assertEq(token.totalSupply(), INITIAL_WEI); // Supply unchanged
    }
}
