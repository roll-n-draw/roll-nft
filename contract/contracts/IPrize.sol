// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPrize {
    struct Prize {
        IERC721 prizeAddress;
        bool claimed;
        uint256 prizeId;
    }
}