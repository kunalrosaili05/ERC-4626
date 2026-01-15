// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WithdrawalQueue
 * @notice FIFO queue for async withdrawals
 */
library WithdrawalQueue {
    struct Request {
        address user;
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    struct Queue {
        Request[] requests;
    }
    // NOTE: Queue is append-only. Old requests are never deleted.
// This is acceptable for protocol-level accounting.


    function enqueue(
        Queue storage self,
        address user,
        uint256 amount,
        uint256 unlockTime
    ) internal {
        require(amount > 0, "Zero amount");
        self.requests.push(
            Request({
                user: user,
                amount: amount,
                unlockTime: unlockTime,
                claimed: false
            })
        );
    }

    function claim(
        Queue storage self,
        uint256 requestId
    ) internal returns (address user, uint256 amount) {

        require(requestId < self.requests.length, "Invalid request");
        Request storage r = self.requests[requestId];

        require(!r.claimed, "Already claimed");
        require(block.timestamp >= r.unlockTime, "Locked");

        r.claimed = true;
        return (r.user, r.amount);
    }

    function length(Queue storage self) internal view returns (uint256) {
        return self.requests.length;
    }
}
