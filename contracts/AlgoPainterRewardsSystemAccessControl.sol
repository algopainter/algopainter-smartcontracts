// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AlgoPainterRewardsSystemAccessControl is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "AlgoPainterRewardsSystemAccessControl: INVALID_ROLE"
        );
        _;
    }
}
