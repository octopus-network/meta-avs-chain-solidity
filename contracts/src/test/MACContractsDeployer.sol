// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {AVSDirectory} from "@eigenlayer/src/contracts/core/AVSDirectory.sol";
import {Slasher} from "@eigenlayer/src/contracts/core/Slasher.sol";
import {ISlasher} from "@eigenlayer/src/contracts/interfaces/ISlasher.sol";
import {PauserRegistry} from "@eigenlayer/src/contracts/permissions/PauserRegistry.sol";
import {IStrategy} from "@eigenlayer/src/contracts/interfaces/IStrategy.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {BitmapUtils} from "@eigenlayer-middleware/src/libraries/BitmapUtils.sol";
import {BN254} from "@eigenlayer-middleware/src/libraries/BN254.sol";
import {EigenLayerDeployer} from "./EigenLayerDeployer.t.sol";

import {OperatorStateRetriever} from "@eigenlayer-middleware/src/OperatorStateRetriever.sol";
import {RegistryCoordinator} from "../RegistryCoordinator.sol";
import {RegistryCoordinatorHarness} from "./harnesses/RegistryCoordinatorHarness.t.sol";
import {MACPubkeyRegistry} from "../MACPubkeyRegistry.sol";
import {MACServiceManager} from "../MACServiceManager.sol";
import {StakeRegistry} from "../StakeRegistry.sol";
import {StakeRegistryHarness} from "./harnesses/StakeRegistryHarness.sol";
import {IndexRegistry} from "../IndexRegistry.sol";
import {IMACPubkeyRegistry} from "../interfaces/IMACPubkeyRegistry.sol";
import {IStakeRegistry} from "@eigenlayer-middleware/src/interfaces/IStakeRegistry.sol";
import {IIndexRegistry} from "@eigenlayer-middleware/src/interfaces/IIndexRegistry.sol";
import {IRegistryCoordinator} from "../interfaces/IRegistryCoordinator.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";

import "forge-std/Test.sol";

