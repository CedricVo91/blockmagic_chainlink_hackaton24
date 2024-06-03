// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pair_v3_AMM.sol";

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

        pair = address(new Pair(tokenA, tokenB, priceFeedA, priceFeedB));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair; // Allow reverse lookup
        allPairs.push(pair);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}









