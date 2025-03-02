// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract YulDeployer is Test {
    ///@notice Compiles a Yul contract and returns the address that the contract was deployed to
    ///@notice If deployment fails, an error will be thrown
    ///@param _fileName - The file name of the Yul contract. For example, the file name for "Example.yul" is "Example"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployContract(
        string memory _fileName,
        address owner
    ) public returns (address) {
        string memory bashCommand = string.concat(
            'cast abi-encode "f(bytes)" $(solc --strict-assembly yul/',
            string.concat(_fileName, ".yul --bin --optimize | tail -1)")
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;

        // wont work with yul
        // bytes memory bytecode = abi.encodePacked(
        //     abi.decode(vm.ffi(inputs), (bytes)),
        //     abi.encode(_admins, _totalSupply)
        // );

        bytes memory bytecode = abi.decode(vm.ffi(inputs), (bytes));

        vm.startPrank(owner);

        uint256 gasBefore = gasleft();
        ///@notice deploy the bytecode with the create instruction
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);

        vm.stopPrank();

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "YulDeployer could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
