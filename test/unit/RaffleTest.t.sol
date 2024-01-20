// SPDX-License-Identfier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RafflTest is Test {
    /** Events */
    event enteredRaffle (address indexed player);
    event pickedWinner (address indexed winner);
	
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    
    address  public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    modifier raffleEntered() {
	vm.prank(PLAYER);
	raffle.enterRaffle{value: entranceFee}();
	_;
    }

    modifier timePassed() {
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
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

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /** Enter Raffle Functions */
    
    function testEnterRaffleRvertWithoutEnoughEntranceFee() public {
        vm.prank(PLAYER); 
	vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();	
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public raffleEntered {
	address playerRecorded = raffle.getPlayer(0);

	assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
	vm.prank(PLAYER);
	vm.expectEmit(true, false, false, false, address(raffle));

	emit enteredRaffle(PLAYER);  
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public raffleEntered timePassed {
	raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
	vm.prank(PLAYER);
	raffle.enterRaffle{value: entranceFee}();
    }

    /** checkUpkeep */

    function testCheckupkeepReturnsFalseWhenItDoesNotHaveBalance() public timePassed {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
	assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseWhenItIsNotOpen() public raffleEntered timePassed {
	raffle.performUpkeep("");
	(bool upkeepNeeded, ) = raffle.checkUpkeep("");

	assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimePassed() public raffleEntered {
	(bool upkeepNeeded, ) = raffle.checkUpkeep("");

	assert(!upkeepNeeded);
    }
    
    function testCheckUpkeepReturnsTrueWhenUpkeepNeeded() public raffleEntered timePassed {
	(bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }

    /** performUpkeep */
    
    function testPerformupkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered timePassed {
	raffle.performUpkeep("");    
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
	uint256 currentBalance = 0;
	uint256 numPlayers = 0;
	Raffle.RaffleState rState = raffle.getRaffleState();

	vm.expectRevert(
	    abi.encodeWithSelector(
	        Raffle.Raffle__UpkeepNotNeeded.selector,
		currentBalance,
		numPlayers,
		rState
	    )
	);
	raffle.performUpkeep("");
    }

    //What if I need to test using the output of an event? 
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered timePassed {
	vm.recordLogs();
	raffle.performUpkeep("");
	Vm.Log[] memory entries = vm.getRecordedLogs();
	bytes32 requestId = entries[1].topics[1];  // all logs are recorded as bytes32

        Raffle.RaffleState rState = raffle.getRaffleState();
	
	assert(uint256(requestId) > 0);
	assert(uint256(rState) == 1);
    }

    /** fulfillRandomWords */

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered timePassed skipFork {
	vm.expectRevert("nonexistent request");
	VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
	    randomRequestId,
	    address(raffle)
	);
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney() public raffleEntered timePassed skipFork {
        //Arrange
	uint256 additionalEntrants = 5;
	uint256 startingIndex = 1;
	for(
	    uint256 i = startingIndex;
	    i< startingIndex + additionalEntrants;
	    i++
	) {
	    address player = address(uint160(i));
	    hoax(player, STARTING_USER_BALANCE);
	    raffle.enterRaffle{value: entranceFee}();
	}

	uint256 prize = entranceFee * (additionalEntrants + 1);
	
        vm.recordLogs();
	raffle.performUpkeep("");
	Vm.Log[] memory entries = vm.getRecordedLogs();
	bytes32 requestId = entries[1].topics[1];  // all logs are recorded as bytes32

	uint256 previousTimeStamp = raffle.getLastTimeStamp();
	
	vm.expectEmit(true, false, false, false, address(raffle));
        emit pickedWinner(address(5));

	//pretend to be chainlink VRF to get random number and pick winner
	VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
	    uint256(requestId),
	    address(raffle)
	);

	assert(uint256(raffle.getRaffleState()) == 0);
	assert(raffle.getRecentWinner() != address(0));
	assert(raffle.getLengthOfPlayers() == 0);
	assert(previousTimeStamp < raffle.getLastTimeStamp());
	assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
    }    
}
