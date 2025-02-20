// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasContract {
    // Slot 1
    uint256 public totalSupply;
    // Slot 2 (packed)
    uint128 public paymentCounter; // 16 bytes
    uint8 public tradePercent = 12; // 1 byte
    bool public tradeFlag = true; // 1 byte
    bool public dividendFlag = true; // 1 byte
    // 13 bytes free

    // Slots 3-7 (array takes 5 slots)
    address[5] public administrators; // each address is 20 bytes

    // Slot 8-10 (mappings each take their own slot)
    mapping(address => uint256) public balances; // slot 8
    mapping(address => Payment[]) public payments; // slot 9
    mapping(address => uint256) public whitelist; // slot 10
    address public owner;

    // No slot (constant values are stored in code, not storage)
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    // No slot (constants don't use storage)
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }

    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        uint8 valueA;
        uint8 valueB;
        uint256 bigValue;
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        require(msg.sender == owner, "onlyAdminOrOwner");
        _;
    }

    //we can delete this
    modifier checkIfWhiteListed(address sender) {
        require(msg.sender == sender, "Sender mismatch");
        require(
            whitelist[msg.sender] > 0 && whitelist[msg.sender] < 4,
            "Invalid whitelist tier"
        );
        _;
    }

    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        owner = msg.sender;
        for (uint8 ii = 0; ii < 5; ii++) {
            administrators[ii] = _admins[ii];
        }
        balances[msg.sender] = _totalSupply;
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        if (administrators[0] == _user) return true;
        if (administrators[1] == _user) return true;
        if (administrators[2] == _user) return true;
        if (administrators[3] == _user) return true;
        if (administrators[4] == _user) return true;

        return false;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getTradingMode() public view returns (bool mode_) {
        if (tradeFlag == true || dividendFlag == true) {
            return true;
        }
        return false;
    }

    function addHistory(
        address _updateAddress,
        bool _tradeMode
    ) public returns (bool status_, bool tradeMode_) {
        paymentHistory.push(
            History({
                blockNumber: block.number,
                lastUpdate: block.timestamp,
                updatedBy: _updateAddress
            })
        );
        return (true, _tradeMode);
    }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        require(_user != address(0), "User must have a valid non zero address");
        return payments[_user];
    }

    error InsufficientBalance();
    error Test();

    function transfer(
    address _recipient,
    uint256 _amount,
    string calldata _name    
) public returns (bool) {    

    if (balances[msg.sender] < _amount) revert InsufficientBalance();
    if (bytes(_name).length >= 9) revert Test();

    unchecked {    // Safe because we checked balance above
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        paymentCounter++;    // Move increment out of struct creation
    }

    // Cache msg.sender to avoid multiple SLOAD
    address sender = msg.sender;
    
    
    payments[sender].push(Payment({
        paymentType: PaymentType.BasicPayment,
        paymentID: paymentCounter,
        adminUpdated: false,
        recipientName: _name,
        recipient: _recipient,
        admin: address(0),
        amount: _amount
    }));

    return true;    
}

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(
            _ID > 0,
            "Gas Contract - Update Payment function - ID must be greater than 0"
        );
        require(
            _amount > 0,
            "Gas Contract - Update Payment function - Amount must be greater than 0"
        );
        require(
            _user != address(0),
            "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
        );

        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(
            _tier < 255,
            "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
        );
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("Contract hacked, imposible, call help");
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(
            _amount,
            0,
            0,
            0,
            true,
            msg.sender
        );

        require(
            balances[senderOfTx] >= _amount,
            "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
