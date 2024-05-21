pragma solidity ^0.8.13;

import { IPolygonZkEVMBridgeV2 } from "./interfaces/IPolygonZkEVMBridgeV2.sol";
import { IXERC20 } from "./interfaces/IXERC20.sol";

contract XLayerBridge {
    IXERC20 immutable xVCX;
    IPolygonZkEVMBridgeV2 immutable bridge;
    uint32 immutable destinationNetworkId;
    // used to verify that the caller is the L2/L1 equivalent of this contract
    address immutable COUNTER_BRIDGE;

    event BridgeToOtherSide(address indexed from, address indexed to, uint amount);
    event ReceiveBridgedFunds(address indexed from, address indexed to, uint amount);

    constructor(
        address _bridge,
        address _xVCX,
        uint32 _destinationNetworkId,
        address _counterBridge
    ) {
        bridge = IPolygonZkEVMBridgeV2(_bridge);
        xVCX = IXERC20(_xVCX);
        destinationNetworkId = _destinationNetworkId;
        COUNTER_BRIDGE = _counterBridge;
    }

    /**
     * 
     * @param amount amount of xVCX that should be bridged
     * @param to the L2 address which will receive the bridged xVCX
     */
    function sendToOtherSide(uint amount, address to) external {
        xVCX.burn(msg.sender, amount);
        bridge.bridgeMessage(
            destinationNetworkId,
            to,
            true,
            abi.encode(to, amount)
        );

        emit BridgeToOtherSide(msg.sender, to, amount);
    }

    function onMessageReceived(address originAddress, uint32 originNetwork, bytes calldata metadata) external {
        if (msg.sender != address(bridge) || originAddress != COUNTER_BRIDGE || originNetwork != destinationNetworkId) {
            revert("Unauthorized");
        }
    
        (address to, uint amount) = abi.decode(metadata, (address, uint));
        xVCX.mint(to, amount);
        
        emit ReceiveBridgedFunds(originAddress, to, amount);
    }
}