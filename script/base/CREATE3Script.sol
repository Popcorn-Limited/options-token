// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

abstract contract CREATE3Script is Script {
    ICreateX internal constant createx = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    string internal version;

    constructor(string memory version_) {
        version = version_;
    }


    function getCreate3Contract(string memory name) internal view virtual returns (address) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        return createx.computeCreate3Address(getCreate3ContractSalt(name, deployer));
    }

    function getCreate3Contract(string memory name, string memory _version) internal view virtual returns (address) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        return createx.computeCreate3Address(getCreate3ContractSalt(name, _version, deployer));
    }

    function getCreate3ContractSalt(string memory name) internal view virtual returns (bytes32) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        return getCreate3ContractSalt(name, version, deployer);
    }

    function getCreate3ContractSalt(string memory name, address deployer) internal view virtual returns (bytes32) {
        return getCreate3ContractSalt(name, version, deployer);
    }


    function getCreate3ContractSalt(string memory name, string memory _version, address deployer)
        internal
        view
        virtual
        returns (bytes32)
    {
        bytes32 salt = bytes32(
            abi.encodePacked(
                deployer,
                hex"00",
                bytes11(keccak256(bytes(string.concat(name, "-v", _version))))
            )
        );

        bytes32 guardedSalt = keccak256(abi.encodePacked(uint256(uint160(deployer)), salt));
        return guardedSalt;
    }
}

interface ICreateX {
    function computeCreate3Address(bytes32 salt) external view returns (address);
    function computeCreate3Address(bytes32 salt, address deployer) external view returns (address);
    function deployCreate3(bytes32 salt, bytes memory initCode) external returns (address);
}
