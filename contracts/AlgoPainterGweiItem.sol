// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./accessControl/AlgoPainterAccessControl.sol";
import "./AlgoPainterToken.sol";

import "./interfaces/IAlgoPainterItem.sol";

contract AlgoPainterGweiItem is
    IAlgoPainterItem,
    AlgoPainterAccessControl,
    ERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => bool) whitelist;

    mapping(bytes32 => uint256) hashes;
    mapping(uint256 => bool) specialPlaces;
    mapping(uint256 => mapping(uint8 => bool)) allowedSpecialPlaces;
    uint256 collectedAmount;

    bool canSetSpecialPlaces;

    address payable owner;

    struct TokenConfig {
        uint8 inspiration;
        string text;
        bool useRandom;
        uint8 probability;
        uint8 place;
    }

    mapping(uint256 => TokenConfig) tokenConfigs;

    AlgoPainterToken algop;
    address payable devAddress;

    event NewPaint(
        uint256 indexed tokenId,
        address indexed owner,
        bytes32 indexed hash
    );

    constructor(AlgoPainterToken _algop, address payable _devAddress)
        ERC721("Algo Painter Gwei Item", "APGI")
    {
        owner = msg.sender;
        whitelist[owner] = true;
        canSetSpecialPlaces = true;
        algop = _algop;
        devAddress = _devAddress;
    }

    function getName(uint256 _algoPainterId)
        public
        pure
        override
        returns (string memory)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        return "Hashly Gwei";
    }

    function getCurrentAmount(uint256 supply) public pure returns (uint256) {
        if (supply <= 300) {
            return 300 ether;
        } else if (supply <= 500) {
            return 600 ether;
        } else if (supply <= 700) {
            return 1200 ether;
        } else if (supply <= 800) {
            return 2400 ether;
        } else if (supply <= 900) {
            return 4800 ether;
        } else if (supply <= 950) {
            return 9600 ether;
        } else if (supply <= 985) {
            return 19200 ether;
        } else {
            return 38400 ether;
        }
    }

    function getCurrentAmount(uint256 _algoPainterId, uint256 _supply)
        public
        pure
        override
        returns (uint256)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
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
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        TokenConfig storage config = tokenConfigs[_tokenId];

        if (_parameter == 0) return uint256(config.inspiration);
        if (_parameter == 3) return uint256(config.probability);
        if (_parameter == 4) return uint256(config.place);

        return 0;
    }

    function getTokenStringConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (string memory) {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        TokenConfig storage config = tokenConfigs[_tokenId];

        if (_parameter == 1) return config.text;

        return "";
    }

    function getTokenBooleanConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) public view override returns (bool) {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        TokenConfig storage config = tokenConfigs[_tokenId];

        if (_parameter == 2) return config.useRandom;

        return false;
    }

    function getPIRS(uint256 _algoPainterId, uint256 _tokenId)
        public
        pure
        override
        returns (uint256)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        return 500;
    }

    function getCollectedTokenAmount(uint256 _algoPainterId)
        public
        view
        override
        returns (uint256)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        return collectedAmount;
    }

    function allowedTokens(uint256 _algoPainterId)
        public
        view
        override
        returns (address[] memory)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        address[] memory addresses;
        addresses[0] = address(algop);

        return addresses;
    }

    function getTokenAmountToBurn(uint256 _algoPainterId)
        public
        view
        override
        returns (uint256)
    {
        require(_algoPainterId == 0, "AlgoPainterGweiItem:INVALID_ID");
        return getAmountToBurn();
    }

    function getAmountToBurn() public view returns (uint256) {
        return collectedAmount == 0 ? 0 : collectedAmount / 2;
    }

    function canMint(address _address, uint256 totalSupply)
        public
        view
        returns (bool)
    {
        return isInWhitelist(_address) || totalSupply >= 100;
    }

    function closeSpecialPlaces() public onlyRole(DEFAULT_ADMIN_ROLE) {
        canSetSpecialPlaces = false;
    }

    function setSpecialPlace(uint256 place)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            canSetSpecialPlaces,
            "AlgoPainterGweiItem:SPCIAL_PLACES_CLOSED"
        );
        specialPlaces[place] = true;
    }

    function manageWhitelist(address[] calldata _addresses, bool _flag)
        public
        onlyRole(WHITELIST_MANAGER_ROLE)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _flag;
        }
    }

    function isInWhitelist(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function hashData(
        uint8 inspiration,
        string memory text,
        bool useRandom,
        uint8 probability
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(inspiration, text, useRandom, probability)
            );
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
        uint8 _inspiration,
        string calldata _text,
        bool _useRandom,
        uint8 _probability,
        uint8 _place,
        uint256 _expectedAmount,
        string memory _tokenURI
    ) public payable returns (uint256) {
        require(
            canMint(msg.sender, totalSupply()),
            "AlgoPainterGweiItem:ONLY_WHITELISTED!"
        );

        bytes32 hash = hashData(_inspiration, _text, _useRandom, _probability);

        require(hashes[hash] == 0, "AlgoPainterGweiItem:ALREADY_REGISTERED");
        require(totalSupply() < 1000, "AlgoPainterGweiItem:GWEI_IS_RETIRED");

        uint256 amount = getCurrentAmount(totalSupply());

        require(
            algop.allowance(msg.sender, address(this)) >= amount,
            "AlgoPainterGweiItem:MINIMUM_ALLOWANCE_REQUIRED"
        );

        require(
            amount <= _expectedAmount,
            "AlgoPainterGweiItem:PRICE_HAS_CHANGED"
        );

        collectedAmount += amount;
        algop.transferFrom(msg.sender, devAddress, amount);

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        tokenConfigs[newItemId] = TokenConfig(
            _inspiration,
            _text,
            _useRandom,
            _probability,
            _place
        );
        hashes[hash] = newItemId;

        emit NewPaint(newItemId, msg.sender, hash);

        return newItemId;
    }

    function getTokenByHash(bytes32 hash) public view returns (uint256) {
        return hashes[hash];
    }

    function allowUpdateToNewPlace(uint256 _tokenId, uint8 _place)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            canSetSpecialPlaces,
            "AlgoPainterGweiItem:SPCIAL_PLACES_CLOSED"
        );

        allowedSpecialPlaces[_tokenId][_place] = true;
    }

    function canUpdateToNewPlace(uint256 _tokenId, uint8 _place)
        public
        view
        returns (bool)
    {
        return
            (specialPlaces[_place] && allowedSpecialPlaces[_tokenId][_place]) ||
            !specialPlaces[_place];
    }

    function updatePlace(uint256 _tokenId, uint8 _place) public {
        require(
            canUpdateToNewPlace(_tokenId, _place),
            "AlgoPainterGweiItem:FORBIDEN_PLACE!"
        );
        tokenConfigs[_tokenId].place = _place;
    }

    function updateTokenURI(
        uint256 _tokenId,
        string calldata _tokenURI,
        bytes calldata _signature
    ) public {
        bytes32 hash = hashTokenURI(_tokenId, _tokenURI);
        address validator = recover(hash, _signature);

        address tokenOwner = ownerOf(_tokenId);

        require(tokenOwner == msg.sender, "AlgoPainterGweiItem:INVALID_SENDER");

        require(
            validator != address(0),
            "AlgoPainterGweiItem:INVALID_SIGNATURE"
        );
        require(
            hasRole(VALIDATOR_ROLE, validator),
            "AlgoPainterGweiItem:INVALID_VALIDATOR"
        );

        _setTokenURI(_tokenId, _tokenURI);
    }
}
