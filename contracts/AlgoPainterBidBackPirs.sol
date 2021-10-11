// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAuctionRewardsProvider.sol";

contract AlgoPainterBidBackPirs is IAuctionRewardsProvider {

    mapping(uint256 => uint256) bidbackPercentagePerAuction;
    mapping(uint256 => uint256) investorPirsPercentagePerAuction;
    mapping(uint256 => mapping(uint256 => uint256)) creatorPirsPercentagePerAuction;
    
    function setBidbackAndInvestorPirsPercentage(uint256 _auctionId, uint256 _bidBackPercentage, uint256 _investorPirsPercentage) public {
        bidbackPercentagePerAuction[_auctionId] = _bidBackPercentage;
        investorPirsPercentagePerAuction[_auctionId] = _investorPirsPercentage;
    }
    
    function setCreatorPirsPercentage(uint256 _algoPainterId, uint256 _tokenId, uint256 _creatorPirsPercentage) public {
        creatorPirsPercentagePerAuction[_tokenId][_algoPainterId] = _creatorPirsPercentage;
    }
    
    function getBidbackPercentage(uint256 _auctionId) 
        public 
        view 
        override
        returns(uint) 
    {
        return bidbackPercentagePerAuction[_auctionId];
    }

    function getInvestorPirsPercentage(uint256 _auctionId)
        public
        view
        override
        returns(uint)
    {
        return investorPirsPercentagePerAuction[_auctionId];
    }

    function getCreatorPirsPercentage(uint256 _algoPainterId, uint256 _tokenId)
        public
        view
        override
        returns(uint) 
    {
        return creatorPirsPercentagePerAuction[_tokenId][_algoPainterId];
    }

}
