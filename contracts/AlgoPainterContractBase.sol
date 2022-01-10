// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./accessControl/AlgoPainterSimpleAccessControl.sol";

abstract contract AlgoPainterContractBase is AlgoPainterSimpleAccessControl {
    uint256 private emncyTimeItvl;
    uint256 private emncyEndsIn;
    bool public inEmncyState;

    constructor(uint256 _emncyTimeItvl) {
        emncyTimeItvl = _emncyTimeItvl;
    }

    function setEmergencyState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            emncyEndsIn == 0,
            "CANNOT_EMERGENCY"
        );

        emncyEndsIn = block.timestamp + emncyTimeItvl;
        inEmncyState = true;
    }

    modifier inEmergencyOwner() {
        require(
            inEmncyState && block.timestamp > emncyEndsIn,
            "NOT_IN_EMERGENCY_MODE"
        );
        _;
    }

    modifier inEmergencyUser() {
        require(
            inEmncyState && emncyEndsIn > block.timestamp,
            "NOT_IN_EMERGENCY_MODE"
        );
        _;
    }
}
