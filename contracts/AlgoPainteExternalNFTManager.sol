// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAlgoPainterStorage.sol";
import "./interfaces/IAuctionRewardsRates.sol";

contract AlgoPainteExternalNFTManager is AlgoPainterSimpleAccessControl {
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

    address payable public devAddress;
    uint256 public price;
    IERC20 public priceToken;

    IAlgoPainterStorage public proxyStorage;
    IAuctionRewardsRates public proxyRates;

    constructor(address storageAddress, address ratesAddress) {
        setStorage(storageAddress);
        setRates(ratesAddress);
    }

    function setStorage(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyStorage = IAlgoPainterStorage(adr);
    }

    function setRates(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyRates = IAuctionRewardsRates(adr);
    }

    function setPrice(address adr, uint256 value)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        price = value;
        priceToken = IERC20(adr);
    }

    function setDevAddress(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        devAddress = payable(adr);
    }

    function getDevAddress() public view returns (address) {
        return address(devAddress);
    }

    function addNFTContract(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256 creatorRate
    ) public {
        bytes32 hashing = keccak256(abi.encodePacked(contractAddress));

        require(!proxyStorage.getBool(hashing), "CONTRACT_ALREADY_ADDED");

        if (address(priceToken) != address(0) && price > 0) {
            require(
                priceToken.allowance(msg.sender, address(this)) >= price,
                "MINIMUM_ALLOWANCE_REQUIRED"
            );

            priceToken.transferFrom(msg.sender, devAddress, price);
        }

        proxyStorage.setBool(hashing, true);
        proxyStorage.setAddress(hashing, msg.sender);

        proxyRates.setCreatorRoyaltiesRate(
            bytes32(bytes20(contractAddress)),
            creatorRate
        );

        emit NFTContractAdded(
            contractAddress,
            tokenIds,
            creatorRate,
            msg.sender
        );
    }

    function addNFTContractTokens(
        address contractAddress,
        uint256[] calldata tokenIds
    ) public {
        bytes32 hashing = keccak256(abi.encodePacked(contractAddress));

        require(proxyStorage.getBool(hashing), "CONTRACT_NOT_ADDED");
        require(proxyStorage.getAddress(hashing) == msg.sender, "NOT_OWNER");

        emit NFTContractTokensAdded(contractAddress, tokenIds, msg.sender);
    }

    function evaluateNFTContract(address contractAddress)
        public
        view
        returns (uint256 tokens, uint256[] memory ownerOf)
    {
        IERC721Enumerable contractInstance = IERC721Enumerable(contractAddress);

        tokens = contractInstance.balanceOf(msg.sender);

        if (tokens > 0) {
            ownerOf = new uint256[](tokens);

            for (uint256 i = 1; i <= tokens; i++) {
                ownerOf[i - 1] = contractInstance.tokenOfOwnerByIndex(
                    msg.sender,
                    i
                );
            }
        }
    }
}
