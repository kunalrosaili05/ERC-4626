// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IWithdrawalQueue {
    function enqueue(address user, uint256 amount, uint256 unlockTime) external;
    function claim(uint256 requestId) external;
}
