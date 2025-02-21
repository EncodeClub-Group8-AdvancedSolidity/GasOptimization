// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    bool public tradeFlag = true; //slot1 1
    bool public dividendFlag = true; //slot1 2
    address public immutable owner; //slot1 22
    uint8 private constant length = 5; //slot1 30

    uint256 public totalSupply; //slot2

    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    address[5] public administrators;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    error OnlyAdminOrOwner();

    modifier onlyAdminOrOwner() {
        if (msg.sender != owner) revert OnlyAdminOrOwner();
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        owner = msg.sender;
        unchecked {
            for (uint8 ii = 0; ii < length; ii++) {
                administrators[ii] = _admins[ii];
            }
            balances[msg.sender] = _totalSupply;
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        unchecked {
            for (uint256 ii = 0; ii < length; ii++) {
                if (administrators[ii] == _user) {
                    return true;
                }
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
        return true;
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255);
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        require(_amount > 3);
        require(balances[msg.sender] >= _amount);
        uint256 change = whitelist[msg.sender];
        whiteListStruct[msg.sender] = _amount;
        unchecked {
            balances[_recipient] += _amount - change;
            balances[msg.sender] += change - _amount;
        }
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }
}
