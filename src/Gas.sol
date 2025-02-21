// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    uint8 constant MAX = 255;
    uint8 constant LENGTH = 5;
    uint8 constant THREE = 3;
    address[LENGTH] public administrators;
    address private immutable owner;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed recipient);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        owner = msg.sender;
        for (uint256 ii = 0; ii < LENGTH; ii++) {
            administrators[ii] = _admins[ii];
        }
        balances[owner] = _totalSupply;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < LENGTH; ii++) {
            if (administrators[ii] == _user) {
                admin_ = true;
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool) {
        require(balances[msg.sender] >= _amount);
        require(bytes(_name).length < 9);
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyOwner {
        unchecked {
            require(_tier < MAX);
            if (_tier <= THREE) {
                whitelist[_userAddrs] = _tier;
            } else {
                whitelist[_userAddrs] = THREE;
            }
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        unchecked {
            require(balances[msg.sender] >= _amount && _amount > THREE);
            whiteListStruct[msg.sender] = _amount;
            uint256 d = _amount - whitelist[msg.sender];
            balances[msg.sender] -= d;
            balances[_recipient] += d;
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address _sender) public view returns (bool, uint256) {
        return (true, whiteListStruct[_sender]);
    }
}
