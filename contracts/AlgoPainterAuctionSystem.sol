// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterContractBase.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";

contract AlgoPainterAuctionSystem is
    AlgoPainterContractBase,
    IAlgoPainterAuctionSystem,
    ERC721Holder
{
    using SafeMath for uint256;
    uint256 constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 constant MAX_INT = 2**256 - 1;

    address public rewardsDistributorAddress;
    address public devAddress;

    uint256 public auctionFeeRate;
    uint256 public bidFeeRate;

    AuctionInfo[] auctionsInfo;
    mapping(address => mapping(uint256 => uint256)) auctions;

    IERC20[] allowedTokens;
    mapping(IERC20 => bool) allowedTokensMapping;

    mapping(uint256 => mapping(address => uint256)) pendingReturns;

    IAuctionHook public proxyHook;
    IAuctionRewardsRates public proxyRates;
    IAlgoPainterNFTCreators public proxyCreators;

    event AuctionCreated(
        uint256 indexed auctionId,
        address creator,
        address tokenAddress,
        uint256 tokenId,
        uint256 minimumAmount,
        uint256 auctionEndTime,
        IERC20 tokenPriceAddress,
        uint256 bidbackRate,
        uint256 creatorRate,
        uint256 pirsRate
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

    constructor(
        uint256 _emergencyTimeInterval,
        address _devAddress,
        uint256 _auctionFeeRate,
        uint256 _bidFeeRate,
        IERC20[] memory _allowedTokens,
        address _hookAddress
    ) AlgoPainterContractBase(_emergencyTimeInterval) {
        setDevAddress(_devAddress);
        setAuctionFee(_auctionFeeRate);
        setBidFeeRate(_bidFeeRate);
        setHook(_hookAddress);

        allowedTokens = _allowedTokens;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedTokensMapping[allowedTokens[i]] = true;
        }
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getAllowedTokens() public view returns (IERC20[] memory) {
        return allowedTokens;
    }

    function getClaimableAmount(uint256 _auctionId, address _address)
        public
        view
        returns (uint256)
    {
        return pendingReturns[_auctionId][_address];
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
        tokenAddress = auctionInfo.tokenAddress;
        tokenId = auctionInfo.tokenId;
        minimumAmount = auctionInfo.minimumAmount;
        auctionEndTime = auctionInfo.auctionEndTime;
        tokenPriceAddress = auctionInfo.tokenPriceAddress;
        state = auctionInfo.state;
        highestBidder = auctionInfo.highestBidder;
        highestBid = auctionInfo.highestBid;
    }

    function setRewardsDistributorAddress(address _rewardsDistributorAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        rewardsDistributorAddress = _rewardsDistributorAddress;
    }

    function setHook(address _adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyHook = IAuctionHook(_adr);
    }

    function setRates(address _adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyRates = IAuctionRewardsRates(_adr);
    }

    function setDevAddress(address _devAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        devAddress = _devAddress;
    }

    function setAuctionFee(uint256 fee) public onlyRole(CONFIGURATOR_ROLE) {
        auctionFeeRate = fee;
    }

    function setBidFeeRate(uint256 fee) public onlyRole(CONFIGURATOR_ROLE) {
        bidFeeRate = fee;
    }

    function setCreators(address _adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyCreators = IAlgoPainterNFTCreators(_adr);
    }

    function addAllowedToken(IERC20 _allowedToken)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        allowedTokens.push(_allowedToken);
        allowedTokensMapping[_allowedToken] = true;
    }

    function disableToken(IERC20 _allowedToken)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        allowedTokensMapping[_allowedToken] = false;
    }

    function createAuction(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _minimumAmount,
        uint256 _auctionEndTime,
        IERC20 _tokenPriceAddress,
        uint256 _bidbackRate,
        uint256 _creatorRate,
        uint256 _pirsRate
    ) public {
        require(getInEmncyState() == false, "NOT_AVAILABLE");

        require(_auctionEndTime > getNow(), "INVALID_TIME_STAMP");

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "INVALID_TOKEN_PRICE_ADDRESS"
        );

        transferNFT(msg.sender, address(this), _tokenAddress, _tokenId, true);

        auctionsInfo.push(
            AuctionInfo(
                msg.sender,
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

        proxyHook.onAuctionCreated(
            auctions[_tokenAddress][_tokenId],
            msg.sender,
            _tokenAddress,
            _tokenId,
            _bidbackRate,
            _creatorRate,
            _pirsRate,
            address(_tokenPriceAddress),
            _minimumAmount
        );

        emit AuctionCreated(
            auctions[_tokenAddress][_tokenId],
            msg.sender,
            _tokenAddress,
            _tokenId,
            _minimumAmount,
            _auctionEndTime,
            _tokenPriceAddress,
            _bidbackRate,
            _creatorRate,
            _pirsRate
        );
    }

    function bid(uint256 _auctionId, uint256 _amount) public {
        require(getInEmncyState() == false, "NOT_AVAILABLE");

        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(
            getNow() <= (auctionInfo.auctionEndTime - getTimeSafety()),
            "AUCTION_EXPIRED"
        );

        require(_amount > auctionInfo.highestBid, "LOW_BID");

        require(_amount >= auctionInfo.minimumAmount, "LOW_BID_MINIMUM_AMOUNT");

        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        (, uint256 feeAmount) = getBidAmountInfo(_amount);
        uint256 totalAmount = _amount.add(feeAmount);

        require(
            tokenPrice.transferFrom(msg.sender, address(this), totalAmount),
            "FAIL_TO_TRANSFER_BID_AMOUNT"
        );

        require(
            tokenPrice.transfer(devAddress, feeAmount),
            "FAIL_TO_TRANSFER_FEE_AMOUNT"
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

        proxyHook.onBid(
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

    function withdraw(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        uint256 amount = pendingReturns[_auctionId][msg.sender];

        pendingReturns[_auctionId][msg.sender] = 0;

        require(amount > 0 && amount < MAX_INT, "NOTHING_TO_WITHDRAW");

        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        //Cannot transfer more than the contract holds
        if (amount > tokenPrice.balanceOf(address(this))) {
            amount = tokenPrice.balanceOf(address(this));
        }

        require(tokenPrice.transfer(msg.sender, amount), "FAIL_TO_WITHDRAW");

        proxyHook.onBidWithdraw(_auctionId, msg.sender, amount);

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
        uint256 rewardsRate = proxyRates.getRewardsRate(_auctionId);
        uint256 creatorRate = proxyRates.getCreatorRoyaltiesRate(_auctionId);

        feeAmount = _amount.mul(auctionFeeRate).div(ONE_HUNDRED_PERCENT);
        creatorAmount = _amount.mul(creatorRate).div(ONE_HUNDRED_PERCENT);
        rewardsAmount = _amount.mul(rewardsRate).div(ONE_HUNDRED_PERCENT);
        netAmount = _amount.sub(feeAmount).sub(creatorAmount).sub(
            rewardsAmount
        );
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

        require(auctionInfo.state == AuctionState.Running, "ALREADY_ENDED");

        auctionInfo.state = AuctionState.Ended;

        require(
            msg.sender == auctionInfo.beneficiary ||
                msg.sender == auctionInfo.highestBidder,
            "ONLY_WINNER_OR_SELLER_CAN_END_AUCTION"
        );

        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        require(
            getNow() >= (auctionInfo.auctionEndTime + getTimeSafety()),
            "AUCTION_STILL_RUNNING"
        );

        address winner = auctionInfo.highestBidder;
        uint256 bidAmount = auctionInfo.highestBid;

        (
            uint256 netAmount,
            uint256 feeAmount,
            uint256 creatorAmount,
            uint256 rewardsAmount
        ) = getAuctionAmountInfo(_auctionId, bidAmount);

        if (creatorAmount > 0) {
            address creator = proxyCreators.getCreator(
                auctionInfo.tokenAddress,
                auctionInfo.tokenId
            );

            require(creator != address(0), "CREATOR_NOT_SET");

            require(
                tokenPrice.transfer(creator, creatorAmount),
                "FAIL_PAY_CREATOR"
            );
        }

        require(
            tokenPrice.transfer(rewardsDistributorAddress, rewardsAmount),
            "FAIL_PAY_REWARDS_SYSTEM"
        );

        require(
            tokenPrice.transfer(auctionInfo.beneficiary, netAmount),
            "FAIL_PAY_AUCTION_WINNER"
        );

        if (tokenPrice.balanceOf(address(this)) < feeAmount)
            feeAmount = tokenPrice.balanceOf(address(this));

        require(
            tokenPrice.transfer(devAddress, feeAmount),
            "FAIL_PAY_DEVADDRESS"
        );

        transferNFT(
            address(this),
            winner,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            false
        );

        proxyHook.onAuctionEnded(
            _auctionId,
            winner,
            bidAmount,
            feeAmount,
            rewardsAmount,
            netAmount,
            creatorAmount
        );

        emit AuctionEnded(_auctionId, winner, bidAmount, feeAmount, netAmount);
    }

    function cancelAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(msg.sender == auctionInfo.beneficiary, "NOT_AUCTION_OWNER");

        require(
            auctionInfo.state == AuctionState.Running,
            "AUCTION_IS_NOT_RUNNING"
        );

        auctionInfo.state = AuctionState.Canceled;

        require(auctionInfo.highestBid == 0, "ALREADY_HAS_BIDS");

        transferNFT(
            address(this),
            auctionInfo.beneficiary,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            false
        );

        proxyHook.onAuctionCancelled(_auctionId, msg.sender);

        emit AuctionCancelled(_auctionId, msg.sender);
    }

    function transferNFT(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId,
        bool checkApproved
    ) private {
        IERC721 token = IERC721(tokenAddress);

        if (checkApproved) {
            require(token.isApprovedForAll(from, to), "ERC721_NOT_APPROVED");
        }

        token.safeTransferFrom(from, to, tokenId);
    }

    //Chaos recovery methods
    function emergencyCancelAuction(uint256 _auctionId) public inEmergencyUser {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(msg.sender == auctionInfo.beneficiary, "NOT_AUCTION_OWNER");

        require(
            auctionInfo.state == AuctionState.Running,
            "AUCTION_IS_NOT_RUNNING"
        );

        auctionInfo.state = AuctionState.Canceled;

        transferNFT(
            address(this),
            auctionInfo.beneficiary,
            auctionInfo.tokenAddress,
            auctionInfo.tokenId,
            false
        );

        proxyHook.onAuctionCancelled(_auctionId, msg.sender);

        emit AuctionCancelled(_auctionId, msg.sender);
    }

    function emergencyTransfer(address tokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        inEmergencyOwner
    {
        address payable self = payable(address(this));

        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(self.balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 contractTokenBalance = token.balanceOf(self);
            if (contractTokenBalance > 0) {
                token.transferFrom(self, msg.sender, contractTokenBalance);
            }
        }
    }
}
