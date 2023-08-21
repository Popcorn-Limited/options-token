pragma solidity ^0.8.0;

import {POP} from "../src/ERC20.sol";

import "forge-std/Script.sol";

// We're using a deprecated factory contract here.
// The oracle funtionality of 2 token pools were removed.
// V2 pools have the `getRate()` reentrancy issue.
interface Factory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory normalizedWeights,
        uint256 swapFeePercentage,
        bool oracleEnabled,
        address owner
    ) external returns (address);
}

contract DeployPOPScript is Script {

    function run() public returns (address) {
        address admin = vm.envAddress("OWNER");
        address pop = vm.envAddress("POPCORN_TOKEN");
        address weth = vm.envAddress("WETH");
        Factory factory = Factory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);
        uint[] memory weights = new uint[](2);
        weights[0] = 200000000000000000;
        weights[1] = 800000000000000000;
        address[] memory tokens = new address[](2);
        tokens[0] = weth;
        tokens[1] = pop;
        vm.startBroadcast(admin);
        address pool = factory.create(
            "Balancer 20 WETH 80 POP",
            "BAL-20WETH-80POP",
            tokens,
            weights,
            10000000000000000, // 1%
            true,
            admin
        );
        vm.stopBroadcast();
        return pool;
    }
}

