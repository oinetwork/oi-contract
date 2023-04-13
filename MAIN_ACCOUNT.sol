// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MOM_TOKEN} from "./MOM_TOKEN.sol";

contract MAIN_ACCOUNT is Ownable, ReentrancyGuard  {

    using SafeERC20 for MOM_TOKEN;
    using SafeMath for *;

    address public _convertAddr;

    uint256 public _startTime;

    uint256 public _cycle;

    uint256 public _quantity;

    uint256 public _nextTime;

    MOM_TOKEN public _currency;

    uint256 public _releaseTotal;

    uint256 public _releaseCount;

    uint256 public _attenuation;

    event ReleaseEvent (
        uint256 nextTime,
        uint256 quantity,
        address convertAddr,
        uint256 total,
        uint256 count
    );

    constructor(
        MOM_TOKEN currency_,
        address convertAddr_,
        uint256 startTime_,
        uint256 quantity_,
        uint256 cycle_,
        uint256 attenuation_
    ){
        _currency = currency_;
        _convertAddr = convertAddr_;
        _startTime = startTime_;
        _cycle = cycle_;
        _quantity = quantity_;
        _nextTime = startTime_;
        _attenuation = attenuation_;
    }

    function release() external nonReentrant{
        
        uint256 time = _nextTime;
        require(block.timestamp >= time,"no time");
        _nextTime = _nextTime.add(_cycle);

        _releaseTotal = _releaseTotal.add(_quantity);
        _releaseCount = _releaseCount.add(1);
        
        _currency.safeTransfer(_convertAddr, _quantity);
        emit ReleaseEvent(_nextTime, _quantity, _convertAddr,_releaseTotal,_releaseCount);

        uint256 attenuation = _quantity.div(_attenuation);
        _quantity = _quantity.sub(attenuation);
    }

    function destroy(uint256 amount) external onlyOwner{
        _currency.burn(amount);
    }

    function changeConfig(address convertAddr_) external onlyOwner {
        _convertAddr = convertAddr_;
    }

    function canRelease() view public returns (bool){
        return block.timestamp > _nextTime && _currency.balanceOf(address(this)) >= _quantity;
    }

}