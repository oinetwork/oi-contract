// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOM_TOKEN is ERC20 {

    constructor() ERC20("MOM", "MOM") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(),amount);
    }

}
