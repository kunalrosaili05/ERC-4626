// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ShareMath
 * @notice Conservative rounding helpers
 */
library ShareMath {
    function assetsToShares(
        uint256 assets,
        uint256 totalSupply,
        uint256 totalAssets
    ) internal pure returns (uint256) {
        if (totalSupply == 0 || totalAssets == 0) {
            return assets;
        }
        return (assets * totalSupply) / totalAssets;
    }

    function sharesToAssets(
        uint256 shares,
        uint256 totalSupply,
        uint256 totalAssets
    ) internal pure returns (uint256) {
        return (shares * totalAssets) / totalSupply;
    }
}
