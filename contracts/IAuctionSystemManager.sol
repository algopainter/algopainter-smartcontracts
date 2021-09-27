// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAuctionSystemManager {
    function onAuctionCreated(
        address contractAddress,
        uint256 auctionId,
        address owner
    ) external;

    function onBid(
        address contractAddress,
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external;

    function onWithdraw(
        address contractAddress,
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external;

    function onAuctionEnded(
        address contractAddress,
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 netAmount
    ) external;

    function onAuctionCancelled(
        address contractAddress,
        uint256 auctionId,
        address owner
    ) external;
}
