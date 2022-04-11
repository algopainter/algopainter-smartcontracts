// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ISecurity {
    function isBannedByContract(address srcAddress, address account)
        external
        view
        returns (bool);

    function banByContract(
        address srcAddress,
        address account,
        string calldata reasonText
    ) external;

    function unBanByContract(address srcAddress, address account) external;

    function isBanned(address account) external view returns (bool);

    function ban(address account, string calldata reasonText) external;

    function unBan(address account) external;

    function getBanReason(address account)
        external
        view
        returns (string memory);
}
