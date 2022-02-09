// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IAuctionRewardsRates.sol";
import "../accessControl/AlgoPainterSimpleAccessControl.sol";

contract AuctionRewardsRatesMOCK is
    IAuctionRewardsRates,
    AlgoPainterSimpleAccessControl
{
    mapping(uint256 => uint256) bidbackRate;
    mapping(bytes32 => uint256) creatorRate;

    function getBidbackRate(uint256 _auctionId)
        public
        view
        override
        returns (uint256)
    {
        return bidbackRate[_auctionId];
    }

    function getPIRSRate(uint256 _auctionId)
        public
        pure
        override
        returns (uint256)
    {
        return 2000;
    }

    function getCreatorRoyaltiesRate(uint256 _auctionId)
        public
        pure
        override
        returns (uint256)
    {
        return 1000;
    }

    function getRewardsRate(uint256 _auctionId)
        public
        view
        override
        returns (uint256)
    {
        return getBidbackRate(_auctionId) + getPIRSRate(_auctionId);
    }

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) public override {
        creatorRate[_hashAddress] = _creatorRoyaltiesRate;
    }

    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        bidbackRate[_auctionId] = _bidbackRate;
    }

    function getMaxCreatorRoyaltiesRate()
        public
        pure
        override
        returns (uint256)
    {
        return 3000;
    }

    function getMaxInvestorPirsRate() public pure override returns (uint256) {
        return 3000;
    }

    function getMaxBidbackRate() public pure override returns (uint256) {
        return 3000;
    }

    function hasPIRSRateSetPerImage(address _tokenAddress, uint256 _tokenId)
        public
        pure
        override
        returns (bool)
    {
        return true;
    }

    function getCreatorRate(address nftAddress, uint256 token)
        public
        pure
        override
        returns (uint256) {
            return 500;
        }
}
