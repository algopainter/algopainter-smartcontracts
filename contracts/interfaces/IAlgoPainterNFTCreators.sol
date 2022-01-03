// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAlgoPainterNFTCreators {
    function getCreator(bytes32 hashKey) external payable returns (address);

    function getCreatorNotPayable(bytes32 hashKey) external view returns (address);

    function setCreator(bytes32 hashKey, address creator) external;

    function getHashKey(address nftAddress, uint256 token)
        external
        pure
        returns (bytes32);

    function getHashKey(address nftAddress) external pure returns (bytes32);
}
