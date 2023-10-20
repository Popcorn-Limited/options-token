pragma solidity ^0.8.0;

interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;
}

interface IAsset {}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}
