// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/utils/SafeERC20.sol";

contract TransferUSDCBasic {
    using SafeERC20 for IERC20;

    error NotEnoughBalanceForFees(uint256 currentBalance, uint256 calculatedFees);
    error NotEnoughBalanceUsdcForTransfer(uint256 currentBalance);
    error NothingToWithdraw();

    address public owner;
    IRouterClient private immutable ccipRouter;
    IERC20 private immutable linkToken;
    IERC20 private immutable usdcToken;

    address ccipRouterAddress = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address linkAddress = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address usdcAddress = 0x5425890298aed601595a70AB815c96711a31Bc65;
    uint64 destinationChainSelector = 16015286601757825753;

    event UsdcTransferred(
        bytes32 messageId,
        uint64 destinationChainSelector,
        address receiver,
        uint256 amount,
        uint256 ccipFee
    );

    constructor() {
        owner = msg.sender;
        ccipRouter = IRouterClient(ccipRouterAddress);
        linkToken = IERC20(linkAddress);
        usdcToken = IERC20(usdcAddress);
    }

    function transferUsdcToSepolia(
        address _receiver,
        uint256 _amount
    )
        external
        returns (bytes32 messageId)
    {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(usdcToken),
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: address(linkToken)
        });

        uint256 ccipFee = ccipRouter.getFee(
            destinationChainSelector,
            message
        );

        if (ccipFee > linkToken.balanceOf(address(this)))
            revert NotEnoughBalanceForFees(linkToken.balanceOf(address(this)), ccipFee);
        linkToken.approve(address(ccipRouter), ccipFee);

        if (_amount > usdcToken.balanceOf(msg.sender))
            revert NotEnoughBalanceUsdcForTransfer(usdcToken.balanceOf(msg.sender));
        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(ccipRouter), _amount);

        // Send CCIP Message
        messageId = ccipRouter.ccipSend(destinationChainSelector, message);

        emit UsdcTransferred(
            messageId,
            destinationChainSelector,
            _receiver,
            _amount,
            ccipFee
        );
    }

    function allowanceUsdc() public view returns (uint256 usdcAmount) {
        usdcAmount = usdcToken.allowance(msg.sender, address(this));
    }

    function balancesOf(address account) public view returns (uint256 linkBalance, uint256 usdcBalance) {
        linkBalance =  linkToken.balanceOf(account);
        usdcBalance = usdcToken.balanceOf(account);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).transfer(_beneficiary, amount);
    }
}
