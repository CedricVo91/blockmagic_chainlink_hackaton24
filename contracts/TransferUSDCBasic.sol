// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TransferUSDCBasic
 * @notice Cross-chain USDC transfer using Chainlink CCIP
 * @dev Allows transferring USDC to other chains via CCIP protocol
 */
contract TransferUSDCBasic {
    using SafeERC20 for IERC20;

    // ============ Errors ============
    error NotEnoughBalanceForFees(uint256 currentBalance, uint256 calculatedFees);
    error NotEnoughBalanceUsdcForTransfer(uint256 currentBalance);
    error NothingToWithdraw();
    error InvalidAddress();

    // ============ State Variables ============
    address public owner;
    IRouterClient private immutable ccipRouter;
    IERC20 private immutable linkToken;
    IERC20 private immutable usdcToken;
    uint64 public immutable destinationChainSelector;

    // ============ Events ============
    event UsdcTransferred(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        uint256 amount,
        uint256 ccipFee
    );

    /**
     * @notice Constructor to initialize the contract with required addresses
     * @param _ccipRouterAddress Address of the CCIP router contract
     * @param _linkAddress Address of the LINK token
     * @param _usdcAddress Address of the USDC token
     * @param _destinationChainSelector Chain selector for the destination chain
     */
    constructor(
        address _ccipRouterAddress,
        address _linkAddress,
        address _usdcAddress,
        uint64 _destinationChainSelector
    ) {
        if (_ccipRouterAddress == address(0) || _linkAddress == address(0) || _usdcAddress == address(0)) {
            revert InvalidAddress();
        }

        owner = msg.sender;
        ccipRouter = IRouterClient(_ccipRouterAddress);
        linkToken = IERC20(_linkAddress);
        usdcToken = IERC20(_usdcAddress);
        destinationChainSelector = _destinationChainSelector;
    }

    /**
     * @notice Transfer USDC to the destination chain via CCIP
     * @dev Requires LINK tokens for fees and user approval for USDC
     * @param _receiver Address to receive USDC on the destination chain
     * @param _amount Amount of USDC to transfer
     * @return messageId Unique identifier for the CCIP message
     */
    function transferUsdcToSepolia(
        address _receiver,
        uint256 _amount
    )
        external
        returns (bytes32 messageId)
    {
        require(_receiver != address(0), "Invalid receiver");
        require(_amount > 0, "Invalid amount");

        // Prepare token transfer data
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(usdcToken),
            amount: _amount
        });

        // Build CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0}) // Gas will be paid on destination
            ),
            feeToken: address(linkToken)
        });

        // Calculate and validate CCIP fee
        uint256 ccipFee = ccipRouter.getFee(destinationChainSelector, message);
        uint256 linkBalance = linkToken.balanceOf(address(this));
        if (ccipFee > linkBalance) {
            revert NotEnoughBalanceForFees(linkBalance, ccipFee);
        }

        // Approve LINK for fee payment
        linkToken.approve(address(ccipRouter), ccipFee);

        // Transfer USDC from sender and approve router
        uint256 usdcBalance = usdcToken.balanceOf(msg.sender);
        if (_amount > usdcBalance) {
            revert NotEnoughBalanceUsdcForTransfer(usdcBalance);
        }
        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(ccipRouter), _amount);

        // Send CCIP message
        messageId = ccipRouter.ccipSend(destinationChainSelector, message);

        emit UsdcTransferred(messageId, destinationChainSelector, _receiver, _amount, ccipFee);
    }

    /**
     * @notice Get the USDC allowance of the caller for this contract
     * @return usdcAmount Amount of USDC approved for transfer
     */
    function allowanceUsdc() public view returns (uint256 usdcAmount) {
        return usdcToken.allowance(msg.sender, address(this));
    }

    /**
     * @notice Get LINK and USDC balances of an account
     * @param account Address to check balances for
     * @return linkBalance LINK token balance
     * @return usdcBalance USDC token balance
     */
    function balancesOf(address account) public view returns (uint256 linkBalance, uint256 usdcBalance) {
        return (linkToken.balanceOf(account), usdcToken.balanceOf(account));
    }

    /**
     * @notice Restricts function access to contract owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @notice Withdraw any ERC20 token from the contract
     * @dev Only callable by the contract owner
     * @param _beneficiary Address to receive the withdrawn tokens
     * @param _token Address of the token to withdraw
     */
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_token != address(0), "Invalid token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }
}
