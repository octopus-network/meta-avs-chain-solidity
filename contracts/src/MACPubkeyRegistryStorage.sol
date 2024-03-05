// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {IMACPubkeyRegistry} from "./interfaces/IMACPubkeyRegistry.sol";
import {IRegistryCoordinator} from "./interfaces/IRegistryCoordinator.sol";

import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

abstract contract MACPubkeyRegistryStorage is Initializable, IMACPubkeyRegistry {
    /// @notice the hash of the zero pubkey aka BN254.G1Point(0,0)
    bytes32 internal constant ZERO_PK_HASH = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";

    /// @notice the registry coordinator contract
    address public immutable registryCoordinator;

    // storage for individual pubkeys
    /// @notice maps operator address to pubkey hash
    mapping(address => bytes32) public operatorToPubkeyHash;
    /// @notice maps pubkey hash to operator address
    mapping(bytes32 => address) public pubkeyHashToOperator;
    /// @notice maps operator address to pubkey in MAC
    mapping(address => bytes32) public operatorToPubkey;

    constructor(IRegistryCoordinator _registryCoordinator) {
        registryCoordinator = address(_registryCoordinator);
        // disable initializers so that the implementation contract cannot be initialized
        _disableInitializers();
    }

    // storage gap for upgradeability
    uint256[45] private __GAP;
}
