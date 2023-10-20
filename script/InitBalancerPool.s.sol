pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {IVault, IAsset, JoinPoolRequest, IERC20} from "../src/interfaces/IVault.sol";

contract InitBalancerPool is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        address pop = vm.envAddress("POPCORN_TOKEN");
        address weth = vm.envAddress("WETH");
        IVault vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(weth);
        assets[1] = IAsset(pop);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = 17387463607634310;
        maxAmountsIn[1] = 1000000000000000000000;

        vm.startBroadcast(deployerPrivateKey);

        IERC20(weth).approve(address(vault), 17387463607634310);
        IERC20(pop).approve(address(vault), 1000000000000000000000);

        vault.joinPool(
            bytes32(
                0xd5a44704befd1cfcca67f7bc498a7654cc092959000200000000000000000609
            ),
            admin,
            admin,
            JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(0, maxAmountsIn),
                fromInternalBalance: false
            })
        );
        vm.stopBroadcast();
    }
}
