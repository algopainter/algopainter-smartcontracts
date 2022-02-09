// // SPDX-License-Identifier: MIT
// pragma solidity ^0.7.4;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

// import "./accessControl/AlgoPainterAccessControl.sol";
// import "./interfaces/IAuctionRewardsRates.sol";
// import "./interfaces/IAlgoPainterNFTCreators.sol";

// contract AlgoPainterPersonalItem is
//     AlgoPainterAccessControl,
//     ERC721,
//     ERC721Burnable
// {
//     bytes32 private constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

//     using SafeMath for uint256;
//     using Counters for Counters.Counter;

//     Counters.Counter private _tokenIds;

//     enum PriceType {
//         FIXED,
//         VARIABLE
//     }

//     struct Price {
//         uint256 from;
//         uint256 to;
//         uint256 amount;
//     }

//     struct Collection {
//         uint256 index;
//         bytes32 hash;
//         address artist;
//         address walletAddress;
//         bytes32 name;
//         uint8 creatorPercentage;
//         uint256 startingPrice;
//         PriceType priceType;
//         Price[] priceRange;
//         uint256 nfts;
//     }

//     Collection[] public collections;

//     mapping(bytes32 => uint256) hashes;
//     mapping(uint256 => uint256) mintedByCollection;
//     mapping(uint256 => mapping(uint256 => uint256)) tokenToIterator;

//     uint16 public maxNFTs;
//     uint16 public timePerBlock;
//     address payable public devAddress;
//     IAlgoPainterNFTCreators public nftCreators;
//     IAuctionRewardsRates public algoPainterRewardsRates;

//     event NewCollectionItem(
//         uint256 indexed tokenId,
//         address indexed owner,
//         bytes32 indexed hash
//     );

//     constructor(
//         address nftCreatorsAddress,
//         address _rewardsRatesAddress,
//         address _devAddress,
//         uint16 _timePerBlock,
//         uint16 _maxNFTs
//     ) ERC721("Algo Painter Artist Collection Item", "APPERI") {
//         nftCreators = IAlgoPainterNFTCreators(nftCreatorsAddress);
//         algoPainterRewardsRates = IAuctionRewardsRates(_rewardsRatesAddress);
//         devAddress = payable(_devAddress);
//         timePerBlock = _timePerBlock;
//         maxNFTs = _maxNFTs;
//     }

//     function setDevAddress(address _devAddress)
//         public
//         onlyRole(CONFIGURATOR_ROLE)
//     {
//         devAddress = payable(_devAddress);
//     }

//     function setTimePerBlock(uint8 _timePerBlock)
//         public
//         onlyRole(CONFIGURATOR_ROLE)
//     {
//         timePerBlock = _timePerBlock;
//     }

//     function setAlgoPainterNFTCreators(address _nftCreators)
//         public
//         onlyRole(CONFIGURATOR_ROLE)
//     {
//         nftCreators = IAlgoPainterNFTCreators(_nftCreators);
//     }

//     function setAlgoPainterRewardsRatesAddress(
//         address algoPainterRewardsRatesAddress
//     ) public onlyRole(CONFIGURATOR_ROLE) {
//         algoPainterRewardsRates = IAuctionRewardsRates(
//             algoPainterRewardsRatesAddress
//         );
//     }

//     function hashTokenURI(uint256 _tokenId, string memory _tokenURI)
//         public
//         pure
//         returns (bytes32)
//     {
//         return keccak256(abi.encodePacked(_tokenId, _tokenURI));
//     }

//     function getTokenHashForAuction(uint256 tokenId)
//         public
//         view
//         returns (bytes32)
//     {
//         return keccak256(abi.encodePacked(address(this), tokenId));
//     }

//     function getCollectionHash(
//         bytes32 name,
//         uint8 creatorPercentage,
//         address walletAddress,
//         uint256 startDT,
//         uint256 endDT,
//         uint256 startingPrice,
//         PriceType priceType,
//         Price[] priceRange,
//         uint256 nfts
//     ) public view returns (bytes32) {
//         return
//             keccak256(
//                 abi.encodePacked(
//                     address(msg.sender),
//                     walletAddress,
//                     name,
//                     creatorPercentage,
//                     startingPrice,
//                     priceType,
//                     priceRange,
//                     nfts
//                 )
//             );
//     }

//     function createCollection(
//         bytes32 name,
//         uint8 creatorPercentage,
//         address walletAddress,
//         uint256 startDT,
//         uint256 endDT,
//         uint256 startingPrice,
//         PriceType priceType,
//         Price[] priceRange,
//         uint256 nfts
//     ) public {
//         require(nfts > 0 && nfts < maxNFTs, "NFT_AMOUNT_HIGHER_ZERO");
//         require(startDT > block.timestamp, "START_HIGHER_CURRENT_TIME");
//         require(endDT > block.timestamp, "END_HIGHER_CURRENT_TIME");
//         require(endDT > startDT, "END_HIGHER_START");
//         require(creatorPercentage < 3000, "CREATOR_RATE_TOO_MUCH");

//         if (priceType == PriceType.VARIABLE) {
//             require(priceRange.length > 1, "PRICE_RANGE_NOT_SET");
//         }

//         uint256 index = collections.length;
//         bytes32 hash = getCollectionHash(
//             name,
//             creatorPercentage,
//             walletAddress,
//             startDT,
//             endDT,
//             startingPrice,
//             priceType,
//             priceRange,
//             nfts
//         );

//         collections.push(
//             Collection(
//                 index,
//                 hash,
//                 address(msg.sender),
//                 walletAddress,
//                 name,
//                 creatorPercentage,
//                 startingPrice,
//                 priceType,
//                 priceRange,
//                 nfts
//             )
//         );
//     }

//     function mint(
//         string memory name,
//         bytes32 collectionHash,
//         bytes32 imageHash,
//         string memory tokenURI
//     ) public payable returns (bytes32) {
//         require(bytes(tokenURI).length > 0, "TOKENURI_REQUIRED");

//         require(bytes(name).length > 0, "NAME_REQUIRED");

//         bytes32 hashKey = keccak256(abi.encodePacked(name, imageHash));

//         require(hashes[hashKey] == 0, "ALREADY_MINTED");

//         require(totalSupply() + 1 < maxTokens, "MAXIMUM_AMOUNT_NFT_REACHED");

//         if (address(mintToken) != address(0) && mintCostToken > 0) {
//             require(
//                 mintToken.allowance(msg.sender, address(this)) >= mintCostToken,
//                 "MINIMUM_ALLOWANCE_REQUIRED"
//             );

//             mintToken.transferFrom(msg.sender, devAddress, mintCostToken);
//         }

//         if (mintCost > 0) {
//             require(msg.value >= mintCost, "REQUIRED_AMOUNT_NOT_SENT");

//             devAddress.transfer(mintCost);
//         }

//         _tokenIds.increment();

//         uint256 newItemId = _tokenIds.current();

//         hashes[hashKey] = newItemId;

//         _mint(msg.sender, newItemId);
//         _setTokenURI(newItemId, tokenURI);

//         bytes32 tokenCreatorRoyaltiesHash = getTokenHashForAuction(newItemId);

//         algoPainterRewardsRates.setCreatorRoyaltiesRate(
//             tokenCreatorRoyaltiesHash,
//             creatorPercentage
//         );

//         nftCreators.setCreator(address(this), newItemId, msg.sender);

//         emit NewPersonalItem(newItemId, msg.sender, hashKey);

//         return hashKey;
//     }

//     function getTokenByHash(bytes32 hash) public view returns (uint256) {
//         return hashes[hash];
//     }
// }
