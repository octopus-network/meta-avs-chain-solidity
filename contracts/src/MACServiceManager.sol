// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import "@eigenlayer/src/contracts/libraries/BytesLib.sol";
import "@eigenlayer-middleware/src/ServiceManagerBase.sol";

/**
 * @title Primary entrypoint for procuring services from IncredibleSquaring.
 * @author Layr Labs, Inc.
 */
contract MACServiceManager is ServiceManagerBase {
    using BytesLib for bytes;

    constructor(
        IAVSDirectory _avsDirectory,
        IRegistryCoordinator _registryCoordinator,
        IStakeRegistry _stakeRegistry
    )
        ServiceManagerBase(
            _avsDirectory,
            _registryCoordinator,
            _stakeRegistry
        )
    {
    }

    /// @notice Called in the event of challenge resolution, in order to forward a call to the Slasher, which 'slash' the `operator`.
    /// @dev The Slasher contract is under active development and its interface expected to change.
    ///      We recommend writing slashing logic without integrating with the Slasher at this point in time.
    function slashOperator(
        address operatorAddr
    ) external onlyRegistryCoordinator() {
        // slasher.slashOperator(operatorAddr);
    }
}
