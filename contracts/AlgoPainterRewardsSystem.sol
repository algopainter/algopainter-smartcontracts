// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterRewardsSystemAccessControl.sol";
import "./IAuctionSystemManager.sol";

contract AlgoPainterRewardsSystem is 
    AlgoPainterRewardsSystemAccessControl,
    IAuctionSystemManager
{
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 10**4;

    address allowedSender;
    IERC20 rewardsTokenAddress;

    mapping(uint256 => bool) private endedAuctionsMapping;
    mapping(uint256 => mapping(address => bool)) private auctionUsersWithBids;

    mapping(uint256 => uint256) private totalBidbackStakes;
    mapping(uint256 => address[]) private bidbackUsers;
    mapping(uint256 => mapping(address => uint256)) private bidbackStakes;
    mapping(uint256 => mapping(address => uint256)) private bidbackPercentages;

    function setAllowedSender(address _allowedSender)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowedSender = _allowedSender;
    }

    function setRewardsTokenAddress(IERC20 _rewardsTokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardsTokenAddress = _rewardsTokenAddress;
    }

    function getTotalBidbackStakes(
        uint256 auctionId
    ) public view returns (uint256) {
        return totalBidbackStakes[auctionId];
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
        uint256 netAmount
    ) override external {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );

        endedAuctionsMapping[auctionId] = true;
    }

    function onAuctionCancelled(
        uint256 auctionId,
        address owner
    ) override external {
        require(
            msg.sender == allowedSender,
            "AlgoPainterRewardsSystem: INVALID_SENDER"
        );

        endedAuctionsMapping[auctionId] = true;
    }

    function stakeBidback(uint256 auctionId, uint256 amount) external {
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
        bidbackStakes[auctionId][msg.sender] = bidbackStakes[auctionId][msg.sender].sub(amount);
        totalBidbackStakes[auctionId] = totalBidbackStakes[auctionId].sub(amount);

        IERC20 rewardsToken = IERC20(rewardsTokenAddress);

        require(
            rewardsToken.transfer(msg.sender, amount),
            "AlgoPainterRewardsSystem:FAIL_TO_TRANSFER_STAKE"
        );

        computeBidbackPercentages(auctionId);
    }

    function computeBidbackPercentages(uint256 auctionId) private {
        for (uint256 i = 0; i < bidbackUsers[auctionId].length; i++) {
            address userAddress = bidbackUsers[auctionId][i];

            bidbackPercentages[auctionId][userAddress] = ONE_HUNDRED_PERCENT
                .mul(bidbackStakes[auctionId][userAddress])
                .div(totalBidbackStakes[auctionId]);
        }
    }
}