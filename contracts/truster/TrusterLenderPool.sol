// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    IERC20 public immutable damnValuableToken;

    constructor(address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(
        // borrowAmount can be 0
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external nonReentrant {
        // No reentrancy vulnerable b/c of nonReentrant
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        // There's no constraint for the borrower to be the same as the target
        damnValuableToken.transfer(borrower, borrowAmount);

        // Ideas to implement in the target function call
        // The first call shouldn't revert

        // @idea1  - finding a way to approve transferring an amount of tokens
        // from this contract to other address
        // we'd leverage DVT as a second vulnerable entrypoint

        // This function should send back the tokens b/c the borrower doesn't have the power
        // @solution - we can directly try calling the DVT token contract, using 0 as borrowAmount
        target.functionCall(data);

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
