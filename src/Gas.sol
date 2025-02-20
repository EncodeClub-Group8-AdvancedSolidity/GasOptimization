// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Constants {
    bool public tradeFlag = true;
    bool public dividendFlag = true;
}

contract GasContract is Ownable, Constants {
    uint256 public immutable totalSupply; //slot1c 32
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    mapping(address => uint256) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(checkForAdmin(msg.sender) || msg.sender == owner(), "Caller not admin");
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        balances[msg.sender] = _totalSupply;
        unchecked {
            for (uint8 ii = 0; ii < 5; ii++) {
                administrators[ii] = _admins[ii];
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        unchecked {
            for (uint256 ii = 0; ii < 5; ii++) {
                if (administrators[ii] == _user) {
                    admin_ = true;
                    break;
                }
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyAdminOrOwner {
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

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }
}
