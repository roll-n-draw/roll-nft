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
    bool fundsClaimed;
    bool requestPending;
    uint256 public s_requestId;
    /// @dev current ticket ID
    uint256 public currentTicketId;
    // /// @dev optional raffle array if shuffling is needed
    //address[] public raffleParticipants;
    /// @dev raffle winners
    uint256 public winnerTicket;
    /// @dev random words
    uint256[] public randomWords;
    /// @dev available prizes
    IPrize.Prize public prize;

    /// @dev EVENTS
    event EnterRaffle(address participant, uint256 numTickets);
    event PrizeClaimed(address indexed winner, uint256 winnerId, address prize, uint256 prizeId);
    event PrizeReclaimed(address indexed host, address prize, uint256 prizeId);
    event ProceedsClaimed(address indexed host, uint256 amountWithdrawn, uint256 amountSentToTresury);
    event TicketSold(address indexed participant, uint256 amount);
    event RefundClaimed(address participant, uint256 numTickets);
    event RaffleWinner(uint256 indexed winner);
    // figure out how to emit this event
    //event RaffleEnded(address indexed raffle, );
    event HostSet(address indexed oldHost, address indexed newHost); 


    /// @dev initialize raffle
    function initialize (
        string memory _raffleName,
        string memory _raffleSymbol,
        IERC721 _prizeAddress,
        uint256 _prizeId,
        address _host,
        address _vrfCoordinator
    ) public initializer {
         __ERC721_init(_raffleName, _raffleSymbol);
         host = _host;
         vrfCoordinator = _vrfCoordinator;
         prize.prizeAddress = _prizeAddress;
         prize.prizeId = _prizeId;
         currentTicketId = 1;
    }


    /// @dev enter raffle
    function participate(uint256 _numTickets) external {
        require(block.timestamp > startTimestamp() && block.timestamp < endTimestamp(), 'CANNOT_PARTICIPATE');
        uint256 _currentTicketId = currentTicketId;
        if(entryUpperLimit() > 0 ){
            require(_currentTicketId + _numTickets <= entryUpperLimit() + 1);
        }
        // retrun ticket ids
        mintToken().transferFrom(msg.sender, address(this), mintCost() * _numTickets);
        for(uint256 i = 0; i < _numTickets;){
            _safeMint(msg.sender, _currentTicketId);
            _currentTicketId++;
            unchecked{i++;}
        }
        currentTicketId = _currentTicketId;
        emit EnterRaffle(msg.sender, _numTickets);
    }           

     /// @dev claim prize from 
    function claimPrize() external {
        uint256 _winner = winnerTicket;
        require(_winner != 0);
        IPrize.Prize memory _prize = prize;
        require(!_prize.claimed && msg.sender == ownerOf(_winner));
        _prize.prizeAddress.safeTransferFrom(address(this), msg.sender, _prize.prizeId);
        prize.claimed = true;
        emit PrizeClaimed(msg.sender, _winner, address(prize.prizeAddress), _prize.prizeId);
    }

    /// @dev claim refund
    function claimRefund(uint256[] calldata _ticketIds) external {
        // require can claim refund
        require(currentTicketId < entryLowerLimit() && endTimestamp() < block.timestamp, 'CANNOT_CLAIM_REFUND');
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
        emit RefundClaimed(msg.sender, validTickets);
    }

    /// @dev host claim prizes (incase raflle doesn't hold)
    function claimPrizeRefund() external {
        require(msg.sender == host, 'UNAUTHORIZED');
        // require can claim prize Refund
        require(currentTicketId < entryLowerLimit() && endTimestamp() < block.timestamp, 'CANNOT_CLAIM_PRIZE_REFUND');
        IPrize.Prize memory _prize = prize;
        require(!_prize.claimed, 'PRIZE_CLAIMED');
        prize.claimed = true;
        _prize.prizeAddress.safeTransferFrom(address(this), msg.sender, _prize.prizeId);
    
        emit PrizeReclaimed(msg.sender, address(_prize.prizeAddress) ,_prize.prizeId);
    }

    /// @dev withdraw raffle proceeds
    function withdrawFunds() external {
        require(msg.sender == host);
        // require raffle has ended and was successful
        require(currentTicketId >= entryLowerLimit(), 'CANNOT_WITHDRAW_FUNDS_TGEL');
        if(entryUpperLimit() > 0){
            require(currentTicketId == entryUpperLimit() + 1 || endTimestamp() < block.timestamp, 'CANNOT_WITHDRAW_FUNDS_TELL_ELB');
        } else {
            require(endTimestamp() < block.timestamp, 'CANNOT_WITHDRAW_FUNDS_ELB');
        }   
        require(!fundsClaimed, 'FUNDS_CLAIMED');
        fundsClaimed = true;
        // amtoftickets * prize of ticket - fee
        uint256 amount = currentTicketId * mintCost();
        uint256 fee = (feePercent() * amount) / 10000;

        mintToken().transferFrom(address(this), msg.sender, amount - fee);
        uint256 balance = mintToken().balanceOf(address(this));
        
        mintToken().transferFrom(address(this), treasury(), balance);
        
        emit ProceedsClaimed(msg.sender, amount, balance);
    }


    /// @dev change raffle host
    function setHost(address _newHost) external {
        require(msg.sender == host);
        host = _newHost;
        emit HostSet( msg.sender, _newHost);
    }

    /// @dev request random word and select winner from raffle tickets
    function draw() external {
        uint256 _ticketId = currentTicketId;
        require(!requestPending, 'REQUEST_PENDING');
        require(_ticketId >= entryLowerLimit(), 'CANNOT_DRAW_TGEL');
        if(entryUpperLimit() > 0){
            require(_ticketId == entryUpperLimit() + 1 || endTimestamp() < block.timestamp, 'CANNOT_DRAW_TEUL_ELB');
        } else {
            require(endTimestamp() < block.timestamp, 'CANNOT_DRAW_ELB');
        }    
        require(winnerTicket == 0);
        VRFCoordinatorV2Interface COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
         // uint16 _minConfirmation = 3;
        // uint32 _callbackGasLimit = 100000;
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash(),
            subscriptionId(),
            3,
            100000,
            1
        );
        requestPending = true;
    }

     
    function fulfillRandomWords(uint256 requestId, uint256[] memory _randomWords) internal override {
        randomWords = _randomWords;
        winnerTicket = (_randomWords[0] % currentTicketId) + 1;

        emit RaffleWinner(winnerTicket);
    }

