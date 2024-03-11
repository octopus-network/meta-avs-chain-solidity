// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {IMACPubkeyRegistry} from "../interfaces/IMACPubkeyRegistry.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {MACContractsDeployer} from "./MACContractsDeployer.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RegistryCoordinatorTest is MACContractsDeployer, ISignatureUtils {
    function setUp() public override {
        _deployEigenLayerContractsLocal();
        _deployMACContracts();
    }

    function testRegisterOperator() public {
        bytes memory quorumNumbers = hex"00";
        _cheats.deal(_defaultOperator, 100000000000000000000);
        _cheats.startPrank(_defaultOperator, _defaultOperator);
        IMACPubkeyRegistry.PubkeyRegistrationParams memory params = IMACPubkeyRegistry.PubkeyRegistrationParams({
            pubkeyInMAC: 0,
            rawInitialSessionKeys: new bytes[](0)
        });
        SignatureWithSaltAndExpiry memory operatorSignature = SignatureWithSaltAndExpiry({
            signature: new bytes(0),
            salt: _defaultSalt,
            expiry: 0
        });
        registryCoordinator.registerOperator(quorumNumbers, _defaultSocket, params, operatorSignature);
        _cheats.stopPrank();
    }
}
