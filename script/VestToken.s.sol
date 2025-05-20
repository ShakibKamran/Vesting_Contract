//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import { VestingToken } from "../src/VestToken.sol";
import {  VestToken } from "../src/Token.sol";

contract DeployVestingToken is Script {
    function run() external {
        vm.startBroadcast();
      VestToken vestToken = new VestToken();
      VestingToken vestTokenContract = new VestingToken(address(vestToken));
      address vestingTokenAddress = address(vestTokenContract);
      address vestTokenAddress = address(vestToken);
      console.log("VestingToken deployed at:", vestingTokenAddress);            
        console.log("VestToken deployed at:", vestTokenAddress);
        vm.stopBroadcast();
    }
}