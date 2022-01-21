// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAuctionRewardsTotalRatesProvider {
    function getRewardsRate(
        uint256 _auctionId
    ) external view returns (uint256);
}