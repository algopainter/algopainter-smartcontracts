// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./interfaces/IExternalNFTHook.sol";
import "./accessControl/AlgoPainterSimpleAccessControl.sol";

contract AlgoPainterExternalNFTHook is
    IExternalNFTHook,
    AlgoPainterSimpleAccessControl
{
    bytes32 public constant HOOK_CALLER_ROLE = keccak256("HOOK_CALLER_ROLE");

    function onNFTContractAdded(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256 creatorRate,
        address owner
    ) public override onlyRole(HOOK_CALLER_ROLE) {}

    function onNFTContractTokenIdsAdded(
        address contractAddress,
        uint256[] memory tokenIds,
        address owner
    ) public override onlyRole(HOOK_CALLER_ROLE) {}
}
