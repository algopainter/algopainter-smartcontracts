// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./interfaces/IAlgoPainterNFTCreators.sol";
import "./accessControl/AlgoPainterSimpleAccessControl.sol";

contract AlgoPainterNFTCreators is
    IAlgoPainterNFTCreators,
    AlgoPainterSimpleAccessControl
{
    mapping(bytes32 => address) private creators;

    function getCreatorNotPayable(address nftAddress, uint256 token)
        public
        view
        override
        returns (address)
    {
        bytes32 hashKey = getHashKey(nftAddress);
        if (creators[hashKey] != address(0)) {
            return creators[hashKey];
        }
        hashKey = getHashKey(nftAddress, token);
        return creators[hashKey];
    }

    function getCreator(address nftAddress, uint256 token)
        public
        payable
        override
        returns (address)
    {
        bytes32 hashKey = getHashKey(nftAddress);

        //If the creator is set on whole collection returns it
        if (creators[hashKey] != address(0)) {
            return creators[hashKey];
        }

        hashKey = getHashKey(nftAddress, token);
        return creators[hashKey];
    }

    function getCreator(bytes32 hashKey)
        public
        payable
        override
        returns (address)
    {
        return creators[hashKey];
    }

    function setCollectionCreatorByCreator(address nftAddress, address creator) public {
        bytes32 hashKey = getHashKey(nftAddress);

        require(
            msg.sender == creators[hashKey],
            "AlgoPainterItemsCreators:ONLY_CREATOR_CAN_SET_CREATORS"
        );

        creators[hashKey] = creator;
    }

    function setCollectionItemCreatorByCreator(
        address nftAddress,
        uint256 token,
        address creator
    ) public {
        bytes32 hashKey = getHashKey(nftAddress, token);

        require(
            msg.sender == creators[hashKey],
            "AlgoPainterItemsCreators:ONLY_CREATOR_CAN_SET_CREATORS"
        );

        creators[getHashKey(nftAddress, token)] = creator;
    }

    function setCreator(address nftAddress, address creator)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        bytes32 hashKey = getHashKey(nftAddress);

        require(
           creators[hashKey] == address(0),
           "AlgoPainterItemsCreators:ONLY_CREATOR_CAN_SET_CREATORS" 
        );

        creators[hashKey] = creator;
    }

    function setCreator(
        address nftAddress,
        uint256 token,
        address creator
    ) public override onlyRole(CONFIGURATOR_ROLE) {
        bytes32 hashKey = getHashKey(nftAddress, token);

        require(
           creators[hashKey] == address(0),
           "AlgoPainterItemsCreators:ONLY_CREATOR_CAN_SET_CREATORS" 
        );

        creators[hashKey] = creator;
    }

    function getHashKey(address nftAddress)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress));
    }

    function getHashKey(address nftAddress, uint256 token)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress, token));
    }
}
