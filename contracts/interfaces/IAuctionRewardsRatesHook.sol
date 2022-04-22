// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAuctionRewardsRatesHook {
    function onSetBidbackRate(uint256 _auctionId, uint256 _bidbackRate)
        external;

    function onSetPIRSRate(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    ) external;

    function onSetCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) external;
}
