// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {CREATE3Script} from "../base/CREATE3Script.sol";

import {IOracle} from ".../../src/interfaces/IOracle.sol";
import {PushOracle} from "../../src/l2/PushOracle.sol";
import {Exercise} from "../../src/l2/Exercise.sol";

contract DeployScript is CREATE3Script {
    constructor() CREATE3Script(vm.envString("VERSION")) {}

    function run() public returns (address oracle, address exercise) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address admin = vm.envAddress("ADMIN");

        oracle = createx.deployCreate3(
            getCreate3ContractSalt("PushOracle"),
            bytes.concat(
                type(PushOracle).creationCode,
                abi.encode(admin)
            )
        );
        exercise = createx.deployCreate3(
            getCreate3ContractSalt("Exercise"),
            bytes.concat(
                type(Exercise).creationCode,
                abi.encode(
                    admin,
                    ERC20(vm.envAddress("EXERCISE_TOKEN")),
                    ERC20(vm.envAddress("PAYMENT_TOKEN")),
                    ERC20(vm.envAddress("UNDERLYING_TOKEN")),
                    oracle
                )
            )
        );

        vm.stopBroadcast();
    }
}
