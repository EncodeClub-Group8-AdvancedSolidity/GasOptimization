// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    address[5] public administrators;
    address public immutable owner;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        owner = msg.sender;
        for (uint256 ii = 0; ii < 5; ii++) {
            address admin = _admins[ii];

            administrators[ii] = admin;
        }
        balances[owner] = _totalSupply;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                admin_ = true;
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
    ) public returns (bool) {
        require(balances[msg.sender] >= _amount);
        require(bytes(_name).length < 9);
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }

        return true;
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyOwner {
        unchecked {
            require(_tier < 255);
            if (_tier < 4) {
                whitelist[_userAddrs] = _tier;
            } else {
                whitelist[_userAddrs] = 3;
            }
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        unchecked {
            address senderOfTx = msg.sender;
            require(balances[senderOfTx] >= _amount && _amount > 3);
            whiteListStruct[senderOfTx] = _amount;
            uint256 wh = whitelist[senderOfTx];
            uint256 d = _amount - wh;
            balances[senderOfTx] -= d;
            balances[_recipient] += d;
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool b_, uint256 status_) {
        b_ = true;
        status_ = whiteListStruct[sender];
    }
}
