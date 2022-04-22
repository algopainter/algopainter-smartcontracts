// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterArtistCollectionItemHook {
    function onCollectionItemMinted(
        uint256 collectionId,
        uint256 tokenId
    ) external;
}
