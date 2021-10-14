// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AlgoPainterBidBackPirsAccessControl is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "AlgoPainterBidBackPirsAccessControl: INVALID_ROLE"
        );
        _;
    }
}
