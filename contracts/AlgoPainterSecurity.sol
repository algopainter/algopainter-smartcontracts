// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./interfaces/ISecurity.sol";
import "./interfaces/IAlgoPainterStorage.sol";
import "./interfaces/ISecurityHook.sol";
import "./accessControl/AlgoPainterSimpleAccessControl.sol";

contract AlgoPainterSecurity is ISecurity, AlgoPainterSimpleAccessControl {
    event BanEvent(
        address account,
        address sourceAddress,
        string reasonText
    );

    event UnBanEvent(
        address account,
        address sourceAddress
    );

    IAlgoPainterStorage public proxyStorage;
    ISecurityHook public proxySecurityHook;

    constructor(address _storageAddr) {
        setStorage(_storageAddr);
    }

    function setStorage(address _storageAddr)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyStorage = IAlgoPainterStorage(_storageAddr);
    }

    function setHook(address _hookAddr) public onlyRole(CONFIGURATOR_ROLE) {
        proxySecurityHook = ISecurityHook(_hookAddr);
    }

    function isBannedByContract(address srcAddress, address account)
        public
        view
        override
        returns (bool)
    {
        return
            proxyStorage.getBool(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        "banByContract",
                        srcAddress,
                        account
                    )
                )
            ) ||
            proxyStorage.getBool(
                keccak256(abi.encodePacked(address(this), "ban", account))
            );
    }

    function banByContract(
        address srcAddress,
        address account,
        string calldata reasonText
    ) public override onlyRole(CONFIGURATOR_ROLE) {
        proxyStorage.setBool(
            keccak256(
                abi.encodePacked(
                    address(this),
                    "banByContract",
                    srcAddress,
                    account
                )
            ),
            true
        );
        proxyStorage.setString(
            keccak256(abi.encodePacked(address(this), "reason", account)),
            reasonText
        );

        if (address(proxySecurityHook) != address(0)) {
            proxySecurityHook.onBan(account, srcAddress, reasonText);
        }

        emit BanEvent(account, srcAddress, reasonText);
    }

    function unBanByContract(address srcAddress, address account)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyStorage.setBool(
            keccak256(
                abi.encodePacked(
                    address(this),
                    "banByContract",
                    srcAddress,
                    account
                )
            ),
            false
        );
        proxyStorage.deleteStringKey(
            keccak256(abi.encodePacked(address(this), "reason", account))
        );

        if (address(proxySecurityHook) != address(0)) {
            proxySecurityHook.onUnBan(account, srcAddress);
        }

        emit UnBanEvent(account, srcAddress);
    }

    function isBanned(address account) public view override returns (bool) {
        return
            proxyStorage.getBool(
                keccak256(abi.encodePacked(address(this), "ban", account))
            );
    }

    function ban(address account, string calldata reasonText)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyStorage.setBool(
            keccak256(abi.encodePacked(address(this), "ban", account)),
            true
        );
        proxyStorage.setString(
            keccak256(abi.encodePacked(address(this), "reason", account)),
            reasonText
        );

        if (address(proxySecurityHook) != address(0)) {
            proxySecurityHook.onBan(account, address(0), reasonText);
        }

        emit BanEvent(account, address(0), reasonText);
    }

    function unBan(address account)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyStorage.setBool(
            keccak256(abi.encodePacked(address(this), "ban", account)),
            false
        );
        proxyStorage.deleteStringKey(
            keccak256(abi.encodePacked(address(this), "reason", account))
        );

        if (address(proxySecurityHook) != address(0)) {
            proxySecurityHook.onUnBan(account, address(0));
        }

        emit UnBanEvent(account, address(0));
    }

    function getBanReason(address account)
        public
        view
        override
        returns (string memory)
    {
        return
            proxyStorage.getString(
                keccak256(abi.encodePacked(address(this), "reason", account))
            );
    }
}
