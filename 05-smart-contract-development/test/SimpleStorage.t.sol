// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public store;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    uint256 constant INITIAL = 42;

    function setUp() public {
        vm.prank(owner);
        store = new SimpleStorage(INITIAL);
    }

    // ===== DEPLOYMENT =====

    function test_InitialState() public view {
        assertEq(store.retrieve(), INITIAL);
        assertEq(store.getUpdateCount(), 0);
        assertEq(store.owner(), owner);

        uint256[] memory history = store.getHistory();
        assertEq(history.length, 1);
        assertEq(history[0], INITIAL);
    }

    // ===== STORE =====

    function test_Store_UpdatesValue() public {
        vm.prank(owner);
        store.store(100);
        assertEq(store.retrieve(), 100);
    }

    function test_Store_IncrementsCounter() public {
        vm.prank(owner);
        store.store(100);
        assertEq(store.getUpdateCount(), 1);

        vm.prank(owner);
        store.store(200);
        assertEq(store.getUpdateCount(), 2);
    }

    function test_Store_AppendsHistory() public {
        vm.prank(owner);
        store.store(100);

        vm.prank(owner);
        store.store(200);

        uint256[] memory h = store.getHistory();
        assertEq(h.length, 3);
        assertEq(h[0], INITIAL);
        assertEq(h[1], 100);
        assertEq(h[2], 200);
    }

    function test_Store_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit SimpleStorage.Updated(owner, INITIAL, 100, block.timestamp);
        store.store(100);
    }

    // ===== REVERTS =====

    function test_Revert_NonOwnerStore() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(SimpleStorage.NotOwner.selector, alice, owner)
        );
        store.store(999);
    }

    function test_Revert_SameValue() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(SimpleStorage.SameValue.selector, INITIAL)
        );
        store.store(INITIAL);
    }

    // ===== OWNERSHIP =====

    function test_TransferOwnership() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit SimpleStorage.OwnershipTransferred(owner, alice);
        store.transferOwnership(alice);

        assertEq(store.owner(), alice);

        // old owner cannot store
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(SimpleStorage.NotOwner.selector, owner, alice)
        );
        store.store(1);

        // new owner can store
        vm.prank(alice);
        store.store(999);
        assertEq(store.retrieve(), 999);
    }

    function test_Revert_TransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(SimpleStorage.ZeroAddress.selector);
        store.transferOwnership(address(0));
    }

    // ===== RESET HISTORY =====

    function test_ResetHistory() public {
        vm.startPrank(owner);
        store.store(1);
        store.store(2);
        store.store(3);
        assertEq(store.getUpdateCount(), 3);
        assertEq(store.getHistory().length, 4);

        vm.expectEmit(true, false, false, true);
        emit SimpleStorage.HistoryReset(owner, 4);
        store.resetHistory();
        vm.stopPrank();

        assertEq(store.getUpdateCount(), 0);
        uint256[] memory h = store.getHistory();
        assertEq(h.length, 1);
        assertEq(h[0], 3); // current value preserved
    }

    // ===== FUZZ =====

    function testFuzz_Store(uint256 value) public {
        vm.assume(value != INITIAL);
        vm.prank(owner);
        store.store(value);
        assertEq(store.retrieve(), value);
    }
}
