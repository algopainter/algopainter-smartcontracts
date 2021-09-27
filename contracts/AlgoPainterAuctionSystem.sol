// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterAuctionSystemAccessControl.sol";
import "./IAuctionSystemManager.sol";

contract AlgoPainterAuctionSystem is
    AlgoPainterAuctionSystemAccessControl,
    ERC1155Holder,
    ERC721Holder
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes private DEFAULT_MESSAGE;

    IAuctionSystemManager private auctionSystemManager;

    mapping(uint256 => mapping(address => uint256)) private pendingReturns;

    enum TokenType {ERC721, ERC1155}

    struct AuctionInfo {
        address beneficiary;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 minimumAmount;
        uint256 auctionEndTime;
        IERC20 tokenPriceAddress;
        uint256 bidBackFee;
        bool ended;
        address highestBidder;
        uint256 highestBid;
    }

    AuctionInfo[] private auctionInfo;
    mapping(address => mapping(uint256 => uint256)) private auctions;

    IERC20[] private allowedTokens;
    mapping(IERC20 => bool) private allowedTokensMapping;

    event AuctionCreated(
        uint256 indexed auctionId,
        address creator,
        address tokenAddress,
        uint256 tokenId,
        uint256 minimumAmount,
        uint256 auctionEndTime,
        IERC20 tokenPriceAddress,
        uint256 bidBackFee
    );

    event HighestBidIncreased(
        uint256 indexed auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    );

    event AuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    );

    event AuctionCancelled(
        uint256 auctionId,
        address indexed owner
    );

    event PendingReturnsIncreased(
        uint256 auctionId,
        address owner,
        uint256 amount
    );

    event PendingReturnsWithdrawn(
        uint256 auctionId,
        address owner,
        uint256 amount
    );

    address addressFee;
    uint256 auctionFeeRate;
    uint256 bidFeeRate;

    event AuctionSystemSetup(
        address addressFee,
        uint256 auctionFeeRate,
        uint256 bidFeeRate,
        IERC20[] allowedTokens,
        IAuctionSystemManager auctionSystemManager
    );

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getAddressFee() public view returns (address) {
        return addressFee;
    }

    function getAuctionFeeRate() public view returns (uint256) {
        return auctionFeeRate;
    }

    function getBidFeeRate() public view returns (uint256) {
        return bidFeeRate;
    }

    function getAllowedTokens() public view returns (IERC20[] memory) {
        return allowedTokens;
    }

    function getAuctionSystemManager() public view returns (IAuctionSystemManager) {
        return auctionSystemManager;
    }

    function setup(
        address _addressFee,
        uint256 _auctionFeeRate,
        uint256 _bidFeeRate,
        IERC20[] memory _allowedTokens,
        IAuctionSystemManager _auctionSystemManager
    ) public onlyRole(CONFIGURATOR_ROLE) {
        require(
            _auctionFeeRate <= ONE_HUNDRED_PERCENT,
            "AlgoPainterAuctionSystem:INVALID_AUCTION_FEE"
        );
        require(
            _bidFeeRate <= ONE_HUNDRED_PERCENT,
            "AlgoPainterAuctionSystem:INVALID_BID_FEE"
        );

        addressFee = _addressFee;
        auctionFeeRate = _auctionFeeRate;
        bidFeeRate = _bidFeeRate;
        auctionSystemManager = _auctionSystemManager;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = false;
        }

        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }

        emit AuctionSystemSetup(
            _addressFee,
            _auctionFeeRate,
            _bidFeeRate,
            _allowedTokens,
            _auctionSystemManager
        );
    }

    function setFeeAddress(address _addressFee)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        addressFee = _addressFee;

        emit AuctionSystemSetup(
            addressFee,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            auctionSystemManager
        );
    }

    function setupFees(uint256 _auctionFeeRate, uint256 _bidFeeRate)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        require(
            _auctionFeeRate <= ONE_HUNDRED_PERCENT,
            "AlgoPainterAuctionSystem:INVALID_AUCTION_FEE"
        );
        require(
            _bidFeeRate <= ONE_HUNDRED_PERCENT,
            "AlgoPainterAuctionSystem:INVALID_BID_FEE"
        );

        auctionFeeRate = _auctionFeeRate;
        bidFeeRate = _bidFeeRate;

        emit AuctionSystemSetup(
            addressFee,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            auctionSystemManager
        );
    }

    function addAllowedToken(IERC20 _allowedToken)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        allowedTokens.push(_allowedToken);
        allowedTokensMapping[_allowedToken] = true;

        emit AuctionSystemSetup(
            addressFee,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            auctionSystemManager
        );
    }

    function setAuctionSystemManager(IAuctionSystemManager _auctionSystemManager)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        auctionSystemManager = _auctionSystemManager;

        emit AuctionSystemSetup(
            addressFee,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            auctionSystemManager
        );
    }

    function createAuction(
        TokenType _tokenType,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _minimumAmount,
        uint256 _auctionEndTime,
        IERC20 _tokenPriceAddress,
        uint256 _bidBackFee
    ) public returns (uint256) {
        if (_tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(_tokenAddress);
            require(
                token.isApprovedForAll(msg.sender, address(this)),
                "AlgoPainterAuctionSystem:ERC721_NOT_APPROVED"
            );

            token.safeTransferFrom(msg.sender, address(this), _tokenId);
        } else {
            IERC1155 token = IERC1155(_tokenAddress);
            require(
                token.isApprovedForAll(msg.sender, address(this)),
                "AlgoPainterAuctionSystem:ERC1155_NOT_APPROVED"
            );

            token.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                1,
                DEFAULT_MESSAGE
            );
        }

        require(
            _auctionEndTime > getNow(),
            "AlgoPainterAuctionSystem:INVALID_TIME_STAMP"
        );

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "AlgoPainterAuctionSystem:INVALID_TOKEN_PRICE_ADDRESS"
        );

        require(
            _bidBackFee <= ONE_HUNDRED_PERCENT,
            "AlgoPainterAuctionSystem:INVALID_BID_BACK_PERCENTUAL"
        );

        auctionInfo.push(
            AuctionInfo(
                msg.sender,
                _tokenType,
                _tokenAddress,
                _tokenId,
                _minimumAmount,
                _auctionEndTime,
                _tokenPriceAddress,
                _bidBackFee,
                false,
                address(0),
                0
            )
        );

        auctions[_tokenAddress][_tokenId] = auctionInfo.length.sub(1);
        
        auctionSystemManager.onAuctionCreated(
            address(this),
            auctions[_tokenAddress][_tokenId],
            msg.sender
        );

        emit AuctionCreated(
            auctions[_tokenAddress][_tokenId],
            msg.sender,
            _tokenAddress,
            _tokenId,
            _minimumAmount,
            _auctionEndTime,
            _tokenPriceAddress,
            _bidBackFee
        );

        return auctions[_tokenAddress][_tokenId];
    }

    function getAuctionLength() public view returns (uint256) {
        return auctionInfo.length;
    }

    function getAuctionId(address _tokenAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return auctions[_tokenAddress][_tokenId];
    }

    function getAuctionInfo(uint256 _auctionId)
        public
        view
        returns (
            address beneficiary,
            TokenType tokenType,
            address tokenAddress,
            uint256 tokenId,
            uint256 minimumAmount,
            uint256 auctionEndTime,
            IERC20 tokenPriceAddress,
            uint256 bidBackFee,
            bool ended,
            address highestBidder,
            uint256 highestBid
        )
    {
        AuctionInfo storage auctionInfo = auctionInfo[_auctionId];

        beneficiary = auctionInfo.beneficiary;
        tokenType = auctionInfo.tokenType;
        tokenAddress = auctionInfo.tokenAddress;
        tokenId = auctionInfo.tokenId;
        minimumAmount = auctionInfo.minimumAmount;
        auctionEndTime = auctionInfo.auctionEndTime;
        tokenPriceAddress = auctionInfo.tokenPriceAddress;
        bidBackFee = auctionInfo.bidBackFee;
        ended = auctionInfo.ended;
        highestBidder = auctionInfo.highestBidder;
        highestBid = auctionInfo.highestBid;
    }

    function bid(uint256 _auctionId, uint256 _amount) public {
        AuctionInfo storage auctionInfo = auctionInfo[_auctionId];

        require(
            getNow() <= auctionInfo.auctionEndTime,
            "AlgoPainterAuctionSystem:AUCTION_ENDED"
        );

        require(
            _amount > auctionInfo.highestBid,
            "AlgoPainterAuctionSystem:LOW_BID"
        );

        require(
            _amount >= auctionInfo.minimumAmount,
            "AlgoPainterAuctionSystem:LOW_BID_MINIMUM_AMOUNT"
        );

        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        (uint256 netAmount, uint256 feeAmount) = getBidAmountInfo(_amount);

        require(
            tokenPrice.transferFrom(msg.sender, address(this), _amount),
            "AlgoPainterAuctionSystem:FAIL_TO_TRANSFER_BID_AMOUNT"
        );

        require(
            tokenPrice.transfer(addressFee, feeAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_TRANSFER_FEE_AMOUNT"
        );

        if (auctionInfo.highestBid != 0) {
            pendingReturns[_auctionId][
                auctionInfo.highestBidder
            ] = pendingReturns[_auctionId][auctionInfo.highestBidder].add(
                auctionInfo.highestBid
            );

            emit PendingReturnsIncreased(
                _auctionId,
                auctionInfo.highestBidder,
                pendingReturns[_auctionId][auctionInfo.highestBidder]
            );
        }

        auctionInfo.highestBidder = msg.sender;
        auctionInfo.highestBid = netAmount;

        auctionSystemManager.onBid(
            address(this),
            _auctionId,
            msg.sender,
            _amount,
            feeAmount,
            netAmount
        );

        emit HighestBidIncreased(
            _auctionId,
            msg.sender,
            _amount,
            feeAmount,
            netAmount
        );
    }

    function getClaimableAmount(uint256 _auctionId, address _address)
        public
        view
        returns (uint256)
    {
        return pendingReturns[_auctionId][_address];
    }

    function withdraw(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionInfo[_auctionId];
        uint256 amount = pendingReturns[_auctionId][msg.sender];

        if (amount > 0) {
            pendingReturns[_auctionId][msg.sender] = 0;
            IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

            require(
                tokenPrice.transfer(msg.sender, amount),
                "AlgoPainterAuctionSystem:FAIL_TO_WITHDRAW"
            );

            auctionSystemManager.onWithdraw(
                address(this),
                _auctionId,
                msg.sender,
                amount
            );

            emit PendingReturnsWithdrawn(
                _auctionId,
                msg.sender,
                amount
            );
        } else {
            revert("AlgoPainterAuctionSystem:NOTHING_TO_WITHDRAW");
        }
    }

    function getFeeAndNetAmount(uint256 _amount, uint256 fee)
        public
        pure
        returns (uint256 netAmount, uint256 feeAmount)
    {
        feeAmount = _amount.mul(fee).div(ONE_HUNDRED_PERCENT);
        netAmount = _amount.sub(feeAmount);
    }

    function getAuctionAmountInfo(uint256 _amount)
        public
        view
        returns (uint256 netAmount, uint256 feeAmount)
    {
        (netAmount, feeAmount) = getFeeAndNetAmount(_amount, auctionFeeRate);
    }

    function getBidAmountInfo(uint256 _amount)
        public
        view
        returns (uint256 netAmount, uint256 feeAmount)
    {
        (netAmount, feeAmount) = getFeeAndNetAmount(_amount, bidFeeRate);
    }

    function endAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionInfo[_auctionId];
        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        require(
            getNow() >= auctionInfo.auctionEndTime,
            "AlgoPainterAuctionSystem:NOT_YET_ENDED"
        );
        require(!auctionInfo.ended, "AlgoPainterAuctionSystem:ALREADY_ENDED");

        address winner = auctionInfo.highestBidder;
        uint256 bidAmount = auctionInfo.highestBid;
        (uint256 feeAmount, uint256 netAmount) =
            getAuctionAmountInfo(bidAmount);

        require(
            tokenPrice.transfer(auctionInfo.beneficiary, netAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_PAY_BENEFICIARY"
        );

        require(
            tokenPrice.transfer(addressFee, feeAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_PAY_DEVADDRESS"
        );

        if (auctionInfo.tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(auctionInfo.tokenAddress);
            token.safeTransferFrom(address(this), winner, auctionInfo.tokenId);
        } else {
            IERC1155 token = IERC1155(auctionInfo.tokenAddress);
            token.safeTransferFrom(
                address(this),
                winner,
                auctionInfo.tokenId,
                1,
                DEFAULT_MESSAGE
            );
        }

        auctionInfo.ended = true;

        auctionSystemManager.onAuctionEnded(
            address(this),
            _auctionId,
            winner,
            bidAmount,
            feeAmount,
            netAmount
        );

        emit AuctionEnded(_auctionId, winner, bidAmount, feeAmount, netAmount);
    }

    function cancelAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionInfo[_auctionId];

        require(!auctionInfo.ended, "AlgoPainterAuctionSystem:ALREADY_ENDED");

        require(
            auctionInfo.highestBid == 0,
            "AlgoPainterAuctionSystem:ALREADY_HAS_BIDS"
        );

        require(
            msg.sender == auctionInfo.beneficiary,
            "AlgoPainterAuctionSystem:NOT_AUCTION_OWNER"
        );
        
        if (auctionInfo.tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(auctionInfo.tokenAddress);
            token.safeTransferFrom(address(this), auctionInfo.beneficiary, auctionInfo.tokenId);
        } else {
            IERC1155 token = IERC1155(auctionInfo.tokenAddress);
            token.safeTransferFrom(
                address(this),
                auctionInfo.beneficiary,
                auctionInfo.tokenId,
                1,
                DEFAULT_MESSAGE
            );
        }

        auctionInfo.ended = true;

        auctionSystemManager.onAuctionCancelled(
            address(this),
            _auctionId,
            msg.sender
        );

        emit AuctionCancelled(_auctionId, msg.sender);
    }
}
