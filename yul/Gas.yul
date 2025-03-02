object "GasContract" {
    code {
        sstore(0, caller()) // Save owner to slot 0 on first call

        // Copy runtime code to memory for deployment
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        // Return the assembled contract
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Storage layout:
            // slot 0 - owner
            // slots 1-5 - administrators[5]
            // slot 6 - balances mapping
            // slot 7 - whitelist mapping
            // slot 8 - whiteListStruct mapping

            // Function dispatcher based on signature
            switch shr(0xe0, calldataload(0))
            
            // initialize(address[],uint256)
            case 0x60b5bb3f {
                // Check if caller is owner
                if iszero(eq(caller(), sload(0))) { revert(0, 0) } // Compare caller with owner
                // Get caller address for balances
                mstore(0, caller()) // Write sender address to memory at offset 0
                mstore(0x20, 6) // Write base slot for balances to memory at offset 0x20
                let balanceSlot := keccak256(0, 0x40) // Calculate slot for balances[msg.sender]
                sstore(balanceSlot, calldataload(0x24)) // Save _totalSupply to balances[msg.sender]

                // Calculate offset of administrators array in calldata
                let dataOffset := add(calldataload(4), 0x24) // Skip array length and start from first element
                
                // Loop to save 5 administrators
                for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                    let admin := calldataload(add(dataOffset, mul(i, 0x20))) // Load next address from calldata
                    sstore(add(1, i), admin) // Save administrator to slots 1-5
                }
            }
            
            // checkForAdmin(address) -> bool
            case 0xb52d15e2 {
                let user := calldataload(4) // Load _user argument from calldata
                let isAdmin := 0 // Initialize return value as false
                // Check all administrator slots
                for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                    let admin := sload(add(1, i)) // Load administrator address from storage
                    if eq(admin, user) { // Compare with requested address
                        isAdmin := 1 // Set flag if a match is found
                    }
                }
                mstore(0, isAdmin) // Write result to memory
                return(0, 0x20) // Return 32 bytes of result
            }
            
            // balanceOf(address) -> uint256
            case 0x70a08231 {
                mstore(0, calldataload(4)) // Write _user address to memory
                mstore(0x20, 6) // Write base slot for balances
                let requestedBalance := sload(keccak256(0, 0x40)) // Load balance from calculated slot
                mstore(0, requestedBalance) // Write balance to memory
                return(0, 0x20) // Return balance value
            }
            
            // transfer(address,uint256,string) -> bool
            case 0x56b8c724 {
                let sender := caller() // Get sender address
                let recipient := calldataload(4) // Get recipient address
                let amount := calldataload(0x24) // Get transfer amount

                // Check sender balance
                mstore(0, sender) // Write sender address
                mstore(0x20, 6) // Write base slot for balances
                let senderSlot := keccak256(0, 0x40) // Calculate sender slot
                let senderBalance := sload(senderSlot) // Load current balance
                if lt(senderBalance, amount) { revert(0, 0) } // Check sufficient funds

                // Update sender balance
                sstore(senderSlot, sub(senderBalance, amount)) // Subtract amount and save

                // Update recipient balance
                mstore(0, recipient) // Write recipient address
                let recipientSlot := keccak256(0, 0x40) // Calculate recipient slot
                let recipientBalance := sload(recipientSlot) // Load current balance
                sstore(recipientSlot, add(recipientBalance, amount)) // Add amount and save

                mstore(0, 1) // Write true as result
                return(0, 0x20) // Return success result
            }
            
            // addToWhitelist(address,uint256)
            case 0x214405fc {
                // Check onlyOwner
                if iszero(eq(caller(), sload(0))) { revert(0, 0) } // Compare caller with owner
                
                let user := calldataload(4) // Get user address
                let tier := calldataload(0x24) // Get tier
                if gt(tier, 254) { revert(0, 0) } // Check tier maximum value

                // Save to whitelist
                mstore(0, user) // Write user address
                mstore(0x20, 7) // Write base slot for whitelist
                let slot := keccak256(0, 0x40) // Calculate slot in mapping
                let value := tier // Set initial value
                if gt(tier, 3) { value := 3 } // Cap tier at maximum 3
                sstore(slot, value) // Save value to storage

                // Emit AddedToWhitelist event
                mstore(0, user) // Write userAddress to memory
                mstore(0x20, tier) // Write tier to memory
                log1(
                    0, // Start of data in memory
                    0x40, // Data length (64 bytes)
                    0x62c1e066774519db9fe35767c15fc33df2f016675b7cc0c330ed185f286a2d52 // Event selector
                )
            }
            
            // whiteTransfer(address,uint256)
            case 0xea28d320 {
                let sender := caller() // Get sender address
                let recipient := calldataload(4) // Get recipient address
                let amount := calldataload(0x24) // Get amount

                // Check sender balance
                mstore(0, sender) // Write sender address
                mstore(0x20, 6) // Write base slot for balances
                let senderSlot := keccak256(0, 0x40) // Calculate sender slot
                let senderBalance := sload(senderSlot) // Load balance
                if lt(senderBalance, amount) { revert(0, 0) } // Check sufficient funds

                // Save amount to whiteListStruct
                mstore(0x20, 8) // Write base slot for whiteListStruct
                let whiteListStructSlot := keccak256(0, 0x40) // Calculate slot
                sstore(whiteListStructSlot, amount) // Save amount

                // Get whitelist value
                mstore(0x20, 7) // Write base slot for whitelist
                let whitelistSlot := keccak256(0, 0x40) // Calculate slot
                let whitelistValue := sload(whitelistSlot) // Load whitelist value
                let val := sub(amount, whitelistValue) // Calculate final transfer amount

                // Update sender balance
                sstore(senderSlot, sub(senderBalance, val)) // Subtract amount

                // Update recipient balance
                mstore(0, recipient) // Write recipient address
                mstore(0x20, 6) // Write base slot for balances
                let recipientSlot := keccak256(0, 0x40) // Calculate recipient slot
                let recipientBalance := sload(recipientSlot) // Load current balance
                sstore(recipientSlot, add(recipientBalance, val)) // Add amount

                // Emit WhiteListTransfer event
                log2(
                    0, // Start of data
                    0, // Data length
                    0x98eaee7299e9cbfa56cf530fd3a0c6dfa0ccddf4f837b8f025651ad9594647b3, // Event selector
                    recipient // Indexed argument
                )
            }
            
            // getPaymentStatus(address) -> (bool,uint256)
            case 0x888b2284 {
                mstore(0, 1) // Write status=true
                mstore(0x20, calldataload(4)) // Write _sender address
                mstore(0x40, 8) // Write base slot for whiteListStruct
                let amount := sload(keccak256(0x20, 0x40)) // Load amount from whiteListStruct
                mstore(0x20, amount) // Write amount to memory
                return(0, 0x40) // Return both values
            }

            // administrators(uint256) -> (address)
            case 0xd89d1510 {
                mstore(0, sload(add(1, calldataload(4))))
                return(0, 0x20)
            }

            // balances(address)
            case 0x27e235e3 {
                mstore(0, calldataload(4)) // Write _user address to memory
                mstore(0x20, 6) // Write base slot for balances
                let requestedBalance := sload(keccak256(0, 0x40)) // Load balance from calculated slot
                mstore(0, requestedBalance) // Write balance to memory
                return(0, 0x20) // Return balance value
            }

            // whitelist(address)
            case 0x9b19251a {
                mstore(0, calldataload(4)) // Write _user address to memory
                mstore(0x20, 7) // Write base slot for whitelist
                let requestedBalance := sload(keccak256(0, 0x40)) // Load whitelist from calculated slot
                mstore(0, requestedBalance) // Write whitelist to memory
                return(0, 0x20) // Return whitelist value
            }
            
            // Handle unknown calls
            default {
                revert(0, 0) // Revert for unknown functions
            }
        }
    }
}