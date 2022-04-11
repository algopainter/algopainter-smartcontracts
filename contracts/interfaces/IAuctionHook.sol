// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAuctionHook {
    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        uint256 bidbackRate,
        uint256 creatorRate,
        uint256 pirsRate,
        address tokenPriceAddress,
        uint256 price
    ) external;

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external;

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external;

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount,
        uint256 creatorAmount
    ) external;

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) external;
}
