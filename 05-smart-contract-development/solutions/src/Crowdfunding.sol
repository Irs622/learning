// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Crowdfunding
 * @notice Trustless crowdfunding with goal, deadline, and refund mechanism.
 * @dev Implements CEI pattern and reentrancy guard.
 *      Phase 5 — Contract 3
 */
contract Crowdfunding {
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
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    modifier isFinalized() {
        if (!finalized) revert CampaignNotFinalized();
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
        if (block.timestamp >= DEADLINE) revert CampaignEnded();
        if (msg.value == 0) revert ZeroAmount();

        _donations[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit Donated(msg.sender, msg.value, totalRaised);
    }

    /// @notice Finalize the campaign after deadline. Anyone can call.
    function finalize() external {
        if (block.timestamp < DEADLINE) revert CampaignNotEnded();
        if (finalized) revert AlreadyFinalized();

        finalized = true;
        succeeded = totalRaised >= GOAL;

        emit Finalized(succeeded, totalRaised);
    }

    /// @notice Withdraw funds if campaign succeeded. Only creator.
    function withdraw() external noReentrant isFinalized {
        if (msg.sender != CREATOR) revert NotCreator();
        if (!succeeded) revert CampaignFailed();

        uint256 amount = address(this).balance;

        emit Withdrawn(CREATOR, amount);

        (bool ok,) = CREATOR.call{value: amount}("");
        require(ok, "Withdraw failed");
    }

    /// @notice Refund your donation if campaign failed.
    function refund() external noReentrant isFinalized {
        if (succeeded) revert CampaignSucceeded();
        if (msg.sender == CREATOR) revert CreatorCannotRefund();

        uint256 amount = _donations[msg.sender];
        if (amount == 0) revert NoDonation(msg.sender);

        // CEI: Effects BEFORE Interaction
        _donations[msg.sender] = 0;

        emit Refunded(msg.sender, amount);

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Refund failed");
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    function getProgress()
        external
        view
        returns (uint256 raised, uint256 goal, uint256 percentageWei, uint256 timeLeft)
    {
        raised = totalRaised;
        goal = GOAL;
        percentageWei = GOAL > 0 ? (totalRaised * 1e18) / GOAL : 0;
        timeLeft = block.timestamp >= DEADLINE ? 0 : DEADLINE - block.timestamp;
    }

    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }

    function isActive() external view returns (bool) {
        return !finalized && block.timestamp < DEADLINE;
    }
}
