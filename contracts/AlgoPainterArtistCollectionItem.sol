// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterArtistCollection.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";
import "./interfaces/IAlgoPainterArtistCollectionItemHook.sol";

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
    mapping(uint256 => mapping(uint256 => uint256)) collectionTokensToToken;
    mapping(uint256 => mapping(bytes32 => uint256)) collectionTokenUniquor;

    IAlgoPainterNFTCreators public nftCreators;
    IAuctionRewardsRates public rewardsRates;
    IAlgoPainterArtistCollection public artistCollection;
    IAlgoPainterArtistCollectionItemHook public proxyHook;

    //event NewCollection(Collection item);
    event NewCollectionNFT(
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

    function setHook(address _hook)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyHook = IAlgoPainterArtistCollectionItemHook(_hook);
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
        uint256 mintedCount = collectionTokens[collectionId].length.add(1);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 mintValue,
            ,
            IAlgoPainterArtistCollection.PriceType priceType,
            uint256[] memory prices,
            ,

        ) = artistCollection.getCollection(collectionId);

        if (
            mintedCount == 0 ||
            priceType == IAlgoPainterArtistCollection.PriceType.Fixed
        ) {
            return mintValue;
        } else {
            for (uint256 i = 0; i < prices.length; i += 3) {
                uint256 from = prices[i];
                uint256 to = prices[i.add(1)];
                uint256 amount = prices[i.add(2)];
                if (from >= mintedCount && to <= mintedCount) {
                    return amount;
                }
            }
        }

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

        (, , , , , , , , , , uint16 nfts, ) = artistCollection.getCollection(
            collectionId
        );

        return nfts - collectionTokens[collectionId].length;
    }

    function getMintValue(uint256 collectionId) public view returns (uint256) {
        uint256 amount = getMintValueWithoutFee(collectionId);
        amount = (amount.mul(mintFee).div(ONE_HUNDRED_PERCENT)).add(amount);
        return amount;
    }

    struct MintInfo {
        bytes32 nameHash;
        bytes32 hashedParams;
        bytes32 hashedTokenUri;
        IERC20 token;
        uint256 amount;
        uint256 artistAmount;
        uint256 userFee;
        uint256 artistFee;
        uint256 devAmount;
        uint256 newItemId;
        address walletAddress;
        uint256 startDT;
        uint256 endDT;
        address tokenPrice;
        uint16 creatorPercentage;
        uint16 nfts;
    }

    function mint(
        string calldata _name,
        uint256 collectionId,
        bytes32[] calldata params,
        string calldata tokenURI,
        uint256 expectedValue
    ) public payable {
        artistCollection.hasCollection(collectionId);

        MintInfo memory toMint;

        require(bytes(tokenURI).length > 0, "TOKENURI_REQUIRED");
        require(bytes(_name).length > 0, "NAME_REQUIRED");

        toMint.nameHash = keccak256(abi.encodePacked(collectionId, _name));

        require(
            collectionTokenUniquor[collectionId][toMint.nameHash] == 0,
            "NAME_NOT_UNIQUE"
        );

        (
            ,
            toMint.walletAddress,
            toMint.startDT,
            toMint.endDT,
            ,
            toMint.creatorPercentage,
            ,
            toMint.tokenPrice,
            ,
            ,
            toMint.nfts,

        ) = artistCollection.getCollection(collectionId);

        require(
            collectionTokens[collectionId].length < toMint.nfts,
            "COLLECTION_RETIRED"
        );

        require(
            block.timestamp > toMint.startDT && block.timestamp < toMint.endDT,
            "CANNOT_MINT"
        );

        toMint.hashedParams = keccak256(abi.encodePacked(params));
        toMint.hashedTokenUri = keccak256(abi.encodePacked(tokenURI));

        require(
            collectionTokenUniquor[collectionId][toMint.hashedTokenUri] == 0,
            "TOKEN_URI_INVALID"
        );
        require(
            collectionTokenUniquor[collectionId][toMint.hashedParams] == 0,
            "NOT_UNIQUE"
        );

        toMint.amount = getMintValue(collectionId);

        require(toMint.amount <= expectedValue, "PRICE_HAS_CHANGED");

        toMint.token = IERC20(toMint.tokenPrice);
        toMint.artistAmount = getMintValueWithoutFee(collectionId);
        toMint.userFee = toMint.amount.sub(toMint.artistAmount);
        toMint.artistFee = toMint.artistAmount.mul(artistMintFee).div(
            ONE_HUNDRED_PERCENT
        );
        toMint.artistAmount = toMint.artistAmount.sub(toMint.artistFee);
        toMint.devAmount = toMint.userFee.add(toMint.artistFee);

        require(
            toMint.token.allowance(msg.sender, address(this)) >= toMint.amount,
            "MINIMUM_ALLOWANCE_REQUIRED"
        );

        require(
            toMint.token.transferFrom(msg.sender, devAddress, toMint.devAmount),
            "FAIL_TRANSFER_DEV"
        );

        require(
            toMint.token.transferFrom(
                msg.sender,
                toMint.walletAddress,
                toMint.artistAmount
            ),
            "FAIL_TRANSFER_ARTIST"
        );

        _mintNFT(
            collectionId,
            [address(msg.sender), toMint.walletAddress],
            toMint.nameHash,
            toMint.hashedTokenUri,
            toMint.hashedParams,
            tokenURI,
            toMint.creatorPercentage
        );
    }

    function _mintNFT(
        uint256 collectionId,
        address[2] memory artistAccounts,
        bytes32 nameHash,
        bytes32 hashedTokenUri,
        bytes32 hashedParams,
        string calldata tokenURI,
        uint16 creatorPercentage
    ) private {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(artistAccounts[0], tokenId);
        _setTokenURI(tokenId, tokenURI);

        collectionTokenUniquor[collectionId][nameHash] = tokenId;
        collectionTokenUniquor[collectionId][hashedTokenUri] = tokenId;
        collectionTokenUniquor[collectionId][hashedParams] = tokenId;
        collectionTokens[collectionId].push(tokenId);
        collectionTokensToToken[collectionId][tokenId] = collectionTokens[
            collectionId
        ].length;

        bytes32 crHash = getTokenHashForAuction(tokenId);

        rewardsRates.setCreatorRoyaltiesRate(crHash, creatorPercentage);

        nftCreators.setCreator(address(this), tokenId, artistAccounts[1]);

        emit NewCollectionNFT(
            collectionId,
            tokenId,
            artistAccounts[0],
            tokenURI
        );

        if(address(proxyHook) != address(0)) {
            proxyHook.onCollectionItemMinted(collectionId, tokenId);
        }
    }

    function getTokenSenquentialNumber(uint256 _collectionId, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return collectionTokensToToken[_collectionId][_tokenId];
    }
}
