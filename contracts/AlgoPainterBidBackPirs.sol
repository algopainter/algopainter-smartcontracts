// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IAuctionRewardsRatesProvider.sol";
import "./IAuctionRewardsTotalRatesProvider.sol";
import "./AlgoPainterBidBackPirsAccessControl.sol";
import "./AlgoPainterAuctionSystem.sol";

contract AlgoPainterBidBackPirs is 
    IAuctionRewardsRatesProvider,
    IAuctionRewardsTotalRatesProvider,
    AlgoPainterBidBackPirsAccessControl
{
    event BidbackUpdated(
        uint256 _auctionId,
        uint256 _bidbackRate
    );

    event InvestorPirsUpdated(
        bytes32 _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    );

    event CreatorRoyaltiesUpdated(
        bytes32 _tokenAddress,
        uint256 _creatorRoyaltiesRate
    );

    AlgoPainterAuctionSystem auctionSystemAddress;

    mapping(uint256 => uint256) bidbackRatePerAuction;
    mapping(bytes32 => mapping(uint256 => uint256)) investorPirsRatePerImage;
    mapping(bytes32 => uint256) creatorRoyaltiesRates;
    
    uint256 maxCreatorRoyaltiesRates;
    uint256 maxInvestorPirsRate;
    uint256 maxBidbackRate;
    
    mapping(uint256 => bool) isBidbackSet;
    mapping(bytes32 => bool) isCreatorRoyaltiesSet;
    mapping(bytes32 => mapping(uint256 => bool)) isInvestorPirsSet;

    function setAuctionSystemAddress(AlgoPainterAuctionSystem _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystemAddress = _auctionSystemAddress;
    }

    function setMaxCreatorRoyaltiesRate(uint256 _maxCreatorRoyaltiesRate)
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxCreatorRoyaltiesRates = _maxCreatorRoyaltiesRate;
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
    
    //@TODO: Do no limit to the registred contract
    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate)
        public 
    {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (address beneficiary,,,,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

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

        emit BidbackUpdated(
            _auctionId,
            _bidbackRate
        );
    }
    
    function setInvestorPirsRate(bytes32 _tokenAddress, uint256 _tokenId, uint256 _investorPirsRate)
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

        emit InvestorPirsUpdated(
            _tokenAddress,
            _tokenId,
            _investorPirsRate
        );
    }
    
    function setCreatorRoyaltiesRate(bytes32 _hashAddress, uint256 _creatorRoyaltiesRate)
        public
    {
        require(
            isCreatorRoyaltiesSet[_hashAddress] == false,
            "AlgoPainterBidBackPirs:CREATOR_ROYALTIES_ALREADY_SET"
        );
        
        require(
            _creatorRoyaltiesRate <= maxCreatorRoyaltiesRates,
            "AlgoPainterBidBackPirs:CREATOR_ROYALTIES_IS_GREATER_THAN_ALLOWED"
        );

        creatorRoyaltiesRates[_hashAddress] = _creatorRoyaltiesRate;
        isCreatorRoyaltiesSet[_hashAddress] = true;

        emit CreatorRoyaltiesUpdated(
            _hashAddress,
            _creatorRoyaltiesRate
        );
    }

    function getCreatorRoyaltiesByTokenAddress(bytes32 _hashAddress)
        public
        view
        returns(uint256)
    {
        return creatorRoyaltiesRates[_hashAddress];
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

        (,,address _tokenAddress, uint256 _tokenId,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

        return investorPirsRatePerImage[bytes32(bytes20(_tokenAddress))][_tokenId];
    }

    function getInvestorPirsRatePerImage(bytes32 _tokenAddress, uint256 _tokenId)
        public
        view
        returns(uint256)
    {
        return investorPirsRatePerImage[_tokenAddress][_tokenId];
    }

    function getCreatorRoyaltiesRate(uint256 _auctionId)
        public
        view
        override
        returns(uint256) 
    {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,address _tokenAddress,,,,,,,) = auctionSystem.getAuctionInfo(_auctionId);

        return creatorRoyaltiesRates[bytes32(bytes20(_tokenAddress))];
    }
    
    function getMaxCreatorRoyaltiesRate()
        public 
        view 
        returns(uint256) 
    {
        return maxCreatorRoyaltiesRates;
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
        getCreatorRoyaltiesRate(_auctionId);
    }
}
