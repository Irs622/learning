// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title VotingSystem
 * @notice On-chain governance voting with proposals, time-based phases, and quorum.
 * @dev Phase 5 — Contract 2
 */
contract VotingSystem {
    // =========================================================
    //                      TYPE DEFINITIONS
    // =========================================================

    struct Proposal {
        uint256 id;
        string description;
        address creator;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 deadline;
        bool executed;
        bool exists;
    }

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    address private _owner;
    uint256 private _nextProposalId;
    uint256 public quorumThreshold;

    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event ProposalCreated(uint256 indexed id, address indexed creator, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id, bool passed);
    event ProposalCancelled(uint256 indexed id);
    event QuorumUpdated(uint256 oldThreshold, uint256 newThreshold);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error NotOwner();
    error ProposalNotFound(uint256 proposalId);
    error VotingEnded(uint256 proposalId, uint256 deadline);
    error VotingNotEnded(uint256 proposalId, uint256 deadline);
    error AlreadyVoted(address voter, uint256 proposalId);
    error AlreadyExecuted(uint256 proposalId);
    error QuorumNotMet(uint256 totalVotes, uint256 required);
    error HasVotes(uint256 proposalId);
    error InvalidDuration();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        if (!_proposals[proposalId].exists) revert ProposalNotFound(proposalId);
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(uint256 _quorumThreshold) {
        _owner = msg.sender;
        quorumThreshold = _quorumThreshold;
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    function createProposal(string calldata description, uint256 durationSeconds)
        external
        onlyOwner
        returns (uint256 proposalId)
    {
        if (durationSeconds == 0) revert InvalidDuration();

        proposalId = _nextProposalId++;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            creator: msg.sender,
            voteFor: 0,
            voteAgainst: 0,
            deadline: block.timestamp + durationSeconds,
            executed: false,
            exists: true
        });

        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp + durationSeconds);
    }

    function vote(uint256 proposalId, bool support) external proposalExists(proposalId) {
        Proposal storage proposal = _proposals[proposalId];

        if (block.timestamp >= proposal.deadline) revert VotingEnded(proposalId, proposal.deadline);
        if (_hasVoted[proposalId][msg.sender]) revert AlreadyVoted(msg.sender, proposalId);

        _hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.executed) revert AlreadyExecuted(proposalId);
        if (block.timestamp < proposal.deadline) revert VotingNotEnded(proposalId, proposal.deadline);

        uint256 totalVotes = proposal.voteFor + proposal.voteAgainst;
        if (totalVotes < quorumThreshold) revert QuorumNotMet(totalVotes, quorumThreshold);

        proposal.executed = true;
        bool passed = proposal.voteFor > proposal.voteAgainst;

        emit ProposalExecuted(proposalId, passed);
    }

    function cancelProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        uint256 totalVotes = proposal.voteFor + proposal.voteAgainst;
        if (totalVotes > 0) revert HasVotes(proposalId);

        delete _proposals[proposalId];
        emit ProposalCancelled(proposalId);
    }

    function setQuorum(uint256 newThreshold) external onlyOwner {
        uint256 old = quorumThreshold;
        quorumThreshold = newThreshold;
        emit QuorumUpdated(old, newThreshold);
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function getProposal(uint256 proposalId) external view proposalExists(proposalId) returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return _hasVoted[proposalId][voter];
    }

    function getResult(uint256 proposalId)
        external
        view
        proposalExists(proposalId)
        returns (bool passed, uint256 forVotes, uint256 againstVotes)
    {
        Proposal storage p = _proposals[proposalId];
        forVotes = p.voteFor;
        againstVotes = p.voteAgainst;
        passed = forVotes > againstVotes;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function nextProposalId() external view returns (uint256) {
        return _nextProposalId;
    }
}
