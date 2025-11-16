// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Pair_final_v3.sol";
import "./LPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Factory
 * @notice Factory contract for creating AMM trading pairs
 * @dev Creates new Pair contracts with their associated LP tokens
 */
contract Factory {
    // ============ Events ============
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        address lpToken,
        uint256 totalPairs
    );

    // ============ State Variables ============
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    /**
     * @notice Creates a new trading pair for two tokens
     * @dev Deploys both the LP token and Pair contracts, transfers LP token ownership to Pair
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param priceFeedA Chainlink price feed for tokenA
     * @param priceFeedB Chainlink price feed for tokenB
     * @param ccipRouter CCIP router address for cross-chain functionality
     * @return pair Address of the newly created Pair contract
     */
    function createPair(
        address tokenA,
        address tokenB,
        address priceFeedA,
        address priceFeedB,
        address ccipRouter
    ) external returns (address pair) {
        require(tokenA != address(0) && tokenB != address(0), "Invalid token address");
        require(tokenA != tokenB, "Identical addresses");
        require(getPair[tokenA][tokenB] == address(0), "Pair already exists");
        require(priceFeedA != address(0) && priceFeedB != address(0), "Invalid price feed");
        require(ccipRouter != address(0), "Invalid CCIP router");

        // Get token symbols for LP token naming
        ERC20 tokenAContract = ERC20(tokenA);
        ERC20 tokenBContract = ERC20(tokenB);

        // Create descriptive LP token name and symbol
        string memory lpTokenName = string(
            abi.encodePacked("OurDEX ", tokenAContract.symbol(), "-", tokenBContract.symbol(), " LP")
        );
        string memory lpTokenSymbol = string(
            abi.encodePacked("OD-", tokenAContract.symbol(), "-", tokenBContract.symbol())
        );

        // Deploy LP token (Factory is initially the owner)
        LPToken lpToken = new LPToken(lpTokenName, lpTokenSymbol);

        // Deploy the Pair contract
        pair = address(new Pair(tokenA, tokenB, priceFeedA, priceFeedB, address(lpToken), ccipRouter));

        // Transfer LP token ownership to the Pair contract
        lpToken.transferOwnership(pair);

        // Register the pair in both directions
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);

        emit PairCreated(tokenA, tokenB, pair, address(lpToken), allPairs.length);

        return pair;
    }

    /**
     * @notice Get the total number of pairs created
     * @return length Total number of trading pairs
     */
    function allPairsLength() external view returns (uint256 length) {
        return allPairs.length;
    }
}
