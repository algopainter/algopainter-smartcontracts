// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterPersonalItemHook {
    function onItemMinted(
        string memory name,
        uint256 tokenId,
        uint256 creatorPercentage,
        string memory tokenURI
    ) external;
}
