// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAuctionRewardsProvider.sol";
import "./AlgoPainterBidBackPirsAccessControl.sol";
import "./AlgoPainterAuctionSystem.sol";

contract AlgoPainterBidBackPirs is 
    IAuctionRewardsProvider,
    AlgoPainterBidBackPirsAccessControl
{
    AlgoPainterAuctionSystem auctionSystemAddress;

    mapping(uint256 => uint256) bidbackPercentagePerAuction;
    mapping(address => mapping(uint256 => uint256)) investorPirsPercentagePerImage;
    mapping(address => uint256) creatorPirsPercentagePerCollection;

    mapping(address => uint256) maxCreatorPirsPercentagePerCollection;
    uint256 maxInvestorPirsPercentage;
    uint256 maxBidbackPercentage;
    
    mapping(uint256 => bool) isBidbackSet;
    mapping(address => bool) isCreatorPirsSet;
    mapping(address => mapping(uint256 => bool)) isInvestorPirsSet;

    function setAuctionSystemAddress(AlgoPainterAuctionSystem _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystemAddress = _auctionSystemAddress;
    }

    function setMaxCreatorPirsPercentage(address _tokenAddress, uint256 _maxCreatorPirsPercentage)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxCreatorPirsPercentagePerCollection[_tokenAddress] = _maxCreatorPirsPercentage;
    }
    
    function setMaxInvestorPirsPercentage(uint256 _maxInvestorPirsPercentage)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxInvestorPirsPercentage = _maxInvestorPirsPercentage;
    }
    
    function setMaxBidbackPercentage(uint256 _maxBidbackPercentage)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxBidbackPercentage = _maxBidbackPercentage;
    }
    
    function setBidbackPercentage(uint256 _auctionId, uint256 _bidbackPercentage)
        public 
    {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (address beneficiary,,,,,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

        require(
            msg.sender == beneficiary,
            "AlgoPainterBidBackPirs:NOT_AUCTION_OWNER"
        );
        
        require(
            isBidbackSet[_auctionId] == false,
            "AlgoPainterBidBackPirs:BIDBACK_ALREADY_SET"
        );
        
        require(
            _bidbackPercentage <= maxBidbackPercentage,
            "AlgoPainterBidBackPirs:BIDBACK_IS_GREATER_THAN_ALLOWED"
        );
        
        bidbackPercentagePerAuction[_auctionId] = _bidbackPercentage;
        isBidbackSet[_auctionId] = true;
    }
    
    function setInvestorPirsPercentage(address _tokenAddress, uint256 _tokenId, uint256 _investorPirsPercentage)
        public 
    {
        
        require(
            isInvestorPirsSet[_tokenAddress][_tokenId] == false,
            "AlgoPainterBidBackPirs:INVESTOR_PIRS_ALREADY_SET"
        );
        
        require(
            _investorPirsPercentage <= maxInvestorPirsPercentage,
            "AlgoPainterBidBackPirs:INVESTOR_PIRS_IS_GREATER_THAN_ALLOWED"
        );

        investorPirsPercentagePerImage[_tokenAddress][_tokenId] = _investorPirsPercentage;
        isInvestorPirsSet[_tokenAddress][_tokenId] = true;
    }
    
    function setCreatorPirsPercentage(address _tokenAddress, uint256 _creatorPirsPercentage)
        public
    {
        
        require(
            isCreatorPirsSet[_tokenAddress] == false,
            "AlgoPainterBidBackPirs:CREATOR_PIRS_ALREADY_SET"
        );
        
        require(
            _creatorPirsPercentage <= maxCreatorPirsPercentagePerCollection[_tokenAddress],
            "AlgoPainterBidBackPirs:CREATOR_PIRS_IS_GREATER_THAN_ALLOWED"
        );

        creatorPirsPercentagePerCollection[_tokenAddress] = _creatorPirsPercentage;
        isCreatorPirsSet[_tokenAddress] = true;
    }
    
    function getBidbackPercentage(uint256 _auctionId) 
        public 
        view 
        override
        returns(uint256) 
    {
        return bidbackPercentagePerAuction[_auctionId];
    }

    function getInvestorPirsPercentage(address _tokenAddress, uint256 _tokenId)
        public
        view
        override
        returns(uint256)
    {
        return investorPirsPercentagePerImage[_tokenAddress][_tokenId];
    }

    function getCreatorPirsPercentage(address _tokenAddress)
        public
        view
        override
        returns(uint256) 
    {
        return creatorPirsPercentagePerCollection[_tokenAddress];
    }
    
    function getMaxCreatorPirsPercentage(address _tokenAddress)
        public 
        view 
        returns(uint256) 
    {
        return maxCreatorPirsPercentagePerCollection[_tokenAddress];
    }
    
    function getMaxInvestorPirsPercentage()
        public 
        view 
        returns(uint256) 
    {
        return maxInvestorPirsPercentage;
    }
    
    function getMaxBidbackPercentage()
        public 
        view
        returns(uint256) 
    {
        return maxBidbackPercentage;
    }
    
}