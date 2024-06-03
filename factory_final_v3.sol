// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pair_final_v3.sol";
import "./LPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(
        address tokenA,
        address tokenB,
        address priceFeedA,
        address priceFeedB,
        address ccipRouter
    ) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        require(getPair[tokenA][tokenB] == address(0), "Pair already exists");

        ERC20 tokenAContract = ERC20(tokenA);
        ERC20 tokenBContract = ERC20(tokenB);

        string memory lpTokenName = string(abi.encodePacked("OurDEX ", tokenAContract.symbol(), "-", tokenBContract.symbol(), " LP"));
        string memory lpTokenSymbol = string(abi.encodePacked("OD-", tokenAContract.symbol(), "-", tokenBContract.symbol(), "LP"));

        LPToken lpToken = new LPToken(lpTokenName, lpTokenSymbol);

        // Deploy the pair contract with the LP token address and CCIP router address
        pair = address(new Pair(tokenA, tokenB, priceFeedA, priceFeedB, address(lpToken), ccipRouter));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);

        return pair;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
