// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/iStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title StrategyA
 * @notice Instant liquidity mock strategy
 */
contract StrategyA is IStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    address public immutable vault;
    uint256 private balance;

    modifier onlyVault() {
    require(msg.sender == vault, "Only vault");
    _;
}

    constructor(IERC20 asset_, address vault_) {
    asset = asset_;
    vault = vault_;
}


    function deposit(uint256 amount) external onlyVault {
    asset.safeTransferFrom(msg.sender, address(this), amount);
    balance += amount;
}


    function withdraw(uint256 amount) external onlyVault returns (uint256) {
    uint256 out = amount > balance ? balance : amount;
    balance -= out;
    asset.safeTransfer(msg.sender, out);
    return out;
}


    function totalAssets() external view returns (uint256) {
        return balance;
    }

    function maxWithdraw() external view returns (uint256) {
        return balance;
    }

    function isLocked() external pure returns (bool) {
        return false;
    }

    function unlockTime() external pure returns (uint256) {
        return 0;
    }

    function simulateYield(uint256 profit) external onlyVault {
    balance += profit;
}

}
