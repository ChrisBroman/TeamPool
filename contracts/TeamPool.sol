//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//Chainlink Imports
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

//errors

/** @title A sports pool contract
 *   @author Chris Broman
 *   @notice This contract is for creating an untamperable fair sports pool
 *   @dev    This implements chainlink subscription for sports results an scores.  */

contract TeamPool is ChainlinkClient {
    //Type declarations

    enum PoolState {
        OPEN,
        PENDING_RESULTS
    }

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    }

    //State Variables
    uint256 private immutable i_entranceFee;
    address payable[] s_homePlayers;
    address payable[] s_awayPlayers;
    bytes32 s_gameId;
    bytes256 s_startTime;
    string s_homeTeam;
    string s_awayTeam;
    uint8 s_homeScore;
    uint8 s_awayScore;
    uint8 s_statusId;

    //Pool Variables
    PoolState private s_poolState;

    //Events

    //Constructor
    /**
     * @param _link the LINK token address.
     * @param _oracle the Operator.sol contract address.
     */
  //  constructor(address _link, address _oracle) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
    }

    //Functions
    //View / Pure Functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getHomePlayers(uint256 index) public view returns (address) {
        return s_homePlayers[index];
    }

    function getAwayPlayers(uint256 index) public view returns (address) {
        return s_awayPlayers[index];
    }

    function getNumberHomePlayers() public view returns (uint256) {
        return s_homePlayers.length;
    }

    function getNumberAwayPlayers() public view returns (uint256) {
        return s_awayPlayers.length;
    }
}
