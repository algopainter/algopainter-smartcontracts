// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./AlgoPainterContractBase.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterArtistCollection.sol";

contract AlgoPainterArtistCollection is
    IAlgoPainterArtistCollection,
    AlgoPainterContractBase
{
    using SafeMath for uint256;
    uint256 constant ONE_HUNDRED_PERCENT = 10**4;

    address[] allowedTokens;
    mapping(address => bool) allowedTokensMapping;

    Collection[] private collections;

    mapping(bytes32 => bool) collectionNames;

    uint16 public maxNFTs;
    uint256 public collectionPrice;
    IERC20 public collectionPriceToken;
    uint256 public maxCollectionTime;
    uint256 public minCollectionTime;
    address payable private devAddress;

    IAuctionRewardsRates public rewardsRates;

    constructor(
        uint256 _emergencyTime,
        address _rewardsRatesAddress,
        address _devAddress,
        uint256 _collectionPrice,
        address _collectionPriceToken,
        uint256 _maxCollectionTime,
        uint256 _minCollectionTime,
        uint16 _maxNFTs,
        address[] memory _allowedTokens
    ) AlgoPainterContractBase(_emergencyTime) {
        rewardsRates = IAuctionRewardsRates(_rewardsRatesAddress);
        devAddress = payable(_devAddress);
        maxNFTs = _maxNFTs;
        collectionPrice = _collectionPrice;
        collectionPriceToken = IERC20(_collectionPriceToken);
        maxCollectionTime = _maxCollectionTime;
        minCollectionTime = _minCollectionTime;
        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function addAllowedToken(address token) public onlyRole(CONFIGURATOR_ROLE) {
        allowedTokens.push(token);
        allowedTokensMapping[token] = true;
    }

    function disableToken(address token) public onlyRole(CONFIGURATOR_ROLE) {
        allowedTokensMapping[token] = false;
    }

    function setMinCollectionTime(uint256 _minCollectionTime)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        minCollectionTime = _minCollectionTime;
    }

    function setMaxCollectionTime(uint256 _maxCollectionTime)
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

    function setCollectionPriceToken(address _collectionPriceToken)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        collectionPriceToken = IERC20(_collectionPriceToken);
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        devAddress = payable(_devAddress);
    }

    function setMaxNFTs(uint16 nfts) public onlyRole(CONFIGURATOR_ROLE) {
        maxNFTs = nfts;
    }

    function setAlgoPainterRewardsRatesAddress(address rewardsRatesAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        rewardsRates = IAuctionRewardsRates(rewardsRatesAddress);
    }

    function hasCollection(uint256 collectionId) public view override {
        require(
            collections[collectionId].artist != address(0),
            "COLLECTION_NOT_FOUND"
        );
    }

    function getAllowedTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](allowedTokens.length);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokensMapping[allowedTokens[i]])
                tokens[i] = allowedTokens[i];
        }

        return tokens;
    }

    function getDevAddress() public view returns (address) {
        return address(devAddress);
    }

    function getCountCollections() public view override returns (uint256) {
        return collections.length;
    }

    function getCollection(uint256 collectionId)
        public
        view
        override
        returns (
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            PriceType priceType,
            uint256[] memory prices,
            uint16 nfts
        )
    {
        hasCollection(collectionId);
        Collection storage collection = collections[collectionId];
        artist = collection.artist;
        walletAddress = collection.walletAddress;
        startDT = collection.startDT;
        endDT = collection.endDT;
        name = collection.name;
        creatorPercentage = collection.creatorPercentage;
        nfts = collection.nfts;
        startingPrice = collection.startingPrice;
        tokenPrice = collection.tokenPrice;
        priceType = collection.priceType;
        prices = collection.prices;
    }

    function createCollection(
        address walletAddress,
        uint256[] calldata timeRange,
        bytes32 name,
        uint16 creatorPercentage,
        uint256 startingPrice,
        address tokenPrice,
        PriceType priceType,
        uint256[] calldata prices,
        uint16 nfts
    ) public payable {
        require(allowedTokensMapping[tokenPrice], "TOKEN_UNAVAILABLE");
        require(nfts > 0 && nfts <= maxNFTs, "NFT_AMOUNT_INVALID");
        require(timeRange[1] > timeRange[0], "TIME_RANGE_INVALID");
        require(
            timeRange[0] >=
                (block.timestamp + minCollectionTime).sub(getTimeSafety()),
            "START_TIME_RANGE_INVALID"
        );
        require(
            timeRange[1] <=
                (block.timestamp + maxCollectionTime).add(getTimeSafety()),
            "END_TIME_RANGE_INVALID"
        );
        require(
            creatorPercentage <= rewardsRates.getMaxCreatorRoyaltiesRate(),
            "CREATOR_RATE_TOO_MUCH"
        );
        require(startingPrice > 0, "MINT_COST_NOT_SET");

        if (priceType == PriceType.Variable) {
            require(prices.length > 1, "PRICE_RANGE_NOT_SET");
            require(prices.length <= 60, "PRICE_RANGE_INVALID");
            require(
                prices[prices.length - 2] == nfts,
                "NO_PRICE_RANGE_FOR_ALL"
            );
        }

        require(!collectionNames[name], "COLLECTION_NAME_NOT_UNIQUE");

        if (
            address(collectionPriceToken) != address(0) && collectionPrice > 0
        ) {
            require(
                collectionPriceToken.allowance(msg.sender, address(this)) >=
                    collectionPrice,
                "MINIMUM_ALLOWANCE_REQUIRED"
            );

            collectionPriceToken.transferFrom(
                msg.sender,
                devAddress,
                collectionPrice
            );
        }

        if (
            address(collectionPriceToken) == address(0) && collectionPrice > 0
        ) {
            require(msg.value >= collectionPrice, "AMOUNT_NOT_SENT");
            devAddress.transfer(collectionPrice);
        }

        collectionNames[name] = true;

        collections.push(
            Collection(
                address(msg.sender),
                walletAddress,
                timeRange[0],
                timeRange[1],
                name,
                creatorPercentage,
                startingPrice,
                tokenPrice,
                priceType,
                prices,
                nfts
            )
        );

        emit CollectionCreated(collections.length.sub(1));
    }
}
