// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract InteractionsTest is Test {

    Raffle raffle;
    HelperConfig helperConfig;
    
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;

    address  public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    modifier skipAnvil() {
	if (block.chainid == 31337) {
	   return;
	}
	_;
    } 
    
    function setUp() external {
	DeployRaffle deployer = new DeployRaffle();
	(raffle, helperConfig) = deployer.run();
	(
        entranceFee,
	interval,
	vrfCoordinator,
	gasLane,
	subscriptionId,
	callbackGasLimit,
	link,
	
	) = helperConfig.activeNetworkConfig();
	vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function  testUserCanCreateSubscriptionUsingInteractions() public {
        // Arrange /Act
    	CreateSubscription createSubscription = new CreateSubscription();
    	subscriptionId = createSubscription.run();
	// Assert
    	assert(subscriptionId != 0);
    }

    function testUserCanRunFundSubscriptionUsingInteractions() public skipAnvil {
	// this only works on fork and presumably testnet
	// Arrange
	// Act
	FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.run();
    }

    function testUserCanRunAddConsumerUsingInteractions() public skipAnvil {
        // this would only work on testnet after --broadcast
	// Arrange
	// Act
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.run();
    }
}
