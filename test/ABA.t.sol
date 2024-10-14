// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

// Forge imports
import "forge-std/console.sol";

// MyOApp imports
import {ABA} from "../../contracts/ABA.sol";
// import "@layerzerolabs/contracts/TestHelper.sol";
import {OptionsBuilder} from "@layerzerolabs/contracts/OptionsBuilder.sol";

// DevTools imports
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

/**
 * @title ABATest
 * @dev This contract is a test suite for ABA, which demonstrates simple message passing using LayerZero.
 */
contract ABATest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 private aEid = 1;
    uint32 private bEid = 2;

    ABA private aABA;
    ABA private bABA;

    uint16 public constant SEND = 1;
    uint16 public constant SEND_ABA = 2;

    /**
     * @dev Sets up the testing environment.
     * This includes setting up endpoints and deploying instances of ABA on different chains.
     */
    function setUp() public virtual override {
        super.setUp();

        // Set up two endpoints to simulate two different chains
        // The setUpEndpoints function is designed to initialize a specified number of mock endpoints.
        // This function allows for the creation of multiple endpoints, each potentially representing different blockchains or networks,
        // and configures them with a chosen library type (e.g., Ultra Light Node, Simple Message Lib).
        setUpEndpoints(
            2, //The number of endpoints to set up
            LibraryType.UltraLightNode //The type of library to use (Ultra Light Node or Simple Message Lib)
        );

        // Deploy instances of ABA on these chains
        // setupOApps automates the deployment and wiring of OApp instances. It enables developers to simulate multiple instances
        // of their OApps on different mock chains, providing a comprehensive testing landscape.
        address[] memory uas = setupOApps(
            type(ABA).creationCode, //Represents the bytecode (creation code) of the Omnichain Application (OApp) to be deployed
            1, //the starting mock Endpoint ID (Eid) for the OApps
            2 //the number of OApp instances to deploy
        );

        aEid = ABA(payable(uas[0]));
        bEid = ABA(payable(uas[1]));
    }

    /**
     * @dev Tests the basic message passing functionality from Chain A to Chain B using ABA.
     * It sends a message from aEid to bEid and checks if the message is received correctly.
     */
    function test_Send() public {
        string memory _dataBefore = bEid.data();
        string memory _message = "test message";
        bytes memory _payload = abi.encode(_message);

        const GAS_LIMIT = 1000000; // Gas limit for the executor
        const MSG_VALUE = 0; // msg.value for the lzReceive() function on destination in wei
        bytes memory _options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(GAS_LIMIT, MSG_VALUE);

        // Estimate fees for sending the message and send it
        MessagingFee memory _fee = aEid.quote(
            bEid,
            SEND, //msgType,
            _message,
            _extraSendOptions,
            _extraReturnOptions,
            false
        );

        MessagingReceipt memory receipt = aEid.send{value: _fee.nativeFee}(
            bEid,
            _message,
            _options
        );

        // Ensure the message at the destination is not changed before delivery
        assertEq(
            bEid.data(),
            _dataBefore,
            "shouldn't change message until lzReceive packet is delivered"
        );

        // Manually deliver the packet to the destination contract
        verifyPackets(bEid, addressToBytes32(address(bEid)));

        // Check if the message has been updated after packet delivery
        assertEq(bEid.data(), _message, "lzReceive data assertion failure");

        // Log the options used for debugging purposes
        console.logBytes(_options);
    }
}
