// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TokenStaking — STARTER (Phase 5 Challenge)
 * @notice Stake ERC20Token dan dapatkan reward 1% per hari.
 * @dev File ini sengaja BELUM diimplementasikan. Kerjakan sesuai spesifikasi di
 *      README.md → "🏆 Challenge: DeFi Mini-Protocol".
 *
 *      Implementasi referensi ada di `solutions/src/TokenStaking.sol`.
 *      Buka HANYA setelah Anda selesai dan test Anda lulus.
 *
 *      Yang perlu Anda rancang sendiri:
 *        - struct untuk menyimpan posisi stake per user
 *        - events (Staked, Unstaked, RewardClaimed, ...)
 *        - custom errors untuk setiap kondisi revert
 *        - reentrancy guard + pola CEI
 *
 *      Catatan: compiler akan memberi "Warning: Function state mutability can be
 *      restricted to pure/view" selama fungsi masih berupa kerangka — itu normal dan
 *      hilang setelah Anda mengimplementasikannya.
 */

/// @dev Interface minimal ke ERC20Token Phase 5 (sudah disediakan).
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract TokenStaking {
    // ── Parameter dari spesifikasi (boleh dipakai apa adanya) ──────────
    uint256 public constant MIN_STAKE = 100 * 1e18; // 100 token
    uint256 public constant LOCK_PERIOD = 7 days;
    uint256 public constant REWARD_RATE = 100; // 1% = 100 basis points per hari
    uint256 public constant BASIS_POINTS = 10_000;

    IERC20 public immutable STAKE_TOKEN;

    error NotImplemented();

    constructor(address stakeToken) {
        STAKE_TOKEN = IERC20(stakeToken);
    }

    /// @notice Transfer `amount` token dari user ke contract (setelah `approve`).
    function stake(uint256 amount) external {
        amount; // TODO: validasi minimum, simpan posisi, transfer token, emit event
        revert NotImplemented();
    }

    /// @notice Setelah LOCK_PERIOD: kembalikan pokok + reward.
    function unstake() external {
        // TODO: cek lock period, hitung reward, CEI, transfer pokok, mint reward
        revert NotImplemented();
    }

    /// @notice Claim reward tanpa unstake (minimal 1 hari sejak claim terakhir).
    function claimReward() external {
        // TODO
        revert NotImplemented();
    }

    /// @notice Pending reward milik `user` (view).
    function getReward(address user) external view returns (uint256) {
        user; // TODO
        revert NotImplemented();
    }

    /// @notice Info posisi stake: (amount, since, lockEnd).
    function getStakeInfo(address user) external view returns (uint256 amount, uint256 since, uint256 lockEnd) {
        user; // TODO
        (amount, since, lockEnd) = (0, 0, 0);
        revert NotImplemented();
    }
}
