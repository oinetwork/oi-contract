// SPDX-License-Identifier: MIT

/**
*Submitted for verification at Etherscan.io on 2020-09-03
*/

pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MOM_TOKEN} from "./MOM_TOKEN.sol";

contract TASK is ReentrancyGuard {

    using Address for address;
    using SafeERC20 for MOM_TOKEN;

    event CreateTaskEvent (
        address addr,
        uint256 taskId,
        uint256 amount
    );

    event BidTaskEvent (
        address addr,
        uint256 taskId,
        uint256 amount
    );

    MOM_TOKEN immutable currency;

    address immutable collect;

    mapping(uint256=>uint256) _tasks;

    constructor(
        MOM_TOKEN currency_,
        address collect_
    ) {
        require(collect_ != address(0), "Cannot be zero address");
        collect = collect_;
        currency = currency_;
    }


    function addTask(uint256 taskId_,uint256 amount_) external nonReentrant {
        require(taskId_ > 0, "task id must is greater than 0");
        require(amount_ > 0, "amount must is greater than 0");
        uint256 balance = currency.balanceOf(msg.sender);
        require(balance >= amount_, "no balance");
        uint256 allowance = currency.allowance(msg.sender,address(this));
        require(allowance >= amount_, "insufficient allowance");
        require(_tasks[taskId_] == 0, "repeat payment");
        _tasks[taskId_] = amount_;
        currency.safeTransferFrom(msg.sender, collect, amount_);

        emit CreateTaskEvent(msg.sender, taskId_, amount_);
    }


    function bidTask(uint256 taskId_,uint256 amount_) external nonReentrant {
        require(taskId_ > 0, "task id must is greater than 0");
        require(amount_ > 0, "amount must is greater than 0");
        uint256 balance = currency.balanceOf(msg.sender);
        require(balance >= amount_, "no balance");
         uint256 allowance = currency.allowance(msg.sender,address(this));
        require(allowance >= amount_, "insufficient allowance");
        require(_tasks[taskId_] > 0, "task nofound");
        _tasks[taskId_] = amount_ + _tasks[taskId_];
        currency.safeTransferFrom(msg.sender, collect, amount_);

        emit BidTaskEvent(msg.sender, taskId_, amount_);
    }
}