pragma solidity ^0.8.0;

import {TestToken} from "../src/ERC20.sol";
import {CREATE3Script} from "./base/CREATE3Script.sol";


contract DeployERC20Script is CREATE3Script {

    constructor() CREATE3Script(vm.envString("VERSION")) {}

    function run() public returns (address, address) {
        address admin = vm.envAddress("OWNER");
        vm.startBroadcast(admin);

        address weth = createx.deployCreate3(
            getCreate3ContractSalt("WETH"),
            bytes.concat(
                type(TestToken).creationCode,
                abi.encode("WETH Test Token", "WETH")
            )
        );
        address pop = createx.deployCreate3(
            getCreate3ContractSalt("POP"),
            bytes.concat(
                type(TestToken).creationCode,
                abi.encode("POP Test Token", "POP")
            )
        );
        vm.stopBroadcast();
    
        return (weth, pop);
    }
}