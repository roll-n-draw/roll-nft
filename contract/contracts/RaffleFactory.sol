// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Raffle.sol";
import "./LinkTokenInterface.sol";

contract RaffleFactory {
     using ClonesWithImmutableArgs for address;

    /// @dev current raffle Id
    address[] public allRaffles;
    /// @dev raffle implementation contract
    address internal immutable implementation;
    /// @dev link token contract address
    LinkTokenInterface public immutable LINK_TOKEN;
    /// @dev chainlink VRF Coordinator address
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;
    /// @dev chainlink key hash
    bytes32 internal immutable KEY_HASH;
    /// @dev chainlink VRF subscription id
    uint64 public subscriptionId;
    /// @dev owner
    address public owner;
    /// @dev fee percentage i.e 1%(100/10000)
    uint256 public feePercent;

    /// EVENTS
    event RaffleCreated(address indexed raffleCreated, address indexed hostAddress, uint256 mintPrice, uint256 deadline);
    event FeeSet(uint256 newFee);



    constructor(address _vrfCoordinator, address linkToken, bytes32 _keyHash) {
        owner = msg.sender;
        implementation = address(new Raffle());
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINK_TOKEN = LinkTokenInterface(linkToken);
        KEY_HASH = _keyHash;
    }

    /// @dev create new raffle 
    function createRollNFT(
        uint64 _startTime,
        uint64 _endTime,
        address _mintToken,
        uint256 _entryUpperLimit,
        uint256 _entryLowerLimit,
        uint256 _mintCost,
        IERC721 _prizeAddress,
        uint256 _prizeId
    ) external returns(Raffle raffle){
        bytes memory data = abi.encodePacked(
            KEY_HASH,
            subscriptionId,
            _startTime,
            _endTime,
            _entryUpperLimit,
            _entryLowerLimit,
            _mintCost,
            _mintToken,
            feePercent,
            address(this)
        );
        // clone raffle implementation contract
        raffle = Raffle(implementation.clone(data));
        //initialize raffle contract
        raffle.initialize(
            string(abi.encodePacked("RAFFLE__",address(raffle))),
            string(abi.encodePacked("RFL__",address(raffle))),
            _prizeAddress, 
            _prizeId,
            msg.sender,
            address(VRF_COORDINATOR)
        );

        allRaffles.push(address(raffle));
        
        // transfer prize to factory
        _prizeAddress.transferFrom(msg.sender, address(this), _prizeId);

        // approve and transfer raffle prize to raffle contract
        _prizeAddress.approve(address(raffle), _prizeId);
        _prizeAddress.transferFrom(address(this), address(raffle), _prizeId);

        addConsumer(address(raffle));

        emit RaffleCreated(address(raffle), msg.sender, _mintCost, _endTime);


    }

    /// @dev set new fee
    function setFee(uint256 _newFee) external {
        if(owner != msg.sender){ 
            revert();
        }
        feePercent = _newFee;
        emit FeeSet(_newFee);
    }

    /// @dev Create a new subscription 
    function createNewSubscription() public {
         if(owner != msg.sender){ 
            revert();
        }

        subscriptionId = VRF_COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        VRF_COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    /// Assumes this contract owns link.
    /// 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) public {
        if(owner != msg.sender){ 
            revert();
        }
        LINK_TOKEN.approve(address(VRF_COORDINATOR), type(uint).max);
        LINK_TOKEN.transferAndCall(address(VRF_COORDINATOR), amount, abi.encode(subscriptionId));
    }

    function addConsumer(address consumerAddress) public {
        if(owner != msg.sender){ 
            revert();
        }
        // Add a consumer contract to the subscription.
        VRF_COORDINATOR.addConsumer(subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) public {
        if(owner != msg.sender){
            revert();
        }
        // Remove a consumer contract from the subscription.
        VRF_COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) public {
        if(owner != msg.sender){
            revert();
        }
        // Cancel the subscription and send the remaining LINK to a wallet address.
        VRF_COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
        subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(IERC20 token, uint256 amount, address to) public {
        if(owner != msg.sender){
            revert();
        }
        token.transfer(to, amount);
    }
}