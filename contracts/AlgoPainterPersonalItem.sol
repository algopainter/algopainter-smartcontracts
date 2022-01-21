// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./accessControl/AlgoPainterAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";

contract AlgoPainterPersonalItem is
    AlgoPainterAccessControl,
    ERC721,
    ERC721Burnable
{
    bytes32 private constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    using Counters for Counters.Counter;

    uint256 public maxTokens;
    uint256 public mintCost;
    uint256 public mintCostToken;

    Counters.Counter private _tokenIds;

    mapping(bytes32 => uint256) hashes;

    address payable public devAddress;
    IERC20 public mintToken;
    IAlgoPainterNFTCreators public nftCreators;
    IAuctionRewardsRates public algoPainterRewardsRates;

    event NewPersonalItem(
        uint256 indexed tokenId,
        address indexed owner,
        bytes32 indexed hash
    );

    constructor(
        address nftCreatorsAddress,
        address _rewardsRatesAddress,
        address _devAddress
    ) ERC721("Algo Painter Personal Item", "APPERI") {
        maxTokens = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        nftCreators = IAlgoPainterNFTCreators(nftCreatorsAddress);
        algoPainterRewardsRates = IAuctionRewardsRates(_rewardsRatesAddress);
        devAddress = payable(_devAddress);
        mintCost = 0.1 ether;
    }

    function setMaxTokens(uint256 _maxTokens)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxTokens = _maxTokens;
    }

    function setMintCostToken(uint256 _cost)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintCostToken = _cost;
    }

    function setMintToken(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintToken = IERC20(_address);
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        devAddress = payable(_devAddress);
    }

    function setMintCost(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintCost = amount;
    }

    function setAlgoPainterNFTCreators(address _nftCreators)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftCreators = IAlgoPainterNFTCreators(_nftCreators);
    }

    function setAlgoPainterRewardsRatesAddress(
        address algoPainterRewardsRatesAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        algoPainterRewardsRates = IAuctionRewardsRates(
            algoPainterRewardsRatesAddress
        );
    }

    function getName() public pure returns (string memory) {
        return "Personal Item by AlgoPainter";
    }

    function hashTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, _tokenURI));
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            return ecrecover(prefixedHash, v, r, s);
        }
    }

    function getTokenHashForAuction(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), tokenId));
    }

    function mint(
        string memory name,
        bytes32 imageHash,
        uint256 creatorPercentage,
        string memory tokenURI
    ) public payable returns (bytes32) {
        require(bytes(tokenURI).length > 0, "TOKENURI_REQUIRED");

        require(bytes(name).length > 0, "NAME_REQUIRED");

        bytes32 hashKey = keccak256(abi.encodePacked(name, imageHash));

        require(hashes[hashKey] == 0, "ALREADY_MINTED");

        require(totalSupply() + 1 < maxTokens, "MAXIMUM_AMOUNT_NFT_REACHED");

        if (address(mintToken) != address(0) && mintCostToken > 0) {
            require(
                mintToken.allowance(msg.sender, address(this)) >= mintCostToken,
                "MINIMUM_ALLOWANCE_REQUIRED"
            );

            mintToken.transferFrom(msg.sender, devAddress, mintCostToken);
        }

        if (mintCost > 0) {
            require(
                msg.value >= mintCost,
                "REQUIRED_AMOUNT_NOT_SENT"
            );

            devAddress.transfer(mintCost);
        }

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        hashes[hashKey] = newItemId;

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        bytes32 tokenCreatorRoyaltiesHash = getTokenHashForAuction(newItemId);

        algoPainterRewardsRates.setCreatorRoyaltiesRate(
            tokenCreatorRoyaltiesHash,
            creatorPercentage
        );

        nftCreators.setCreator(address(this), newItemId, msg.sender);

        emit NewPersonalItem(newItemId, msg.sender, hashKey);

        return hashKey;
    }

    function getTokenByHash(bytes32 hash) public view returns (uint256) {
        return hashes[hash];
    }

    function updateTokenURI(
        uint256 _tokenId,
        string calldata _tokenURI,
        bytes calldata _signature
    ) public {
        bytes32 hash = hashTokenURI(_tokenId, _tokenURI);
        address validator = recover(hash, _signature);
        address tokenOwner = ownerOf(_tokenId);

        require(tokenOwner == msg.sender, "INVALID_SENDER");
        require(validator != address(0), "INVALID_SIGNATURE");
        require(hasRole(VALIDATOR_ROLE, validator), "INVALID_VALIDATOR");

        _setTokenURI(_tokenId, _tokenURI);
    }
}
