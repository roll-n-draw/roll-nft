// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "./Raffle.sol";
import "./IPrize.sol";
import "./LinkTokenInterface.sol";

contract RaffleFactory {
     using ClonesWithImmutableArgs for address;

    /// @dev current raffle Id
    uint256 internal currentRaffleId;
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
    /// @dev mapping of raffle Id to address
    mapping (uint256 => address) public rollIDToAddress;

    /// EVENTS
    event RaffleCreated(uint256 indexed raffleID, address indexed hostAddress, uint256 mintPrice, uint256 deadline);
    event FeeSet(uint256 newFee);



    constructor(address _vrfCoordinator, address linkToken, uint64 _subscriptionId, bytes32 _keyHash) {
        implementation = address(new Raffle());
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINK_TOKEN = LinkTokenInterface(linkToken);
        owner = msg.sender;
        subscriptionId = _subscriptionId;
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
        IPrize.Prize[] calldata prizes
    ) external returns(Raffle raffle){
        uint256 _currentRaffleId = currentRaffleId;
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
            string(abi.encodePacked("RAFFLE__",currentRaffleId)),
            string(abi.encodePacked("RFL__",currentRaffleId)),
            prizes,
            msg.sender,
            address(VRF_COORDINATOR)
        );

        rollIDToAddress[_currentRaffleId] = address(raffle);
        // transfer raffle prize to raffle contract
        for(uint256 i=0; i < prizes.length;){
            prizes[i].prizeAddress.transferFrom(msg.sender, address(raffle), prizes[i].prizeId);
            unchecked{i++;}
        }
        addConsumer(address(raffle));
        currentRaffleId = _currentRaffleId++;
        emit RaffleCreated(_currentRaffleId, msg.sender, _mintCost, _endTime);


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