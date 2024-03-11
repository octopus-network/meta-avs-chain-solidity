// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {IMACPubkeyRegistry} from "../interfaces/IMACPubkeyRegistry.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {IDelegationManager} from "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import {MACContractsDeployer} from "./MACContractsDeployer.t.sol";
import {EIP1271SignatureUtils} from "@eigenlayer/src/contracts/libraries/EIP1271SignatureUtils.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "forge-std/Vm.sol";

contract RegistryCoordinatorTest is MACContractsDeployer, ISignatureUtils {
    // Dummy vals used across tests
    uint256 maxExpiry = type(uint256).max;

    function setUp() public override {
        _deployEigenLayerContractsLocal();
        _deployMACContracts();
    }

    function testRegisterOperator() public {
        bytes memory quorumNumbers = hex"00";
        VmSafe.Wallet memory wallet = _cheats.createWallet("operator-0");
        address operator = wallet.addr;
        uint256 operatorPrivateKey = wallet.privateKey;

        _cheats.deal(operator, 100000000000000000000);

        IDelegationManager.OperatorDetails
            memory operatorDetails = IDelegationManager.OperatorDetails({
                earningsReceiver: operator,
                delegationApprover: address(0),
                stakerOptOutWindowBlocks: 0
            });
        _testRegisterAsOperator(operator, operatorDetails);

        IMACPubkeyRegistry.PubkeyRegistrationParams
            memory params = IMACPubkeyRegistry.PubkeyRegistrationParams({
                pubkeyInMAC: 0,
                rawInitialSessionKeys: new bytes[](0)
            });
        SignatureWithSaltAndExpiry
            memory operatorSignature = _getOperatorSignature(
                operatorPrivateKey,
                operator,
                address(serviceManager),
                _defaultSalt,
                maxExpiry
            );
        _cheats.prank(operator, operator);
        registryCoordinator.registerOperator(
            quorumNumbers,
            _defaultSocket,
            params,
            operatorSignature
        );
    }

    /**
     * INTERNAL / HELPER FUNCTIONS
     */

    function _testRegisterAsOperator(
        address sender,
        IDelegationManager.OperatorDetails memory operatorDetails
    ) internal {
        _cheats.startPrank(sender);
        string memory emptyStringForMetadataURI;
        delegation.registerAsOperator(
            operatorDetails,
            emptyStringForMetadataURI
        );
        assertTrue(
            delegation.isOperator(sender),
            "testRegisterAsOperator: sender is not a operator"
        );

        assertTrue(
            keccak256(abi.encode(delegation.operatorDetails(sender))) ==
                keccak256(abi.encode(operatorDetails)),
            "_testRegisterAsOperator: operatorDetails not set appropriately"
        );

        assertTrue(
            delegation.isDelegated(sender),
            "_testRegisterAsOperator: sender not marked as actively delegated"
        );
        _cheats.stopPrank();
    }

    function _getOperatorSignature(
        uint256 _operatorPrivateKey,
        address operator,
        address avs,
        bytes32 salt,
        uint256 expiry
    )
        internal
        view
        returns (
            ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
        )
    {
        operatorSignature.expiry = expiry;
        operatorSignature.salt = salt;
        {
            bytes32 digestHash = avsDirectory
                .calculateOperatorAVSRegistrationDigestHash(
                    operator,
                    avs,
                    salt,
                    expiry
                );
            (uint8 v, bytes32 r, bytes32 s) = _cheats.sign(
                _operatorPrivateKey,
                digestHash
            );
            operatorSignature.signature = abi.encodePacked(r, s, v);
        }
        return operatorSignature;
    }
}
