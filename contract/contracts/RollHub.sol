// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    constructor() {
        ///
    }


}