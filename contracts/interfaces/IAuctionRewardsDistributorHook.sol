// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAuctionRewardsDistributorHook {
    function onStakeBidback(
        uint256 auctionId, 
        uint256 amount,
        uint256 total
    ) external;

    function onStakePirs(
        uint256 auctionId, 
        uint256 amount,
        uint256 total
    ) external;

    function onUnstakeBidback(
        uint256 auctionId, 
        uint256 amount,
        uint256 total
    ) external;

    function onUnstakePirs(
        uint256 auctionId, 
        uint256 amount,
        uint256 total
    ) external;

    function onBidbackClaimed(
        uint256 auctionId, 
        uint256 amount
    ) external;

    function onPIRSClaimed(
        uint256 auctionId,
        uint256 amount
    ) external;
}