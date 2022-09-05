// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard {
    using Address for address;

    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    function fixedFee() external pure returns (uint256) {
        return FIXED_FEE;
    }

    function flashLoan(address borrower, uint256 borrowAmount)
        external
        nonReentrant
    {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough ETH in pool");

        // @potential - borrower can be ANY address that is a contract
        // and it doesn't have to be the borrower address

        // @idea 1) we can try using a malicious contract as a (proxy) borrower
        // which calls the User's contract preserving its msg.sender and msg.value
        // delegatecall can help us with this
        // this way, we can modify the fee to be RECEIVER_BALANCE - msg.value,
        // --- this doesn't work because we'll execute the borrow contract logic on the hacker contract
        // --- this doesn't affect the actual borrower contract balance

        // @idea 2) we need to find a way to preserve the msg.sender
        // but change the fee value
        // ---  did't find a way to do this
        require(borrower.isContract(), "Borrower must be a deployed contract");
        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(
            abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE),
            borrowAmount
        );

        require(
            address(this).balance >= balanceBefore + FIXED_FEE,
            "Flash loan hasn't been paid back"
        );
    }

    // Allow deposits of ETH
    receive() external payable {}
}
