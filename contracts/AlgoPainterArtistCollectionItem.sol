// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterArtistCollection.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";

contract AlgoPainterArtistCollectionItem is
    AlgoPainterSimpleAccessControl,
    ERC721
{
    uint256 constant ONE_HUNDRED_PERCENT = 10**4;

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public mintFee;
    uint256 public artistMintFee;
    address payable private devAddress;

    mapping(uint256 => uint256[]) collectionTokens;
    mapping(bytes32 => bool) collectionTokenUriUniquor;
    mapping(uint256 => mapping(bytes32 => uint256)) collectionTokenUniquor;

    IAlgoPainterNFTCreators public nftCreators;
    IAuctionRewardsRates public rewardsRates;
    IAlgoPainterArtistCollection public artistCollection;

    //event NewCollection(Collection item);
    event NewNFT(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        address mintedBy,
        string tokenURI
    );

    constructor(
        address nftCreatorsAddress,
        address _rewardsRatesAddress,
        address _artistCollectionAddress,
        address _auctionSystemAddress,
        address _devAddress,
        uint256 _mintFee,
        uint256 _artistMintFee
    ) ERC721("Algo Painter Artist Collection Item", "APPERI") {
        nftCreators = IAlgoPainterNFTCreators(nftCreatorsAddress);
        rewardsRates = IAuctionRewardsRates(_rewardsRatesAddress);
        artistCollection = IAlgoPainterArtistCollection(
            _artistCollectionAddress
        );
        devAddress = payable(_devAddress);
        mintFee = _mintFee;
        artistMintFee = _artistMintFee;

        setApprovalForAll(_auctionSystemAddress, true);
    }

    function setMintFee(uint256 _mintFee) public onlyRole(CONFIGURATOR_ROLE) {
        mintFee = _mintFee;
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        devAddress = payable(_devAddress);
    }

    function setAlgoPainterNFTCreators(address _nftCreators)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        nftCreators = IAlgoPainterNFTCreators(_nftCreators);
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

    function getTokenHashForAuction(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), tokenId));
    }

    function getMintValueWithoutFee(uint256 collectionId)
        private
        view
        returns (uint256)
    {
        artistCollection.hasCollection(collectionId);
        uint256 mintedCount = artistCollection
            .getCollectionTokens(collectionId)
            .length;
        uint256 mintValue = 0;

        (
            bytes32 hash,
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            IAlgoPainterArtistCollection.PriceType priceType,
            IAlgoPainterArtistCollection.Price[] memory prices,
            uint16 paramsCount,
            uint16 nfts
        ) = artistCollection.getCollection(collectionId);

        if (mintedCount == 0) return startingPrice;

        for (uint8 i = 0; i < prices.length; i++) {
            if (prices[i].from >= mintedCount && prices[i].to < mintedCount) {
                mintValue = prices[i].amount;
                break;
            }
        }

        require(mintValue > 0, "MINT_VALUE_INVALID");

        return mintValue;
    }

    function getCollectionTokens(uint256 collectionId)
        public
        view
        returns (uint256[] memory)
    {
        artistCollection.hasCollection(collectionId);
        return collectionTokens[collectionId];
    }

    function getRemainingTokens(uint256 collectionId)
        public
        view
        returns (uint256)
    {
        artistCollection.hasCollection(collectionId);

        (
            bytes32 hash,
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            IAlgoPainterArtistCollection.PriceType priceType,
            IAlgoPainterArtistCollection.Price[] memory prices,
            uint16 paramsCount,
            uint16 nfts
        ) = artistCollection.getCollection(collectionId);

        return nfts - collectionTokens[collectionId].length;
    }

    function getMintValue(uint256 collectionId) public view returns (uint256) {
        uint256 amount = getMintValueWithoutFee(collectionId);
        amount = (amount.mul(mintFee).div(ONE_HUNDRED_PERCENT)).add(amount);
        return amount;
    }

    function mint(
        string calldata name,
        uint256 collectionId,
        bytes32[] calldata params,
        string calldata tokenURI,
        uint256 expectedValue
    ) public payable {
        require(bytes(tokenURI).length > 0, "TOKENURI_REQUIRED");
        require(bytes(name).length > 0, "NAME_REQUIRED");

        artistCollection.hasCollection(collectionId);

        (
            bytes32 hash,
            address artist,
            address walletAddress,
            uint256 startDT,
            uint256 endDT,
            bytes32 name,
            uint16 creatorPercentage,
            uint256 startingPrice,
            address tokenPrice,
            IAlgoPainterArtistCollection.PriceType priceType,
            IAlgoPainterArtistCollection.Price[] memory prices,
            uint16 paramsCount,
            uint16 nfts
        ) = artistCollection.getCollection(collectionId);

        require(
            params.length == paramsCount,
            "PARAMS_NOT_MATCH"
        );

        bytes32 hashedParams = keccak256(abi.encodePacked(params));
        bytes32 hashedTokenUri = keccak256(abi.encodePacked(tokenURI));

        require(
            collectionTokenUriUniquor[hashedTokenUri] == false,
            "TOKEN_URI_INVALID"
        );
        require(
            collectionTokenUniquor[collectionId][hashedParams] == 0,
            "NOT_UNIQUE"
        );

        uint256 amount = getMintValue(collectionId);

        require(amount <= expectedValue, "PRICE_HAS_CHANGED");

        IERC20 token = IERC20(tokenPrice);
        uint256 artistAmount = getMintValueWithoutFee(collectionId);
        uint256 userFee = amount.sub(artistAmount);
        uint256 artistFee = artistAmount.mul(artistMintFee).div(
            ONE_HUNDRED_PERCENT
        );
        artistAmount = artistAmount.sub(artistFee);
        uint256 devAmount = userFee.add(artistFee);

        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "MINIMUM_ALLOWANCE_REQUIRED"
        );

        require(
            token.transferFrom(msg.sender, devAddress, devAmount),
            "FAIL_TRANSFER_DEV"
        );

        require(
            token.transferFrom(
                msg.sender,
                walletAddress,
                artistAmount
            ),
            "FAIL_TRANSFER_ARTIST"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        collectionTokenUriUniquor[hashedTokenUri] = true;
        collectionTokenUniquor[collectionId][hashedParams] = newItemId;
        collectionTokens[collectionId].push(newItemId);

        emit NewNFT(
            collectionId,
            newItemId,
            address(msg.sender),
            tokenURI
        );
    }
}
