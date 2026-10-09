// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/VotingSystem.sol";

contract VotingSystemTest is Test {
    VotingSystem public voting;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public dave = makeAddr("dave");

    uint256 constant QUORUM = 3;
    uint256 constant DURATION = 7 days;

    function setUp() public {
        vm.prank(owner);
        voting = new VotingSystem(QUORUM);
    }

    // ===== HELPERS =====

    function _createProposal(string memory desc) internal returns (uint256) {
        vm.prank(owner);
        return voting.createProposal(desc, DURATION);
    }

    function _voteThree(uint256 pid) internal {
        vm.prank(alice);
        voting.vote(pid, true);
        vm.prank(bob);
        voting.vote(pid, true);
        vm.prank(carol);
        voting.vote(pid, false);
    }

    // ===== PROPOSAL CREATION =====

    function test_CreateProposal() public {
        uint256 id = _createProposal("Increase rewards");
        assertEq(id, 0);
        assertEq(voting.nextProposalId(), 1);

        VotingSystem.Proposal memory p = voting.getProposal(0);
        assertEq(p.description, "Increase rewards");
        assertEq(p.voteFor, 0);
        assertEq(p.voteAgainst, 0);
        assertFalse(p.executed);
        assertApproxEqAbs(p.deadline, block.timestamp + DURATION, 1);
    }

    function test_CreateMultipleProposals() public {
        _createProposal("Proposal A");
        _createProposal("Proposal B");
        _createProposal("Proposal C");
        assertEq(voting.nextProposalId(), 3);
    }

    function test_RevertWhen_NonOwnerCreate() public {
        vm.prank(alice);
        vm.expectRevert(VotingSystem.NotOwner.selector);
        voting.createProposal("Sneaky proposal", DURATION);
    }

    function test_RevertWhen_ZeroDuration() public {
        vm.prank(owner);
        vm.expectRevert(VotingSystem.InvalidDuration.selector);
        voting.createProposal("Bad duration", 0);
    }

    // ===== VOTING =====

    function test_Vote_ForAndAgainst() public {
        _createProposal("Test");
        vm.prank(alice);
        voting.vote(0, true);
        vm.prank(bob);
        voting.vote(0, false);
        vm.prank(carol);
        voting.vote(0, true);

        VotingSystem.Proposal memory p = voting.getProposal(0);
        assertEq(p.voteFor, 2);
        assertEq(p.voteAgainst, 1);
    }

    function test_Vote_TracksHasVoted() public {
        _createProposal("Test");
        assertFalse(voting.hasVoted(0, alice));

        vm.prank(alice);
        voting.vote(0, true);
        assertTrue(voting.hasVoted(0, alice));
    }

    function test_Vote_EmitsEvent() public {
        _createProposal("Test");
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit VotingSystem.Voted(0, alice, true);
        voting.vote(0, true);
    }

    function test_RevertWhen_DoubleVote() public {
        _createProposal("Test");
        vm.prank(alice);
        voting.vote(0, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.AlreadyVoted.selector, alice, 0));
        voting.vote(0, true);
    }

    function test_RevertWhen_VoteAfterDeadline() public {
        _createProposal("Test");
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.VotingEnded.selector, 0, block.timestamp - 1));
        voting.vote(0, true);
    }

    function test_RevertWhen_VoteOnNonExistentProposal() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.ProposalNotFound.selector, 99));
        voting.vote(99, true);
    }

    // ===== EXECUTION =====

    function test_Execute_Passed() public {
        _createProposal("Passing");
        _voteThree(0); // 2 for, 1 against

        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VotingSystem.ProposalExecuted(0, true);
        voting.executeProposal(0);

        (bool passed,,) = voting.getResult(0);
        assertTrue(passed);
    }

    function test_Execute_Failed() public {
        _createProposal("Failing");
        vm.prank(alice);
        voting.vote(0, false);
        vm.prank(bob);
        voting.vote(0, false);
        vm.prank(carol);
        voting.vote(0, false);

        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(owner);
        voting.executeProposal(0);

        (bool passed,,) = voting.getResult(0);
        assertFalse(passed);
    }

    function test_RevertWhen_ExecuteBeforeDeadline() public {
        _createProposal("Test");
        _voteThree(0);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.VotingNotEnded.selector, 0, block.timestamp + DURATION));
        voting.executeProposal(0);
    }

    function test_RevertWhen_ExecuteTwice() public {
        _createProposal("Test");
        _voteThree(0);
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(owner);
        voting.executeProposal(0);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.AlreadyExecuted.selector, 0));
        voting.executeProposal(0);
    }

    function test_RevertWhen_QuorumNotMet() public {
        _createProposal("Low turnout");
        vm.prank(alice);
        voting.vote(0, true);
        vm.prank(bob);
        voting.vote(0, true);
        // Only 2 votes, quorum = 3

        vm.warp(block.timestamp + DURATION + 1);
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.QuorumNotMet.selector, 2, QUORUM));
        voting.executeProposal(0);
    }

    // ===== CANCEL =====

    function test_CancelProposal_NoVotes() public {
        _createProposal("Cancel me");
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit VotingSystem.ProposalCancelled(0);
        voting.cancelProposal(0);

        vm.expectRevert(abi.encodeWithSelector(VotingSystem.ProposalNotFound.selector, 0));
        voting.getProposal(0);
    }

    function test_RevertWhen_CancelWithVotes() public {
        _createProposal("Has votes");
        vm.prank(alice);
        voting.vote(0, true);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(VotingSystem.HasVotes.selector, 0));
        voting.cancelProposal(0);
    }

    // ===== QUORUM UPDATE =====

    function test_SetQuorum() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit VotingSystem.QuorumUpdated(QUORUM, 5);
        voting.setQuorum(5);

        assertEq(voting.quorumThreshold(), 5);
    }

    // ===== PROPOSALS ARE INDEPENDENT =====

    function test_MultipleProposals_IndependentVotes() public {
        _createProposal("Proposal 0");
        _createProposal("Proposal 1");

        vm.prank(alice);
        voting.vote(0, true);
        vm.prank(alice);
        voting.vote(1, false);

        VotingSystem.Proposal memory p0 = voting.getProposal(0);
        VotingSystem.Proposal memory p1 = voting.getProposal(1);

        assertEq(p0.voteFor, 1);
        assertEq(p1.voteFor, 0);
        assertEq(p1.voteAgainst, 1);
    }
}
