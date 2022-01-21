// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterRewardsDistributor {
    function hasPIRSStakes(uint256 auctionId) external view returns (bool);

    function hasBidbackStakes(uint256 auctionId) external view returns (bool);
}
