// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterRewardsSystemAccessControl.sol";
import "./AlgoPainterAuctionSystem.sol";
import "./IAuctionSystemManager.sol";

contract AlgoPainterRewardsSystem is 
    AlgoPainterRewardsSystemAccessControl,
    IAuctionSystemManager
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;

    address allowedSender;
    IERC20 rewardsTokenAddress;
    AlgoPainterAuctionSystem auctionSystemAddress;

    mapping(uint256 => mapping(address => bool)) private auctionUsersWithBids;

    mapping(uint256 => uint256) private totalBidbackStakes;
    mapping(uint256 => uint256) private bidbackAmountMapping;
    mapping(uint256 => address[]) private bidbackUsers;
    mapping(uint256 => mapping(address => uint256)) private bidbackStakes;
    mapping(uint256 => mapping(address => uint256)) private bidbackPercentages;

    mapping(uint256 => uint256) private totalPirsStakes;
    mapping(uint256 => uint256) private pirsAmountMapping;
    mapping(uint256 => address[]) private pirsUsers;
    mapping(uint256 => mapping(address => uint256)) private pirsStakes;
    mapping(uint256 => mapping(address => uint256)) private pirsPercentages;

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

    function onAuctionCreated(
        uint256 auctionId,
        address owner
    ) override external {        
    }

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
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
        uint256 bidbackAmount,
        uint256 netAmount
    ) override external {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );

        bidbackAmountMapping[auctionId] = bidbackAmount;
    }

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) override external {
    }

    function stakeBidback(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended == false, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        require(
            auctionUsersWithBids[auctionId][msg.sender],
            "AlgoPainterRewardsSystem: USER_NOT_A_BIDDER"
        );

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_STAKE"
        );

        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].add(amount);
        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][msg.sender].add(amount);
        bidbackUsers[auctionId].push(msg.sender);

        computeBidbackPercentages(auctionId);
    }

    function unstakeBidback(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended == false, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][msg.sender].sub(amount);
        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_UNSTAKE"
        );

        computeBidbackPercentages(auctionId);
    }

    function stakePirs(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended == false, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transferFrom(msg.sender, address(this), amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_STAKE"
        );

        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].add(amount);
        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].add(amount);
        pirsUsers[auctionId].push(msg.sender);

        computePirsPercentages(auctionId);
    }

    function unstakePirs(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended == false, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].sub(amount);
        totalPirsStakes[auctionId] = totalPirsStakes[auctionId].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_UNSTAKE"
        );

        computePirsPercentages(auctionId);
    }

    function withdrawPirs(uint256 auctionId, uint256 amount) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,,,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: AUCTION_ENDED");

        pirsStakes[auctionId][msg.sender] = pirsStakes[auctionId][msg.sender].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_PIRS_WITHDRAW"
        );
    }

    function computeBidbackPercentages(uint256 auctionId) private {
        for (uint256 i = 0; i < bidbackUsers[auctionId].length; i++) {
            address userAddress = bidbackUsers[auctionId][i];

            bidbackPercentages[auctionId][userAddress] = ONE_HUNDRED_PERCENT
                .mul(bidbackStakes[auctionId][userAddress])
                .div(totalBidbackStakes[auctionId]);
        }
    }

    function computePirsPercentages(uint256 auctionId) private {
        for (uint256 i = 0; i < pirsUsers[auctionId].length; i++) {
            address userAddress = pirsUsers[auctionId][i];

            pirsPercentages[auctionId][userAddress] = ONE_HUNDRED_PERCENT
                .mul(pirsStakes[auctionId][userAddress])
                .div(totalPirsStakes[auctionId]);
        }
    }

    function claimBidback(uint256 auctionId) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,, IERC20 tokenPriceAddress,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: NOT_YET_ENDED");

        uint256 bidbackEarnings = bidbackAmountMapping[auctionId]
            .mul(bidbackPercentages[auctionId][msg.sender])
            .div(ONE_HUNDRED_PERCENT);

        bidbackPercentages[auctionId][msg.sender] = 0;
        
        IERC20 bidbackToken = IERC20(tokenPriceAddress);

        require(
            bidbackToken.transfer(msg.sender, bidbackEarnings),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_BIDBACK"
        );

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, bidbackStakes[auctionId][msg.sender]),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_BIDBACK_WITHDRAW"
        );

        bidbackStakes[auctionId][msg.sender] = 0;
    }

    function claimPirs(uint256 auctionId) external {
        AlgoPainterAuctionSystem auctionSystem = AlgoPainterAuctionSystem(auctionSystemAddress);

        (,,,,,, IERC20 tokenPriceAddress,, bool ended,,) = auctionSystem.getAuctionInfo(auctionId);

        require(ended, "AlgoPainterRewardsSystem: NOT_YET_ENDED");

        uint256 pirsEarnings = pirsAmountMapping[auctionId]
            .mul(pirsPercentages[auctionId][msg.sender])
            .div(ONE_HUNDRED_PERCENT);

        pirsPercentages[auctionId][msg.sender] = 0;
        
        IERC20 pirsToken = IERC20(tokenPriceAddress);

        require(
            pirsToken.transfer(msg.sender, pirsEarnings),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_PIRS"
        );
    }
}