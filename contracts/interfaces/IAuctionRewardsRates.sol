// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAuctionRewardsRates {
    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate) external;

    function getBidbackRate(uint256 _auctionId) external view returns (uint256);

    function getPIRSRate(uint256 _auctionId) external view returns (uint256);

    function setPIRSRate(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    ) external;

    function hasPIRSRateSetPerImage(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns (bool);

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) external;

    function getCreatorRoyaltiesRate(uint256 _auctionId)
        external
        view
        returns (uint256);

    function getMaxCreatorRoyaltiesRate() external view returns (uint256);

    function getMaxInvestorPirsRate() external view returns (uint256);

    function getMaxBidbackRate() external view returns (uint256);

    function getCreatorRate(address nftAddress, uint256 token)
        external
        view
        returns (uint256);
    
    function isCreatorRateSet(address _adr, uint256 _token)
        external
        view
        returns (bool);

    function getRewardsRate(uint256 _auctionId) external view returns (uint256);
}
