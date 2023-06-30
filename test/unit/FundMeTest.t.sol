// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
     FundMe fundMe;

     address USER = makeAddr("user");
     uint256 constant SEND_VALUE = 0.1 ether;
     uint256 constant STARTING_BALANCE = 10 ether;
     uint256 constant GAS_PRICE = 1;
     
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {

        assertEq(fundMe.MINIMUM_USD(), 5e18);
        // console.log(fundMe.MINIMUM_USD);

    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund(); //send 0 eth
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER);
        // fundMe.fund{value:SEND_VALUE}();

        uint256 amoutnFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amoutnFunded, SEND_VALUE);


    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER);
        // fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);

    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
       
        fundMe.withdraw();

    }

    function testWithDrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE); 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
         assertEq(endingFundMeBalance, 0);
         assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);


    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingnFunderIndex = 2;
        for(uint160 i = startingnFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance
        );
    }

        function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingnFunderIndex = 2;
        for(uint160 i = startingnFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance
        );
    }

} 