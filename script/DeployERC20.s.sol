pragma solidity ^0.8.0;

import {TestToken} from "../src/ERC20.sol";

import {CREATE3Script} from "./base/CREATE3Script.sol";

contract DeployERC20Script is CREATE3Script {

    constructor() CREATE3Script(vm.envString("VERSION")) {}

    function run() public returns (address) {
        address admin = vm.envAddress("OWNER");
        vm.startBroadcast(admin);

        address result = create3.deploy(getCreate3ContractSalt("ERC20"), type(TestToken).creationCode);

        vm.stopBroadcast();
    
        return result;
    }
}