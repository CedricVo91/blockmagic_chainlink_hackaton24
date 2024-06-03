// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pair_v6_LP.sol";
import "./LPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Import ERC20 from OpenZeppelin

contract Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(
        address tokenA,
        address tokenB,
        address priceFeedA, // Price feed for tokenA/USD
        address priceFeedB  // Price feed for tokenB/USD
    ) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        require(getPair[tokenA][tokenB] == address(0), "Pair already exists");

        // Cast token addresses to ERC20 to get the symbols
        ERC20 tokenAContract = ERC20(tokenA);
        ERC20 tokenBContract = ERC20(tokenB);

        // Create a unique name and symbol for the LP token
        string memory lpTokenName = string(abi.encodePacked("OurDEX ", tokenAContract.symbol(), "-", tokenBContract.symbol(), " LP"));
        string memory lpTokenSymbol = string(abi.encodePacked("OD-", tokenAContract.symbol(), "-", tokenBContract.symbol(), "LP"));

        // Deploy the LP token contract
        LPToken lpToken = new LPToken(lpTokenName, lpTokenSymbol);

        // Deploy the pair contract with the LP token address
        pair = address(new Pair(tokenA, tokenB, priceFeedA, priceFeedB, address(lpToken)));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair; // Allow reverse lookup
        allPairs.push(pair);

        return pair;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}

