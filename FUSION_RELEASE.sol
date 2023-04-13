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
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract FUSION_RELEASE is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for *;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using SafeERC20Upgradeable for ERC20BurnableUpgradeable;


    struct Investor {
        Order[] orderList;
        mapping(uint256 => uint256) orderCountForDay;
    }

    struct Order {
        uint256 amount;
        uint256 quantity;
        uint256 unlockTime;
        uint256 day;
        bool extracted;
        uint8 refundState;
    }

    struct RefundOrder {
        address addr;
        uint256 orderId;
        uint256 amount;
        uint256 state;
    }


    struct FusionSeq {
        uint256 price;
        uint256 balance;
    }

    event FusionEvent (
        address addr,
        uint256 amount,
        uint256 quantity,
        uint256 orderId,
        uint256 unlockTime,
        uint256 day,
        uint256 startSeq,
        uint256 endSeq,
        bool p
    );

    event RefundEvent (
        address addr,
        uint256 orderId,
        uint256 amount,
        uint256 quantity,
        uint256 gobackSeq
    );

    event RefundDoneEvent (
        address addr,
        uint256 orderId,
        uint256 amount
    );

    event ExecRefundEvent (
        uint256 day
    );

    event SaveFusionEvent (
        uint256 seq,
        uint256 price,
        uint256 balance
    );

    event addWhiteListEvent (
        address addr,
        uint256 quota
    );

    event removeWhiteListEvent (
        address addr
    );


    event FusionSeqBalanceChangeEvent(
        uint256 seq,
        uint256 balance
    );

    event FusionSeqDestoryEvent(
        uint256 seq,
        uint256 quantity
    );

    event StateChangeEvent (
        bool state
    );

    event CollectEvent (
        uint256 day,
        uint256 amount
    );

    event ClaimEvent (
        address addr,
        uint256 orderId,
        uint256 quantity
    );

    event ConfigChangeEvent (
        uint256 openStart,
        uint256 refundHour,
        uint256 lockTime,
        uint256 maxOrderCountForDay,
        uint256 priorityTime,
        uint256 orderAmountLimit,
        address collect
    );

    bool public _state;

    ERC20Upgradeable public _usdt;

    ERC20BurnableUpgradeable public _mom;

    uint256 public _uoffset;

    uint256 public _moffset;

    FusionSeq[] public _fusionList;

    mapping(address=>Investor) _investor;

    uint256 public _seq;

    mapping (uint256 => uint256) public _incomeForDay;

    mapping (address => uint256) public _whitelist;

    mapping (uint256 => RefundOrder[]) public _refundList;

    uint256 public _openStart;

    uint256 public _lockTime;

    uint256 public _maxOrderCountForDay;

    uint256 public _orderAmountLimit;

    uint256 public _refundHour;

    uint256 public _priorityTime;

    address public _collect;

    address public _manager;

    constructor() {}

    function initialize() initializer public {
       __Ownable_init();
       __ReentrancyGuard_init();

        _lockTime = 3300;
        _maxOrderCountForDay = 5;
        _refundHour = 23;
    }

    function initData(
        ERC20Upgradeable usdt_,             
        ERC20BurnableUpgradeable mom_,               
        uint256 openStart_,          
        address collect_,
        address manager_
    ) public onlyOwner  {
        require(block.timestamp < openStart_,"open start time error");
        _collect = collect_;
        _manager = manager_;
        _usdt = usdt_;
        _mom = mom_;
        _openStart = openStart_;
        _uoffset = uint256(10) ** usdt_.decimals();
        _moffset = uint256(10) ** mom_.decimals();
        _seq = 0;
        _state = true;
         _orderAmountLimit = _uoffset.mul(20000);
        _priorityTime = 30 * 60;
    }

    function addFusionSeq(uint256[] calldata price_,uint256[] calldata balance_) external onlyOwner {
        require(price_.length <= 200, "The number cannot exceed 200 address");
        require(price_.length == balance_.length, "The array length of address and quota must be the same");
        for (uint i = 0; i < price_.length; i++) {
            require(price_[i] > 0 && balance_[i] > 0,"param is error");
            _fusionList.push(FusionSeq({
            price: price_[i],
            balance: balance_[i]
            }));
            emit SaveFusionEvent(_fusionList.length - 1, price_[i], balance_[i]);
        }
    }

    function modifyFusionSeq(uint256 seq_,uint256 price_,uint256 balance_) external onlyOwner {
        require(_fusionList.length > seq_,"index error");
        require(seq_ >= _seq,"seq is done");
        require(price_ > 0 && balance_ > 0,"param is error");
        _fusionList[seq_].price = price_;
        _fusionList[seq_].balance = balance_;
        emit SaveFusionEvent(seq_, price_, balance_);
    }

    function addWhitelist(address[] calldata addr_,uint256[] calldata quota_) external onlyOwner {
        require(addr_.length <= 200, "The number cannot exceed 200 address");
        require(addr_.length == quota_.length, "The array length of address and quota must be the same");
        for (uint i = 0; i < addr_.length; i++) {
            require(!addr_[i].isContract(),"can't be contract address");
            _whitelist[addr_[i]] = quota_[i];
            emit addWhiteListEvent(addr_[i],quota_[i]);
        }
    }

    function checkInvestorValidity(address[] calldata addr_) view public returns (uint8) {
        require(addr_.length <= 200,"address number to much");
        for (uint8 i = 0; i < addr_.length; i++) {
            if(addr_[i].isContract()){
                return i + 1;
            }
        }
        return 0;
    }

    function stopFusion() external {
        require(_msgSender() == _manager,"only manager call");
        _state = false;
        emit StateChangeEvent(false);
    }

    function startFusion() external {
        require(_msgSender() == _manager,"only manager call");
        _state = true;
        emit StateChangeEvent(true);
    }

    function changeConfig(uint256 lockTime_,uint256 maxOrderCount_,uint256 orderAmountLimit_,address collect_,address manager_) external onlyOwner {
        _lockTime = lockTime_;
        _maxOrderCountForDay = maxOrderCount_;
        _orderAmountLimit = orderAmountLimit_;
        _collect = collect_;
        _manager = manager_;
        emit ConfigChangeEvent(_openStart, _refundHour, _lockTime, _maxOrderCountForDay, _priorityTime, _orderAmountLimit, _collect);
    }

    function priorityFusion(uint256 amount_) private {
        require(_whitelist[_msgSender()] >= amount_,"The fusion credit has been used up");
        uint256 startSeq = _seq;
        uint256 getQuantity;
        uint256 useAmount;
        (useAmount,getQuantity) = doFusion(amount_);
        uint256 endSeq = _seq;
        uint256 day = getDayNumber();
        _whitelist[_msgSender()] = _whitelist[_msgSender()].sub(useAmount);
        emit FusionEvent(_msgSender(),useAmount,getQuantity,_investor[_msgSender()].orderList.length - 1,block.timestamp.add(_lockTime),day,startSeq,endSeq,true);
    }

    function publicFusion(uint256 amount_) private {
        uint256 day = getDayNumber();
        uint256 dayOrderCount = _investor[_msgSender()].orderCountForDay[day];
        require(dayOrderCount < _maxOrderCountForDay,"Exceeded today's order limit");
        uint256 startSeq = _seq;
        uint256 getQuantity;
        uint256 useAmount;
        (useAmount,getQuantity) = doFusion(amount_);
        uint256 endSeq = _seq;
        _investor[_msgSender()].orderCountForDay[day] = dayOrderCount.add(1);
        emit FusionEvent(_msgSender(),useAmount,getQuantity,_investor[_msgSender()].orderList.length - 1,block.timestamp.add(_lockTime),day,startSeq,endSeq,false);
    }

    function doFusion(uint256 amount_) private returns (uint256 useAmount_,uint256 getQuantity_){
        require(amount_ > 0,"The purchase quantity must be greater than 0");
        (useAmount_,getQuantity_) = calcFusion(_msgSender(), amount_);
        require(getQuantity_ > 0,"Can't get mom");
        require(useAmount_ > 0,"no send usdt");
        require(_mom.balanceOf(address(this)) >= getQuantity_,"Insufficient balance of fusion contract");
        uint256 amount;
        uint256 quantity = getQuantity_;
        uint256 seq = _seq;
        while(quantity > 0) {
            uint256 balance = _fusionList[seq].balance;
            uint256 price = _fusionList[seq].price;
            if(balance > quantity){
                amount = amount.add(quantity.mul(price).div(_moffset));
                _fusionList[seq].balance = _fusionList[seq].balance.sub(quantity);
                emit FusionSeqBalanceChangeEvent(seq, _fusionList[seq].balance);
                break;
            }
            if(balance == quantity){
                amount = amount.add(quantity.mul(price).div(_moffset));
                _fusionList[seq].balance = 0;
                emit FusionSeqBalanceChangeEvent(seq, 0);
                seq = seq.add(1);
                break;
            }
            if(balance < quantity) {
                // require(_fusionList.length > seq + 1,"beyond the quota");
                amount = amount.add(balance.mul(price).div(_moffset));
                quantity = quantity.sub(balance);
                _fusionList[seq].balance = 0;
                emit FusionSeqBalanceChangeEvent(seq, 0);
                seq = seq.add(1);
            }
        }
        _seq = seq;
        uint256 orderDay = getDayNumber();
        _investor[_msgSender()].orderList.push(Order({
            amount : amount,
            quantity : getQuantity_,
            unlockTime: block.timestamp.add(_lockTime),
            day: orderDay,
            extracted: false,
            refundState: 0
        }));
        _usdt.safeTransferFrom(_msgSender(), _collect, amount);
    }


    function fusion(uint256 amount_) external nonReentrant {
        require(!_msgSender().isContract(),"Contract address calls are not supported");
        require(amount_ <= _orderAmountLimit, "Exceed the single order limit");
        require(_fusionList[_seq].price > 0,"seq is error");
        require(!canRefund(),"Fusion service is not open during the refund period");
        require(_state,"Fusion service is not open");
        require(_usdt.balanceOf(_msgSender()) >= amount_,"The USDT balance of the address is insufficient");
        uint256 allowance = _usdt.allowance(_msgSender(),address(this));
        require(allowance >= amount_, "Insufficient USDT allowance");
        uint256 nowTime = block.timestamp;
        if(nowTime > _openStart){
            publicFusion(amount_);
            return ;
        }
        if(nowTime > _openStart - _priorityTime){
            priorityFusion(amount_);
            return ;
        }
        require(nowTime > _openStart, "Fusion services have yet to begin");
    }

    function refund(uint256 orderId_) external nonReentrant {
        require(_state,"Fusion service is not open");
        require(canRefund(),"The refund service is not open");
        require(_investor[_msgSender()].orderList[orderId_].extracted,"The order must claim the fetch operation");
        
        uint256 orderDay = _investor[_msgSender()].orderList[orderId_].day;
        require(getDayNumber() == orderDay,"Same-day orders are only refundable");

        uint256 quantity = _investor[_msgSender()].orderList[orderId_].quantity;
        uint256 momBalance = _mom.balanceOf(_msgSender());
        require(momBalance >= quantity,"Insufficient MOM balance");
        
        uint256 allowance = _mom.allowance(_msgSender(),address(this));
        require(allowance >= quantity, "Insufficient MOM allowance");
        
        require(_investor[_msgSender()].orderList[orderId_].refundState == 0, "Order is refunded");

        uint256 amount = _investor[_msgSender()].orderList[orderId_].amount;
        _investor[_msgSender()].orderList[orderId_].quantity = 0;
        _investor[_msgSender()].orderList[orderId_].amount = 0;
        _investor[_msgSender()].orderList[orderId_].refundState = 1;
        _refundList[orderDay].push(RefundOrder({
            addr: _msgSender(),
            orderId: orderId_,
            amount: amount,
            state: 0
        }));
        if(_fusionList.length == _seq){
            _seq = _seq - 1;
        }
        emit RefundEvent(_msgSender(), orderId_, amount, quantity,_seq);
        _fusionList[_seq].balance = _fusionList[_seq].balance.add(quantity);
        emit SaveFusionEvent(_seq, _fusionList[_seq].price, _fusionList[_seq].balance);
        _mom.safeTransferFrom(_msgSender(), address(this), quantity);
    }

    function execRefund(uint256 day_) external nonReentrant {
        if(_refundList[day_].length > 0){
            for(uint i=0;i<_refundList[day_].length;i++){
                uint256 fusionOrderId = _refundList[day_][i].orderId;
                address fusionAddr = _refundList[day_][i].addr;
                uint256 fusionAmount = _refundList[day_][i].amount;
                if(_refundList[day_][i].state == 0){
                    if(_investor[fusionAddr].orderList[fusionOrderId].refundState != 1){
                        continue;
                    }
                    _investor[fusionAddr].orderList[fusionOrderId].refundState = 2;
                    _refundList[day_][i].state = 1;
                    emit RefundDoneEvent(fusionAddr,fusionOrderId,fusionAmount);
                    _usdt.safeTransferFrom(_msgSender(), fusionAddr, fusionAmount);
                }
            }
        }
        emit ExecRefundEvent(day_);
    }

    function getRefundOrderAmountTotal(uint256 day_) view public returns (uint256 total) {
         RefundOrder[] memory refundList = _refundList[day_];
         for(uint i=0;i<refundList.length;i++){
            RefundOrder memory refundOrder = refundList[i];
            if(refundOrder.state == 0){
                total = total.add(refundOrder.amount);
            }
        }
    }

    function claim(uint256 orderId_) external nonReentrant {
        require(_state,"Fusion service is not open");

        address owner = _msgSender();
        require(orderId_ < _investor[owner].orderList.length,"orderId is error");

        uint256 quantity = _investor[owner].orderList[orderId_].quantity;
        require(quantity > 0,"orderId is error");
        
        require(!_investor[owner].orderList[orderId_].extracted, "The order has been claim");
        require(_investor[owner].orderList[orderId_].unlockTime < block.timestamp, "The order has not been unlocked");
        
        _investor[owner].orderList[orderId_].extracted = true;
        emit ClaimEvent(owner,orderId_,quantity);
        uint256 balance = _mom.balanceOf(address(this));
        require(balance >= quantity,"Insufficient balance of fusion contract");
        _mom.safeTransfer(_msgSender(), quantity);
    }

    function canFusion(address addr_) view public returns (bool){
        if(canRefund()){
            return false;
        }
        if(!_state){
            return false;
        }
        if(_fusionList.length == 0){
            return false;
        }
        if(_fusionList.length == _seq){
            return false;
        }
        uint256 nowTime = block.timestamp;
        if(nowTime > _openStart){
            return true;
        }
        uint256 priorityStartTime = _openStart - _priorityTime;
        return _whitelist[addr_] > 0 && nowTime > priorityStartTime;
    }

    function orderCanRefund(address addr_,uint256 orderId_) view public returns (string memory) {
        if(orderId_ >= _investor[addr_].orderList.length){
            return "orderId is error";
        }
        Order memory order = _investor[addr_].orderList[orderId_];
        if(order.refundState != 0){
            return "Order is refunded";
        }
        if(!canRefund()){
            return "The refund service is not open";
        }
        if(!order.extracted){
            return "The order must claim the fetch operation";
        }
        uint256 orderDay = order.day;
        if(getDayNumber() != orderDay){
            return "Same-day orders are only refundable";
        }
        uint256 quantity = order.quantity;
        uint256 momBalance = _mom.balanceOf(addr_);
        if(momBalance < quantity){
            return "Insufficient MOM balance";
        }
        uint256 allowance = _mom.allowance(addr_,address(this));
        if(allowance < quantity){
            return "Insufficient MOM allowance";
        } 
        return "1";
    }

    function orderCanClaim(address addr_,uint256 orderId_) view public returns (string memory) {
        Order[] memory orderList = _investor[addr_].orderList;
        if(orderId_ >= _investor[addr_].orderList.length){
            return "orderId is error";
        }
        Order memory order = orderList[orderId_];
        if(order.extracted){
            return "The order has been claim";
        }
        if(order.unlockTime > block.timestamp){
            return "The order has not been unlocked";
        }
        if(order.quantity == 0){
            return "orderId is error";
        }
        return "1";
    }

    function canRefund() view public returns (bool) {
        return getUTCHour() == _refundHour;
    }

    function getState() view public returns (uint8) {
        uint256 nowTime = block.timestamp;
        if(nowTime < _openStart){
            return 0;
        }else {
            return 1;
        }
    }

    function getFusionBalance() view public returns (uint256 fusionBalance_,uint256 contractBalance_){
        contractBalance_ = _mom.balanceOf(address(this));
        fusionBalance_ = 0;
        for (uint i = 0; i < _fusionList.length; i++) {
            fusionBalance_ = _fusionList[i].balance.add(fusionBalance_);
        }
    }

    function calcFusion(address addr_,uint256 amount_) view public returns (uint256 amount,uint256 quantity) {
        if(canFusion(addr_) && _fusionList.length > _seq){
            uint256 seq = _seq;
            while(amount_ > 0) {
                uint256 balance = _fusionList[seq].balance;
                uint256 price = _fusionList[seq].price;
                uint256 quantity_ = amount_.mul(_moffset).div(price);
                if(balance > quantity_){
                    quantity = quantity.add(quantity_);
                    amount = amount.add(amount_);
                    amount_ = 0;
                    break;
                }
                if(balance == quantity_){
                    quantity = quantity.add(quantity_);
                    seq = seq.add(1);
                    amount = amount.add(amount_);
                    amount_ = 0;
                    break; 
                }
                if(balance < quantity_) {
                    quantity = quantity.add(balance);
                    uint256 useAmount = balance.mul(price).div(_moffset);
                    amount = amount.add(useAmount);
                    amount_ = amount_.sub(useAmount);
                    seq = seq.add(1);
                    if(seq == _fusionList.length){
                        break;
                    }
                }
            }
        }
    }

    function getDayNumber() view public returns (uint256) {
        return block.timestamp / (3600 * 24);
    }

    function getUTCHour() public view returns (uint256 hour) {
        uint256 daySec = block.timestamp % (3600 * 24);
        hour = daySec / 3600;
    }

    function getUserOrderCount(address addr_,uint256 day_) view public returns (uint256 dayOrderCount) {
        dayOrderCount = _investor[addr_].orderCountForDay[day_];
    }

    function getOrderInfo(address addr_,uint256 orderId_) view public returns (
        uint256 amount,
        uint256 quantity,
        uint256 unlockTime,
        uint256 day,
        bool extracted,
        uint256 refundState
        ) {
        Order memory order = _investor[addr_].orderList[orderId_];
            amount = order.amount;
            quantity = order.quantity;
            unlockTime = order.unlockTime;
            day = order.day;
            extracted = order.extracted;
            refundState = order.refundState;

    }

    function destroy(uint256[] calldata seqList_) external onlyOwner{
        uint256 amount;
        for (uint i = 0; i < seqList_.length; i++) {
            uint256 seq = seqList_[i];
            require(_fusionList.length > seq,"seq is error");
            amount = amount.add(_fusionList[seq].balance);
            if(_fusionList[seq].balance > 0){
                emit FusionSeqDestoryEvent(seq,_fusionList[seq].balance);
            }
            _fusionList[seq].balance = 0;
        }
        if(amount > 0){
            _mom.burn(amount);
        }
    }


}