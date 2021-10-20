// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "./IAuctionRewardsRatesProvider.sol";
import "./IAuctionRewardsTotalRatesProvider.sol";
import "./AlgoPainterBidBackPirsAccessControl.sol";
import "./AlgoPainterAuctionSystem.sol";

contract AlgoPainterBidBackPirs is 
    IAuctionRewardsRatesProvider,
    IAuctionRewardsTotalRatesProvider,
    AlgoPainterBidBackPirsAccessControl
{
    AlgoPainterAuctionSystem auctionSystemAddress;

    mapping(uint256 => uint256) bidbackRatePerAuction;
    mapping(address => mapping(uint256 => uint256)) investorPirsRatePerImage;
    mapping(address => uint256) creatorPirsRatePerCollection;

    mapping(address => uint256) maxCreatorPirsRatePerCollection;
    uint256 maxInvestorPirsRate;
    uint256 maxBidbackRate;
    
    mapping(uint256 => bool) isBidbackSet;
    mapping(address => bool) isCreatorPirsSet;
    mapping(address => mapping(uint256 => bool)) isInvestorPirsSet;

    function setAuctionSystemAddress(AlgoPainterAuctionSystem _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystemAddress = _auctionSystemAddress;
    }

    function setMaxCreatorPirsRate(address _tokenAddress, uint256 _maxCreatorPirsRate)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxCreatorPirsRatePerCollection[_tokenAddress] = _maxCreatorPirsRate;
    }
    
    function setMaxInvestorPirsRate(uint256 _maxInvestorPirsRate)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxInvestorPirsRate = _maxInvestorPirsRate;
    }
    
    function setMaxBidbackRate(uint256 _maxBidbackRate)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxBidbackRate = _maxBidbackRate;
    }
    
    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate)
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
            _bidbackRate <= maxBidbackRate,
            "AlgoPainterBidBackPirs:BIDBACK_IS_GREATER_THAN_ALLOWED"
        );
        
        bidbackRatePerAuction[_auctionId] = _bidbackRate;
        isBidbackSet[_auctionId] = true;
    }
    
    function setInvestorPirsRate(address _tokenAddress, uint256 _tokenId, uint256 _investorPirsRate)
        public 
    {
        
        require(
            isInvestorPirsSet[_tokenAddress][_tokenId] == false,
            "AlgoPainterBidBackPirs:INVESTOR_PIRS_ALREADY_SET"
        );
        
        require(
            _investorPirsRate <= maxInvestorPirsRate,
            "AlgoPainterBidBackPirs:INVESTOR_PIRS_IS_GREATER_THAN_ALLOWED"
        );

        investorPirsRatePerImage[_tokenAddress][_tokenId] = _investorPirsRate;
        isInvestorPirsSet[_tokenAddress][_tokenId] = true;
    }
    
    function setCreatorPirsRate(address _tokenAddress, uint256 _creatorPirsRate)
        public
    {
        
        require(
            isCreatorPirsSet[_tokenAddress] == false,
            "AlgoPainterBidBackPirs:CREATOR_PIRS_ALREADY_SET"
        );
        
        require(
            _creatorPirsRate <= maxCreatorPirsRatePerCollection[_tokenAddress],
            "AlgoPainterBidBackPirs:CREATOR_PIRS_IS_GREATER_THAN_ALLOWED"
        );

        creatorPirsRatePerCollection[_tokenAddress] = _creatorPirsRate;
        isCreatorPirsSet[_tokenAddress] = true;
    }
    
    function getBidbackRate(uint256 _auctionId) 
        public 
        view 
        override
        returns(uint256) 
    {
        return bidbackRatePerAuction[_auctionId];
    }

    function getInvestorPirsRate(uint256 _auctionId)
        public
        view
        override
        returns(uint256)
    {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,address _tokenAddress, uint256 _tokenId,,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

        return investorPirsRatePerImage[_tokenAddress][_tokenId];
    }

    function getCreatorPirsRate(uint256 _auctionId)
        public
        view
        override
        returns(uint256) 
    {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,address _tokenAddress,,,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

        return creatorPirsRatePerCollection[_tokenAddress];
    }
    
    function getMaxCreatorPirsRate(address _tokenAddress)
        public 
        view 
        returns(uint256) 
    {
        return maxCreatorPirsRatePerCollection[_tokenAddress];
    }
    
    function getMaxInvestorPirsRate()
        public 
        view 
        returns(uint256) 
    {
        return maxInvestorPirsRate;
    }
    
    function getMaxBidbackRate()
        public 
        view
        returns(uint256) 
    {
        return maxBidbackRate;
    }

    function getRewardsRate(
        uint256 _auctionId
    ) external view override returns (uint256) {
        return getBidbackRate(_auctionId) +
        getInvestorPirsRate(_auctionId) +
        getCreatorPirsRate(_auctionId);
    }
}
