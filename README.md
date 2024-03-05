# meta-avs-chain-solidity

This repository contains the Solidity smart contracts for the Meta AVS Chain(MAC) on Ethereum.

These contracts are modified based on the default implementation of the [eigenlayer-middileware](https://github.com/Layr-Labs/eigenlayer-middleware), by implementing a service manager and a MAC pubkey registry for operators.

## Use Cases

### Register Operator

![registor operator](/images/register_operator.png)

### Deregsiter Operator

![deregistor operator](/images/deregister_operator.png)

### Slash Operator

![slash escalation](/images/slash_escalation.png)

## Contracts Events

| Contract | Function | Event | Notes
|---|---|---|---
| RegistryCoordinator | registerOperator | OperatorRegistered(operator, operatorId) | If the operator is not registered or has been deregistered, the operator can be registered.
| | deregisterOperator | OperatorDeregistered(operator, operatorId) | -
| MACPubkeyRegistry | registerOperator | OperatorAddedToQuorum(operator, quorumNumber) | -
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
