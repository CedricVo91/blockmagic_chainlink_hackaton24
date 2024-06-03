// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";
import "./Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//The Router contract is essential in your DEX setup as it... 
//provides user-friendly functions to interact with the Pair contracts. 
//It facilitates adding liquidity, performing token swaps, and removing...
//liquidity, making it easier for users to interact with the decentralized... 
//exchange.

contract Router {
    Factory public factory;

    constructor(address _factory) {
        factory = Factory(_factory);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");
        emit PairAddress(pair); // Emit the pair address for debugging
        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);
        Pair(pair).addLiquidity(amountADesired, amountBDesired);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        address inputToken,
        address outputToken
    ) external {
        address pair = factory.getPair(inputToken, outputToken);
        require(pair != address(0), "Pair does not exist");
        Pair(pair).swap(amountIn, inputToken);
    }

    event PairAddress(address pair); // Define the event
}