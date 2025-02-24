// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    address private immutable owner;
    address[5] public administrators;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
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
            mstore(0x20, balances.slot)
            let balanceSlot := keccak256(0, 0x40)
            sstore(balanceSlot, _totalSupply)

            let dataOffset := add(_admins, 0x20)

            for {
                let i := 0
            } lt(i, 5) {
                i := add(i, 1)
            } {
                let admin := mload(add(dataOffset, mul(i, 0x20)))
                sstore(add(administrators.slot, i), admin)
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
            mstore(0x20, balances.slot)
            balance_ := sload(keccak256(0, 0x40))
        }
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata
    ) public returns (bool) {
        assembly {
            mstore(0, caller())
            mstore(0x20, balances.slot)
            let senderSlot := keccak256(0, 0x40)

            let senderBalance := sload(senderSlot)
            if lt(senderBalance, _amount) {
                revert(0, 0)
            }

            let newSenderBalance := sub(senderBalance, _amount)
            sstore(senderSlot, newSenderBalance)

            mstore(0, _recipient)
            mstore(0x20, balances.slot)
            let recipientSlot := keccak256(0, 0x40)
            let recipientBalance := sload(recipientSlot)
            let newRecipientBalance := add(recipientBalance, _amount)
            sstore(recipientSlot, newRecipientBalance)

            mstore(0, 1)
            return(0, 0x20)
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
            mstore(0x20, whitelist.slot)
            let slot := keccak256(0, 0x40)

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
            mstore(0x20, balances.slot)
            let senderSlot := keccak256(0, 0x40)
            let senderBalance := sload(senderSlot)
            if lt(senderBalance, _amount) {
                revert(0, 0)
            }

            mstore(0, caller())
            mstore(0x20, whiteListStruct.slot)
            let whiteListStructSlot := keccak256(0, 0x40)
            sstore(whiteListStructSlot, _amount)

            mstore(0, caller())
            mstore(0x20, whitelist.slot)
            let whitelistSlot := keccak256(0, 0x40)
            let whitelistValue := sload(whitelistSlot)

            let val := sub(_amount, whitelistValue)

            let newSenderBalance := sub(senderBalance, val)
            sstore(senderSlot, newSenderBalance)

            mstore(0, _recipient)
            mstore(0x20, balances.slot)
            let recipientSlot := keccak256(0, 0x40)
            let recipientBalance := sload(recipientSlot)
            let newRecipientBalance := add(recipientBalance, val)
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
            mstore(0x20, whiteListStruct.slot)
            amount_ := sload(keccak256(0, 0x40))
        }
    }
}
