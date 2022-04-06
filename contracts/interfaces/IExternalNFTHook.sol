// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IExternalNFTHook {
  function onNFTContractAdded(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 creatorRate,
    address owner
  ) external;

  function onNFTContractTokenIdsAdded(
    address contractAddress,
    uint256[] memory tokenIds,
    address owner
  ) external;
}