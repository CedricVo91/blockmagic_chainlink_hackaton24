// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleDEX {
    IERC20 public token1;
    IERC20 public token2;
    AggregatorV3Interface public priceFeed;

    address public owner;
    uint256 public reserve1;
    uint256 public reserve2;

    constructor(address _token1, address _token2, address _priceFeed) {
        owner = msg.sender;
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function addLiquidity(uint256 _amount1, uint256 _amount2) external {
        token1.transferFrom(msg.sender, address(this), _amount1);
        token2.transferFrom(msg.sender, address(this), _amount2);
        reserve1 += _amount1;
        reserve2 += _amount2;
    }

    function getPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

// Add the Debug event
event Debug(string message, uint256 value1, uint256 value2);

function swap(uint256 _amount1) external {
    require(_amount1 > 0, "Amount1 must be greater than 0");
    require(reserve1 >= _amount1, "Not enough liquidity in reserve1");

    uint256 price = uint256(getPrice());
    require(price > 0, "Invalid price");

    uint256 amount2 = (_amount1 * price) / 1e8; // Adjust for price feed precision
    require(reserve2 >= amount2, "Not enough liquidity in reserve2");

    emit Debug("Before transferFrom for token1", _amount1, 0);
    require(token1.transferFrom(msg.sender, address(this), _amount1), "Transfer of token1 failed");

    emit Debug("Before transfer of token2", amount2, 0);
    require(token2.transfer(msg.sender, amount2), "Transfer of token2 failed");

    reserve1 += _amount1;
    reserve2 -= amount2;

    emit Debug("After swap", reserve1, reserve2);
}

    function removeLiquidity(uint256 _amount1, uint256 _amount2) external {
        require(reserve1 >= _amount1 && reserve2 >= _amount2, "Not enough liquidity");

        token1.transfer(msg.sender, _amount1);
        token2.transfer(msg.sender, _amount2);

        reserve1 -= _amount1;
        reserve2 -= _amount2;
    }
}