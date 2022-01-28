// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAuctionHook.sol";
import "../interfaces/IAlgoPainterRewardsDistributor.sol";

contract AuctionHookMOCK is IAuctionHook, IAlgoPainterRewardsDistributor {
    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        address tokenPriceAddress
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
        uint256 netAmount
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
}
