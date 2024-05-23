pragma solidity ^0.8.13;

contract MockBridge {
    function bridgeMessage(
        uint32,
        address,
        bool,
        bytes calldata
    ) external pure {
        return;
    }
}