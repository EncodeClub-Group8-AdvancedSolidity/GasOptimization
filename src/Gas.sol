// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    address private immutable owner;
    address[5] public administrators;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed recipient);

    modifier onlyOwner() {
        address _owner = owner;
        assembly {
            if iszero(eq(caller(), _owner)) {
                revert(0, 0)
            }
        }
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        owner = msg.sender;
        assembly {
            mstore(0, caller())
            mstore(32, balances.slot)
            let balanceSlot := keccak256(0, 64)
            sstore(balanceSlot, _totalSupply)

            let adminsLength := mload(_admins)
            if gt(adminsLength, 5) {
                adminsLength := 5
            }
            let adminSlot := administrators.slot
            let dataOffset := add(_admins, 32)

            for {
                let i := 0
            } lt(i, adminsLength) {
                i := add(i, 1)
            } {
                let admin := mload(add(dataOffset, mul(i, 32)))
                sstore(add(adminSlot, i), admin)
            }
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
        string calldata
    ) public returns (bool) {
        assembly {
            mstore(0, caller())
            mstore(32, balances.slot)
            let senderSlot := keccak256(0, 64)

            let senderBalance := sload(senderSlot)
            if lt(senderBalance, _amount) {
                revert(0, 0)
            }

            let newSenderBalance := sub(senderBalance, _amount)
            sstore(senderSlot, newSenderBalance)

            mstore(0, _recipient)
            mstore(32, balances.slot)
            let recipientSlot := keccak256(0, 64)
            let recipientBalance := sload(recipientSlot)
            let newRecipientBalance := add(recipientBalance, _amount)
            sstore(recipientSlot, newRecipientBalance)

            mstore(0, 1)
            return(0, 32)
        }
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
        assembly {
            mstore(0, caller())
            mstore(32, balances.slot)
            let senderSlot := keccak256(0, 64)
            let senderBalance := sload(senderSlot)
            if lt(senderBalance, _amount) {
                revert(0, 0)
            }

            mstore(0, caller())
            mstore(32, whiteListStruct.slot)
            let whiteListStructSlot := keccak256(0, 64)
            sstore(whiteListStructSlot, _amount)

            mstore(0, caller())
            mstore(32, whitelist.slot)
            let whitelistSlot := keccak256(0, 64)
            let whitelistValue := sload(whitelistSlot)

            let d := sub(_amount, whitelistValue)

            let newSenderBalance := sub(senderBalance, d)
            sstore(senderSlot, newSenderBalance)

            mstore(0, _recipient)
            mstore(32, balances.slot)
            let recipientSlot := keccak256(0, 64)
            let recipientBalance := sload(recipientSlot)
            let newRecipientBalance := add(recipientBalance, d)
            sstore(recipientSlot, newRecipientBalance)
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
