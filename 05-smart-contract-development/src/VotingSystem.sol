// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ⚠️ STARTER — Phase 5, Contract 2.
// Antarmuka (state, struct, event, error, signature, constructor) sudah disediakan agar
// test di test/ bisa di-compile. Tugas Anda: isi setiap body yang berisi TODO sampai
// `forge test` lulus. Warning compiler (unused parameter, restrict to pure/view) normal
// selama fungsi masih kerangka. Referensi: solutions/src/ — buka setelah selesai.

/**
 * @title VotingSystem
 * @notice On-chain governance voting with proposals, time-based phases, and quorum.
 * @dev Phase 5 — Contract 2
 */
contract VotingSystem {
    /// @dev Dipakai oleh kerangka starter. Hapus setelah semua fungsi diimplementasikan.
    error NotImplemented();

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
        // TODO: implementasikan pengecekan modifier ini
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        // TODO: implementasikan pengecekan modifier ini
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
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function vote(uint256 proposalId, bool support) external proposalExists(proposalId) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function executeProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function cancelProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function setQuorum(uint256 newThreshold) external onlyOwner {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function getProposal(uint256 proposalId) external view proposalExists(proposalId) returns (Proposal memory) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function getResult(uint256 proposalId)
        external
        view
        proposalExists(proposalId)
        returns (bool passed, uint256 forVotes, uint256 againstVotes)
    {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function owner() external view returns (address) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }

    function nextProposalId() external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 2 → Spesifikasi)
        revert NotImplemented();
    }
}
