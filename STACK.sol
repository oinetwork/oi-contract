// SPDX-License-Identifier: MIT

/**
*Submitted for verification at Etherscan.io on 2020-09-03
*/

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./NFT.sol";

contract STACK is  OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for *;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserStack {
        uint256 stackQuantity;
        uint256 quantityTotal;
        mapping(uint=>uint256) stackList;
        mapping(uint=>uint256) lockList;
    }

    event UserAddStackEvent (
        address addr,
        uint256 timeLimit,
        uint256 quantity
    );

    event UserSubStackEvent (
        address addr,
        uint256 timeLimit,
        uint256 quantity
    );

    event UserRedeemEvent (
        address addr,
        uint256 timeLimit,
        uint256 unlockTime,
        uint256 quantity
    );

    event UserPenaltyEvent (
        uint256 penaltyId
    );

    event UserExtractEvent (
        address addr,
        uint256 unlockTime,
        uint256 quantity
    );

    mapping (address=>UserStack) public _users;

    uint256[] public _quantityLevel;

    uint256[] public _timeLimits;

    mapping (uint8=>mapping(uint=>uint8)) public _nftLevel;

    mapping (uint256=>uint256) public _penaltyHistory;

    IERC20Upgradeable public _currency;

    uint _LOCK_TIME;

    address public _collect;

    address public _manager;

    address public _nftAddress;

    bool public _state;

    mapping (uint8=>uint32) public NFT_TOTAL_SUPPLY;

    constructor() {}

    function initialize() initializer public {
       __Ownable_init();
       __ReentrancyGuard_init();

    }

    function initData(
        IERC20Upgradeable currency_,
        address collect_,
        address manager_,
        address proxyRegistryAddress_
    ) public onlyOwner  {
        _state = true;
        _currency = currency_;
        _manager = manager_;
        _collect = collect_;
        _quantityLevel.push(500000000000000000000);
        _quantityLevel.push(2500000000000000000000);
        _quantityLevel.push(25000000000000000000000);
        _quantityLevel.push(125000000000000000000000);
        
        _nftLevel[1][604800] = 1;
        _nftLevel[1][1209600] = 2;
        _nftLevel[1][1814400] = 3;
        _nftLevel[1][2419200] = 4;
        _nftLevel[1][3024000] = 5;
        _nftLevel[1][3628800] = 6;
        _nftLevel[1][4233600] = 7;
        _nftLevel[1][4838400] = 8;
        _nftLevel[1][5443200] = 9;
        _nftLevel[1][7776000] = 10;
        //1000
        _nftLevel[2][604800] = 11;
        _nftLevel[2][1209600] = 12;
        _nftLevel[2][1814400] = 13;
        _nftLevel[2][2419200] = 14;
        _nftLevel[2][3024000] = 15;
        _nftLevel[2][3628800] = 16;
        _nftLevel[2][4233600] = 17;
        _nftLevel[2][4838400] = 18;
        _nftLevel[2][5443200] = 19;
        _nftLevel[2][7776000] = 20;

        //10000
        _nftLevel[3][604800] = 21;
        _nftLevel[3][1209600] = 22;
        _nftLevel[3][1814400] = 23;
        _nftLevel[3][2419200] = 24;
        _nftLevel[3][3024000] = 25;
        _nftLevel[3][3628800] = 26;
        _nftLevel[3][4233600] = 27;
        _nftLevel[3][4838400] = 28;
        _nftLevel[3][5443200] = 29;
        _nftLevel[3][7776000] = 30;

        //50000
        _nftLevel[4][604800] =  31;
        _nftLevel[4][1209600] = 32;
        _nftLevel[4][1814400] = 33;
        _nftLevel[4][2419200] = 34;
        _nftLevel[4][3024000] = 35;
        _nftLevel[4][3628800] = 36;
        _nftLevel[4][4233600] = 37;
        _nftLevel[4][4838400] = 38;
        _nftLevel[4][5443200] = 39;
        _nftLevel[4][7776000] = 40;

        NFT oiNFT = new NFT();
        oiNFT.setProxyRegistryAddress(proxyRegistryAddress_);
        _nftAddress = address(oiNFT);
        NFT_TOTAL_SUPPLY[1] = 20000;
        NFT_TOTAL_SUPPLY[2] = 15000;
        NFT_TOTAL_SUPPLY[3] = 10000;
        NFT_TOTAL_SUPPLY[4] = 5000;
        _LOCK_TIME = 86400; 
        _timeLimits.push(_LOCK_TIME);
        _timeLimits.push(604800);
        _timeLimits.push(1209600);
        _timeLimits.push(1814400);
        _timeLimits.push(2419200);
        _timeLimits.push(3024000);
        _timeLimits.push(3628800);
        _timeLimits.push(4233600);
        _timeLimits.push(4838400);
        _timeLimits.push(5443200);
        _timeLimits.push(7776000);
    }

    function setNFTProxyRegistryAddress(address proxyRegistryAddress_) public onlyOwner {
        NFT(_nftAddress).setProxyRegistryAddress(proxyRegistryAddress_);
    }

    function setNFTBaseUrl(string memory baseUrl_) public onlyOwner {
        NFT(_nftAddress).setBaseUrl(baseUrl_);
    }

    function changeNftLevel(uint8 level_,uint timeLimit_,uint8 nftLevel_) external onlyOwner {
        _nftLevel[level_][timeLimit_] = nftLevel_;
    }

    function changeQuantityLevel(uint8 level_,uint quantity_) external onlyOwner {
        if(level_ > _quantityLevel.length){
            _quantityLevel.push(quantity_);
        }else {
            _quantityLevel[level_] = quantity_;
        }
    }

    function addFlexibleStack(uint256 quantity_) external  nonReentrant {
        addStack(quantity_, _LOCK_TIME);
    }

    function addFixedStack(uint256 quantity_,uint timeLimit_) external nonReentrant {
        _addFixedStack(quantity_, timeLimit_,0);
    }

    function addFixedStackGetNft(uint256 quantity_,uint timeLimit_,uint8 stackLevel_) external  nonReentrant {
        _addFixedStack(quantity_, timeLimit_, stackLevel_);
    }

    function canMint(uint8 stackLevel_) public view returns (bool) {
        if (stackLevel_ >= 4) {
            return false;
        }
        NFT nft = NFT(_nftAddress);
        uint32 nftSupply = nft._nftTotalSupply(stackLevel_);
        return nftSupply < (NFT_TOTAL_SUPPLY[stackLevel_] - 1);
    }


    function _addFixedStack(uint256 quantity_,uint timeLimit_,uint8 stackLevel_) private {
        require(quantity_ >= _quantityLevel[0],"stack quantity to few");
        uint8 level = 0;
        for (uint8 i = 0;i<_quantityLevel.length;i++){
            if(quantity_ >= _quantityLevel[i]){
                level = i + 1;
            }
        }
        uint8 nftLevel = _nftLevel[level][timeLimit_];
        require(nftLevel > 0,"stack time limit error");
        addStack(quantity_, timeLimit_);
        if(stackLevel_ > 0){
            require(level >= stackLevel_, "quantity too little");
            require(canMint(stackLevel_),"nft no balance");
            NFT nft = NFT(_nftAddress);
            nft.mintTo(_msgSender(), stackLevel_, nftLevel);
        }
    }


    function addStack(uint256 quantity_,uint timeLimit_) private {
        require(_state,"Stack service is not open");
        require(quantity_ > 0, "stack quantity must is greater than 0");
        uint256 balance = _currency.balanceOf(_msgSender());
        require(balance >= quantity_, "no balance");
        uint256 allowance = _currency.allowance(_msgSender(),address(this));
        require(allowance >= quantity_, "Insufficient MOM allowance");
        uint256 nowQuantity = _users[_msgSender()].stackList[timeLimit_];
        _users[_msgSender()].stackList[timeLimit_] = quantity_.add(nowQuantity);

        _users[_msgSender()].quantityTotal = quantity_.add(_users[_msgSender()].quantityTotal);
        _users[_msgSender()].stackQuantity = quantity_.add(_users[_msgSender()].stackQuantity);

        _currency.safeTransferFrom(_msgSender(), address(this), quantity_);

        emit UserAddStackEvent(_msgSender(), timeLimit_, quantity_);
    }

    function redeem(uint timeLimit_,uint256 quantity_) external nonReentrant {
        require(_state,"Stack service is not open");
        require(timeLimit_ > 0);
        require(quantity_ > 0, "quantity must is greater than 0");
        require(_users[_msgSender()].stackList[timeLimit_] >= quantity_,"greater than balance");

        _users[_msgSender()].stackList[timeLimit_] = _users[_msgSender()].stackList[timeLimit_].sub(quantity_);
        _users[_msgSender()].stackQuantity = _users[_msgSender()].stackQuantity.sub(quantity_);

        uint unlockTime = block.timestamp.add(timeLimit_);
        _users[_msgSender()].lockList[unlockTime] = _users[_msgSender()].lockList[unlockTime].add(quantity_);
        emit UserRedeemEvent(_msgSender(), timeLimit_,unlockTime, quantity_);
    }

    function extract(uint[] calldata unlockTime_) external nonReentrant{
        require(_state,"Stack service is not open");
        require(unlockTime_.length <= 200 && unlockTime_.length > 0, "The number cannot exceed 200 item");
        require(repeatability(unlockTime_),"Unlock time duplicate");
        for(uint i=0;i<unlockTime_.length;i++){
            uint unlockTime = unlockTime_[i];
            require(unlockTime > 0);
            require(unlockTime < block.timestamp,"no time");
        }
        uint256 extractQuantity = 0;
        for(uint i=0;i<unlockTime_.length;i++){
            uint unlockTime = unlockTime_[i];
            uint256 quantity = _users[_msgSender()].lockList[unlockTime];
            require(quantity > 0,"Unlock time is error");
            extractQuantity = extractQuantity.add(quantity);
            _users[_msgSender()].lockList[unlockTime] = 0;
            emit UserExtractEvent(_msgSender(), unlockTime, quantity);
        }
        require(_users[_msgSender()].quantityTotal >= extractQuantity,"extract error");
        _users[_msgSender()].quantityTotal = _users[_msgSender()].quantityTotal.sub(extractQuantity);
        _currency.safeTransfer(_msgSender(), extractQuantity);
    }

    function repeatability(uint[] memory list) internal pure returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            uint time1 = list[i];
            for (uint j = i + 1; j < list.length; j++) {
                uint time2 = list[j];
                if (time1 == time2) {
                    return false;
                }
            }
        }
        return true;
    }

    function getStackQuantity(address addr_,uint expireTime_) view public returns (uint256) {
        return _users[addr_].stackList[expireTime_];
    }

    function getLockQuantity(address addr_,uint unlockTime_) view public returns (uint256) {
        return _users[addr_].lockList[unlockTime_];
    }


    function penalty(address[] memory addr_,uint256[] memory quantity_,uint256[] memory penaltyIds_) external nonReentrant  {
        require(_msgSender() == _manager,"only manager address call");
        require(addr_.length <= 200, "The number cannot exceed 200 item");
        require(addr_.length == quantity_.length, "The array length of address and quantity must be the same");
        require(addr_.length == penaltyIds_.length, "The array length of address and penaltyIds must be the same");
        uint256 quantityTotal = 0;
        for(uint i=0;i<addr_.length;i++){
            _penalty(addr_[i], quantity_[i], penaltyIds_[i]);
            quantityTotal = quantityTotal.add(quantity_[i]);
        }
        _currency.safeTransfer( _collect, quantityTotal);
    }

    function _penalty(address addr_,uint256 quantity_,uint256 penaltyId) private {
        uint256 quantityTemp = quantity_;
        require(_penaltyHistory[penaltyId] == 0,"repeat penalty ");
        require(_users[addr_].stackQuantity >= quantity_,"no balance");
        for(uint256 i=0;i<_timeLimits.length;i++){
            if(_users[addr_].stackList[_timeLimits[i]] >= quantityTemp){
                _users[addr_].stackList[_timeLimits[i]] = _users[addr_].stackList[_timeLimits[i]].sub(quantityTemp);
                emit UserSubStackEvent(addr_, _timeLimits[i], quantityTemp);
                quantityTemp = 0;
                break;
            }else {
                if(_users[addr_].stackList[_timeLimits[i]] > 0){
                    uint sub = _users[addr_].stackList[_timeLimits[i]];
                    _users[addr_].stackList[_timeLimits[i]] = 0;
                    quantityTemp = quantityTemp.sub(sub);
                    emit UserSubStackEvent(addr_, _timeLimits[i], sub);
                }
            }
        }
        require(quantityTemp==0,"Lack of stack balance");
        _users[addr_].stackQuantity = _users[addr_].stackQuantity.sub(quantity_);
        _users[addr_].quantityTotal = _users[addr_].quantityTotal.sub(quantity_);
        _penaltyHistory[penaltyId] = quantity_;
        emit UserPenaltyEvent(penaltyId);
    }

    function transferNftOwnership() public onlyOwner {
        NFT nft = NFT(_nftAddress);
        nft.transferOwnership(owner());
    }

    function changeConfig(address collect_,address manager_,bool state_) external onlyOwner  {
        require(collect_ != address(0), "Cannot be zero address");
        require(manager_ != address(0), "Cannot be zero address");
        _collect = collect_;
        _manager = manager_;
        _state = state_;
    }

    function changeNFTAddress(address nftAddress_) external onlyOwner {
        _nftAddress = nftAddress_;
    }

}