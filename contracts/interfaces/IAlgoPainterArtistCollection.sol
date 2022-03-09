// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterArtistCollection {
    enum PriceType {
        Fixed,
        Variable
    }

    struct Collection {
        address artist;
        address walletAddress;
        uint256 startDT;
        uint256 endDT;
        bytes32 name;
        uint16 creatorPercentage;
        uint256 startingPrice;
        address tokenPrice;
        PriceType priceType;
        uint256[] prices;
        uint16 nfts;
    }

    event CollectionCreated(
        uint256 indexed index
    );

    function getCountCollections()
        external
        view
        returns (uint256);

    function getCollection(uint256 collectionId)
        external
        view
        returns (
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            PriceType priceType,
            uint256[] memory prices,
            uint16 nfts
        );

    function hasCollection(uint256 collectionId) external view;
}
