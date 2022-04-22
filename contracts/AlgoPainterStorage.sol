// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAlgoPainterStorage.sol";

contract AlgoPainterStorage is
    IAlgoPainterStorage,
    AlgoPainterSimpleAccessControl
{
    mapping(bytes32 => uint256) uint256Storage;
    mapping(bytes32 => bytes32) bytes32Storage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bool) boolStorage;

    function giveAccessToConfigurators(bytes32 role, address[] memory accounts)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            grantRole(role, accounts[i]);
        }
    }

    function setUint256(bytes32 key, uint256 value)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        uint256Storage[key] = value;
    }

    function setBytes32(bytes32 key, bytes32 value)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        bytes32Storage[key] = value;
    }

    function setString(bytes32 key, string calldata value)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        stringStorage[key] = value;
    }

    function setAddress(bytes32 key, address value)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        addressStorage[key] = value;
    }

    function setBool(bytes32 key, bool value)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        boolStorage[key] = value;
    }

    function deleteUint256Key(bytes32 key)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        delete uint256Storage[key];
    }

    function deleteBytes32Key(bytes32 key)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        delete bytes32Storage[key];
    }

    function deleteStringKey(bytes32 key)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        delete stringStorage[key];
    }

    function deleteAddressKey(bytes32 key)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        delete addressStorage[key];
    }

    function deleteBoolKey(bytes32 key)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        delete boolStorage[key];
    }

    function getUint256(bytes32 key) public view override returns (uint256) {
        return uint256Storage[key];
    }

    function getBytes32(bytes32 key) public view override returns (bytes32) {
        return bytes32Storage[key];
    }

    function getString(bytes32 key)
        public
        view
        override
        returns (string memory)
    {
        return stringStorage[key];
    }

    function getAddress(bytes32 key) public view override returns (address) {
        return addressStorage[key];
    }

    function getBool(bytes32 key) public view override returns (bool) {
        return boolStorage[key];
    }
}
