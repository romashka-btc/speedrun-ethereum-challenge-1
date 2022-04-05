// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public constant threshold = 1 ether;

    enum Status {
        Stake,
        Success,
        Withdraw
    }

    Status public status;
    bool public isExecuted;

    uint256 public deadline = block.timestamp + 72 hours;
    mapping(address => uint256) public balances;

    event Stake(address owner, uint256 amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable {
        require(status == Status.Stake, "It's not Stake phase");

        balances[msg.sender] = msg.value;

        if (address(this).balance >= threshold) {
            complete();
        }

        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    //  if the `threshold` was not met, allow everyone to call a `withdraw()` function

    function execute() public {
        require(!isExecuted, "Already executed");
        require(block.timestamp >= deadline, "Deadline wasn't met");

        if (status != Status.Stake) {
            return;
        }

        if (address(this).balance < threshold) {
            status = Status.Withdraw;
        } else {
            complete();
        }

        isExecuted = true;
    }

    // Add a `withdraw()` function to let users withdraw their balance

    function withdraw() public {
        require(status == Status.Withdraw, "It's not Withdraw phase");

        uint256 amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }

        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()

    receive() external payable {
        stake();
    }

    function complete() private {
        status = Status.Success;
        exampleExternalContract.complete{value: address(this).balance}();
    }
}
