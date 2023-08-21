pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract TestToken is ERC20 {

    address owner;
    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}