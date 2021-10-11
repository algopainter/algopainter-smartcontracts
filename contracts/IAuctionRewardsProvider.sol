// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAuctionRewardsProvider {
    
    function getBidbackPercentage(
        uint256 _auctionId
    ) external view returns(uint);

    function getInvestorPirsPercentage(
        uint256 _auctionId
    ) external view returns(uint);

    function getCreatorPirsPercentage(
        uint256 _algoPainterId, uint256 _tokenId
    ) external view returns(uint);

}