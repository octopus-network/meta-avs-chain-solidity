// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {IRegistry} from "@eigenlayer-middleware/src/interfaces/IRegistry.sol";

/**
 * @title Minimal interface for a registry that keeps track of operator public keys in Meta AVS Chain across many quorums. Modified based on the implementation of `IBLSApkRegistry` in `eigenlayer-middleware` repo.
 * @author Octopus Network
 */
interface IMACPubkeyRegistry is IRegistry {
    /**
     * @notice Struct used when registering a new public key
     * @param pubkeyInMAC is the corresponding public key of the operator in MAC
     * @param rawInitialSessionKeys is the corresponding initial session key of the operator in MAC
     */     
    struct PubkeyRegistrationParams {
        bytes32 pubkeyInMAC;
        bytes[] rawInitialSessionKeys;
    }

    // EVENTS
    /// @notice Emitted when `operator` registers with the public key and initial session keys
    event NewPubkeyRegistration(address indexed operator, bytes32 pubkeyInMAC, bytes[] rawInitialSessionKeys);

    // @notice Emitted when a new operator pubkey is registered for a quorum
    event OperatorAddedToQuorums(
        address operator,
        bytes quorumNumbers
    );

    // @notice Emitted when an operator pubkey is removed from a quorum
    event OperatorRemovedFromQuorums(
        address operator,
        bytes quorumNumbers
    );

    /**
     * @notice Registers the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to register.
     * @param quorumNumbers The quorum numbers the operator is registering for.
     * @dev access restricted to the RegistryCoordinator
     */
    function registerOperator(address operator, bytes calldata quorumNumbers) external;

    /**
     * @notice Deregisters the `operator`'s pubkey for the specified `quorumNumbers`.
     * @param operator The address of the operator to deregister.
     * @param quorumNumbers The quorum numbers the operator is deregistering from.
     * @dev access restricted to the RegistryCoordinator
     */ 
    function deregisterOperator(address operator, bytes calldata quorumNumbers) external;
    
    /**
     * @notice mapping from operator address to pubkey hash.
     * Returns *zero* if the `operator` has never registered, and otherwise returns the hash of the public key of the operator.
     */
    function operatorToPubkeyHash(address operator) external view returns (bytes32);

    /**
     * @notice mapping from pubkey hash to operator address.
     * Returns *zero* if no operator has ever registered the public key corresponding to `pubkeyHash`,
     * and otherwise returns the (unique) registered operator who owns the BLS public key that is the preimage of `pubkeyHash`.
     */
    function pubkeyHashToOperator(bytes32 pubkeyHash) external view returns (address);

    /**
     * @notice Called by the RegistryCoordinator register an operator as the owner of a BLS public key.
     * @param operator is the operator for whom the key is being registered
     * @param params contains the G1 & G2 public keys of the operator, and a signature proving their ownership
     */
    function registerMACPubkey(
        address operator,
        PubkeyRegistrationParams calldata params
    ) external returns (bytes32 operatorId);

    /**
     * @notice Returns the pubkey and pubkey hash of an operator
     * @dev Reverts if the operator has not registered a valid pubkey
     */
    function getRegisteredPubkey(address operator) external view returns (bytes32, bytes32);

    /// @notice Returns the operator address for the given `pubkeyHash`
    function getOperatorFromPubkeyHash(bytes32 pubkeyHash) external view returns (address);

    /// @notice returns the ID used to identify the `operator` within this AVS.
    /// @dev Returns zero in the event that the `operator` has never registered for the AVS
    function getOperatorId(address operator) external view returns (bytes32);
}
