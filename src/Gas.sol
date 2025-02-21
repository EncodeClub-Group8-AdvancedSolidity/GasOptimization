// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    address[5] public administrators;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        for (uint256 ii = 0; ii < 5; ii++) {
            address admin = _admins[ii];

            administrators[ii] = admin;
            if (admin == msg.sender) {
                balances[admin] = _totalSupply;
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool _admin) {
        for (uint256 ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                _admin = true;
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
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
        require(_tier < 255);
        unchecked {
            if (_tier < 4) {
                whitelist[_userAddrs] = _tier;
            } else {
                whitelist[_userAddrs] = 3;
            }
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = _amount;

        require(balances[senderOfTx] >= _amount && _amount > 3);
        unchecked {
            uint256 wh = whitelist[senderOfTx];
            uint256 d = _amount - wh;
            balances[senderOfTx] -= d;
            balances[_recipient] += d;
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
