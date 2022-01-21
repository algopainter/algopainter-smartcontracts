// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./accessControl/AlgoPainterSimpleAccessControl.sol";

abstract contract AlgoPainterContractBase is AlgoPainterSimpleAccessControl {
    uint256 private emncyTimeItvl;
    uint256 private emncyEndsIn;
    bool private inEmncyState;
    uint256 private timeSafety;

    constructor(uint256 _emncyTimeItvl) {
        emncyTimeItvl = _emncyTimeItvl;
        timeSafety = 3;
    }

    function getTimeSafety() public view returns (uint256) {
        return timeSafety;
    }

    function setTimeSafety(uint256 _timeSafety)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        timeSafety = _timeSafety;
    }

    function getInEmncyState() public view returns (bool) {
        return inEmncyState;
    }

    function setInEmncyState(bool _inEmncyState)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        inEmncyState = _inEmncyState;
    }

    function setEmergencyState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(emncyEndsIn == 0, "CANNOT_EMERGENCY");

        emncyEndsIn = block.timestamp + emncyTimeItvl;
        inEmncyState = true;
    }

    modifier inEmergencyOwner() {
        require(
            inEmncyState && block.timestamp > (emncyEndsIn + timeSafety),
            "NOT_IN_EMERGENCY_MODE"
        );
        _;
    }

    modifier inEmergencyUser() {
        require(
            inEmncyState && (emncyEndsIn - timeSafety) > block.timestamp,
            "NOT_IN_EMERGENCY_MODE"
        );
        _;
    }
}
