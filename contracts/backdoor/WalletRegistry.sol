// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
           When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract WalletRegistry is IProxyCreationCallback, Ownable {
    uint256 private constant MAX_OWNERS = 1;
    uint256 private constant MAX_THRESHOLD = 1;
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18

    address public immutable masterCopy;
    address public immutable walletFactory;
    IERC20 public immutable token;

    mapping(address => bool) public beneficiaries;

    // owner => wallet
    mapping(address => address) public wallets;

    constructor(
        address masterCopyAddress,
        address walletFactoryAddress,
        address tokenAddress,
        address[] memory initialBeneficiaries
    ) {
        require(masterCopyAddress != address(0));
        require(walletFactoryAddress != address(0));

        masterCopy = masterCopyAddress;
        walletFactory = walletFactoryAddress;
        token = IERC20(tokenAddress);

        for (uint256 i = 0; i < initialBeneficiaries.length; i++) {
            addBeneficiary(initialBeneficiaries[i]);
        }
    }

    function addBeneficiary(address beneficiary) public onlyOwner {
        // only owner adds beneficiary
        beneficiaries[beneficiary] = true;
    }

    function _removeBeneficiary(address beneficiary) private {
        beneficiaries[beneficiary] = false;
    }

    /**
     @notice Function executed when user creates a Gnosis Safe wallet via GnosisSafeProxyFactory::createProxyWithCallback
             setting the registry's address as the callback.
     */
    //  @potential - we can create a custom GnosisSafeProxy that passes all the required conditions
    // we also need to be careful about the initializer value
    function proxyCreated(
        GnosisSafeProxy proxy,
        address singleton,
        bytes calldata initializer,
        uint256
    ) external override {
        // @notice - each existing beneficiary needs to have a wallet registered
        // Make sure we have enough DVT to pay
        require(
            token.balanceOf(address(this)) >= TOKEN_PAYMENT,
            "Not enough funds to pay"
        );

        address payable walletAddress = payable(proxy);

        // Ensure correct factory and master copy
        // @notice - this can only be called from wallet factory
        require(msg.sender == walletFactory, "Caller must be factory");

        // @notice - not sure what 'singletone' role is, but its value is dictated here
        require(singleton == masterCopy, "Fake mastercopy used");

        // Ensure initial calldata was a call to `GnosisSafe::setup`
        // @notice - this can be faked afaik
        require(
            bytes4(initializer[:4]) == GnosisSafe.setup.selector,
            "Wrong initialization"
        );

        // Ensure wallet initialization is the expected
        // @notice - these can be assured in the proxy implementation
        require(
            GnosisSafe(walletAddress).getThreshold() == MAX_THRESHOLD,
            "Invalid threshold"
        );
        require(
            GnosisSafe(walletAddress).getOwners().length == MAX_OWNERS,
            "Invalid number of owners"
        );

        // Ensure the owner is a registered beneficiary
        // @potential - we can return a beneficiary address here
        address walletOwner = GnosisSafe(walletAddress).getOwners()[0];

        require(
            beneficiaries[walletOwner],
            "Owner is not registered as beneficiary"
        );

        // Remove owner as beneficiary
        _removeBeneficiary(walletOwner);

        // Register the wallet under the owner's address
        wallets[walletOwner] = walletAddress;

        // @note - single place where the contract transfers tokens
        // Pay tokens to the newly created wallet
        // @potential - funds transferred to the PROXY contract, not the actual beneficiary (wallet owner)
        token.transfer(walletAddress, TOKEN_PAYMENT);

        // proposed solution:
        // setup GonisisSafe&GonisisSafeProxy needed for each beneficiary address
        // Create GnosisSafe wallet via GnosisSafeProxyFactory::createProxyWithCallback
        // 1. Make sure GnosisSafe(walletAddress).getOwners()[0]; -> returns beneficiary address
        // 2. Add custom method on proxy contract that transfers DVT tokens to the attacker
    }
}
