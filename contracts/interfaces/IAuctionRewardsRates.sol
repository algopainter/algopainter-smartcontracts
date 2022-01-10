// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAuctionRewardsRates {
    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate) external;

    function getBidbackRate(uint256 _auctionId) external view returns (uint256);

    function getPIRSRate(uint256 _auctionId) external view returns (uint256);

    function hasPIRSRateSetPerImage(address _tokenAddress, uint256 _tokenId)
        external
        view returns (bool);

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) external;

    function getCreatorRoyaltiesRate(uint256 _auctionId)
        external
        view
        returns (uint256);

    function getRewardsRate(uint256 _auctionId) external view returns (uint256);
}
