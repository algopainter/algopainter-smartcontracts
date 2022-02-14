// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IAlgoPainterArtistCollection {
    enum PriceType {
        FIXED,
        VARIABLE
    }

    struct Price {
        uint16 from;
        uint16 to;
        uint256 amount;
    }

    struct Collection {
        uint256 index;
        bytes32 hash;
        CollectionData data;
        uint256 pricesCount;
        mapping(uint256 => Price) PriceRange;
    }

    struct CollectionData {
        address artist;
        address walletAddress;
        uint256 startDT;
        uint256 endDT;
        bytes32 name;
        uint16 creatorPercentage;
        uint256 startingPrice;
        address tokenPrice;
        PriceType priceType;
        uint16 paramsCount;
        uint16 nfts;
    }

    function getCollection(uint256 collectionId)
        external
        view
        returns (
            bytes32 hash,
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            PriceType priceType,
            Price[] memory prices,
            uint16 paramsCount,
            uint16 nfts
        );

    function hasCollection(uint256 collectionId) external view;
}
