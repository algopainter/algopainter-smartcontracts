// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../contracts/interfaces/IAuctionRewardsRates.sol";
import "../../contracts/accessControl/AlgoPainterSimpleAccessControl.sol";

contract AuctionRewardsRatesMOCK is
    IAuctionRewardsRates,
    AlgoPainterSimpleAccessControl
{
    using SafeMath for uint256;

    mapping(uint256 => uint256) bidbackRate;
    mapping(bytes32 => uint256) creatorRate;

    function getBidbackRate(
        uint256 _auctionId
    ) override public view returns (uint256) {
        return bidbackRate[_auctionId];
    }

    function getPIRSRate(
        uint256 _auctionId
    ) override public pure returns (uint256) {
        return 2000;
    }

    function getCreatorRoyaltiesRate(
        uint256 _auctionId
    ) override public pure returns (uint256) {
        return 1000;
    }

    function getRewardsRate(
        uint256 _auctionId
    ) override public view
     returns (uint256) {
        return getBidbackRate(_auctionId) 
            .add(getPIRSRate(_auctionId));
    }

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) override public {
        creatorRate[_hashAddress] = _creatorRoyaltiesRate;
    }

    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate) 
        override 
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        bidbackRate[_auctionId] = _bidbackRate;
    }
}
