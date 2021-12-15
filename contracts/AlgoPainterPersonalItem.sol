// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterAccessControl.sol";
import "./AlgoPainterToken.sol";

import "./IAlgoPainterItem.sol";
import "./AlgoPainterBidBackPirs.sol";

contract AlgoPainterPersonalItem is
    IAlgoPainterItem,
    AlgoPainterAccessControl,
    ERC721,
    ERC721Burnable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    uint256 maxTokens;
    uint256 mintAmount;

    Counters.Counter private _tokenIds;

    mapping(bytes32 => uint256) hashes;

    event NewPaint(
        uint256 indexed tokenId,
        address indexed owner,
        bytes32 indexed hash
    );

    address algoPainterBidBackPirsAddress;

    constructor() ERC721("Algo Painter Personal Item", "APPERI") {
        maxTokens = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function setAlgoPainterBidBackPirsAddress(address _algoPainterBidBackPirs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        algoPainterBidBackPirsAddress = _algoPainterBidBackPirs;
    }

    function getAlgoPainterBidBackPirsAddress()
        public
        view
        returns(address)
    {
        return algoPainterBidBackPirsAddress;
    }

    function getName(uint256 _algoPainterId)
        public
        pure
        override
        returns (string memory)
    {
        require(_algoPainterId == 3, "AlgoPainterPersonalItem:INVALID_ID");
        return "Personal Item by AlgoPainter";
    }

    function setMaximumTokens(uint256 tokens)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        maxTokens = tokens;
    }

    function getCurrentAmount(uint256 _algoPainterId, uint256 _supply)
        public
        view
        override
        returns (uint256)
    {
        require(_algoPainterId == 2, "AlgoPainterPersonalItem:INVALID_ID");
        return mintAmount;
    }

    function getTokenBytes32ConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (bytes32) {
        revert();
    }

    function getTokenUint256ConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (uint256) {
        revert();
    }

    function getTokenStringConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (string memory) {
        revert();
    }

    function getTokenBooleanConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (bool) {
        revert();
    }

    function getPIRS(uint256 _algoPainterId, uint256 _tokenId)
        public
        pure
        override
        returns (uint256)
    {
        revert();
    }

    function getCollectedTokenAmount(uint256 _algoPainterId)
        public
        view
        override
        returns (uint256)
    {
        revert();
    }

    function allowedTokens(uint256 _algoPainterId)
        public
        view
        override
        returns (address[] memory)
    {
        revert();
    }

    function getTokenAmountToBurn(uint256 _algoPainterId)
        public
        view
        override
        returns (uint256)
    {
        revert();
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
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(bytes32(bytes20(address(this))), tokenId)
        );
    }

    function mint(
        string memory name,
        bytes32 imageHash,
        uint256 creatorPercentage,
        string memory tokenURI
    ) public payable returns (bytes32) {
        require(
            bytes(tokenURI).length > 0,
            "AlgoPainterPersonalItem:TOKENURI_IS_REQUIRED"
        );

        require(
            bytes(name).length > 0,
            "AlgoPainterPersonalItem:NAME_IS_REQUIRED"
        );

        bytes32 hash = keccak256(abi.encodePacked(name, imageHash));

        require(
            hashes[hash] == 0,
            "AlgoPainterPersonalItem:ALREADY_REGISTERED"
        );

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        hashes[hash] = newItemId;

        AlgoPainterBidBackPirs algoPainterBidBackPirs = AlgoPainterBidBackPirs(
            algoPainterBidBackPirsAddress
        );

        bytes32 tokenCreatorRoyaltiesHash = keccak256(
            abi.encodePacked(bytes32(bytes20(address(this))), newItemId)
        );
        
        algoPainterBidBackPirs.setCreatorRoyaltiesRate(
            tokenCreatorRoyaltiesHash,
            creatorPercentage
        );

        emit NewPaint(newItemId, msg.sender, hash);

        return hash;
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

        require(
            tokenOwner == msg.sender,
            "AlgoPainterPersonalItem:INVALID_SENDER"
        );

        require(
            validator != address(0),
            "AlgoPainterPersonalItem:INVALID_SIGNATURE"
        );
        require(
            hasRole(VALIDATOR_ROLE, validator),
            "AlgoPainterPersonalItem:INVALID_VALIDATOR"
        );

        _setTokenURI(_tokenId, _tokenURI);
    }
}
