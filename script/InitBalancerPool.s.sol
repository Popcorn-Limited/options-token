pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {IVault, IAsset, JoinPoolRequest, IERC20} from "../src/interfaces/IVault.sol";

contract InitBalancerPool is Script {
    function run() public {
        address admin = vm.envAddress("OWNER");

        address pop = vm.envAddress("POPCORN_TOKEN");
        address weth = vm.envAddress("WETH");
        IVault vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(weth);
        assets[1] = IAsset(pop);

        uint256 wethAmount = 17387463607634310; // Adjust this based on token price and how many lpToken you want to receive
        uint256 popAmount = 1000000000000000000000; // Adjust this based on token price and how many lpToken you want to receive

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = wethAmount;
        maxAmountsIn[1] = popAmount;

        vm.startBroadcast(admin);

        IERC20(weth).approve(address(vault), wethAmount);
        IERC20(pop).approve(address(vault), popAmount);

        vault.joinPool(
            bytes32(
                0xd5a44704befd1cfcca67f7bc498a7654cc092959000200000000000000000609
            ),
            admin,
            admin,
            JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(0, maxAmountsIn), // first param is the enum for initializing a pool
                fromInternalBalance: false
            })
        );
        vm.stopBroadcast();
    }
}
