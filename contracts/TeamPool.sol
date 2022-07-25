// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

error TeamPool__NotEnoughMaticSent();
error TeamPool__PoolNotOpen();
error FailedTransferLINK(address to, uint256 amount);
error TeamPool__TransferOwnerFailed();
error TeamPool__TransferFailed();

contract TeamPool is ReentrancyGuard, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    //Type Declarations
    enum PoolState {
        OPEN,
        CLOSED
    }

    enum Winner {
        HOME,
        AWAY,
        TIE
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
    bytes32 private s_gameCreateRequestId;
    bytes32 private s_gameResolveRequestId;
    uint256 public s_entranceFee;
    uint256 public s_poolTotal;
    uint256 private s_toDistribute;
    address private immutable i_owner;
    address payable[] s_homeTeamPickers;
    address payable[] s_awayTeamPickers;
    AggregatorV3Interface private s_priceFeed;
    PoolState public s_poolState;
    Winner public s_winner;

    //Mappings
    mapping(bytes32 => bytes[]) public requestIdGames;

    //Events
    event HomeTeamPicked(address indexed entrant);
    event AwayTeamPicked(address indexed entrant);
    event WinningsDistributed();

    //Functions

    constructor(
        uint256 entranceFee,
        address priceFeedAddress,
        address link,
        address oracle
    ) {
        setChainlinkToken(link);
        setChainlinkOracle(oracle);
        s_entranceFee = entranceFee;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
        s_poolTotal = 0;
        s_poolState = PoolState.OPEN;
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) external {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function requestGames(
        bytes32 _specId,
        uint256 _payment,
        string calldata _market,
        uint256 _sportId,
        uint256 _date
    ) external {
        Chainlink.Request memory req = buildOperatorRequest(
            _specId,
            this.fulfillCreateGames.selector
        );

        req.addUint("date", _date);
        req.add("market", _market);
        req.addUint("sportId", _sportId);

        sendOperatorRequest(req, _payment);
    }

    function fulfillCreateGames(bytes32 _requestId, bytes[] memory _games)
        public
        recordChainlinkFulfillment(_requestId)
    {
        requestIdGames[_requestId] = _games;
        s_gameCreateRequestId = _requestId;
    }

    function pickHomeTeam() public payable nonReentrant {
        uint256 time = block.timestamp;
        GameCreate memory game = getGamesCreated(s_gameCreateRequestId, 0);
        if (time >= (game.startTime - 600)) {
            s_poolState = PoolState.CLOSED;
        }
        if (msg.value != s_entranceFee) {
            revert TeamPool__NotEnoughMaticSent();
        }
        if (s_poolState != PoolState.OPEN) {
            revert TeamPool__PoolNotOpen();
        }
        s_poolTotal += msg.value;
        s_homeTeamPickers.push(payable(msg.sender));
        emit HomeTeamPicked(msg.sender);
    }

    function pickAwayTeam() public payable nonReentrant {
        uint256 time = block.timestamp;
        GameCreate memory game = getGamesCreated(s_gameCreateRequestId, 0);
        if (time >= (game.startTime - 600)) {
            s_poolState = PoolState.CLOSED;
        }
        if (msg.value != s_entranceFee) {
            revert TeamPool__NotEnoughMaticSent();
        }
        if (s_poolState != PoolState.OPEN) {
            revert TeamPool__PoolNotOpen();
        }
        s_poolTotal += msg.value;
        s_awayTeamPickers.push(payable(msg.sender));
        emit AwayTeamPicked(msg.sender);
    }

    function requestGamesResolveWithFilters(
        bytes32 _specId,
        uint256 _payment,
        string calldata _market,
        uint256 _sportId,
        uint256 _date,
        string[] calldata _statusIds,
        string[] calldata _gameIds
    ) external {
        Chainlink.Request memory req = buildOperatorRequest(
            _specId,
            this.fulfillResolveGames.selector
        );

        req.addUint("date", _date);
        req.add("market", _market);
        req.addUint("sportId", _sportId);
        req.addStringArray("statusIds", _statusIds);
        req.addStringArray("gameIds", _gameIds);

        sendOperatorRequest(req, _payment);
    }

    function fulfillResolveGames(bytes32 _requestId, bytes[] memory _games)
        public
        recordChainlinkFulfillment(_requestId)
    {
        requestIdGames[_requestId] = _games;
        s_gameResolveRequestId = _requestId;
    }

    function determineWinningTeam() private {
        GameResolve memory game = getGamesResolved(s_gameResolveRequestId, 0);
        if (game.homeScore > game.awayScore) {
            s_winner = Winner.HOME;
        } else if (game.awayScore > game.homeScore) {
            s_winner = Winner.AWAY;
        } else {
            s_winner = Winner.TIE;
        }
    }

    function distributeWinnings() external payable {
        bool success;
        bool tie = false;
        determineWinningTeam();
        address payable[] memory winningTeam;
        if (s_winner == Winner.HOME) {
            winningTeam = s_homeTeamPickers;
        } else if (s_winner == Winner.AWAY) {
            winningTeam = s_awayTeamPickers;
        } else {
            tie = true;
        }
        if (!tie) {
            uint256 ownerFee = (s_poolTotal * 5) / 100;
            uint256 remainingBalance = s_poolTotal - ownerFee;
            (success, ) = i_owner.call{value: ownerFee}("");
            if (!success) {
                revert TeamPool__TransferOwnerFailed();
            }

            s_toDistribute = remainingBalance / winningTeam.length;
            for (uint256 i = 0; i < winningTeam.length; i++) {
                (success, ) = winningTeam[i].call{value: s_toDistribute}("");
                if (!success) {
                    revert TeamPool__TransferFailed();
                }
            }
            s_toDistribute = 0;
            s_poolTotal = 0;
            emit WinningsDistributed();
        }
    }

    function setOracle(address _oracle) external {
        setChainlinkOracle(_oracle);
    }

    function withdrawLink(uint256 _amount, address payable _payee) external {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        _requireTransferLINK(linkToken.transfer(_payee, _amount), _payee, _amount);
    }

    //External View Functions
    function getGamesCreated(bytes32 _requestId, uint256 index)
        internal
        view
        returns (GameCreate memory)
    {
        GameCreate memory game = abi.decode(requestIdGames[_requestId][index], (GameCreate));
        return game;
    }

    function getGamesResolved(bytes32 _requestId, uint256 index)
        internal
        view
        returns (GameResolve memory)
    {
        GameResolve memory game = abi.decode(requestIdGames[_requestId][index], (GameResolve));
        return game;
    }

    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    //Private Pure Functions
    function _requireTransferLINK(
        bool _success,
        address _to,
        uint256 _amount
    ) private pure {
        if (!_success) {
            revert FailedTransferLINK(_to, _amount);
        }
    }
}