//     function onERC721Received(
//         address,
//         address,
//         uint256,
//         bytes
//   ) public returns(bytes4){
//     return this.onERC721Received.selector;
//   }


    // /// @dev shuffle participants tickects using shuffling algo ie fischer-yates
    // function _shuffle() internal {}

    /// @dev chainlink KEY HASH
    function keyHash() public pure returns(bytes32){
        return bytes32(_getArgUint256(0));
    }
    /// @dev treasury address
    function treasury() public pure returns(address){
        return _getArgAddress(0xCC);
    }
    /// @dev chainlink subscription Id
    function subscriptionId() public pure returns(uint64){
        return _getArgUint64(0x20);
    }
    /// @dev raffle start time
    function startTimestamp() public pure returns(uint64){
        return _getArgUint64(0x28);
    }
    /// @dev raffle end time
    function endTimestamp() public pure returns(uint64){
        return _getArgUint64(0x30);
    }
    /// @dev max amount of tickets that can be sold
    function entryUpperLimit() public pure returns(uint256){
        return _getArgUint256(0x38);
    }
    /// @dev min amount of tickets that can be sold
    function entryLowerLimit() public pure returns(uint256){
        return _getArgUint256(0x58);
    }
    /// @dev ticket cost
    function mintCost() public pure returns(uint256){
        return _getArgUint256(0x78);
    }
    /// @dev ticket purchase token
    function mintToken() public pure returns(IERC20){
        return IERC20(_getArgAddress(0x98));
    }
    function feePercent() public pure returns(uint256){
        return _getArgUint256(0xAC);
    }


}