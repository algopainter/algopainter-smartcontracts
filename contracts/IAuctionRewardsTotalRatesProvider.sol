// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAuctionRewardsTotalRatesProvider {
    function getRewardsRate(
        uint256 _auctionId
    ) external view returns (uint256);
}