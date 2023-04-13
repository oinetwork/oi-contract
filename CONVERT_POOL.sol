// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MOM_TOKEN} from "./MOM_TOKEN.sol";

contract CONVERT_POOL is Ownable, ReentrancyGuard  {

    using Address for address;
    using SafeERC20 for MOM_TOKEN;
    using SafeMath for *;

    event UserConvertEvent (
        uint256 convertId,
        address addr,
        uint256 quantity
    );

    address public _coldAddr;

    address public _manager;

    MOM_TOKEN public _currency;

    uint256 public  _reserve;

    mapping (uint256=>uint256) public _convertHistory;

    constructor (
        MOM_TOKEN currency_,
        address coldAddr_,
        address manager_,
        uint256 reserve_
    ) {
        _currency = currency_;
        _coldAddr = coldAddr_;
        _manager = manager_;
        _reserve = reserve_;
    }

    function extract(uint256[] memory convertIds_,address[] memory addr_,uint256[] memory quantity_) external nonReentrant {
        require(_msgSender() == _manager,"only manager address call");
        require(addr_.length <= 200, "The number cannot exceed 200 item");
        require(addr_.length == quantity_.length, "The array length of address and quantity must be the same");
        require(addr_.length == convertIds_.length, "The array length of address and convertIds must be the same");
        for(uint i=0;i<addr_.length;i++){
            _extract(convertIds_[i],addr_[i], quantity_[i]);
        }
    }

    function _extract(uint256 convertId_,address target_,uint256 quantity_) private {
        require(quantity_ > 0,"quantity must is greater than 0 ");
        require(_convertHistory[convertId_] == 0,"repeat convert");
        _convertHistory[convertId_] = quantity_;
        _currency.safeTransfer(target_, quantity_);
        emit UserConvertEvent(convertId_,target_, quantity_);
    }

    function collection() external nonReentrant{
        uint256 contractBalance = _currency.balanceOf(address(this));
        require(contractBalance > _reserve,"no balance");
        _currency.safeTransfer(_coldAddr, contractBalance.sub(_reserve));
    }

    function needCollection() view public returns (bool){
        uint256 contractBalance = _currency.balanceOf(address(this));
        return contractBalance > _reserve;
    }

    function balance() view public returns (uint256) {
        return _currency.balanceOf(address(this));
    }

    function changeConfig(address coldAddr_,address manager_,uint256 reserve_) external onlyOwner  {
        require(coldAddr_ != address(0), "Cannot be zero address");
        require(manager_ != address(0), "Cannot be zero address");
        require(reserve_ > 0, "reserve must is greater than 0 ");
        _coldAddr = coldAddr_;
        _manager = manager_;
        _reserve = reserve_;
    }

}