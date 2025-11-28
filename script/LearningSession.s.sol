// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {LearningSession} from "../src/LearningSession.sol";

/// @title LearningSessionScript
/// @notice Simple deployment script for the DED Learning Session showcase contract.
contract LearningSessionScript is Script {
    function run() public {
        vm.startBroadcast();
        new LearningSession();
        vm.stopBroadcast();
    }
}
