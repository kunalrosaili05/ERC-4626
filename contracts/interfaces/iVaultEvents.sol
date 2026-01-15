// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVaultEvents {
    event StrategyAdded(address indexed strategy, uint256 weightBps);
    event Rebalanced();
    event WithdrawalQueued(address indexed user, uint256 amount, uint256 unlockTime);
    event Claimed(address indexed user, uint256 amount);
    event StrategyDebtUpdated(address indexed strategy, uint256 newDebt);

}
