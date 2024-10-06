// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {Constants} from "v4-core/test/utils/Constants.sol";
// import {Deployers} from "v4-core/test/utils/Deployers.sol";

import {ProxyContract} from "../src/ProxyContract.sol";
import {Implementation} from "../src/Implementation.sol";
import {HookMiner} from "./HookMiner.sol";
import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Deploy is Script {

    event LogUint(uint256 value);
    event LogAddress(address addr);
    event LogStr(string str);
    
    using StateLibrary for IPoolManager;

    // Helpful test constants
    bytes constant ZERO_BYTES = Constants.ZERO_BYTES;
    uint160 constant SQRT_PRICE_1_1 = Constants.SQRT_PRICE_1_1;
    uint160 constant SQRT_PRICE_1_2 = Constants.SQRT_PRICE_1_2;
    uint160 constant SQRT_PRICE_2_1 = Constants.SQRT_PRICE_2_1;
    uint160 constant SQRT_PRICE_1_4 = Constants.SQRT_PRICE_1_4;
    uint160 constant SQRT_PRICE_4_1 = Constants.SQRT_PRICE_4_1;

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    uint256 tokenId;
    
    PoolId poolId;
    address token0;
    address token1;
    address proxyAddr;
    address hookAddr;
    Currency currency0;
    Currency currency1;
    IPoolManager manager;
    PoolKey key;
    address deployer = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    
    function run() public {
        vm.startBroadcast();
        
        token0 = address(new Token0());
        token1 = address(new Token1());

        if (address(token0) > address(token1)) {
            address temp = token0;
            token0 = token1;
            token1 = temp;
        }
        

        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        manager = IPoolManager(0x39BF2eFF94201cfAA471932655404F63315147a4);
        

        bytes memory implBytecode = type(Implementation).creationCode;
        (address addr, uint hookSalt) = HookMiner.find(address(deployer), Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG , implBytecode, new bytes(0));
        addr = address(new Implementation{salt: bytes32(hookSalt)}());
        hookAddr = payable(addr);

        console.log("hookAddr : ", hookAddr);

        bytes memory mockBytecode = type(ProxyContract).creationCode;
        (address addr2, uint mockSalt) = HookMiner.find(address(deployer),Hooks.ALL_HOOK_MASK,  mockBytecode, new bytes(0));
        console.logAddress(addr2);
        addr2 = address(new ProxyContract{salt: bytes32(mockSalt)}());
        proxyAddr = payable(addr2);

        console.log("proxyAddr : ", proxyAddr);

        ProxyContract(payable(proxyAddr)).setImplementation(hookAddr);


        key = PoolKey(currency0, currency1, 0, 60, IHooks(proxyAddr));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

    }

}



contract Token0 is ERC20 {
    constructor () ERC20("Token0", "TK0") {
        _mint(tx.origin, 1000000 * (10 ** uint(decimals())));
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

}

contract Token1 is ERC20 {
    constructor () ERC20 ("Token1", "TK1") {
        _mint(tx.origin, 1000000 * (10 ** uint(decimals())));
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}