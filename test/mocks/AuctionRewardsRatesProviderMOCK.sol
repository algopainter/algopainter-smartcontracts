// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../contracts/IAuctionRewardsRatesProvider.sol";
import "../../contracts/IAuctionRewardsTotalRatesProvider.sol";

contract AuctionRewardsRatesProviderMOCK is
    IAuctionRewardsRatesProvider,
    IAuctionRewardsTotalRatesProvider
{
    using SafeMath for uint256;

    function getBidbackRate(
        uint256
    ) override public pure returns (uint256) {
        return 3000;
    }

    function getInvestorPirsRate(
        uint256
    ) override public pure returns (uint256) {
        return 2000;
    }

    function getCreatorPirsRate(
        uint256
    ) override public pure returns (uint256) {
        return 1000;
    }

    function getRewardsRate(
        uint256 _auctionId
    ) override public pure returns (uint256) {
        return getBidbackRate(_auctionId) 
            .add(getInvestorPirsRate(_auctionId))
            .add(getCreatorPirsRate(_auctionId));
    }
}
