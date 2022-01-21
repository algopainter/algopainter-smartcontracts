// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAuctionRewardsRatesProvider {
    function getBidbackRate(
        uint256 _auctionId
    ) external view returns (uint256);

    function getInvestorPirsRate(
        uint256 _auctionId
    ) external view returns (uint256);

    function getCreatorPirsRate(
        uint256 _auctionId
    ) external view returns (uint256);
}
