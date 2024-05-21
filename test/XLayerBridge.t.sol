pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {TestERC20Mintable} from "./mocks/TestERC20Mintable.sol";
import {MockBridge} from "./mocks/MockBridge.sol";

import {XLayerBridge} from "../src/XLayerBridge.sol";

contract XLayerBridgeTest is Test {
    uint32 immutable destinationNetworkId = 3;
    MockBridge mockBridge;
    address counterBridge;
    XLayerBridge bridge;
    TestERC20Mintable erc20;

    address user;

    function setUp() public {
        user = makeAddr("user");
        mockBridge = new MockBridge();
        erc20 = new TestERC20Mintable();
    
        counterBridge = makeAddr("counterBridge");
        bridge = new XLayerBridge(
            address(mockBridge),
            address(erc20),
            destinationNetworkId,
            counterBridge
        );
    } 

    function test_shouldBurnTokensWhenBridging(uint amount) external {
        erc20.mint(user, amount);
        assertEq(erc20.balanceOf(user), amount, "didn't mint tokens to user");

        vm.prank(user);
        bridge.sendToOtherSide(amount, user);

        assertEq(erc20.balanceOf(user), 0, "didn't mint tokens to user");
    }

    function test_onMessageReceived_onlyCallableByBridge() external {
        vm.expectRevert("Unauthorized");
        bridge.onMessageReceived(counterBridge, 3, ""); 
    
    }

    function test_onMessageReceived_mintTokensToUser(uint amount) external {
        bytes memory data = abi.encode(user, amount);
        vm.prank(address(mockBridge));
        bridge.onMessageReceived(counterBridge, 3, data); 

        assertEq(erc20.balanceOf(user), amount, "didn't mint tokens to user");
    }

    function test_onMessageReceived_onlyAllowBridingFromDestNetwork() external {
        vm.startPrank(address(mockBridge));
        vm.expectRevert("Unauthorized");
        bridge.onMessageReceived(counterBridge, 1, ""); 
    }
}
