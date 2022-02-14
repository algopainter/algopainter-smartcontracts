// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterArtistCollection.sol";

contract AlgoPainterArtistCollection is
    IAlgoPainterArtistCollection,
    AlgoPainterSimpleAccessControl
{
    uint256 constant ONE_HUNDRED_PERCENT = 10**4;

    address[] allowedTokens;
    mapping(address => bool) allowedTokensMapping;

    Collection[] private collections;

    mapping(bytes32 => bool) collectionHashes;
    mapping(bytes32 => bool) collectionNames;

    uint16 public maxNFTs;
    uint16 public timePerBlock;
    uint256 public collectionPrice;
    uint256 public maxCollectionTime;
    address payable private devAddress;

    IAuctionRewardsRates public rewardsRates;

    constructor(
        address _rewardsRatesAddress,
        address _devAddress,
        uint16 _collectionPrice,
        uint256 _maxCollectionTime,
        uint16 _maxNFTs,
        address[] memory _allowedTokens
    ) {
        rewardsRates = IAuctionRewardsRates(_rewardsRatesAddress);
        devAddress = payable(_devAddress);
        maxNFTs = _maxNFTs;
        collectionPrice = _collectionPrice;
        maxCollectionTime = _maxCollectionTime;
        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }
    }

    function getAllowedTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](allowedTokens.length);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokensMapping[allowedTokens[i]])
                tokens[i] = allowedTokens[i];
        }

        return tokens;
    }

    function addAllowedToken(address token) public onlyRole(CONFIGURATOR_ROLE) {
        allowedTokens.push(token);
        allowedTokensMapping[token] = true;
    }

    function disableToken(address token) public onlyRole(CONFIGURATOR_ROLE) {
        allowedTokensMapping[token] = false;
    }

    function setMaxCollectionTimeFee(uint256 _maxCollectionTime)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        maxCollectionTime = _maxCollectionTime;
    }

    function setCollectionPrice(uint256 _collectionPrice)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        collectionPrice = _collectionPrice;
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        devAddress = payable(_devAddress);
    }

    function setAlgoPainterRewardsRatesAddress(address rewardsRatesAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        rewardsRates = IAuctionRewardsRates(rewardsRatesAddress);
    }

    function getDevAddress() public view returns (address) {
        return address(devAddress);
    }

    function hasCollection(uint256 collectionId) public view override {
        require(
            collections[collectionId].data.artist != address(0),
            "COLLECTION_NOT_FOUND"
        );
    }

    function getCollection(uint256 collectionId)
        public
        view
        override
        returns (
            bytes32 hash,
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            PriceType priceType,
            Price[] memory prices,
            uint16 paramsCount,
            uint16 nfts
        )
    {
        hasCollection(collectionId);
        Collection storage collection = collections[collectionId];
        hash = collection.hash;
        artist = collection.data.artist;
        walletAddress = collection.data.walletAddress;
        startDT = collection.data.startDT;
        endDT = collection.data.endDT;
        name = collection.data.name;
        creatorPercentage = collection.data.creatorPercentage;
        startingPrice = collection.data.startingPrice;
        tokenPrice = collection.data.tokenPrice;
        priceType = collection.data.priceType;
        paramsCount = collection.data.paramsCount;
        nfts = collection.data.nfts;

        Price[] memory auxPrices = new Price[](collection.pricesCount);

        for (uint256 i = 0; i < collection.pricesCount; i++) {
            auxPrices[i] = collection.PriceRange[i];
        }

        prices = auxPrices;
    }

    function getCollectionHash(
        CollectionData calldata collectionInput,
        Price[] memory priceRange
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    collectionInput.artist,
                    collectionInput.walletAddress,
                    collectionInput.startDT,
                    collectionInput.endDT,
                    collectionInput.name,
                    collectionInput.creatorPercentage,
                    collectionInput.startingPrice,
                    collectionInput.tokenPrice,
                    collectionInput.priceType,
                    abi.encode(priceRange),
                    collectionInput.paramsCount,
                    collectionInput.nfts
                )
            );
    }

    function createCollection(
        CollectionData calldata collectionInput,
        Price[] memory priceRange
    ) public payable returns (uint256) {
        require(
            allowedTokensMapping[collectionInput.tokenPrice],
            "TOKEN_UNAVAILABLE"
        );
        require(
            collectionInput.nfts > 0 && collectionInput.nfts <= maxNFTs,
            "NFT_AMOUNT_INVALID"
        );
        require(
            collectionInput.startDT > block.timestamp &&
                collectionInput.endDT > block.timestamp &&
                collectionInput.endDT > collectionInput.startDT,
            "TIME_RANGE_INVALID"
        );
        require(
            collectionInput.creatorPercentage <
                rewardsRates.getMaxCreatorRoyaltiesRate(),
            "CREATOR_RATE_TOO_MUCH"
        );

        require(collectionInput.startingPrice > 0, "MINT_COST_NOT_SET");

        if (collectionInput.priceType == PriceType.VARIABLE) {
            require(priceRange.length > 1, "PRICE_RANGE_NOT_SET");
            require(priceRange.length <= 20, "PRICE_RANGE_INVALID");
        }

        require(
            !collectionNames[collectionInput.name],
            "COLLECTION_NAME_NOT_UNIQUE"
        );

        bytes32 hashedCollection = getCollectionHash(
            collectionInput,
            priceRange
        );

        require(!collectionHashes[hashedCollection], "COLLECTION_NOT_UNIQUE");

        if (collectionPrice > 0) {
            require(msg.value >= collectionPrice, "REQUIRED_AMOUNT_NOT_SENT");
            devAddress.transfer(collectionPrice);
        }

        uint256 index = collections.length;

        Collection storage collection = collections[index];

        collection.index = index;
        collection.hash = hashedCollection;
        collection.data = collectionInput;
        collection.pricesCount = priceRange.length;

        for (uint256 i = 0; i < priceRange.length; i++) {
            collection.PriceRange[i] = priceRange[i];
        }

        //emit NewCollection(collections[index]);

        return index;
    }
}
