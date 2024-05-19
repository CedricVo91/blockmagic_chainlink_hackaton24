// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleDEX {
    IERC20 public token1;
    IERC20 public token2;
    AggregatorV3Interface public priceFeed;

    uint256 public reserve1;
    uint256 public reserve2;

    constructor(address _token1, address _token2, address _priceFeed) {
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

    function swap(uint256 _amount1) external {
        require(reserve1 >= _amount1, "Not enough liquidity");

        uint256 amount2 = (_amount1 * uint256(getPrice())) / 1e8; // Adjust price feed precision
        require(reserve2 >= amount2, "Not enough liquidity");

        token1.transferFrom(msg.sender, address(this), _amount1);
        token2.transfer(msg.sender, amount2);

        reserve1 += _amount1;
        reserve2 -= amount2;
    }

    function removeLiquidity(uint256 _amount1, uint256 _amount2) external {
        require(reserve1 >= _amount1 && reserve2 >= _amount2, "Not enough liquidity");

        token1.transfer(msg.sender, _amount1);
        token2.transfer(msg.sender, _amount2);

        reserve1 -= _amount1;
        reserve2 -= _amount2;
    }
}
