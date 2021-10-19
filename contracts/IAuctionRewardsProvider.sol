// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

interface IAuctionRewardsProvider {
    
    function getBidbackPercentage(
        uint256 _auctionId
    ) external view returns(uint256);

    function getInvestorPirsPercentage(
        address _tokenAddress, uint256 _tokenId
    ) external view returns(uint256);

    function getCreatorPirsPercentage(
        address _tokenAddress
    ) external view returns(uint256);
    
}