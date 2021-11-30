// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterRewardsSystemAccessControl.sol";
import "./AlgoPainterAuctionSystem.sol";
import "./IAuctionSystemManager.sol";
import "./IAuctionRewardsRatesProvider.sol";
import "./IAuctionRewardsTotalRatesProvider.sol";

contract AlgoPainterRewardsSystem is 
    AlgoPainterRewardsSystemAccessControl,
    IAuctionSystemManager
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;

    address allowedSender;
    IERC20 rewardsTokenAddress;
    AlgoPainterAuctionSystem auctionSystemAddress;
    IAuctionRewardsRatesProvider rewardsRatesProviderAddress;
    IAuctionRewardsTotalRatesProvider rewardsTotalRatesProviderAddress;

    mapping(address => mapping(uint256 => mapping(address => bool))) private oldOwnersUsersMapping;
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

    event BidbackClaimed(
        uint256 auctionId,
        address account,
        uint256 amount
    );

    event PIRSStaked(
        uint256 auctionId,
        address account,
        uint256 stakeAmount
    );

    event PIRSUnstaked(
        uint256 auctionId,
        address account,
        uint256 stakeAmount
    );

    event PIRSClaimed(
        uint256 auctionId,
        address account,
        uint256 amount
    );

    function setAllowedSender(address _allowedSender)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowedSender = _allowedSender;
    }

    function getAllowedSender() public view returns (address) {
        return allowedSender;
    }

    function setRewardsTokenAddress(IERC20 _rewardsTokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardsTokenAddress = _rewardsTokenAddress;
    }

    function getRewardsTokenAddress() public view returns (IERC20) {
        return rewardsTokenAddress;
    }

    function setAuctionSystemAddress(AlgoPainterAuctionSystem _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystemAddress = _auctionSystemAddress;
    }

    function getAuctionSystemAddress() public view returns (AlgoPainterAuctionSystem) {
        return auctionSystemAddress;
    }

    function setRewardsRatesProviderAddress(IAuctionRewardsRatesProvider _rewardsRatesProviderAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardsRatesProviderAddress = _rewardsRatesProviderAddress;
    }

    function getRewardsRatesProviderAddress() public view returns (IAuctionRewardsRatesProvider) {
        return rewardsRatesProviderAddress;
    }

    function setRewardsTotalRatesProviderAddress(IAuctionRewardsTotalRatesProvider _rewardsTotalRatesProviderAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardsTotalRatesProviderAddress = _rewardsTotalRatesProviderAddress;
    }

    function getRewardsTotalRatesProviderAddress() public view returns (IAuctionRewardsTotalRatesProvider) {
        return rewardsTotalRatesProviderAddress;
    }

    function getTotalBidbackStakes(
        uint256 auctionId
    ) public view returns (uint256) {
        return totalBidbackStakes[auctionId];
    }

    function getTotalPirsStakes(
        uint256 auctionId
    ) public view returns (uint256) {
        return totalPirsStakes[auctionId];
    }

    function getBidbackUsers(
        uint256 auctionId
    ) public view returns (address[] memory) {
        return bidbackUsers[auctionId];
    }

    function getBidbackPercentages(uint256 auctionId) public view returns (
        address[] memory users,
        uint256[] memory percentages
    ) {
        uint256[] memory amountsList = new uint256[](bidbackUsers[auctionId].length);

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
        address owner
    ) override external {        
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );
    }

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount,
        bool isOverriden
    ) override external {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );

        auctionUsersWithBids[auctionId][bidder] = true;
    }

    function onWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) override external {
    }

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount
    ) override external {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );

        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (address beneficiary,, address tokenAddress, uint256 tokenId,,,,,,) =
            auctionSystem.getAuctionInfo(auctionId);

        oldOwnersUsersMapping[tokenAddress][tokenId][beneficiary] = true;
        rewardsAmountMapping[auctionId] = rewardsAmount;
    }

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) override external {
    }

    function stakeBidback(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,, uint256 auctionEndTime,,,,) = auctionSystem.getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsSystem: AUCTION_ENDED"
        );

        require(
            auctionUsersWithBids[auctionId][msg.sender],
            "AlgoPainterRewardsSystem: USER_NOT_A_BIDDER"
        );

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_STAKE"
        );

        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].add(amount);
        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][msg.sender].add(amount);

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

    function unstakeBidback(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,, uint256 auctionEndTime,,,,) = auctionSystem.getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsSystem: AUCTION_ENDED"
        );

        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][msg.sender].sub(amount);
        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_UNSTAKE"
        );

        computeBidbackPercentages(auctionId);

        emit BidbackUnstaked(
            auctionId,
            msg.sender,
            bidbackStakes[auctionId][msg.sender]
        );
    }

    function stakePirs(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (address beneficiary,, address tokenAddress, uint256 tokenId,, uint256 auctionEndTime,,,,) =
            auctionSystem.getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsSystem: AUCTION_ENDED"
        );

        require(
            oldOwnersUsersMapping[tokenAddress][tokenId][beneficiary],
            "AlgoPainterRewardsSystem: ACCOUNT_NOT_ELIGIBLE"
        );

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_STAKE"
        );

        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].add(amount);
        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].add(amount);

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
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,, uint256 auctionEndTime,,,,) = auctionSystem.getAuctionInfo(auctionId);

        require(
            getNow() <= auctionEndTime,
            "AlgoPainterRewardsSystem: AUCTION_ENDED"
        );

        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].sub(amount);
        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_UNSTAKE"
        );

        computePirsPercentages(auctionId);

        emit PIRSUnstaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionId][msg.sender]
        );
    }

    function withdrawPirs(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_PIRS_WITHDRAW"
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

    function getRewardAmount(uint256 auctionId, uint256 rate) internal view returns (uint256) {
        IAuctionRewardsTotalRatesProvider totalRatesProvider = IAuctionRewardsTotalRatesProvider(rewardsTotalRatesProviderAddress);

        uint256 totalRate = totalRatesProvider.getRewardsRate(auctionId);

        return totalRate == 0 ? 0 : ONE_HUNDRED_PERCENT
            .mul(rate)
            .div(totalRate);
    }

    function claimBidback(uint256 auctionId) external {
        require(
            bidbackPercentages[auctionId][msg.sender] > 0,
            "AlgoPainterRewardsSystem: NOTHING_TO_CLAIM"
        );

        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,, IERC20 tokenPriceAddress, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: NOT_YET_ENDED");

        IAuctionRewardsRatesProvider ratesProvider = IAuctionRewardsRatesProvider(rewardsRatesProviderAddress);
        uint256 bidbackRate = getRewardAmount(auctionId, ratesProvider.getBidbackRate(auctionId));
        
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
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_BIDBACK"
        );

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, bidbackStakes[auctionId][msg.sender]),
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_BIDBACK_WITHDRAW"
        );

        bidbackStakes[auctionId][msg.sender] = 0;

        emit BidbackClaimed(
            auctionId,
            msg.sender,
            bidbackEarnings
        );
    }

    function claimPirs(uint256 auctionId) external {
        require(
            pirsPercentages[auctionId][msg.sender] > 0,
            "AlgoPainterRewardsSystem: NOTHING_TO_CLAIM"
        );

        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,, IERC20 tokenPriceAddress, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: NOT_YET_ENDED");

        IAuctionRewardsRatesProvider ratesProvider = IAuctionRewardsRatesProvider(rewardsRatesProviderAddress);
        uint256 pirsRate = getRewardAmount(auctionId, ratesProvider.getInvestorPirsRate(auctionId));
        
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
            "AlgoPainterRewardsSystem: FAIL_TO_TRANSFER_PIRS"
        );

        emit PIRSClaimed(
            auctionId,
            msg.sender,
            pirsEarnings
        );
    }
}
