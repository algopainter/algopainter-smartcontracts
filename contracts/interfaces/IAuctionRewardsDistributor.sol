// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAuctionRewardsDistributor {
    function hasPIRSStakes(uint256 auctionId) external view returns (bool);

    function hasBidbackStakes(uint256 auctionId) external view returns (bool);

    function addEligibleBidder(uint256 auctionId, address bidder) external;

    function remAccountFromBidRewards(uint256 auctionId, address account)
        external;

    function setAuctionRewardsDistributable(
        uint256 auctionId,
        uint256 rewardsAmount
    ) external;
    
    function getTotalBidbackStakes(uint256 auctionId)
        external
        view
        returns (uint256);

    function getTotalPirsStakes(uint256 auctionId)
        external
        view
        returns (uint256);

    function getBidbackUsers(uint256 auctionId)
        external
        view
        returns (address[] memory);

    function getBidbackPercentages(uint256 auctionId)
        external
        view
        returns (address[] memory users, uint256[] memory percentages);
}
