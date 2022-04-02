// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./AlgoPainterContractBase.sol";

contract AccessTesting is
    AlgoPainterContractBase
{
  string public data;

  constructor(uint256 _emncyTimeItvl) AlgoPainterContractBase(_emncyTimeItvl) {

  }

  function doSomething(string memory _data) 
    public 
    onlyRole(CONFIGURATOR_ROLE) 
  {
    data = _data;
  }

  function doSomethingAdmin(string memory _data) 
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    data = _data;
  }
}