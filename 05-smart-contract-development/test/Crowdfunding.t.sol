// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/Crowdfunding.sol";

// =========================================================
//           ATTACKER CONTRACT — Reentrancy PoC
// =========================================================

contract ReentrancyAttacker {
    Crowdfunding public target;
    uint256 public attackCount;
    uint256 public stolenAmount;

    constructor(address _target) {
        target = Crowdfunding(_target);
    }

    function attack() external payable {
        target.donate{value: msg.value}();
    }

    receive() external payable {
        attackCount++;
        if (attackCount < 5 && address(target).balance > 0) {
            try target.refund() {
                stolenAmount += msg.value;
            } catch {
                // Reentrancy guard blocked — expected!
            }
        }
    }
}

// =========================================================
//                   MAIN TEST CONTRACT
// =========================================================

contract CrowdfundingTest is Test {
    Crowdfunding public cf;

    address payable public creator = payable(makeAddr("creator"));
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");

    uint256 constant GOAL = 10 ether;
    uint256 constant DURATION = 30 days;

    function setUp() public {
        vm.prank(creator);
        cf = new Crowdfunding(GOAL, DURATION);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
    }

    // ===== DEPLOYMENT =====

    function test_InitialState() public view {
        assertEq(cf.CREATOR(), creator);
        assertEq(cf.GOAL(), GOAL);
        assertEq(cf.totalRaised(), 0);
        assertFalse(cf.finalized());
        assertFalse(cf.succeeded());
        assertTrue(cf.isActive());
    }

    // ===== DONATIONS =====

    function test_Donate_UpdatesState() public {
        vm.prank(alice);
        cf.donate{value: 3 ether}();

        assertEq(cf.totalRaised(), 3 ether);
        assertEq(cf.getDonation(alice), 3 ether);
    }

    function test_Donate_AccumulatesMultiple() public {
        vm.prank(alice);
        cf.donate{value: 1 ether}();
        vm.prank(alice);
        cf.donate{value: 2 ether}();

        assertEq(cf.getDonation(alice), 3 ether);
        assertEq(cf.totalRaised(), 3 ether);
    }

    function test_Donate_EmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Crowdfunding.Donated(alice, 3 ether, 3 ether);
        cf.donate{value: 3 ether}();
    }

    function test_RevertWhen_DonateAfterDeadline() public {
        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(alice);
        vm.expectRevert(Crowdfunding.CampaignEnded.selector);
        cf.donate{value: 1 ether}();
    }

    function test_RevertWhen_DonateZero() public {
        vm.prank(alice);
        vm.expectRevert(Crowdfunding.ZeroAmount.selector);
        cf.donate{value: 0}();
    }

    // ===== FINALIZE =====

    function test_Finalize_Success() public {
        vm.prank(alice);
        cf.donate{value: 10 ether}();

        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        assertTrue(cf.finalized());
        assertTrue(cf.succeeded());
        assertFalse(cf.isActive());
    }

    function test_Finalize_Failed() public {
        vm.prank(alice);
        cf.donate{value: 1 ether}(); // Below goal

        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        assertTrue(cf.finalized());
        assertFalse(cf.succeeded());
    }

    function test_RevertWhen_FinalizeBeforeDeadline() public {
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        cf.finalize();
    }

    function test_RevertWhen_FinalizeTwice() public {
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.expectRevert(Crowdfunding.AlreadyFinalized.selector);
        cf.finalize();
    }

    // ===== SUCCESS SCENARIO =====

    function test_Success_CreatorWithdraws() public {
        vm.prank(alice);
        cf.donate{value: 6 ether}();
        vm.prank(bob);
        cf.donate{value: 4 ether}();

        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        uint256 before = creator.balance;
        vm.prank(creator);
        vm.expectEmit(true, false, false, true);
        emit Crowdfunding.Withdrawn(creator, 10 ether);
        cf.withdraw();

        assertEq(creator.balance, before + 10 ether);
        assertEq(address(cf).balance, 0);
    }

    function test_RevertWhen_NonCreatorWithdraw() public {
        vm.prank(alice);
        cf.donate{value: 10 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.prank(alice);
        vm.expectRevert(Crowdfunding.NotCreator.selector);
        cf.withdraw();
    }

    // ===== FAILURE SCENARIO =====

    function test_Failed_DonorsRefund() public {
        vm.prank(alice);
        cf.donate{value: 2 ether}();
        vm.prank(bob);
        cf.donate{value: 3 ether}();

        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        uint256 aliceBefore = alice.balance;
        vm.prank(alice);
        cf.refund();
        assertEq(alice.balance, aliceBefore + 2 ether);
        assertEq(cf.getDonation(alice), 0);

        uint256 bobBefore = bob.balance;
        vm.prank(bob);
        cf.refund();
        assertEq(bob.balance, bobBefore + 3 ether);
    }

    function test_RevertWhen_RefundOnSuccess() public {
        vm.prank(alice);
        cf.donate{value: 10 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.prank(alice);
        vm.expectRevert(Crowdfunding.CampaignSucceeded.selector);
        cf.refund();
    }

    function test_RevertWhen_RefundNoDonation() public {
        vm.prank(alice);
        cf.donate{value: 1 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        // carol never donated
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(Crowdfunding.NoDonation.selector, carol));
        cf.refund();
    }

    function test_RevertWhen_CreatorRefund() public {
        vm.prank(alice);
        cf.donate{value: 1 ether}();
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        vm.prank(creator);
        vm.expectRevert(Crowdfunding.CreatorCannotRefund.selector);
        cf.refund();
    }

    // ===== REENTRANCY PROTECTION =====

    function test_ReentrancyAttack_IsBlocked() public {
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(cf));
        vm.deal(address(attacker), 10 ether);

        // Attacker donates 1 ETH
        attacker.attack{value: 1 ether}();

        // Alice also donates so there's ETH to steal
        vm.prank(alice);
        cf.donate{value: 5 ether}();

        // Campaign fails (total 6 ETH < 10 ETH goal)
        vm.warp(block.timestamp + DURATION + 1);
        cf.finalize();

        uint256 contractBefore = address(cf).balance;

        // Attacker attempts reentrancy
        vm.prank(address(attacker));
        cf.refund();

        // Attacker's donation zeroed — cannot re-enter
        assertEq(cf.getDonation(address(attacker)), 0);
        // Only 1 ETH withdrawn, not more
        assertEq(address(cf).balance, contractBefore - 1 ether);
        // Reentrancy was blocked after first call
        assertEq(attacker.attackCount(), 1);
    }

    // ===== PROGRESS =====

    function test_GetProgress() public {
        vm.prank(alice);
        cf.donate{value: 5 ether}();

        (uint256 raised, uint256 goal, uint256 pct, uint256 timeLeft) = cf.getProgress();
        assertEq(raised, 5 ether);
        assertEq(goal, GOAL);
        assertEq(pct, 0.5e18); // 50% = 0.5 * 1e18
        assertGt(timeLeft, 0);
    }

    // ===== FUZZ =====

    function testFuzz_Donate(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(alice, uint256(amount));

        vm.prank(alice);
        cf.donate{value: amount}();

        assertEq(cf.getDonation(alice), amount);
        assertEq(cf.totalRaised(), amount);
    }
}
