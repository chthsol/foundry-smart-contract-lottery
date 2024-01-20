// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
	uint256 entranceFee;
	uint256 interval;
	address vrfCoordinator;
	bytes32 gasLane;
	uint64 subscriptionId;
	uint32 callbackGasLimit;
	address link;
	uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY =
	0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    NetworkConfig public activeNetworkConfig;
	
    constructor() {
	if (block.chainid == 11155111){
	    activeNetworkConfig = getSepoliaEthConfig();
	} else if (block.chainid == 1){
	    activeNetworkConfig = getMainnetEthConfig();
	} else {    
	    activeNetworkConfig = getOrCreateAnvilEthConfig();
	}
    }

    function getMainnetEthOConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig ({
	    entranceFee: 0.01 ether,
 	    interval: 30,
	    vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
	    gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
	    subscriptionId: 0, // If left at zero, one will be created
	    callbackGasLimit: 500000,
	    link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
	    deployerKey: vm.envUint("PRIVATE_KEY")
	    });
    }
	
    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig ({
	    entranceFee: 0.01 ether,
 	    interval: 30,
	    vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
	    gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
	    subscriptionId: 0, // If left at zero, one will be created
	    callbackGasLimit: 500000,
	    link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
	    deployerKey: vm.envUint("PRIVATE_KEY")
	    });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
	if (activeNetworkConfig.vrfCoordinator != address(0)) {
	    return activeNetworkConfig;
        }

	uint96 baseFee = 0.25 ether; // 0.25 LINK
	uint96 gasPriceLink = 1e9; //1 gwei
	    
	vm.startBroadcast();
	VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
	    baseFee,
	    gasPriceLink
	);
	LinkToken link = new LinkToken();
	vm.stopBroadcast();

	anvilNetworkConfig = NetworkConfig ({
	    entranceFee: 0.01 ether,
	    interval: 30,
	    vrfCoordinator: address(vrfCoordinatorMock),
	    gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
	    subscriptionId: 0, // our script will add this!
	    callbackGasLimit: 500000,
	    link: address(link),
	    deployerKey: DEFAULT_ANVIL_KEY
	    });
    }
}
