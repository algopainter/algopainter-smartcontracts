// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterStorage {
    function giveAccessToConfigurators(bytes32 role, address[] memory accounts)
        external;

    function setUint256(bytes32 key, uint256 value) external;

    function setBytes32(bytes32 key, bytes32 value) external;

    function setString(bytes32 key, string calldata value) external;

    function setAddress(bytes32 key, address value) external;

    function setBool(bytes32 key, bool value) external;

    function deleteUint256Key(bytes32 key) external;

    function deleteBytes32Key(bytes32 key) external;

    function deleteStringKey(bytes32 key) external;

    function deleteAddressKey(bytes32 key) external;

    function deleteBoolKey(bytes32 key) external;

    function getUint256(bytes32 key) external view returns (uint256);

    function getBytes32(bytes32 key) external view returns (bytes32);

    function getString(bytes32 key) external view returns (string memory);

    function getAddress(bytes32 key) external view returns (address);

    function getBool(bytes32 key) external view returns (bool);
}
