// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AlgoPainterAccessControl is AccessControl {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant SNAPSHOT_MANAGER = keccak256("SNAPSHOT_MANAGER");
    bytes32 public constant PAUSE_MANAGER = keccak256("PAUSE_MANAGER");
    bytes32 public constant WHITELIST_MANAGER_ROLE =
        keccak256("WHITELIST_MANAGER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WHITELIST_MANAGER_ROLE, _msgSender());
        _setupRole(SNAPSHOT_MANAGER, _msgSender());
        _setupRole(PAUSE_MANAGER, _msgSender());
    }

    modifier onlyRole(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "AlgoPainterAccessControl: INVALID_ROLE"
        );
        _;
    }
}
