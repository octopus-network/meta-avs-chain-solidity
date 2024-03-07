# meta-avs-chain-solidity

This repository contains the Solidity smart contracts for the Meta AVS Chain(MAC) on Ethereum.

These contracts are modified based on the default implementation of the [eigenlayer-middileware](https://github.com/Layr-Labs/eigenlayer-middleware), by implementing a service manager and a MAC pubkey registry for operators.

## Use Cases

### Register Operator

![registor operator](/images/register_operator.png)

### Deregsiter Operator

![deregistor operator](/images/deregister_operator.png)

### Register Operator With Churn

The `registerOperatorWithChurn` function in the `RegistryCoordinator` contract allows any user to substitute an existing operator within quorums with a new one by providing a new address and MAC public key. This process involves verifying the signature of the churn approver as well as the signature of the operator to be replaced before implementing the modifications. The operational flow of `registerOperatorWithChurn` mirrors that of the `registerOperator` function, also part of the `RegistryCoordinator` contract, ensuring a consistent procedure for operator registration and replacement.

### Update Operators Stake View

Anyone can call the `updateOperators` function of the `RegistryCoordinator` contract to update the StakeRegistry's view of one or more operators' stakes. If any operator is found to be below the minimum stake for the quorum, they are deregistered.

### Update Operators Stake View in Quorums

Anyone can call the `updateOperatorsForQuorum` function of the `RegistryCoordinator` contract to update the StakeRegistry's view of ALL its registered operators' stakes for one or more quorums. Each quorum's `quorumUpdateBlockNumber` is also updated, which tracks the most recent block number when ALL registered operators were updated.

### Update Socket for an Operator

An operator can call the `updateSocket` function of the `RegistryCoordinator` contract to update their socket. This function is only accessible to registered operators.

### Slash Operator

![slash escalation](/images/slash_escalation.png)

## Owner Functions

### Create Quorum

The `createQuorum` function of the `RegistryCoordinator` contract allows the owner to create a new quorum. The owner can specify the minimum stake required for the quorum, the `OperatorSetParam` including the max number of operators allowed in the quorum, and the `StrategyParams` of `IStakeRegistry`.

### Set Operator Set Params

The `setOperatorSetParams` function of the `RegistryCoordinator` contract allows the owner to set the `OperatorSetParam` of a quorum.

### Set Churn Approver

The `setChurnApprover` function of the `RegistryCoordinator` contract allows the owner to set address of the churn approver.

### Set Ejector

The `setEjector` function of the `RegistryCoordinator` contract allows the owner to set address of the ejector.

## Ejector Functions

### Eject Operator

The `ejectOperator` function of the `RegistryCoordinator` contract allows the ejector to deregister an operator.

## Contracts Events

| Contract | Function | Event | Notes
|---|---|---|---
| RegistryCoordinator | registerOperator | OperatorRegistered(operator, operatorId) | If the operator is not registered or has been deregistered, the operator can be registered.
| | deregisterOperator | OperatorDeregistered(operator, operatorId) | -
| | setOperatorSetParams | OperatorSetParamsUpdated(quorumNumber, operatorSetParams) | -
| | setChurnApprover | ChurnApproverUpdated(churnApprover) | -
| | setEjector | EjectorUpdated(ejector) | -
| | updateOperatorsForQuorum | QuorumBlockNumberUpdated(quorumNumber, blocknumber) | -
| MACPubkeyRegistry | registerMACPubkey | NewPubkeyRegistration(operator, pubkeyInMAC, rawInitialSessionKeys) | The `rawInitialSessionKeys` will not saved in the contract storage.
| | registerOperator | OperatorAddedToQuorum(operator, quorumNumber) | -
| | deregisterOperator | OperatorRemovedFromQuorum(operator, quorumNumber) | -
| StakeRegistry | registerOperator | OperatorStakeUpdate(operatorId, quorumNumber, newStake) | -
| | deregisterOperator | OperatorStakeUpdate(operatorId, quorumNumber, newStake) | The `newStake` in the event is 0.
| IndexRegistry | registerOperator | QuorumIndexUpdate(operatorId, quorumNumber, operatorIndex) | -
| | deregisterOperator | QuorumIndexUpdate(operatorId, quorumNumber, operatorIndex) | The `operatorIndex` is the index of the removed operator in the quorum. And the `operatorId` is the last operator in the quorum.

## Contracts Deployment

* Deploy the `ProxyAdmin` contract (of the implementation in `openzeppelin` libraries) and get the `proxyAdmin` address.
* Deploy the `TransparentUpgradeableProxy` by empty contract address and `proxyAdmin` address. And get the proxy address of `RegistryCoordinator`.
* Deploy the `TransparentUpgradeableProxy` by empty contract address and `proxyAdmin` address. And get the proxy address of `MACPubkeyRegistry`.
* Deploy the `TransparentUpgradeableProxy` by empty contract address and `proxyAdmin` address. And get the proxy address of `StakeRegistry`.
* Deploy the `TransparentUpgradeableProxy` by empty contract address and `proxyAdmin` address. And get the proxy address of `IndexRegistry`.
* Deploy the `TransparentUpgradeableProxy` by empty contract address and `proxyAdmin` address. And get the proxy address of `MACServiceManager`.
* Deploy the `MACPubkeyRegistry` contract with the proxy address of `RegistryCoordinator`.
* Deploy the `StakeRegistry` contract with the proxy address of `RegistryCoordinator` and the proxy address of `DelegationManager` of `EigenLayer Core`.
* Deploy the `IndexRegistry` contract with the proxy address of `RegistryCoordinator`.
* Deploy the `MACServiceManager` contract with the proxy address of `RegistryCoordinator`, the proxy address of `StakeRegistry` and the proxy address of `AVSDirectory` of `EigenLayer Core`.
* Deploy the `RegistryCoordinator` contract with the the proxy address of `MACPubkeyRegistry`, the proxy address of `StakeRegistry`, the proxy address of `IndexRegistry`, and the proxy address of `MACServiceManager`.
* Upgrade the address of `MACPubkeyRegistry` by calling `upgrade` function of `proxyAdmin` with the new address of `MACPubkeyRegistry`.
* Upgrade the address of `StakeRegistry` by calling `upgrade` function of `proxyAdmin` with the new address of `StakeRegistry`.
* Upgrade the address of `IndexRegistry` by calling `upgrade` function of `proxyAdmin` with the new address of `IndexRegistry`.
* Upgrade the address of `MACServiceManager` by calling `upgrade` function of `proxyAdmin` with the new address of `MACServiceManager`.
* Upgrade the address of `RegistryCoordinator` by calling `upgrade` function of `proxyAdmin` with the new address of `RegistryCoordinator`. And call the `initialize` function of `RegistryCoordinator` in the new address.
