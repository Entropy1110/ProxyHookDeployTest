// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "forge-std/Script.sol";

contract TestIfProxy is Script {
    address targetaddr = address(0xB3c2A6269c96fD4eA333408FB0349372Fa743ffF);

    function test_if_proxy(address _hook) public {
        targetaddr = _hook;
        //get slot 0 value of the proxy contract
        bytes32 slot0 = vm.load(targetaddr, 0);
        address couldBeImplementation = address(uint160(uint(slot0)));
        if (couldBeImplementation != address(0)) {
            bool isImplementation = couldBeImplementation.code.length > 0;
            require(!isImplementation, "Hook might be a proxy");
        }
    }
}