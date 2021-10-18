// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IAuctionSystemManager.sol";

contract AuctionSystemManagerMOCK is IAuctionSystemManager {
    function onAuctionCreated(
        uint256 auctionId,
        address owner
    ) public override {}

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) public override {}

    function onWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) public override {}

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 bidbackAmount,
        uint256 netAmount
    ) public override {}

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) public override {}
}
