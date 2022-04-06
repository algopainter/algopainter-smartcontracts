// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAlgoPainterStorage.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";
import "./interfaces/IExternalNFTHook.sol";

contract AlgoPainterExternalNFTManager is AlgoPainterSimpleAccessControl {
    event NFTContractAdded(
        address contractAddress,
        uint256[] tokenIds,
        uint256 creatorRate,
        address owner
    );

    event NFTContractTokensAdded(
        address contractAddress,
        uint256[] tokenIds,
        address owner
    );

    IAlgoPainterStorage public proxyStorage;
    IAuctionRewardsRates public proxyRates;
    IAlgoPainterNFTCreators public proxyNftCreators;
    IExternalNFTHook public proxyExternalNFTHook;

    constructor(
        address storageAddress,
        address ratesAddress,
        address nftCreatorsAddress
    ) {
        setStorage(storageAddress);
        setRates(ratesAddress);
        setNFTCreators(nftCreatorsAddress);
    }

    function addInitialContracts(address[] memory adrs)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        for (uint256 i = 0; i < adrs.length; i++) {
            proxyStorage.setBool(keccak256(abi.encodePacked(adrs[i])), true);
        }
    }

    function setExternalNFTHook(address adr)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyExternalNFTHook = IExternalNFTHook(adr);
    }

    function setNFTCreators(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyNftCreators = IAlgoPainterNFTCreators(adr);
    }

    function setStorage(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyStorage = IAlgoPainterStorage(adr);
    }

    function setRates(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyRates = IAuctionRewardsRates(adr);
    }

    function registerNFTContract(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256 creatorRate
    ) public {
        bytes32 hashing = keccak256(abi.encodePacked(contractAddress));

        require(!proxyStorage.getBool(hashing), "CONTRACT_ALREADY_ADDED");

        proxyStorage.setBool(hashing, true);
        proxyStorage.setAddress(hashing, msg.sender);

        proxyRates.setCreatorRoyaltiesRate(
            bytes32(bytes20(contractAddress)),
            creatorRate
        );

        proxyNftCreators.setCreator(contractAddress, msg.sender);

        emit NFTContractAdded(
            contractAddress,
            tokenIds,
            creatorRate,
            msg.sender
        );

        if (address(proxyExternalNFTHook) != address(0)) {
            proxyExternalNFTHook.onNFTContractAdded(
                contractAddress,
                tokenIds,
                creatorRate,
                msg.sender
            );
        }
    }

    function registerTokens(
        address contractAddress,
        uint256[] calldata tokenIds
    ) public {
        bytes32 hashing = keccak256(abi.encodePacked(contractAddress));

        require(proxyStorage.getBool(hashing), "CONTRACT_NOT_ADDED");
        require(proxyStorage.getAddress(hashing) == msg.sender, "NOT_OWNER");

        emit NFTContractTokensAdded(contractAddress, tokenIds, msg.sender);

        if (address(proxyExternalNFTHook) != address(0)) {
            proxyExternalNFTHook.onNFTContractTokenIdsAdded(
                contractAddress,
                tokenIds,
                msg.sender
            );
        }
    }
}
