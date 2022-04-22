// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ISecurityHook {
  function onBan(
    address account,
    address contractAddress,
    string calldata reasonText
  ) external;

  function onUnBan(
    address account,
    address contractAddress
  ) external;
}