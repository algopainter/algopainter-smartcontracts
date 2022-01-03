// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";

contract AlgoPainterAuctionSystem is
    IAlgoPainterAuctionSystem,
    AlgoPainterSimpleAccessControl,
    ERC721Holder
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;
    bytes private DEFAULT_MESSAGE;

    address addressFee;
    address rewardsSystemAddress;
    uint256 auctionFeeRate;
    uint256 bidFeeRate;

    IAuctionHook private auctionHooker;
    IAuctionRewardsRates private rewardsRatesProvider;
    IAlgoPainterNFTCreators private nftCreators;

    mapping(uint256 => mapping(address => uint256)) private pendingReturns;

    AuctionInfo[] private auctionsInfo;
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
        IERC20 tokenPriceAddress
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

    event AuctionCancelled(uint256 auctionId, address indexed owner);

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

    event AuctionSystemSetup(
        address addressFee,
        address rewardsSystemAddress,
        uint256 auctionFeeRate,
        uint256 bidFeeRate,
        IERC20[] allowedTokens,
        address rewardsRatesProvider
    );

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getAddressFee() public view returns (address) {
        return addressFee;
    }

    function getRewardsSystemAddress() public view returns (address) {
        return rewardsSystemAddress;
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

    function getAuctionHook()
        public
        view
        returns (IAuctionHook)
    {
        return auctionHooker;
    }

    function getRewardsRates()
        public
        view
        returns (IAuctionRewardsRates)
    {
        return rewardsRatesProvider;
    }

    function setup(
        address _addressFee,
        address _rewardsSystemAddress,
        uint256 _auctionFeeRate,
        uint256 _bidFeeRate,
        IERC20[] memory _allowedTokens,
        address _rewardsRatesAddress
    ) public onlyRole(CONFIGURATOR_ROLE) {
        addressFee = _addressFee;
        rewardsSystemAddress = _rewardsSystemAddress;
        auctionFeeRate = _auctionFeeRate;
        bidFeeRate = _bidFeeRate;
        auctionHooker = IAuctionHook(_rewardsSystemAddress);
        rewardsRatesProvider = IAuctionRewardsRates(_rewardsRatesAddress);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = false;
        }

        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }

        emit AuctionSystemSetup(
            _addressFee,
            _rewardsSystemAddress,
            _auctionFeeRate,
            _bidFeeRate,
            _allowedTokens,
            _rewardsRatesAddress
        );
    }

    function setAlgoPainterNFTCreators(address _nftCreators)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftCreators = IAlgoPainterNFTCreators(_nftCreators);
    }

    function getAlgoPainterNFTCreators() public view returns (address) {
        return address(nftCreators);
    }

    function setFeeAddress(address _addressFee)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        addressFee = _addressFee;

        emit AuctionSystemSetup(
            addressFee,
            rewardsSystemAddress,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            address(rewardsRatesProvider)
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
            rewardsSystemAddress,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            address(rewardsRatesProvider)
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
            rewardsSystemAddress,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            address(rewardsRatesProvider)
        );
    }

    function setauctionHook(
        IAuctionHook _auctionHook
    ) public onlyRole(CONFIGURATOR_ROLE) {
        auctionHooker = _auctionHook;

        emit AuctionSystemSetup(
            addressFee,
            rewardsSystemAddress,
            auctionFeeRate,
            bidFeeRate,
            allowedTokens,
            address(rewardsRatesProvider)
        );
    }

    function setrewardsRates(
        IAuctionRewardsRates _rewardsRates
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsRatesProvider = _rewardsRates;
    }

    function createAuction(
        TokenType _tokenType,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _minimumAmount,
        uint256 _auctionEndTime,
        IERC20 _tokenPriceAddress,
        uint256 _bidbackRate
    ) public returns (uint256) {
        transferNFT(
            msg.sender,
            address(this),
            _tokenAddress,
            _tokenId,
            _tokenType,
            true
        );

        require(
            _auctionEndTime > getNow(),
            "AlgoPainterAuctionSystem:INVALID_TIME_STAMP"
        );

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "AlgoPainterAuctionSystem:INVALID_TOKEN_PRICE_ADDRESS"
        );

        auctionsInfo.push(
            AuctionInfo(
                msg.sender,
                _tokenType,
                _tokenAddress,
                _tokenId,
                _minimumAmount,
                _auctionEndTime,
                _tokenPriceAddress,
                address(0),
                0,
                AuctionState.Running
            )
        );

        auctions[_tokenAddress][_tokenId] = auctionsInfo.length.sub(1);

        auctionHooker.onAuctionCreated(
            auctions[_tokenAddress][_tokenId],
            msg.sender,
            _tokenAddress,
            _tokenId,
            address(_tokenPriceAddress)
        );

        emit AuctionCreated(
            auctions[_tokenAddress][_tokenId],
            msg.sender,
            _tokenAddress,
            _tokenId,
            _minimumAmount,
            _auctionEndTime,
            _tokenPriceAddress
        );

        rewardsRatesProvider.setBidbackRate(auctions[_tokenAddress][_tokenId], _bidbackRate);

        bytes32 creatorKey = nftCreators.getHashKey(_tokenAddress, _tokenId);
        address creator = nftCreators.getCreator(creatorKey);

        if (creator == address(0)) {
            nftCreators.setCreator(creatorKey, msg.sender);
        }

        return auctions[_tokenAddress][_tokenId];
    }

    function getAuctionLength() public view returns (uint256) {
        return auctionsInfo.length;
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
        override
        returns (
            address beneficiary,
            TokenType tokenType,
            address tokenAddress,
            uint256 tokenId,
            uint256 minimumAmount,
            uint256 auctionEndTime,
            IERC20 tokenPriceAddress,
            AuctionState state,
            address highestBidder,
            uint256 highestBid
        )
    {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        beneficiary = auctionInfo.beneficiary;
        tokenType = auctionInfo.tokenType;
        tokenAddress = auctionInfo.tokenAddress;
        tokenId = auctionInfo.tokenId;
        minimumAmount = auctionInfo.minimumAmount;
        auctionEndTime = auctionInfo.auctionEndTime;
        tokenPriceAddress = auctionInfo.tokenPriceAddress;
        state = auctionInfo.state;
        highestBidder = auctionInfo.highestBidder;
        highestBid = auctionInfo.highestBid;
    }

    function bid(uint256 _auctionId, uint256 _amount) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(
            getNow() <= auctionInfo.auctionEndTime,
            "AlgoPainterAuctionSystem:AUCTION_EXPIRED"
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

        (, uint256 feeAmount) = getBidAmountInfo(_amount);
        uint256 totalAmount = _amount.add(feeAmount);

        require(
            tokenPrice.transferFrom(msg.sender, address(this), totalAmount),
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
        auctionInfo.highestBid = _amount;
        auctionInfo.state = AuctionState.Running;

        auctionHooker.onBid(
            _auctionId,
            msg.sender,
            totalAmount,
            feeAmount,
            _amount
        );

        emit HighestBidIncreased(
            _auctionId,
            msg.sender,
            totalAmount,
            feeAmount,
            _amount
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
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        uint256 amount = pendingReturns[_auctionId][msg.sender];

        require(amount > 0, "AlgoPainterAuctionSystem:NOTHING_TO_WITHDRAW");

        pendingReturns[_auctionId][msg.sender] = 0;
        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        //Cannot transfer more than the contract holds
        if (amount > tokenPrice.balanceOf(address(this))) {
            amount = tokenPrice.balanceOf(address(this));
        }

        require(
            tokenPrice.transfer(msg.sender, amount),
            "AlgoPainterAuctionSystem:FAIL_TO_WITHDRAW"
        );

        emit PendingReturnsWithdrawn(_auctionId, msg.sender, amount);
    }

    function getFeeAndNetAmount(uint256 _amount, uint256 fee)
        public
        pure
        returns (uint256 netAmount, uint256 feeAmount)
    {
        feeAmount = _amount.mul(fee).div(ONE_HUNDRED_PERCENT);
        netAmount = _amount.sub(feeAmount);
    }

    function getAuctionAmountInfo(uint256 _auctionId, uint256 _amount)
        public
        view
        returns (
            uint256 netAmount,
            uint256 feeAmount,
            uint256 creatorAmount,
            uint256 rewardsAmount
        )
    {
        IAuctionRewardsRates rewardsTotalRatesProvider = IAuctionRewardsRates(
                rewardsRatesProvider
            );

        uint256 rewardsRate = rewardsTotalRatesProvider.getRewardsRate(_auctionId);
        uint256 creatorRate = rewardsTotalRatesProvider.getCreatorRoyaltiesRate(_auctionId);

        feeAmount = _amount.mul(auctionFeeRate).div(ONE_HUNDRED_PERCENT);
        creatorAmount = _amount.mul(creatorRate).div(ONE_HUNDRED_PERCENT);
        rewardsAmount = _amount.mul(rewardsRate).div(ONE_HUNDRED_PERCENT);
        netAmount = _amount.sub(feeAmount).sub(creatorAmount).sub(rewardsAmount);
    }

    function getBidAmountInfo(uint256 _amount)
        public
        view
        returns (uint256 netAmount, uint256 feeAmount)
    {
        (netAmount, feeAmount) = getFeeAndNetAmount(_amount, bidFeeRate);
    }

    function endAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];
        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        require(
            getNow() >= auctionInfo.auctionEndTime,
            "AlgoPainterAuctionSystem:AUCTION_STILL_RUNNING"
        );

        require(
            auctionInfo.state == AuctionState.Running,
            "AlgoPainterAuctionSystem:ALREADY_ENDED"
        );

        address winner = auctionInfo.highestBidder;
        uint256 bidAmount = auctionInfo.highestBid;

        (
            uint256 netAmount,
            uint256 feeAmount,
            uint256 creatorAmount,
            uint256 rewardsAmount
        ) = getAuctionAmountInfo(_auctionId, bidAmount);

        bytes32 creatorKey = nftCreators.getHashKey(auctionInfo.tokenAddress, auctionInfo.tokenId);
        address creator = nftCreators.getCreator(creatorKey);

        require(
            creator != address(0),
            "AlgoPainterRewardsDistributor:NFT_CREATOR_HAS_NOT_BEEN_FOUND"
        );

        require(
            tokenPrice.transfer(creator, creatorAmount),
            "AlgoPainterRewardsDistributor:UNABLE_TO_COMPLETE_TRANSFER_TO_CREATOR"
        );
        require(
            tokenPrice.transfer(rewardsSystemAddress, rewardsAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_PAY_REWARDS_SYSTEM"
        );

        require(
            tokenPrice.transfer(auctionInfo.beneficiary, netAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_PAY_BENEFICIARY"
        );

        if(tokenPrice.balanceOf(address(this)) < feeAmount)
            feeAmount = tokenPrice.balanceOf(address(this));

        require(
            tokenPrice.transfer(addressFee, feeAmount),
            "AlgoPainterAuctionSystem:FAIL_TO_PAY_DEVADDRESS"
        );

        transferNFT(
            address(this),
            winner,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            auctionInfo.tokenType,
            false
        );

        auctionInfo.state = AuctionState.Ended;

        auctionHooker.onAuctionEnded(
            _auctionId,
            winner,
            bidAmount,
            feeAmount,
            creatorAmount,
            rewardsAmount,
            netAmount
        );

        emit AuctionEnded(_auctionId, winner, bidAmount, feeAmount, netAmount);
    }

    function cancelAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(
            auctionInfo.state != AuctionState.Running,
            "AlgoPainterAuctionSystem:ALREADY_ENDED"
        );

        require(
            auctionInfo.highestBid == 0,
            "AlgoPainterAuctionSystem:ALREADY_HAS_BIDS"
        );

        require(
            msg.sender == auctionInfo.beneficiary,
            "AlgoPainterAuctionSystem:NOT_AUCTION_OWNER"
        );

        transferNFT(
            address(this),
            auctionInfo.beneficiary,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            auctionInfo.tokenType,
            false
        );

        auctionInfo.state = AuctionState.Canceled;

        auctionHooker.onAuctionCancelled(_auctionId, msg.sender);

        emit AuctionCancelled(_auctionId, msg.sender);
    }

    function transferNFT(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId,
        TokenType tokenType,
        bool checkApproved
    ) private {
        if (tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(tokenAddress);

            if (checkApproved) {
                require(
                    token.isApprovedForAll(from, to),
                    "AlgoPainterAuctionSystem:ERC721_NOT_APPROVED"
                );
            }

            token.safeTransferFrom(from, to, tokenId);
        } else {
            revert();
        }
    }

    //Chaos recovery methods
    function emergencyCancelAuction(uint256 _auctionId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        //@ASK - Should we transfer the NFT back to its owner since this is a emergency?
        transferNFT(
            address(this),
            auctionInfo.beneficiary,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            auctionInfo.tokenType,
            false
        );

        auctionInfo.state = AuctionState.Canceled;
        auctionHooker.onAuctionCancelled(_auctionId, msg.sender);

        emit AuctionCancelled(_auctionId, msg.sender);
    }
}
