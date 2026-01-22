// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @notice Strategy adapter interface
 * @dev Implementations MUST restrict all state-changing functions
 *      to be callable only by the Vault contract.
 */

interface IStrategy {
    /// @dev Must only be callable by Vault
    function deposit(uint256 amount) external;

    /// @dev Must only be callable by Vault
    function withdraw(uint256 amount) external returns (uint256);

    function totalAssets() external view returns (uint256);
    function maxWithdraw() external view returns (uint256);

    function isLocked() external view returns (bool);
    function unlockTime() external view returns (uint256);
    // ✅ TEST / MOCK ONLY
    function simulateYield(uint256 amount) external;
}
