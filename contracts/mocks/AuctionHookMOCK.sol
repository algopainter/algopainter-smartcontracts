// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAuctionHook.sol";
import "../interfaces/IAuctionRewardsDistributor.sol";

contract AuctionHookMOCK is IAuctionHook, IAuctionRewardsDistributor {
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
    ) public override {}

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) public override {}

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) public override {}

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount,
        uint256 creatorAmount
    ) public override {}

    function onAuctionCancelled(uint256 auctionId, address owner)
        public
        override
    {}

    function hasPIRSStakes(uint256 auctionId)
        external
        view
        override
        returns (bool)
    {
        return true;
    }

    function hasBidbackStakes(uint256 auctionId)
        external
        view
        override
        returns (bool)
    {
        return true;
    }

    function addEligibleBidder(uint256 auctionId, address bidder)
        external
        override
    {}

    function remAccountFromBidRewards(uint256 auctionId, address account)
        external
        override
    {}

    function setAuctionRewardsDistributable(
        uint256 auctionId,
        uint256 rewardsAmount
    ) external override {}

    function getTotalBidbackStakes(uint256 auctionId)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalPirsStakes(uint256 auctionId)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function getBidbackUsers(uint256 auctionId)
        external
        pure
        override
        returns (address[] memory)
    {
        address[] memory mock = new address[](1);
        return mock;
    }

    function getBidbackPercentages(uint256 auctionId)
        external
        pure
        override
        returns (address[] memory users, uint256[] memory percentages)
    {
        users = new address[](1);
        percentages = new uint256[](1);
    }
}
