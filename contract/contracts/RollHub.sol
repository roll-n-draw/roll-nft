// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @dev nonReentrant modifier
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RollTickets.sol";

contract RollNFT is ERC721URIStorage {
    ///
    using Counters for Counters.Counter;
    Counters.Counter private _rollIds;
    Counters.Counter private _counter;

    /// @param Address of contract owner
    address payable owner;
    /// @param Address of Factory contract for 'Roll Tickets Collection'
    address public rollFactory;
    /// @param Price for Hosting a Roll
    uint256 hostingPrice = 0.001 ether;
    /// @param Fee for Hosting a Roll
    uint256 hostingPrice = 0.001 ether;

    mapping(uint256 => Roll) private idToRoll;

    struct Roll {
        uint rollId;
        address ticketContract;
        address prizeContract;
        uint256 prizeId;
        // PrizeItem internal prize;
        address payable host;
        address payable owner;
        uint256 ticketPrice;
        uint256 ticketsUpperLimit;
        uint256 ticketsLowerLimit;
        uint256 endTime;
        uint256 startTime;
        uint256 ticketsSold;
        uint256 winnerTicketId;
        uint256 hostReward;
        // bool prizeAvailable;
        // bool prizeToWithdraw;
        bool succeed;
        bool finished;
        bool rewardClaimed;
        bool prizeClaimed;
    }

    event RollHosted (
        uint indexed rollId,
        address ticketContract,
        IERC721 indexed prizeContract,
        uint256 prizeId;
        address indexed host,
        // address owner,
        uint256 ticketPrice,
        uint256 ticketsUpperLimit,
        uint256 ticketsLowerLimit,
        uint256 endTime,
        uint256 startTime
        // uint256 ticketsSold,
        // uint256 winnerTicketId,
        // uint256 hostReward,
        // bool rewardClaimed,
        // bool prizeClaimed,
        // bool prizeAvailable,
        // bool prizeToWithdraw,
        // bool succeed,
        // bool finished,
        // bool prizeClaimed,
    )

    struct PrizeItem {
        IERC721 prizeAddress;
        uint256 prizeId;
        bool claimed;
    }

    constructor() ERC721("Roll NFT","RNFT") {
        /// @dev Set owner of the Roll protocol
        owner = payable(msg.sender);
    }

    /* Updates the listing price of the contract */
    function updateHostingPrice(uint _hostingPrice) public payable {
      require(owner == msg.sender, "Only protocol owner can update hosting price.");
      hostingPrice = _hostingPrice;
    }

    /* Returns the hosting price of a Roll */
    function getHostingPrice() public view returns (uint256) {
      return hostingPrice;
    }

    function hostRoll(
        address _prizeContract,
        uint256 _prizeId,
        uint256 _ticketPrice,
        uint256 _ticketsUpperLimit,
        uint256 _ticketsLowerLimit,
        uint256 _endTime,
        uint256 _startTime
    ) public payable returns (uint256) nonReentrant {
        require(_ticketPrice > 0, "Ticket price must be greater then 0");
        require(msg.value > hostingPrice, "Not enough to cover hosting price");

        _rollIds.increment();
        uint256 rollId = _rollIds.current();

        /// @dev Transfer selected NFT from owner to RollNFT Hub contract
        IERC721(_prizeContract).transferFrom(msg.sender, address(this), _prizeId);

        bytes memory data = abi.encodePacked(
            KEY_HASH,
            subscriptionId,
            _startTime,
            _endTime,
            _ticketsUpperLimit,
            _ticketsLowerLimit,
            _mintCost,
            _mintToken,
            feePercent,
            address(this)
        );
        /// @dev Clone RollTickets implementation contract
        rollTickets = RollTickets(implementation.clone(data));
        /// @dev Initialize RollTickets contract
        rollTickets.initialize(
            string(abi.encodePacked("Roll_NFT_Tickets__",rollId)),
            string(abi.encodePacked("RTCK__",rollId)),
            _prizeAddress, 
            _prizeId,
            msg.sender,
            address(VRF_COORDINATOR)
        );

        /// @note Provide ticketContract address
        address ticketsContract = address(rollTickets);

        /// @note Provide rollContract address
        idToRoll[rollId] = Roll(
            rollId, // uint rollId;
            ticketsContract, // address rollAddress;
            _prizeContract, // address prizeContract;
            _prizeId, // uint256 prizeId;
            payable(msg.sender), // address payable host;
            payable(address(0)), // address payable owner;
            _ticketPrice, // uint256 ticketPrice;
            _ticketsUpperLimit, // uint256 upperTicketLimit;
            _ticketsLowerLimit, // uint256 lowerTicketLimit;
            _endTime, // uint256 endTime;
            _startTime, // uint256 startTime;
            0, // uint256 ticketsSold;
            0, // uint256 winnerTicketId;
            0, // uint256 hostReward;
            false, // bool succeed;
            false, // bool finished;
            false, // bool rewardClaimed;
            false // bool prizeClaimed
        );

        emit RollHosted(
            rollId,
            ticketsContract,
            _prizeContract,
            _prizeId,
            msg.sender,
            _ticketPrice,
            _upperTicketLimit,
            _lowerTicketLimit,
            _endTime,
            _startTime
        );
    }
    
    /// 
}