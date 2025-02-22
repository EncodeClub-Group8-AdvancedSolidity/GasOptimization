// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    uint8 constant LENGTH = 5;
    uint8 constant THREE = 3;
    address private immutable owner;
    address[LENGTH] public administrators;

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
        balances[msg.sender] = _totalSupply;
        for (uint256 ii; ii < LENGTH; ++ii) {
            administrators[ii] = _admins[ii];
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        assembly {
            for {
                let i := 0
            } lt(i, 5) {
                i := add(i, 1)
            } {
                let admin := sload(add(administrators.slot, i))
                if eq(admin, _user) {
                    admin_ := 1
                }
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        assembly {
            mstore(0, _user)
            mstore(32, balances.slot)
            balance_ := sload(keccak256(0, 64))
        }
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
        assembly {
            if gt(_tier, 254) {
                revert(0, 0)
            }

            mstore(0, _userAddrs)
            mstore(32, whitelist.slot)
            let slot := keccak256(0, 64)

            let value := _tier
            if gt(_tier, 3) {
                value := 3
            }
            sstore(slot, value)
        }

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        unchecked {
            require(balances[msg.sender] >= _amount);
            whiteListStruct[msg.sender] = _amount;
            uint256 d = _amount - whitelist[msg.sender];
            balances[msg.sender] -= d;
            balances[_recipient] += d;
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address _sender
    ) public view returns (bool status_, uint256 amount_) {
        assembly {
            status_ := 1
            mstore(0, _sender)
            mstore(32, whiteListStruct.slot)
            amount_ := sload(keccak256(0, 64))
        }
    }
}
