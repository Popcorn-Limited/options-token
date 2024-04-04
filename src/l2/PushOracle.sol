pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract PushOracle is IOracle, Owned {
    uint price;

    event PriceUpdate(uint oldPrice, uint newPrice);

    constructor(address _owner) Owned(_owner) {}

    function setPrice(uint _price) external onlyOwner {
        emit PriceUpdate(price, _price);
        price = _price;
    }

    function getPrice() external view returns (uint) {
        return price;
    }
}