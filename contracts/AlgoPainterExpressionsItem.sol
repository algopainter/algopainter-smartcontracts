// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterAccessControl.sol";
import "./AlgoPainterToken.sol";

import "./IAlgoPainterItem.sol";

contract AlgoPainterExpressionsItem is
    IAlgoPainterItem,
    AlgoPainterAccessControl,
    ERC721
{
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 private constant TEN_PERCENT = 10**3;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(bytes32 => uint256) hashes;
    uint256 collectedAmount;

    mapping(uint256 => uint8[]) tokenConfigs;

    address payable devAddress;
    address payable artistAddress;
    uint256 serviceFee;

    event NewPaint(
        uint256 indexed tokenId,
        address indexed owner,
        bytes32 indexed hash
    );

    constructor(address payable _devAddress, address payable _artistAddress)
        ERC721("Algo Painter Expressions Item", "APEXPI")
    {
        devAddress = _devAddress;
        artistAddress = _artistAddress;
        serviceFee = 250;
    }

    function getName(uint256 _algoPainterId)
        public
        pure
        override
        returns (string memory)
    {
        require(_algoPainterId == 1, "AlgoPainterExpressionsItem:INVALID_ID");
        return "Expressions my ManWithNoName";
    }

    function setServiceFee(uint256 _serviceFee)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        serviceFee = _serviceFee;
    }

    function getServiceFee() public view returns (uint256) {
        return serviceFee;
    }

    function setArtirstAddress(address payable _artistAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        artistAddress = _artistAddress;
    }

    function getArtirstAddress() public view returns (address) {
        return artistAddress;
    }

    function getCurrentAmountWithoutFee(uint256 supply)
        public
        pure
        returns (uint256)
    {
        uint256 amount = 0;

        if (supply <= 300) {
            amount = 0.1 ether;
        } else if (supply <= 500) {
            amount = 0.2 ether;
        } else if (supply <= 600) {
            amount = 0.3 ether;
        } else if (supply <= 700) {
            amount = 0.4 ether;
        } else {
            amount = 0.5 ether;
        }

        return amount;
    }

    function getCurrentAmount(uint256 supply) public view returns (uint256) {
        uint256 amount = getCurrentAmountWithoutFee(supply);

        amount = amount.mul(getServiceFee()).div(ONE_HUNDRED_PERCENT).add(
            amount
        );
        return amount;
    }

    function getCurrentAmount(uint256 _algoPainterId, uint256 _supply)
        public
        view
        override
        returns (uint256)
    {
        require(_algoPainterId == 1, "AlgoPainterExpressionsItem:INVALID_ID");
        return getCurrentAmount(_supply);
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
        require(_algoPainterId == 1, "AlgoPainterExpressionsItem:INVALID_ID");

        return uint256(tokenConfigs[_tokenId][_parameter]);

        return 0;
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
        require(_algoPainterId == 1, "AlgoPainterExpressionsItem:INVALID_ID");
        return collectedAmount;
    }

    function allowedTokens(uint256 _algoPainterId)
        public
        view
        override
        returns (address[] memory)
    {
        require(_algoPainterId == 1, "AlgoPainterExpressionsItem:INVALID_ID");
        address[] memory addresses;

        return addresses;
    }

    function getTokenAmountToBurn(uint256 _algoPainterId)
        public
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function hashData(uint8[] memory _parameters)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_parameters));
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

    function mint(
        uint8[] calldata _parameters,
        uint256 _expectedAmount,
        string memory _tokenURI
    ) public payable returns (uint256) {
        bytes32 hash = hashData(_parameters);

        require(
            hashes[hash] == 0,
            "AlgoPainterExpressionsItem:ALREADY_REGISTERED"
        );
        require(totalSupply() < 750, "AlgoPainterExpressionsItem:IS_RETIRED");

        uint256 amount = getCurrentAmount(totalSupply());

        require(
            amount <= _expectedAmount,
            "AlgoPainterExpressionsItem:PRICE_HAS_CHANGED"
        );
        require(
            msg.value >= amount,
            "AlgoPainterExpressionsItem:INVALID_AMOUNT"
        );

        uint256 amountWithoutFee = getCurrentAmountWithoutFee(totalSupply());
        uint256 artistFee =
            amountWithoutFee.mul(TEN_PERCENT).div(ONE_HUNDRED_PERCENT);
        uint256 userFee = amount.sub(amountWithoutFee);
        uint256 aristAmount = amountWithoutFee.sub(artistFee);

        devAddress.transfer(userFee.add(artistFee));
        artistAddress.transfer(aristAmount);

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        tokenConfigs[newItemId] = _parameters;
        hashes[hash] = newItemId;

        emit NewPaint(newItemId, msg.sender, hash);

        return newItemId;
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
            "AlgoPainterExpressionsItem:INVALID_SENDER"
        );

        require(
            validator != address(0),
            "AlgoPainterExpressionsItem:INVALID_SIGNATURE"
        );
        require(
            hasRole(VALIDATOR_ROLE, validator),
            "AlgoPainterExpressionsItem:INVALID_VALIDATOR"
        );

        _setTokenURI(_tokenId, _tokenURI);
    }
}
