pragma solidity ^0.8.0;

import {POP} from "../src/ERC20.sol";

import "forge-std/Script.sol";

contract DeployERC20Script is Script {

    function run() public returns (address) {
        address admin = vm.envAddress("OWNER");

        vm.startBroadcast(admin);

        POP pop = new POP();
        vm.stopBroadcast();
        return address(pop);
    }
}