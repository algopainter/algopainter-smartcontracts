// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";

contract AlgoPainterRewardsDistributor is
    AlgoPainterSimpleAccessControl,
    IAuctionHook
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;

    IERC20 stakeToken;
    address allowedSender;
    IAlgoPainterAuctionSystem auctionSystem;
    IAuctionRewardsRates rewardsRatesProvider;

    mapping(address => mapping(uint256 => mapping(address => bool)))
        private oldOwnersUsersMapping;
    mapping(uint256 => mapping(address => bool)) private auctionUsersWithBids;

    mapping(uint256 => uint256) private rewardsAmountMapping;

    mapping(uint256 => uint256) private totalBidbackStakes;
    mapping(uint256 => address[]) private bidbackUsers;
    mapping(uint256 => mapping(address => bool)) private bidbackUsersMapping;
    mapping(uint256 => mapping(address => uint256)) private bidbackStakes;
    mapping(uint256 => mapping(address => uint256)) private bidbackPercentages;

    mapping(uint256 => uint256) private totalPirsStakes;
    mapping(uint256 => address[]) private pirsUsers;
    mapping(uint256 => mapping(address => bool)) private pirsUsersMapping;
    mapping(uint256 => mapping(address => uint256)) private pirsStakes;
    mapping(uint256 => mapping(address => uint256)) private pirsPercentages;

    event BidbackStaked(
        uint256 auctionId,
        address account,
        uint256 stakeAmount
    );

    event BidbackUnstaked(
        uint256 auctionId,
        address account,
        uint256 stakeAmount
    );

    event BidbackClaimed(uint256 auctionId, address account, uint256 amount);

    event PIRSStaked(uint256 auctionId, address account, uint256 stakeAmount);

    event PIRSUnstaked(uint256 auctionId, address account, uint256 stakeAmount);

    event PIRSClaimed(uint256 auctionId, address account, uint256 amount);

    function setStakeToken(address _tokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakeToken = IERC20(_tokenAddress);
    }

    function getStakeToken() public view returns (address) {
        return address(stakeToken);
    }

    function setAllowedSender(address _allowedSender)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowedSender = _allowedSender;
    }

    function getAllowedSender() public view returns (address) {
        return allowedSender;
    }

    function setAuctionSystemAddress(address _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystem = IAlgoPainterAuctionSystem(_auctionSystemAddress);
    }

    function getAuctionSystemAddress()
        public
        view
        returns (IAlgoPainterAuctionSystem)
    {
        return auctionSystem;
    }

    function setRewardsRatesProviderAddress(
        address _rewardsRatesProviderAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsRatesProvider = IAuctionRewardsRates(
            _rewardsRatesProviderAddress
        );
    }

    function getRewardsRatesProviderAddress()
        public
        view
        returns (IAuctionRewardsRates)
    {
        return rewardsRatesProvider;
    }

    function getTotalBidbackStakes(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        return totalBidbackStakes[auctionId];
    }

    function getTotalPirsStakes(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        return totalPirsStakes[auctionId];
    }

    function getBidbackUsers(uint256 auctionId)
        public
        view
        returns (address[] memory)
    {
        return bidbackUsers[auctionId];
    }

    function getBidbackPercentages(uint256 auctionId)
        public
        view
        returns (address[] memory users, uint256[] memory percentages)
    {
        uint256[] memory amountsList = new uint256[](
            bidbackUsers[auctionId].length
        );

        for (uint256 i = 0; i < bidbackUsers[auctionId].length; i++) {
            address userAddress = bidbackUsers[auctionId][i];
            amountsList[i] = (bidbackPercentages[auctionId][userAddress]);
        }

        return (bidbackUsers[auctionId], amountsList);
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        address tokenPriceAddress
    ) external override {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsDistributor:INVALID_SENDER"
        );
    }

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external override {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsDistributor:INVALID_SENDER"
        );

        auctionUsersWithBids[auctionId][bidder] = true;
    }

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external override {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsDistributor:INVALID_SENDER"
        );

        removeUserFromBidback(auctionId, owner);
    }

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 creatorAmount,
        uint256 rewardsAmount,
        uint256 netAmount
    ) external override {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsDistributor:INVALID_SENDER"
        );

        (
            address beneficiary,
            ,
            address tokenAddress,
            uint256 tokenId,
            ,
            ,
            ,
            ,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        oldOwnersUsersMapping[tokenAddress][tokenId][beneficiary] = true;
        rewardsAmountMapping[auctionId] = rewardsAmount;
    }

    function onAuctionCancelled(uint256 auctionId, address owner)
        external
        override
    {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsDistributor:INVALID_SENDER"
        );
    }

    function removeUserFromBidback(uint256 auctionId, address user) private {
        bidbackUsersMapping[auctionId][user] = false;

        for (uint256 i = 0; i < bidbackUsers[auctionId].length; i++) {
            if (bidbackUsers[auctionId][i] == user) {
                delete bidbackUsers[auctionId][i];
                break;
            }
        }
    }

    function stakeBidback(uint256 auctionId, uint256 amount) external {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 auctionEndTime,
            ,
            IAlgoPainterAuctionSystem.AuctionState state,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        require(
            state == IAlgoPainterAuctionSystem.AuctionState.Running,
            "AlgoPainterRewardsDistributor:AUCTION_ENDED"
        );

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsDistributor:AUCTION_EXPIRED"
        );

        require(
            auctionUsersWithBids[auctionId][msg.sender],
            "AlgoPainterRewardsDistributor:USER_NOT_A_BIDDER"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_STAKE"
        );

        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].add(
            amount
        );
        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][
            msg.sender
        ].add(amount);

        if (!bidbackUsersMapping[auctionId][msg.sender]) {
            bidbackUsers[auctionId].push(msg.sender);
            bidbackUsersMapping[auctionId][msg.sender] = true;
        }

        computeBidbackPercentages(auctionId);

        emit BidbackStaked(
            auctionId,
            msg.sender,
            bidbackStakes[auctionId][msg.sender]
        );
    }

    function unstakeBidback(uint256 auctionId, uint256 amount) public {
        (, , , , , uint256 auctionEndTime, , , , ) = auctionSystem
            .getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsDistributor:AUCTION_ENDED"
        );

        require(
            amount <= bidbackStakes[auctionId][msg.sender],
            "AlgoPainterRewardsDistributor:UNSTAKE_AMOUNT_HIGHER_THAN_AVAILABLE"
        );

        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(
            stakeToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_UNSTAKE_AMOUNT"
        );

        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][
            msg.sender
        ].sub(amount);
        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].sub(
            amount
        );

        computeBidbackPercentages(auctionId);

        emit BidbackUnstaked(
            auctionId,
            msg.sender,
            bidbackStakes[auctionId][msg.sender]
        );
    }

    function stakePirs(uint256 auctionId, uint256 amount) external {
        (
            ,
            ,
            address tokenAddress,
            uint256 tokenId,
            ,
            uint256 auctionEndTime,
            ,
            ,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsDistributor:AUCTION_ENDED"
        );

        require(
            oldOwnersUsersMapping[tokenAddress][tokenId][msg.sender],
            "AlgoPainterRewardsDistributor:ACCOUNT_NOT_ELIGIBLE"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_STAKE"
        );

        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].add(amount);
        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender]
            .add(amount);

        if (!pirsUsersMapping[auctionId][msg.sender]) {
            pirsUsers[auctionId].push(msg.sender);
            pirsUsersMapping[auctionId][msg.sender] = true;
        }

        computePirsPercentages(auctionId);

        emit PIRSStaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionId][msg.sender]
        );
    }

    function unstakePirs(uint256 auctionId, uint256 amount) external {
        (, , , , , uint256 auctionEndTime, , , , ) = auctionSystem
            .getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsDistributor:AUCTION_ENDED"
        );

        require(
            amount <= pirsStakes[auctionId][msg.sender],
            "AlgoPainterRewardsDistributor:UNSTAKE_AMOUNT_HIGHER_THAN_AVAILABLE"
        );

        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(
            stakeToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_UNSTAKE_AMOUNT"
        );

        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender]
            .sub(amount);
        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].sub(amount);

        computePirsPercentages(auctionId);

        emit PIRSUnstaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionId][msg.sender]
        );
    }

    function computeBidbackPercentages(uint256 auctionId) private {
        for (uint256 i = 0; i < bidbackUsers[auctionId].length; i++) {
            address userAddress = bidbackUsers[auctionId][i];

            if (totalBidbackStakes[auctionId] == 0) {
                bidbackPercentages[auctionId][userAddress] = 0;
            } else {
                bidbackPercentages[auctionId][userAddress] = ONE_HUNDRED_PERCENT
                    .mul(bidbackStakes[auctionId][userAddress])
                    .div(totalBidbackStakes[auctionId]);
            }
        }
    }

    function computePirsPercentages(uint256 auctionId) private {
        for (uint256 i = 0; i < pirsUsers[auctionId].length; i++) {
            address userAddress = pirsUsers[auctionId][i];

            if (totalPirsStakes[auctionId] == 0) {
                pirsPercentages[auctionId][userAddress] = 0;
            } else {
                pirsPercentages[auctionId][userAddress] = ONE_HUNDRED_PERCENT
                    .mul(pirsStakes[auctionId][userAddress])
                    .div(totalPirsStakes[auctionId]);
            }
        }
    }

    function getRewardAmount(uint256 auctionId, uint256 rate)
        internal
        view
        returns (uint256)
    {
        uint256 totalRate = rewardsRatesProvider.getRewardsRate(auctionId);

        return
            totalRate == 0 ? 0 : ONE_HUNDRED_PERCENT.mul(rate).div(totalRate);
    }

    function claimBidback(uint256 auctionId) external {
        require(
            bidbackPercentages[auctionId][msg.sender] > 0,
            "AlgoPainterRewardsDistributor:NOTHING_TO_CLAIM"
        );

        (
            ,
            ,
            ,
            ,
            ,
            ,
            IERC20 tokenPriceAddress,
            IAlgoPainterAuctionSystem.AuctionState state,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        require(
            state != IAlgoPainterAuctionSystem.AuctionState.Running,
            "AlgoPainterRewardsDistributor:AUCTION_STILL_RUNNING"
        );

        uint256 bidbackRate = getRewardAmount(
            auctionId,
            rewardsRatesProvider.getBidbackRate(auctionId)
        );

        uint256 bidbackTotalEarnings = rewardsAmountMapping[auctionId]
            .mul(bidbackRate)
            .div(ONE_HUNDRED_PERCENT);

        uint256 bidbackEarnings = bidbackTotalEarnings
            .mul(bidbackPercentages[auctionId][msg.sender])
            .div(ONE_HUNDRED_PERCENT);

        bidbackPercentages[auctionId][msg.sender] = 0;

        IERC20 bidbackToken = IERC20(tokenPriceAddress);

        require(
            bidbackToken.transfer(msg.sender, bidbackEarnings),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_BIDBACK"
        );

        uint256 harvestAmount = bidbackStakes[auctionId][msg.sender];
        uint256 contractAmount = stakeToken.balanceOf(address(this));

        if (contractAmount < harvestAmount) harvestAmount = contractAmount;

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_BIDBACK_WITHDRAW"
        );

        bidbackStakes[auctionId][msg.sender] = 0;

        emit BidbackClaimed(auctionId, msg.sender, bidbackEarnings);
    }

    function claimPirs(uint256 auctionId) external {
        require(
            pirsPercentages[auctionId][msg.sender] > 0,
            "AlgoPainterRewardsDistributor:NOTHING_TO_CLAIM"
        );

        (
            ,
            ,
            ,
            ,
            ,
            ,
            IERC20 tokenPriceAddress,
            IAlgoPainterAuctionSystem.AuctionState state,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        require(
            state != IAlgoPainterAuctionSystem.AuctionState.Running,
            "AlgoPainterRewardsDistributor:AUCTION_STILL_RUNNING"
        );

        uint256 pirsRate = getRewardAmount(
            auctionId,
            rewardsRatesProvider.getPIRSRate(auctionId)
        );

        uint256 pirsTotalEarnings = rewardsAmountMapping[auctionId]
            .mul(pirsRate)
            .div(ONE_HUNDRED_PERCENT);

        uint256 pirsEarnings = pirsTotalEarnings
            .mul(pirsPercentages[auctionId][msg.sender])
            .div(ONE_HUNDRED_PERCENT);

        pirsPercentages[auctionId][msg.sender] = 0;

        IERC20 pirsToken = IERC20(tokenPriceAddress);

        require(
            pirsToken.transfer(msg.sender, pirsEarnings),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_PIRS"
        );

        uint256 harvestAmount = pirsStakes[auctionId][msg.sender];
        uint256 contractAmount = stakeToken.balanceOf(address(this));

        if (contractAmount < harvestAmount) harvestAmount = contractAmount;

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "AlgoPainterRewardsDistributor:FAIL_TO_TRANSFER_PIRS_STAKES_WITHDRAW"
        );

        emit PIRSClaimed(auctionId, msg.sender, pirsEarnings);
    }

    function emergencyTransfer(address tokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address payable self = payable(address(this));

        if (tokenAddress == address(0)) {
            msg.sender.transfer(self.balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 contractTokenBalance = token.balanceOf(self);
            if(contractTokenBalance > 0) {
                token.transferFrom(self, msg.sender, contractTokenBalance);
            }
        }
    }
}
