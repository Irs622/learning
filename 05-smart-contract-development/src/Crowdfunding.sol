// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ⚠️ STARTER — Phase 5, Contract 3.
// Antarmuka (state, struct, event, error, signature, constructor) sudah disediakan agar
// test di test/ bisa di-compile. Tugas Anda: isi setiap body yang berisi TODO sampai
// `forge test` lulus. Warning compiler (unused parameter, restrict to pure/view) normal
// selama fungsi masih kerangka. Referensi: solutions/src/ — buka setelah selesai.

/**
 * @title Crowdfunding
 * @notice Trustless crowdfunding with goal, deadline, and refund mechanism.
 * @dev Implements CEI pattern and reentrancy guard.
 *      Phase 5 — Contract 3
 */
contract Crowdfunding {
    /// @dev Dipakai oleh kerangka starter. Hapus setelah semua fungsi diimplementasikan.
    error NotImplemented();

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    address payable public immutable CREATOR;
    uint256 public immutable GOAL;
    uint256 public immutable DEADLINE;

    uint256 public totalRaised;
    bool public finalized;
    bool public succeeded;

    bool private _locked;

    mapping(address => uint256) private _donations;

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Donated(address indexed donor, uint256 amount, uint256 newTotal);
    event Finalized(bool indexed succeeded, uint256 totalRaised);
    event Refunded(address indexed donor, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error CampaignEnded();
    error CampaignNotEnded();
    error CampaignNotFinalized();
    error AlreadyFinalized();
    error NoDonation(address donor);
    error NotCreator();
    error CampaignFailed();
    error CampaignSucceeded();
    error ZeroAmount();
    error ReentrantCall();
    error CreatorCannotRefund();

    // =========================================================
    //                       MODIFIERS
    // =========================================================

    modifier noReentrant() {
        // TODO: implementasikan pengecekan modifier ini
        _;
    }

    modifier isFinalized() {
        // TODO: implementasikan pengecekan modifier ini
        _;
    }

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    /**
     * @param goal Funding goal in wei.
     * @param durationSeconds Campaign duration in seconds.
     */
    constructor(uint256 goal, uint256 durationSeconds) {
        if (goal == 0) revert ZeroAmount();
        if (durationSeconds == 0) revert ZeroAmount();

        CREATOR = payable(msg.sender);
        GOAL = goal;
        DEADLINE = block.timestamp + durationSeconds;
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /// @notice Donate ETH to the campaign.
    function donate() external payable {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    /// @notice Finalize the campaign after deadline. Anyone can call.
    function finalize() external {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    /// @notice Withdraw funds if campaign succeeded. Only creator.
    function withdraw() external noReentrant isFinalized {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    /// @notice Refund your donation if campaign failed.
    function refund() external noReentrant isFinalized {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function getProgress()
        external
        view
        returns (uint256 raised, uint256 goal, uint256 percentageWei, uint256 timeLeft)
    {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    function getDonation(address donor) external view returns (uint256) {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }

    function isActive() external view returns (bool) {
        // TODO: implementasikan (lihat README → Contract 3 → Spesifikasi)
        revert NotImplemented();
    }
}
