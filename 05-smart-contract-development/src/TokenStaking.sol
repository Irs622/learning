// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TokenStaking
 * @notice Stake ERC20Token and earn 1% daily rewards.
 * @dev Challenge contract — integrates with ERC20Token.
 *      Phase 5 — Challenge
 */
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract TokenStaking {
    // =========================================================
    //                      TYPE DEFINITIONS
    // =========================================================

    struct StakeInfo {
        uint256 amount;      // Tokens staked
        uint256 stakedAt;    // Timestamp when staked
        uint256 lockEnd;     // Timestamp when lock ends
        uint256 lastClaim;   // Timestamp of last reward claim
    }

    // =========================================================
    //                      STATE VARIABLES
    // =========================================================

    IERC20  public immutable STAKE_TOKEN;
    address public immutable OWNER;

    uint256 public constant MIN_STAKE      = 100 * 1e18;  // 100 tokens minimum
    uint256 public constant LOCK_PERIOD    = 7 days;
    uint256 public constant REWARD_RATE    = 100;          // 1% = 100 basis points
    uint256 public constant BASIS_POINTS   = 10_000;
    uint256 public constant SECONDS_IN_DAY = 86_400;

    uint256 public totalStaked;

    mapping(address => StakeInfo) private _stakes;

    // =========================================================
    //                       REENTRANCY
    // =========================================================

    bool private _locked;

    modifier noReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    // =========================================================
    //                         EVENTS
    // =========================================================

    event Staked(address indexed user, uint256 amount, uint256 lockEnd);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    // =========================================================
    //                     CUSTOM ERRORS
    // =========================================================

    error ZeroAmount();
    error BelowMinimum(uint256 sent, uint256 minimum);
    error AlreadyStaking(address user);
    error NotStaking(address user);
    error LockNotExpired(uint256 current, uint256 lockEnd);
    error ClaimTooSoon(uint256 current, uint256 nextClaimTime);
    error ZeroReward();

    // =========================================================
    //                      CONSTRUCTOR
    // =========================================================

    constructor(address _stakeToken) {
        STAKE_TOKEN = IERC20(_stakeToken);
        OWNER       = msg.sender;
    }

    // =========================================================
    //                    EXTERNAL FUNCTIONS
    // =========================================================

    /**
     * @notice Stake tokens. Must approve contract first.
     * @param amount Amount of tokens to stake (must be >= MIN_STAKE).
     */
    function stake(uint256 amount) external noReentrant {
        if (amount == 0) revert ZeroAmount();
        if (amount < MIN_STAKE) revert BelowMinimum(amount, MIN_STAKE);
        if (_stakes[msg.sender].amount > 0) revert AlreadyStaking(msg.sender);

        // Effects
        _stakes[msg.sender] = StakeInfo({
            amount:    amount,
            stakedAt:  block.timestamp,
            lockEnd:   block.timestamp + LOCK_PERIOD,
            lastClaim: block.timestamp
        });
        totalStaked += amount;

        // Interaction
        STAKE_TOKEN.transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, block.timestamp + LOCK_PERIOD);
    }

    /**
     * @notice Unstake all tokens + claim all pending rewards.
     *         Only callable after lock period.
     */
    function unstake() external noReentrant {
        StakeInfo storage info = _stakes[msg.sender];
        if (info.amount == 0) revert NotStaking(msg.sender);
        if (block.timestamp < info.lockEnd) {
            revert LockNotExpired(block.timestamp, info.lockEnd);
        }

        uint256 stakedAmount = info.amount;
        uint256 reward       = _calculateReward(msg.sender);

        // Effects
        totalStaked         -= stakedAmount;
        delete _stakes[msg.sender];

        emit Unstaked(msg.sender, stakedAmount, reward);

        // Interactions
        STAKE_TOKEN.transfer(msg.sender, stakedAmount);
        if (reward > 0) {
            STAKE_TOKEN.mint(msg.sender, reward);
        }
    }

    /**
     * @notice Claim pending rewards without unstaking.
     *         Minimum 1 day between claims.
     */
    function claimReward() external noReentrant {
        StakeInfo storage info = _stakes[msg.sender];
        if (info.amount == 0) revert NotStaking(msg.sender);

        uint256 nextClaim = info.lastClaim + SECONDS_IN_DAY;
        if (block.timestamp < nextClaim) {
            revert ClaimTooSoon(block.timestamp, nextClaim);
        }

        uint256 reward = _calculateReward(msg.sender);
        if (reward == 0) revert ZeroReward();

        // Effects
        info.lastClaim = block.timestamp;

        emit RewardClaimed(msg.sender, reward);

        // Interaction
        STAKE_TOKEN.mint(msg.sender, reward);
    }

    // =========================================================
    //                      VIEW FUNCTIONS
    // =========================================================

    /**
     * @notice Get staking info for a user.
     */
    function getStakeInfo(address user) external view returns (
        uint256 amount,
        uint256 stakedAt,
        uint256 lockEnd,
        uint256 pendingReward
    ) {
        StakeInfo storage info = _stakes[user];
        amount        = info.amount;
        stakedAt      = info.stakedAt;
        lockEnd       = info.lockEnd;
        pendingReward = _calculateReward(user);
    }

    /**
     * @notice Get pending reward for a user.
     */
    function getReward(address user) external view returns (uint256) {
        return _calculateReward(user);
    }

    // =========================================================
    //                    INTERNAL FUNCTIONS
    // =========================================================

    /**
     * @dev Calculate reward: amount × rate × days_elapsed / BASIS_POINTS
     *      1% per day = 100 bps per day
     */
    function _calculateReward(address user) internal view returns (uint256) {
        StakeInfo storage info = _stakes[user];
        if (info.amount == 0) return 0;

        uint256 elapsed = block.timestamp - info.lastClaim;
        if (elapsed == 0) return 0;

        // reward = amount * REWARD_RATE * elapsed / (BASIS_POINTS * SECONDS_IN_DAY)
        return (info.amount * REWARD_RATE * elapsed) / (BASIS_POINTS * SECONDS_IN_DAY);
    }
}
