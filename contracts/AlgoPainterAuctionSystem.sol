// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

    address addressFee;
    address rewardsSystemAddress;
    uint256 auctionFeeRate;
    uint256 bidFeeRate;

    IAuctionHook auctionHooker;
    IAuctionRewardsRates rewardsRatesProvider;
    IAlgoPainterNFTCreators nftCreators;

    AuctionInfo[] auctionsInfo;
    mapping(address => mapping(uint256 => uint256)) auctions;

    IERC20[] allowedTokens;
    mapping(IERC20 => bool) allowedTokensMapping;

    mapping(uint256 => mapping(address => uint256)) pendingReturns;

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

    constructor(uint256 _emergencyTimeInterval) AlgoPainterContractBase(_emergencyTimeInterval) {
    }

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

    function setAuctionHook(
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

    function setRewardsRates(
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
        require(
            _auctionEndTime > getNow(),
            "INVALID_TIME_STAMP"
        );

        require(
            allowedTokensMapping[_tokenPriceAddress],
            "INVALID_TOKEN_PRICE_ADDRESS"
        );

        bool nftPIRSRate = rewardsRatesProvider.hasPIRSRateSetPerImage(_tokenAddress, _tokenId);

        require(nftPIRSRate,
            "PIRS_NOT_SET"
        );

        address creator = nftCreators.getCreator(_tokenAddress, _tokenId);

        require(
            creator != address(0),
            "CANNOT_CREATE_AUCTION_WITHOUT_NFT_CREATOR_SET"
        );

        transferNFT(
            msg.sender,
            address(this),
            _tokenAddress,
            _tokenId,
            _tokenType,
            true
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

        rewardsRatesProvider.setBidbackRate(auctions[_tokenAddress][_tokenId], _bidbackRate);

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
            "AUCTION_EXPIRED"
        );

        require(
            _amount > auctionInfo.highestBid,
            "LOW_BID"
        );

        require(
            _amount >= auctionInfo.minimumAmount,
            "LOW_BID_MINIMUM_AMOUNT"
        );

        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        (, uint256 feeAmount) = getBidAmountInfo(_amount);
        uint256 totalAmount = _amount.add(feeAmount);

        require(
            tokenPrice.transferFrom(msg.sender, address(this), totalAmount),
            "FAIL_TO_TRANSFER_BID_AMOUNT"
        );

        require(
            tokenPrice.transfer(addressFee, feeAmount),
            "FAIL_TO_TRANSFER_FEE_AMOUNT"
        );

        if (auctionInfo.highestBid != 0) {
            pendingReturns[_auctionId][auctionInfo.highestBidder] = pendingReturns[_auctionId][auctionInfo.highestBidder].add(auctionInfo.highestBid);

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

        require(amount > 0, "NOTHING_TO_WITHDRAW");

        pendingReturns[_auctionId][msg.sender] = 0;
        IERC20 tokenPrice = IERC20(auctionInfo.tokenPriceAddress);

        //Cannot transfer more than the contract holds
        if (amount > tokenPrice.balanceOf(address(this))) {
            amount = tokenPrice.balanceOf(address(this));
        }

        require(
            tokenPrice.transfer(msg.sender, amount),
            "FAIL_TO_WITHDRAW"
        );

        auctionHooker.onBidWithdraw(_auctionId, msg.sender, amount);

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
        uint256 rewardsRate = rewardsRatesProvider.getRewardsRate(_auctionId);
        uint256 creatorRate = rewardsRatesProvider.getCreatorRoyaltiesRate(_auctionId);

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
            "AUCTION_STILL_RUNNING"
        );

        require(
            auctionInfo.state == AuctionState.Running,
            "ALREADY_ENDED"
        );

        address winner = auctionInfo.highestBidder;
        uint256 bidAmount = auctionInfo.highestBid;

        (
            uint256 netAmount,
            uint256 feeAmount,
            uint256 creatorAmount,
            uint256 rewardsAmount
        ) = getAuctionAmountInfo(_auctionId, bidAmount);

        address creator = nftCreators.getCreator(auctionInfo.tokenAddress, auctionInfo.tokenId);

        require(
            tokenPrice.transfer(creator, creatorAmount),
            "FAIL_TO_PAY_CREATOR"
        );

        require(
            tokenPrice.transfer(rewardsSystemAddress, rewardsAmount),
            "FAIL_TO_PAY_REWARDS_SYSTEM"
        );

        require(
            tokenPrice.transfer(auctionInfo.beneficiary, netAmount),
            "FAIL_TO_PAY_AUCTION_WINNER"
        );

        if(tokenPrice.balanceOf(address(this)) < feeAmount)
            feeAmount = tokenPrice.balanceOf(address(this));

        require(
            tokenPrice.transfer(addressFee, feeAmount),
            "FAIL_TO_PAY_DEVADDRESS"
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
            rewardsAmount,
            netAmount
        );

        emit AuctionEnded(_auctionId, winner, bidAmount, feeAmount, netAmount);
    }

    function cancelAuction(uint256 _auctionId) public {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

        require(
            msg.sender == auctionInfo.beneficiary,
            "NOT_AUCTION_OWNER"
        );

        require(
            auctionInfo.state == AuctionState.Running,
            "AUCTION_IS_NOT_RUNNING"
        );

        require(
            auctionInfo.highestBid == 0,
            "ALREADY_HAS_BIDS"
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
                    "ERC721_NOT_APPROVED"
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
        inEmergencyUser()
    {
        AuctionInfo storage auctionInfo = auctionsInfo[_auctionId];

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

    function emergencyTransfer(address tokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        inEmergencyOwner()
    {
        address payable self = payable(address(this));

        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(self.balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 contractTokenBalance = token.balanceOf(self);
            if(contractTokenBalance > 0) {
                token.transferFrom(self, msg.sender, contractTokenBalance);
            }
        }
    }
}
