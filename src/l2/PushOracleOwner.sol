pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IOracle} from "../interfaces/IOracle.sol";

interface IPushOracle is IOracle {
    function setPrice(uint _price) external;
}

contract PushOracleOwner is Owned {
    IPushOracle public oracle;

    address public keeper;

    event KeeperUpdated(address previous, address current);

    error NotKeeperNorOwner();

    constructor(address _oracle, address _owner) Owned(_owner) {
        oracle = IPushOracle(_oracle);
    }

    function setKeeper(address _keeper) external onlyOwner {
        emit KeeperUpdated(keeper, _keeper);
        keeper = _keeper;
    }

    function setPrice(uint _price) external onlyKeeperOrOwner {
        oracle.setPrice(_price);
    }

    modifier onlyKeeperOrOwner() {
        if (msg.sender != owner && msg.sender != keeper)
            revert NotKeeperNorOwner();
        _;
    }
}
