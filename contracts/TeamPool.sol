//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error TeamPool__NotEnoughEthStaked();
error TeamPool__GameClosed();
error TeamPool__TransferOwnerFailed();
error TeamPool__TransferFailed();

contract TeamPool {
    //Type Definitions

    enum PoolState {
        OPEN,
        CLOSED
    }

    //State Variables

    address private immutable i_owner;
    uint private immutable i_entranceFee = 45000000000000000;
    address payable[] s_homeTeamPlayers;
    address payable[] s_awayTeamPlayers;
    uint private s_totalPool = 0;
    uint private s_toDistribute;

    //Pool Variables

    PoolState private s_poolState;

    //Events

    event HomeTeamPicked(address indexed player);
    event AwayTeamPicked(address indexed player);
    event WinningsDistributed();

    //Functions

    constructor() {
        i_owner = msg.sender;
    }

    function pickHomeTeam() public payable {
        if (msg.value < i_entranceFee) {
            revert TeamPool__NotEnoughEthStaked();
        }
        if (s_poolState != PoolState.OPEN) {
            revert TeamPool__GameClosed();
        }
        s_homeTeamPlayers.push(payable(msg.sender));
        s_totalPool += msg.value;
        emit HomeTeamPicked(msg.sender);
    }

    function pickAwayTeam() public payable {
        if (msg.value < i_entranceFee) {
            revert TeamPool__NotEnoughEthStaked();
        }
        if (s_poolState != PoolState.OPEN) {
            revert TeamPool__GameClosed();
        }
        s_awayTeamPlayers.push(payable(msg.sender));
        s_totalPool += msg.value;
        emit AwayTeamPicked(msg.sender);
    }

    function distributeWinnings() public payable {
        bool success;
        address payable[] memory winningTeam = s_awayTeamPlayers;
        uint ownerFee = (s_totalPool * 5) / 100;
        uint remainingBalance = s_totalPool - ownerFee;
        (success, ) = i_owner.call{value: ownerFee}("");
        if (!success) {
            revert TeamPool__TransferOwnerFailed();
        }
        s_toDistribute = remainingBalance / winningTeam.length;
        for (uint i = 0; i < winningTeam.length; i++) {
            (success, ) = winningTeam[i].call{value: s_toDistribute}("");
            if (!success) {
                revert TeamPool__TransferFailed();
            }
        }
        s_toDistribute = 0;
        s_totalPool = 0;
        emit WinningsDistributed();
    }

    //View / Pure functions

    function getPoolState() public view returns (PoolState) {
        return s_poolState;
    }

    function getHomeTeamPlayer(uint index) public view returns (address) {
        return s_homeTeamPlayers[index];
    }

    function getAwayTeamPlayer(uint index) public view returns (address) {
        return s_awayTeamPlayers[index];
    }

    function getEntranceFee() public pure returns (uint) {
        return i_entranceFee;
    }

    function contractTotal() public view returns (uint) {
        return address(this).balance;
    }

    function getPoolTotal() public view returns (uint) {
        return s_totalPool;
    }

    function getToDistribute() public view returns (uint) {
        return s_toDistribute;
    }
}
