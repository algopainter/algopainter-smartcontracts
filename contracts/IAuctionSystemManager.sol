// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAuctionSystemManager {
    function onAuctionCreated(
        uint256 auctionId,
        address owner
    ) external;

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external;

    function onWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external;

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 netAmount
    ) external;

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) external;
}
