// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

/**
 * @title UnstoppableLender
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract UnstoppableLender is ReentrancyGuard {
    IERC20 public immutable damnValuableToken;
    uint256 public poolBalance;

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        damnValuableToken = IERC20(tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Must deposit at least one token");

        // Transfer token from sender. Sender must have first approved them.

        // @potential - playing with amount not approved; what does it happen
        // [not applying]
        damnValuableToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        require(borrowAmount > 0, "Must borrow at least one token");

        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        // Ensured by the protocol via the `depositTokens` function

        // @question - what assert do?!
        // assert is used to validate the internal local state of the function.
        // It should be used when you think that a current state has the potential to become inconsistent.

        // @potential - is it possible to influence this?
        // poolBalance can diverge from actual balanceBefore
        // b/c poolBalance is only updated when calling depositTokens
        // but we can directly transfer to the contract so that
        // poolBalance != balanceBefore
        assert(poolBalance == balanceBefore);

        damnValuableToken.transfer(msg.sender, borrowAmount);

        // @potential 0 - send more tokens than borrowed
        // poolBalance and the actual balance of the contract will diverge in this case
        IReceiver(msg.sender).receiveTokens(
            address(damnValuableToken),
            borrowAmount
        );

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
