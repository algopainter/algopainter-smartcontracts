// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../contracts/interfaces/IAuctionHook.sol";

contract AuctionHookMOCK is IAuctionHook {
    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        address tokenPriceAddress
    ) override public {}

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) override public {}

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) override public {}

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 creatorAmount,
        uint256 rewardsAmount,
        uint256 netAmount
    ) override public {}

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) override public {}
}
