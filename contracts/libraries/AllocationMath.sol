// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AllocationMath
 * @notice Allocation and cap enforcement helpers
 */
library AllocationMath {
    uint256 internal constant MAX_BPS = 10_000;

    function computeTarget(
    uint256 totalAssets,
    uint256 weightBps
) internal pure returns (uint256) {
    require(weightBps <= MAX_BPS, "Invalid BPS");
    return (totalAssets * weightBps) / MAX_BPS;
}


    function checkCap(
        uint256 weightBps,
        uint256 maxCapBps
    ) internal pure {
        require(weightBps <= maxCapBps, "Allocation cap exceeded");
    }
}
