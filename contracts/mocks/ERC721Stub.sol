// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract ERC721Stub is ERC721
{
  constructor() ERC721("ERC721 Stub", "ERC721S") {}
}