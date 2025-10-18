// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleProvablyFairDice
/// @notice Educational example of a mini on-chain dice/lottery using pseudo-randomness
/// @dev Not for production — replace pseudo-randomness with Chainlink VRF for real fairness

contract SimpleProvablyFairDice {
    address public owner;
    uint256 public minBet = 0.01 ether;
    uint256 public maxBet = 1 ether;
    uint256 public houseEdge = 2; // 2% house edge

    event BetPlaced(address indexed player, uint256 amount, uint256 guess);
    event BetResult(address indexed player, uint256 rolled, bool win, uint256 payout);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Place a bet guessing a dice roll between 1-6
    /// @param guess The player’s guessed number (1-6)
    function bet(uint256 guess) external payable {
        require(guess >= 1 && guess <= 6, "Guess must be 1-6");
        require(msg.value >= minBet && msg.value <= maxBet, "Bet out of range");
        require(address(this).balance >= msg.value * 6, "Contract lacks payout funds");

        emit BetPlaced(msg.sender, msg.value, guess);

        // Generate pseudo-random dice roll
        uint256 rolled = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao, // randomness beacon (post-Merge)
                    msg.sender
                )
            )
        ) % 6) + 1;

        bool win = (rolled == guess);
        uint256 payout = 0;

        if (win) {
            payout = (msg.value * 6 * (100 - houseEdge)) / 100;
            payable(msg.sender).transfer(payout);
        }

        emit BetResult(msg.sender, rolled, win, payout);
    }

    /// @notice Owner can fund the contract to ensure payouts
    function deposit() external payable onlyOwner {}

    /// @notice Owner can withdraw profits
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough funds");
        payable(owner).transfer(amount);
    }

    /// @notice Get contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Accept ETH sent directly
    receive() external payable {}
}
