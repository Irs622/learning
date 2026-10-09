// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "src/SimpleStorage.sol";
import "src/VotingSystem.sol";
import "src/Crowdfunding.sol";
import "src/ERC20Token.sol";
import "src/NFTCollection.sol";
import "src/TokenStaking.sol";

/**
 * @title DeployAll
 * @notice Deploys all Phase 5 contracts to the target network.
 * @dev Run with:
 *      Local:   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
 *      Sepolia: forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployAll is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        console.log("=== Phase 5 Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Balance: ", deployer.balance / 1e18, "ETH");
        console.log("");

        vm.startBroadcast(deployerKey);

        // ── Contract 1: SimpleStorage ──────────────────────────
        SimpleStorage simpleStorage = new SimpleStorage(42);
        console.log("SimpleStorage:  ", address(simpleStorage));

        // ── Contract 2: VotingSystem ───────────────────────────
        VotingSystem votingSystem = new VotingSystem(3); // quorum = 3
        console.log("VotingSystem:   ", address(votingSystem));

        // ── Contract 3: Crowdfunding ───────────────────────────
        Crowdfunding crowdfunding = new Crowdfunding(
            1 ether,   // goal: 1 ETH
            30 days    // duration: 30 days
        );
        console.log("Crowdfunding:   ", address(crowdfunding));

        // ── Contract 4: ERC-20 Token ───────────────────────────
        ERC20Token token = new ERC20Token(
            "LearningToken",
            "LRN",
            1_000_000   // 1M initial supply
        );
        console.log("ERC20Token:     ", address(token));

        // ── Contract 5: NFT Collection ─────────────────────────
        NFTCollection nftCollection = new NFTCollection(
            "PixelCats",
            "PCAT",
            1000,            // max supply
            0.05 ether,      // mint price
            5,               // max per wallet
            500,             // 5% royalty
            "ipfs://QmUnrevealed/hidden.json"
        );
        console.log("NFTCollection:  ", address(nftCollection));

        // ── Challenge: TokenStaking ────────────────────────────
        TokenStaking staking = new TokenStaking(address(token));
        // Grant staking contract minter role — transfer ownership temporarily
        // NOTE: In production you'd use roles (AccessControl), not ownership transfer
        console.log("TokenStaking:   ", address(staking));

        vm.stopBroadcast();

        console.log("");
        console.log("=== All contracts deployed! ===");
        console.log("Verify with: forge verify-contract <address> <ContractName> --chain sepolia");
    }
}
