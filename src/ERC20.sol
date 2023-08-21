pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract POP is ERC20 {

    address owner;
    constructor() ERC20("Popcorn", "POP", 18) {
        owner = msg.sender;
    }

    function mint(address to, uint amount) external {
        require(msg.sender == owner);
        _mint(to, amount);
    }

    function burn(address from, uint amount) external {
        require(msg.sender == owner);
        _burn(from, amount);
    }
}