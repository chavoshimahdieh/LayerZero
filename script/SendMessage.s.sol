// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/MyOApp.sol";
import "../contracts/MockLZToken.sol";
import { console } from "forge-std/Script.sol";

contract SendMessage is Script {
    // Address of the deployed MyOApp contract on Amoy testnet
    address constant myOAppAddress = address(0xfB51ba95CeC5F8a389A36D538B7e20CA11291800);

    uint32 constant dstEid = 40217; // Destination endpoint ID for Holesky
    string constant message = "Hello from Amoy to Holesky!";
    bytes constant options = ""; // Empty options if not needed
    uint256 constant fee = 0.001 ether; // Example fee for LayerZero messaging
    address constant lzEndpoint = address(0x6EDCE65403992e310A62460808c4b910D972f10f); // LayerZero endpoint

    function run() external {
        // Start broadcast to send real transactions
        vm.startBroadcast();

        // Initialize the deployed MyOApp contract instance
        MyOApp myOApp = MyOApp(myOAppAddress);

        // Deploy a MockLZToken contract with required constructor arguments
        MockLZToken mockLZToken = new MockLZToken(
            "MockLZToken",
            "MLZ",
            lzEndpoint,
            msg.sender // Using deployer as delegate for simplicity
        );

        // mockLZToken.transfer(msg.sender, 1000 ether);

        // Execute the send function to initiate cross-chain messaging
        (bool success, bytes memory txHash) = address(myOApp).call{ value: fee }(
            abi.encodeWithSignature("send(uint32,string,bytes)", dstEid, message, options)
        );

        require(success, "Transaction failed!");
        // console.log("Transaction sent! Hash:", txHash);

        // End broadcast
        vm.stopBroadcast();
    }
}


// forge script script/SendMessage.s.sol:SendMessage --rpc-url $AMOY_RPC_URL --private-key $PRIVATE_KEY --broadcast