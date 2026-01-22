// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/iStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title StrategyB
 * @notice Locked liquidity mock strategy
 */
contract StrategyB is IStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    address public immutable vault;
    uint256 private balance;
    uint256 public immutable unlockAt;

    modifier onlyVault() {
    require(msg.sender == vault, "Only vault");
    _;
}


    constructor(IERC20 asset_, address vault_) {
    asset = asset_;
    vault = vault_;
    unlockAt = block.timestamp + 3 days;
   }


    function deposit(uint256 amount) external onlyVault {
    asset.safeTransferFrom(msg.sender, address(this), amount);
    balance += amount;
   }


    function withdraw(uint256 amount) external onlyVault returns (uint256) {
    require(block.timestamp >= unlockAt, "Locked");
    uint256 out = amount > balance ? balance : amount;
    balance -= out;
    asset.safeTransfer(msg.sender, out);
    return out;
   }

    function totalAssets() external view returns (uint256) {
        return balance;
    }

    function maxWithdraw() external view returns (uint256) {
        return block.timestamp >= unlockAt ? balance : 0;
    }

    function isLocked() external pure returns (bool) {
        return true;
    }

    function unlockTime() external view returns (uint256) {
        return unlockAt;
    }

    function simulateYield(uint256 /*amount*/) external override {
    // StrategyB does not generate yield
    // Intentionally left blank
}

}
