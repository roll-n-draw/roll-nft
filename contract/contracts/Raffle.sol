// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "clones-with-immutable-args/Clone.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./IPrize.sol";


contract Raffle is Clone, Initializable, ERC721Upgradeable, VRFConsumerBaseV2 {
    
    /// @dev raffle host
    address public host;
    /// @param True when Host claimed ticket's reward
    bool fundsClaimed;
    /// @question What is that?
    // uint256 public s_requestId;
    /// @dev current ticket ID
    uint256 public currentTicketId = 1;
    /// @dev random words generated by chainlink VRF
    uint256[] private randomWords;
    // /// @dev optional raffle array if shuffling is needed
    //address[] public raffleParticipants;
    /// @dev raffle winners
    uint256[] internal winners;
    /// @dev available prizes
    IPrize.Prize[] internal prizes;

    /// @dev EVENTS
    event EnterRaffle(address indexed raffle, address participant, uint256 numTickets);
    event PrizeClaimed(address indexed raffle, address indexed winner);
    event PrizeReclaimed(address indexed raffle, address indexed host);
    event ProceedsClaimed(address indexed raffle, address indexed host);
    event TicketSold(address indexed raffle, address indexed participant, uint256 amount);
    event RefundClaimed(address indexed raffle, uint256 numTickets);
    // figure out how to emit this event
    //event RaffleEnded(address indexed raffle, );
    event HostSet(address indexed raffle, address indexed oldHost, address indexed newHost); 


    /// @dev initialize raffle
    function initialize (
        string memory _raffleName,
        string memory _raffleSymbol,
        IPrize.Prize[] calldata _prizes,
        address _host,
        address _vrfCoordinator
    ) public initializer {
         __ERC721_init(_raffleName, _raffleSymbol);
         host = _host;
         vrfCoordinator = _vrfCoordinator;
         // push prizes to storage
         for(uint256 i =0; i < _prizes.length;){
            prizes.push(_prizes[i]);
            unchecked {
                ++i;
            }
         }
    }

    function canParticipate() internal view returns(bool){
        return block.timestamp > startTimestamp() && block.timestamp < endTimestamp();
    }
    function canClaimRefund() internal view returns(bool) {
        return currentTicketId < entryLowerLimit() && endTimestamp() < block.timestamp;
    }
    function canClaimFunds() internal view returns(bool) {
        return currentTicketId >= entryLowerLimit() && endTimestamp() < block.timestamp;
    }

    /// @dev enter raffle
    function participate(uint256 _numTickets) external {
        require(canParticipate());
        uint256 _currentTicketId = currentTicketId;
        if(entryUpperLimit() > 0 ){
            require(_currentTicketId + _numTickets <= entryUpperLimit());
        }
        mintToken().transferFrom(msg.sender, address(this), mintCost() * _numTickets);
        for(uint256 i = 0; i < _numTickets;){
            _safeMint(msg.sender, _currentTicketId);
            _currentTicketId++;
            unchecked{i++;}
        }
        currentTicketId = _currentTicketId;
        emit EnterRaffle(address(this), msg.sender, _numTickets);
    }

     /// @dev claim prize from 
    function claimPrize(uint256 winnerId) external {
        IPrize.Prize memory _prize = prizes[winnerId];
        if(prizes.length > 0){
            require(!_prize.claimed && msg.sender == ownerOf(getIdFromIndex(winnerId)));
            _prize.prizeAddress.safeTransferFrom(address(this), msg.sender, _prize.prizeId);
            prizes[winnerId].claimed = true;
        }else {
            revert("NO_PRIZES");
        } 
    }

    /// @dev claim refund
    function claimRefund(uint256[] calldata _ticketIds) external {
        require(canClaimRefund());
        uint256 validTickets;
        for(uint256 i=0; i<_ticketIds.length;){
            if(msg.sender == ownerOf(_ticketIds[i])){
                _burn(_ticketIds[i]);
                validTickets++;
                unchecked{i++;}
            }
        }
        if(validTickets > 0){
            mintToken().transferFrom(address(this),msg.sender, mintCost() * validTickets);
        }
        emit RefundClaimed(address(this), validTickets);
    }

    /// @dev host claim prizes (incase raflle doesn't hold)
    function claimPrizeRefund() external {
        IPrize.Prize[] memory _prizes = prizes;
        require(canClaimRefund());
        require(msg.sender == host);
        for(uint256 i=0; i<_prizes.length;){
            require(!_prizes[i].claimed);
            prizes[i].claimed = true;
            _prizes[i].prizeAddress.safeTransferFrom(address(this), msg.sender, _prizes[i].prizeId);
            unchecked{i++;}
        }
        if(_prizes.length > 0) emit PrizeReclaimed(address(this), msg.sender);
    }

    /// @dev withdraw raffle proceeds
    function withdrawFunds() external {
        require(canClaimFunds());
        require(msg.sender == host);
        require(!fundsClaimed);
        fundsClaimed = true;
        // amtoftickets * prize of ticket - fee
        uint256 amount = currentTicketId * mintCost();
        uint256 fee = (feePercent() * amount) / 10000;

        mintToken().transferFrom(address(this), msg.sender, amount - fee);
        uint256 balance = mintToken().balanceOf(address(this));
        
        mintToken().transferFrom(address(this), treasury(), balance);
        
        emit ProceedsClaimed(address(this), msg.sender);
    }

    /// @dev get winner ticket id from index
    function getIdFromIndex(uint256 _index) internal view returns(uint256){
        return winners[_index];
    }

    /// @dev change raffle host
    function setHost(address _newHost) external {
        require(msg.sender == host);
        host = _newHost;
        emit HostSet(address(this), msg.sender, _newHost);
    }

    /// @dev request random word and select winner from raffle tickets
    function draw() external {
        uint256 prizeLen = prizes.length;
        requestRandomWords(uint32(prizeLen));
        // basic
        for(uint256 i=0; i<prizeLen;){
            //do something
            unchecked {
                i++;
            }
        }
    }

    /// @dev request random words from chainlink oracle
    function requestRandomWords(uint32 _numWords) internal {
        VRFCoordinatorV2Interface COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        // uint16 _minConfirmation = 3;
        // uint32 _callbackGasLimit = 100000;
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash(),
            subscriptionId(),
            3,
            100000,
            _numWords
        );
    }
    
    function fulfillRandomWords( uint256, uint256[] memory _randomWords) internal override {
        randomWords = _randomWords;
    }

    /// @dev shuffle participants tickects using shuffling algo ie fischer-yates
    // function _shuffle() internal {}

    /// @dev chainlink KEY HASH
    function keyHash() internal pure returns(bytes32){
        return bytes32(_getArgUint256(0));
    }
    /// @dev treasury address
    function treasury() internal pure returns(address){
        return _getArgAddress(0xCC);
    }
    /// @dev chainlink subscription Id
    function subscriptionId() internal pure returns(uint64){
        return _getArgUint64(0x20);
    }
    /// @dev raffle start time
    function startTimestamp() internal pure returns(uint64){
        return _getArgUint64(0x28);
    }
    /// @dev raffle end time
    function endTimestamp() internal pure returns(uint64){
        return _getArgUint64(0x30);
    }
    /// @dev max amount of tickets that can be sold
    function entryUpperLimit() internal pure returns(uint256){
        return _getArgUint256(0x38);
    }
    /// @dev min amount of tickets that can be sold
    function entryLowerLimit() internal pure returns(uint256){
        return _getArgUint256(0x58);
    }
    /// @dev ticket cost
    function mintCost() internal pure returns(uint256){
        return _getArgUint256(0x78);
    }
    /// @dev ticket purchase token
    function mintToken() internal pure returns(IERC20){
        return IERC20(_getArgAddress(0x98));
    }
    function feePercent() internal pure returns(uint256){
        return _getArgUint256(0xAC);
    }


}