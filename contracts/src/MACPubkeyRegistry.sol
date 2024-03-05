// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {MACPubkeyRegistryStorage} from "./MACPubkeyRegistryStorage.sol";

import {IRegistryCoordinator} from "./interfaces/IRegistryCoordinator.sol";

contract MACPubkeyRegistry is MACPubkeyRegistryStorage {
    /// @notice when applied to a function, only allows the RegistryCoordinator to call it
    modifier onlyRegistryCoordinator() {
        require(
            msg.sender == address(registryCoordinator),
            "MACPubkeyRegistry.onlyRegistryCoordinator: caller is not the registry coordinator"
        );
        _;
    }

    /// @notice Sets the (immutable) `registryCoordinator` address
    constructor(
        IRegistryCoordinator _registryCoordinator
    ) MACPubkeyRegistryStorage(_registryCoordinator) {}

    /*******************************************************************************
                      EXTERNAL FUNCTIONS - REGISTRY COORDINATOR
    *******************************************************************************/

    /**
     * @notice Registers the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to register.
     * @param quorumNumbers The quorum numbers the operator is registering for.
     * @dev access restricted to the RegistryCoordinator
     */
    function registerOperator(
        address operator,
        bytes calldata quorumNumbers
    ) public virtual onlyRegistryCoordinator {
        // Get the operator's pubkey. Reverts if they have not registered a key
        (bytes32 pubkey, ) = getRegisteredPubkey(operator);

        emit OperatorAddedToQuorums(operator, quorumNumbers);
    }

    /**
     * @notice Deregisters the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to deregister.
     * @param quorumNumbers The quorum numbers the operator is deregistering from.
     * @dev access restricted to the RegistryCoordinator
     */
    function deregisterOperator(
        address operator,
        bytes calldata quorumNumbers
    ) public virtual onlyRegistryCoordinator {
        // Get the operator's pubkey. Reverts if they have not registered a key
        (bytes32 pubkey, ) = getRegisteredPubkey(operator);

        emit OperatorRemovedFromQuorums(operator, quorumNumbers);
    }

    /**
     * @notice Called by the RegistryCoordinator register an operator as the owner of a public key in MAC.
     * @param operator is the operator for whom the key is being registered
     * @param params contains the public keys and initial session keys of the operator
     */
    function registerMACPubkey(
        address operator,
        PubkeyRegistrationParams calldata params
    ) external onlyRegistryCoordinator returns (bytes32 operatorId) {
        bytes32 pubkeyHash = keccak256(abi.encodePacked(params.pubkeyInMAC));
        require(
            pubkeyHash != ZERO_PK_HASH, "MACPubkeyRegistry.registerMACPubkey: cannot register zero pubkey"
        );
        require(
            operatorToPubkeyHash[operator] == bytes32(0),
            "MACPubkeyRegistry.registerMACPubkey: operator already registered pubkey"
        );
        require(
            pubkeyHashToOperator[pubkeyHash] == address(0),
            "MACPubkeyRegistry.registerMACPubkey: public key already registered"
        );

        operatorToPubkey[operator] = params.pubkeyInMAC;
        operatorToPubkeyHash[operator] = pubkeyHash;
        pubkeyHashToOperator[pubkeyHash] = operator;

        emit NewPubkeyRegistration(operator, params.pubkeyInMAC, params.rawInitialSessionKeys);
        return pubkeyHash;
    }

    /*******************************************************************************
                            VIEW FUNCTIONS
    *******************************************************************************/
    /**
     * @notice Returns the pubkey and pubkey hash of an operator
     * @dev Reverts if the operator has not registered a valid pubkey
     */
    function getRegisteredPubkey(address operator) public view returns (bytes32, bytes32) {
        bytes32 pubkey = operatorToPubkey[operator];
        bytes32 pubkeyHash = operatorToPubkeyHash[operator];

        require(
            pubkeyHash != bytes32(0),
            "MACPubkeyRegistry.getRegisteredPubkey: operator is not registered"
        );
        
        return (pubkey, pubkeyHash);
    }

    /// @notice Returns the operator address for the given `pubkeyHash`
    function getOperatorFromPubkeyHash(bytes32 pubkeyHash) public view returns (address) {
        return pubkeyHashToOperator[pubkeyHash];
    }

    /// @notice returns the ID used to identify the `operator` within this AVS
    /// @dev Returns zero in the event that the `operator` has never registered for the AVS
    function getOperatorId(address operator) public view returns (bytes32) {
        return operatorToPubkeyHash[operator];
    }
}
