// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanReceiver {
    using Address for address payable;

    address payable private pool;

    constructor(address payable poolAddress) {
        pool = poolAddress;
    }

    // Function called by the pool during flash loan

    // @potential - fee doesn't have any limit here
    function receiveEther(uint256 fee) public payable {
        // but the caller is limited to be the pool contract
        // making a contract to call this isn't a solution
        // using delegatecall isn't a solution b/c we're not modifying
        // the target contract balance
        require(msg.sender == pool, "Sender must be pool");

        // @solution 1 - FIRST (easier solution) is to flashloan 10 times
        // this way we'll get the 10 ETH initial funds of this contract

        // @solution 2 - ACTUAL SOLUTION - flashloan 10 times from a attacker contract
        // so that we do the entire attack in one tx
        uint256 amountToBeRepaid = msg.value + fee;

        require(
            address(this).balance >= amountToBeRepaid,
            "Cannot borrow that much"
        );

        _executeActionDuringFlashLoan();

        // Return funds to pool
        pool.sendValue(amountToBeRepaid);
    }

    // Internal function where the funds received are used
    function _executeActionDuringFlashLoan() internal {}

    // Allow deposits of ETH
    receive() external payable {}
}