contract MACContractsDeployer is EigenLayerDeployer {
    using BN254 for BN254.G1Point;

    ProxyAdmin public proxyAdmin;

    AVSDirectory public avsDirectory;

    RegistryCoordinatorHarness public registryCoordinatorImplementation;
    StakeRegistryHarness public stakeRegistryImplementation;
    IMACPubkeyRegistry public macPubkeyRegistryImplementation;
    IIndexRegistry public indexRegistryImplementation;
    MACServiceManager public serviceManagerImplementation;

    OperatorStateRetriever public operatorStateRetriever;
    RegistryCoordinatorHarness public registryCoordinator;
    MACPubkeyRegistry public macPubkeyRegistry;
    StakeRegistryHarness public stakeRegistry;
    IIndexRegistry public indexRegistry;
    MACServiceManager public serviceManager;

    /// @notice StakeRegistry, Constant used as a divisor in calculating weights.
    uint256 public constant WEIGHTING_DIVISOR = 1e18;

    address public proxyAdminOwner = address(uint160(uint256(keccak256("proxyAdminOwner"))));
    address public registryCoordinatorOwner = address(uint160(uint256(keccak256("registryCoordinatorOwner"))));

    uint256 _churnApproverPrivateKey = uint256(keccak256("churnApproverPrivateKey"));
    address _churnApprover = _cheats.addr(_churnApproverPrivateKey);
    bytes32 _defaultSalt = bytes32(uint256(keccak256("defaultSalt")));

    address _ejector = address(uint160(uint256(keccak256("ejector"))));
    
    address _defaultOperator = address(uint160(uint256(keccak256("defaultOperator"))));
    bytes32 _defaultOperatorId;

    string _defaultSocket = "69.69.69.69:420";
    uint96 _defaultStake = 1 ether;
    uint8 _defaultQuorumNumber = 0;

    uint32 _defaultMaxOperatorCount = 10;
    uint16 _defaultKickBIPsOfOperatorStake = 15000;
    uint16 _defaultKickBIPsOfTotalStake = 150;
    uint8 _numQuorums = 192;

    IRegistryCoordinator.OperatorSetParam[] _operatorSetParams;

    uint8 _maxQuorumsToRegisterFor = 4;
    uint256 _maxOperatorsToRegister = 4;
    uint32 _registrationBlockNumber = 100;
    uint32 _blocksBetweenRegistrations = 10;

    IMACPubkeyRegistry.PubkeyRegistrationParams _pubkeyRegistrationParams;

    struct OperatorMetadata {
        uint256 quorumBitmap;
        address operator;
        bytes32 operatorId;
        BN254.G1Point pubkey;
        uint96[] stakes; // in every quorum for simplicity
    }

    uint256 _maxQuorumBitmap = type(uint192).max;

    function _deployMACContracts() internal {
        _deployMACContracts(_numQuorums);
    }

    function _deployMACContracts(uint8 numQuorumsToAdd) internal {
        _cheats.startPrank(proxyAdminOwner);
        proxyAdmin = new ProxyAdmin();

        avsDirectory = AVSDirectory(
            address(new TransparentUpgradeableProxy(address(emptyContract), address(proxyAdmin), ""))
        );
        AVSDirectory avsDirectoryImplemntation = new AVSDirectory(delegation);
        // AVSDirectory
        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(address(avsDirectory))),
            address(avsDirectoryImplemntation),
            abi.encodeWithSelector(
                AVSDirectory.initialize.selector,
                eigenLayerReputedMultisig, // initialOwner
                eigenLayerPauserReg,
                0 // initialPausedStatus
            )
        );

        _cheats.startPrank(registryCoordinatorOwner);
        registryCoordinator = RegistryCoordinatorHarness(address(
            new TransparentUpgradeableProxy(
                address(emptyContract),
                address(proxyAdmin),
                ""
            )
        ));

        stakeRegistry = StakeRegistryHarness(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );

        indexRegistry = IndexRegistry(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );

        macPubkeyRegistry = MACPubkeyRegistry(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );

        serviceManager = MACServiceManager(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );

        _cheats.stopPrank();

        _cheats.startPrank(proxyAdminOwner);

        stakeRegistryImplementation = new StakeRegistryHarness(
            IRegistryCoordinator(registryCoordinator),
            delegation
        );

        proxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(address(stakeRegistry))),
            address(stakeRegistryImplementation)
        );

        macPubkeyRegistryImplementation = new MACPubkeyRegistry(
            registryCoordinator
        );

        proxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(address(macPubkeyRegistry))),
            address(macPubkeyRegistryImplementation)
        );

        indexRegistryImplementation = new IndexRegistry(
            registryCoordinator
        );

        proxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(address(indexRegistry))),
            address(indexRegistryImplementation)
        );

        serviceManagerImplementation = new MACServiceManager(
            avsDirectory,
            registryCoordinator,
            stakeRegistry
        );

        proxyAdmin.upgrade(
            TransparentUpgradeableProxy(payable(address(serviceManager))),
            address(serviceManagerImplementation)
        );

        // setup the dummy minimum stake for quorum
        uint96[] memory minimumStakeForQuorum = new uint96[](numQuorumsToAdd);
        for (uint256 i = 0; i < minimumStakeForQuorum.length; i++) {
            minimumStakeForQuorum[i] = uint96(i+1);
        }

        // setup the dummy quorum strategies
        IStakeRegistry.StrategyParams[][] memory quorumStrategiesConsideredAndMultipliers =
            new IStakeRegistry.StrategyParams[][](numQuorumsToAdd);
        for (uint256 i = 0; i < quorumStrategiesConsideredAndMultipliers.length; i++) {
            quorumStrategiesConsideredAndMultipliers[i] = new IStakeRegistry.StrategyParams[](1);
            quorumStrategiesConsideredAndMultipliers[i][0] = IStakeRegistry.StrategyParams(
                IStrategy(address(uint160(i))),
                uint96(WEIGHTING_DIVISOR)
            );
        }

        registryCoordinatorImplementation = new RegistryCoordinatorHarness(
            serviceManager,
            stakeRegistry,
            macPubkeyRegistry,
            indexRegistry
        );
        {
            delete _operatorSetParams;
            for (uint i = 0; i < numQuorumsToAdd; i++) {
                // hard code these for now
                _operatorSetParams.push(IRegistryCoordinator.OperatorSetParam({
                    maxOperatorCount: _defaultMaxOperatorCount,
                    kickBIPsOfOperatorStake: _defaultKickBIPsOfOperatorStake,
                    kickBIPsOfTotalStake: _defaultKickBIPsOfTotalStake
                }));
            }

            proxyAdmin.upgradeAndCall(
                TransparentUpgradeableProxy(payable(address(registryCoordinator))),
                address(registryCoordinatorImplementation),
                abi.encodeWithSelector(
                    RegistryCoordinator.initialize.selector,
                    registryCoordinatorOwner,
                    _churnApprover,
                    _ejector,
                    eigenLayerPauserReg,
                    0/*initialPausedStatus*/,
                    _operatorSetParams,
                    minimumStakeForQuorum,
                    quorumStrategiesConsideredAndMultipliers
                )
            );
        }

        operatorStateRetriever = new OperatorStateRetriever();

        _cheats.stopPrank();
    }

    function _incrementAddress(address start, uint256 inc) internal pure returns(address) {
        return address(uint160(uint256(uint160(start) + inc)));
    }

    function _incrementBytes32(bytes32 start, uint256 inc) internal pure returns(bytes32) {
        return bytes32(uint256(start) + inc);
    }

    function _signOperatorChurnApproval(address registeringOperator, bytes32 registeringOperatorId, IRegistryCoordinator.OperatorKickParam[] memory operatorKickParams, bytes32 salt,  uint256 expiry) internal view returns(ISignatureUtils.SignatureWithSaltAndExpiry memory) {
        bytes32 digestHash = registryCoordinator.calculateOperatorChurnApprovalDigestHash(
            registeringOperator,
            registeringOperatorId,
            operatorKickParams,
            salt,
            expiry
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_churnApproverPrivateKey, digestHash);
        return ISignatureUtils.SignatureWithSaltAndExpiry({
            signature: abi.encodePacked(r, s, v),
            expiry: expiry,
            salt: salt
        });
    }
}
