// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAlgoPainterAuctionSystem {
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum AuctionState {
        Running,
        Ended,
        Canceled
    }

    struct AuctionInfo {
        address beneficiary;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 minimumAmount;
        uint256 auctionEndTime;
        IERC20 tokenPriceAddress;
        address highestBidder;
        uint256 highestBid;
        AuctionState state;
    }

    function getAuctionInfo(uint256 _auctionId)
        external
        view
        returns (
            address beneficiary,
            TokenType tokenType,
            address tokenAddress,
            uint256 tokenId,
            uint256 minimumAmount,
            uint256 auctionEndTime,
            IERC20 tokenPriceAddress,
            AuctionState state,
            address highestBidder,
            uint256 highestBid
        );
}
