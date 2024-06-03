// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract CCIPMessageSender {
    IRouterClient private s_router;
    LinkTokenInterface private s_linkToken;

    constructor(address _router, address _link) {
        s_router = IRouterClient(_router);
        s_linkToken = LinkTokenInterface(_link);
    }

    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        string calldata text
    ) external returns (bytes32 messageId) {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0); // Initialize an empty array

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(text),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(s_linkToken)
        });

        uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);
        require(fees <= s_linkToken.balanceOf(address(this)), "Not enough LINK balance");

        s_linkToken.approve(address(s_router), fees);
        messageId = s_router.ccipSend(destinationChainSelector, evm2AnyMessage);

        return messageId;
    }
}
