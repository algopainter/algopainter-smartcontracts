// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAlgoPainterNFTCreators {
    function getCreator(bytes32 hashKey) external payable returns (address);

    function getCreator(address nftAddress, uint256 token)
        external
        payable
        returns (address);

    function getCreatorNotPayable(address nftAddress, uint256 token)
        external
        view
        returns (address);

    function setCreator(
        address nftAddress,
        address creator
    ) external;

    function setCreator(
        address nftAddress,
        uint256 token,
        address creator
    ) external;

    function getHashKey(address nftAddress, uint256 token)
        external
        pure
        returns (bytes32);

    function getHashKey(address nftAddress) external pure returns (bytes32);
}
