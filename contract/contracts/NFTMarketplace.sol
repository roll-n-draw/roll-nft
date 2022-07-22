// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract RollNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _rollIds;
    // Counters.Counter private _itemsSold;
    IERC20 payToken;

    mintToken().transferFrom(address(this), msg.sender, amount - fee);

    uint256 listingPrice = 0.025 ether;
    address payable owner;
    address public rollFactory;

    mapping(uint256 => RollPrize) private idToPrize;

    struct RollPrize {
      uint256 tokenId;
      address tokenCollection;
      uint256 rollId;
      address rollContract,
      address payable host;
      address payable owner;
      uint256 entryPrice;
      uint256 startTime;
      uint256 endTime;
      uint256 minTicketSold;
      uint256 maxTicketSold;
      uint256 winningTicketId;
      bool finished;
      bool successfull;
    }

    event PrizePublished (
      uint256 tokenId,
      address tokenCollection,
      address host,
      address owner,
    );

    uint256 indexed rollId,
      address rollContract,
      uint256 entryPrice,
      uint256 startTime,
      uint256 endTime,
      uint256 minTicketSold,
      uint256 maxTicketSold,
      
      

    constructor() ERC721("Roll NFT", "ROLL") {
      owner = payable(msg.sender);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint _listingPrice) public payable {
      require(owner == msg.sender, "Only marketplace owner can update listing price.");
      listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
      return listingPrice;
    }

    /* Mints a token and lists it in the marketplace */
    // function getTicket(string memory tokenURI, uint256 price) public payable returns (uint) {
    //   _tokenIds.increment();
    //   uint256 newTokenId = _tokenIds.current();

    //   _mint(msg.sender, newTokenId);
    //   _setTokenURI(newTokenId, tokenURI);
    //   createMarketItem(newTokenId, price);
    //   return newTokenId;
    // }

    function publishRoll(
      uint256 tokenId,
      address tokenCollection,
      uint256 rollId,
      address rollContract;
      uint256 entryPrice;
      address IERC20(payToken);
      uint256 startTime;
      uint256 endTime;
      uint256 minTicketSold;
      uint256 maxTicketSold;
      Roll memory rollMetadata;
    ) private {
      // require(price > 0, "Price must be at least 1 wei");
      require(msg.value == listingPrice, "Price must be equal to listing price");

      idToPrize[rollId] =  PrizeNFT(
        tokenId;
        tokenCollection,
        rollId,
        rollContract,
        payable(msg.sender),
        payable(address(this)),
        entryPrice,
        payToken,
        startTime;
        endTime;
        minTicketSold;
        maxTicketSold;
        0,
        false,
        false,
      );

      _transfer(msg.sender, address(this), tokenId);
      emit RollPublished(
        rollId,
        rollContract,
        payable(msg.sender),
        payable(address(this)),
        entryPrice,
        payToken,
        
        uint256 indexed rollId,
      address rollContract,
      address host,
      address owner,
      uint256 entryPrice,
      address payToken,
      uint256 endTime;
      uint256 startTime;
      uint256 minTicketSold;
      uint256 maxTicketSold;
      );
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      require(msg.value == listingPrice, "Price must be equal to listing price");
      idToMarketItem[tokenId].sold = false;
      idToMarketItem[tokenId].price = price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));
      _itemsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(
      uint256 tokenId
      ) public payable {
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      require(msg.value == price, "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _itemsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      payable(owner).transfer(listingPrice);
      payable(seller).transfer(msg.value);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
      uint itemCount = _tokenIds.current();
      uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
      uint currentIndex = 0;

      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }
}