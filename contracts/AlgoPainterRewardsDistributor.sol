// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./AlgoPainterContractBase.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAuctionRewardsDistributor.sol";
import "./interfaces/IAuctionRewardsDistributorHook.sol";

contract AlgoPainterRewardsDistributor is
    AlgoPainterContractBase,
    IAuctionRewardsDistributor
{
    using SafeMath for uint256;

    uint256 constant ONE_HUNDRED_PERCENT = 10**4;
    uint256 MAX_INT = 2**256 - 1;

    IERC20 public stakeToken;
    IAlgoPainterAuctionSystem public auctionSystem;
    IAuctionRewardsRates public rewardsRatesProvider;
    IAuctionRewardsDistributorHook public proxyHook;

    mapping(address => mapping(uint256 => mapping(address => bool))) oldOwnersUsersMapping;

    mapping(bytes32 => mapping(address => bool)) auctionUsersWithBids;
    mapping(bytes32 => uint256) auctionRewardsAmount;

    mapping(bytes32 => uint256) totalBidbackStakes;
    mapping(bytes32 => address[]) bidbackUsers;
    mapping(bytes32 => mapping(address => bool)) bidbackUsersMapping;
    mapping(bytes32 => mapping(address => uint256)) bidbackStakes;
    mapping(bytes32 => mapping(address => uint256)) bidbackPercentages;

    mapping(bytes32 => uint256) totalPirsStakes;
    mapping(bytes32 => address[]) pirsUsers;
    mapping(bytes32 => mapping(address => bool)) pirsUsersMapping;
    mapping(bytes32 => mapping(address => uint256)) pirsStakes;
    mapping(bytes32 => mapping(address => uint256)) pirsPercentages;

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

    constructor(
        uint256 _emergencyTimeInterval,
        address _auctionSystem,
        address _stakeToken
    ) AlgoPainterContractBase(_emergencyTimeInterval)
    {
        setAuctionSystemAddress(_auctionSystem);
        setStakeToken(_stakeToken);
    }

    function auctionKey(uint256 auctionId) private view returns (bytes32){
        return keccak256(abi.encodePacked(address(auctionSystem), auctionId));
    }

    function setStakeToken(address _tokenAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        stakeToken = IERC20(_tokenAddress);
    }

    function setHook(address _adr)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyHook = IAuctionRewardsDistributorHook(_adr);
    }

    function setAuctionSystemAddress(address _auctionSystemAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        auctionSystem = IAlgoPainterAuctionSystem(_auctionSystemAddress);
    }

    function setRewardsRatesProviderAddress(
        address _rewardsRatesProviderAddress
    ) public onlyRole(CONFIGURATOR_ROLE) {
        rewardsRatesProvider = IAuctionRewardsRates(
            _rewardsRatesProviderAddress
        );
    }

    function getTotalBidbackStakes(uint256 auctionId)
        override
        public
        view
        returns (uint256)
    {
        return totalBidbackStakes[auctionKey(auctionId)];
    }

    function getTotalPirsStakes(uint256 auctionId)
        override
        public
        view
        returns (uint256)
    {
        return totalPirsStakes[auctionKey(auctionId)];
    }

    function getBidbackUsers(uint256 auctionId)
        override
        public
        view
        returns (address[] memory)
    {
        return bidbackUsers[auctionKey(auctionId)];
    }

    function getBidbackPercentages(uint256 auctionId)
        override
        public
        view
        returns (address[] memory users, uint256[] memory percentages)
    {
        uint256[] memory amountsList = new uint256[](
            bidbackUsers[auctionKey(auctionId)].length
        );

        for (
            uint256 i = 0;
            i < bidbackUsers[auctionKey(auctionId)].length;
            i++
        ) {
            address userAddress = bidbackUsers[auctionKey(auctionId)][i];
            amountsList[i] = (
                bidbackPercentages[auctionKey(auctionId)][
                    userAddress
                ]
            );
        }

        return (bidbackUsers[auctionKey(auctionId)], amountsList);
    }

    function addEligibleBidder(
        uint256 auctionId,
        address bidder
    ) override public onlyRole(CONFIGURATOR_ROLE) {
        auctionUsersWithBids[auctionKey(auctionId)][bidder] = true;
    }

    function remAccountFromBidRewards(
        uint256 auctionId,
        address account
    ) override public onlyRole(CONFIGURATOR_ROLE) {
        bidbackUsersMapping[auctionKey(auctionId)][account] = false;
        auctionUsersWithBids[auctionKey(auctionId)][account] = false;

        if (bidbackStakes[auctionKey(auctionId)][account] > 0) {
            unstakeBidBackFromAccount(
                auctionId,
                account,
                bidbackStakes[auctionKey(auctionId)][account]
            );
        }
    }

    function setAuctionRewardsDistributable(
        uint256 auctionId,
        uint256 rewardsAmount
    ) override public onlyRole(CONFIGURATOR_ROLE) {
        (
            address beneficiary,
            address tokenAddress,
            uint256 tokenId,
            ,
            ,
            ,
            ,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        oldOwnersUsersMapping[tokenAddress][tokenId][beneficiary] = true;
        auctionRewardsAmount[auctionKey(auctionId)] = rewardsAmount;
    }

    function stakeBidback(uint256 auctionId, uint256 amount) external {
        require (getInEmncyState() == false, "NOT_AVAILABLE");

        (
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
            "AUCTION_ENDED"
        );

        require(block.timestamp <= (auctionEndTime - getTimeSafety()), "AUCTION_EXPIRED");

        require(
            auctionUsersWithBids[auctionKey(auctionId)][msg.sender],
            "USER_NOT_BIDDER"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "FAIL_STAKE"
        );

        totalBidbackStakes[auctionKey(auctionId)] = totalBidbackStakes[auctionKey(auctionId)].add(amount);
        bidbackStakes[auctionKey(auctionId)][msg.sender] = bidbackStakes[auctionKey(auctionId)][msg.sender].add(amount);

        if (!bidbackUsersMapping[auctionKey(auctionId)][msg.sender]) {
            bidbackUsers[auctionKey(auctionId)].push(msg.sender);
            bidbackUsersMapping[auctionKey(auctionId)][
                msg.sender
            ] = true;
        }

        computeBidbackPercentages(auctionId);

        emit BidbackStaked(
            auctionId,
            msg.sender,
            bidbackStakes[auctionKey(auctionId)][msg.sender]
        );

        if(address(proxyHook) != address(0)) {
            proxyHook.onStakeBidback(auctionId, amount, bidbackStakes[auctionKey(auctionId)][msg.sender]);
        }
    }

    function unstakeBidback(uint256 auctionId, uint256 amount) public {
        unstakeBidBackFromAccount(auctionId, msg.sender, amount);
    }

    function unstakeBidBackFromAccount(uint256 auctionId, address account, uint256 amount) private {
        require(amount > 0 && amount < MAX_INT, "CANNOT_UNSTAKE_ZERO");

        require(amount <= bidbackStakes[auctionKey(auctionId)][account],
            "UNSTAKE_TOO_MUCH"
        );

        bidbackStakes[auctionKey(auctionId)][account] = bidbackStakes[auctionKey(auctionId)][account].sub(amount);
        totalBidbackStakes[auctionKey(auctionId)] = totalBidbackStakes[auctionKey(auctionId)].sub(amount);
        computeBidbackPercentages(auctionId);
        
        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(stakeToken.transfer(account, amount), "FAIL_UNSTAKE");

        emit BidbackUnstaked(
            auctionId,
            account,
            bidbackStakes[auctionKey(auctionId)][account]
        );

        if(address(proxyHook) != address(0)) {
            proxyHook.onUnstakeBidback(auctionId, amount, bidbackStakes[auctionKey(auctionId)][account]);    
        }
    }

    function stakePirs(uint256 auctionId, uint256 amount) external {
        require (getInEmncyState() == false, "NOT_AVAILABLE");
        
        (
            ,
            address tokenAddress,
            uint256 tokenId,
            ,
            uint256 auctionEndTime,
            ,
            ,
            ,

        ) = auctionSystem.getAuctionInfo(auctionId);

        require(block.timestamp <= (auctionEndTime - getTimeSafety()), "AUCTION_ENDED");

        require(
            oldOwnersUsersMapping[tokenAddress][tokenId][msg.sender],
            "NOT_ELIGIBLE"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "FAIL_STAKE"
        );

        totalPirsStakes[auctionKey(auctionId)] =
            totalPirsStakes[auctionKey(auctionId)].add(amount);

        pirsStakes[auctionKey(auctionId)][msg.sender] =
            pirsStakes[auctionKey(auctionId)][msg.sender].add(amount);

        if (!pirsUsersMapping[auctionKey(auctionId)][msg.sender]) {
            pirsUsers[auctionKey(auctionId)].push(msg.sender);
            pirsUsersMapping[auctionKey(auctionId)][
                msg.sender
            ] = true;
        }

        computePirsPercentages(auctionId);

        emit PIRSStaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionKey(auctionId)][msg.sender]
        );

        if(address(proxyHook) != address(0)) {
            proxyHook.onStakePirs(auctionId, amount, pirsStakes[auctionKey(auctionId)][msg.sender]);   
        }
    }

    function unstakePirs(uint256 auctionId, uint256 amount) external {
        require(amount > 0 && amount < MAX_INT, "CANNOT_UNSTAKE_ZERO");

        require(
            amount <= pirsStakes[auctionKey(auctionId)][msg.sender],
            "UNSTAKE_HIGH"
        );

        pirsStakes[auctionKey(auctionId)][msg.sender] = pirsStakes[auctionKey(auctionId)][msg.sender].sub(amount);
        totalPirsStakes[auctionKey(auctionId)] = totalPirsStakes[auctionKey(auctionId)].sub(amount);

        computePirsPercentages(auctionId);

        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(stakeToken.transfer(msg.sender, amount), "FAIL_UNSTAKE");

        emit PIRSUnstaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionKey(auctionId)][msg.sender]
        );

        if(address(proxyHook) != address(0)) {
            proxyHook.onUnstakePirs(auctionId, amount, pirsStakes[auctionKey(auctionId)][msg.sender]);
        }
    }

    function computeBidbackPercentages(uint256 auctionId) private {
        for (
            uint256 i = 0;
            i < bidbackUsers[auctionKey(auctionId)].length;
            i++
        ) {
            address userAddress = bidbackUsers[auctionKey(auctionId)][i];

            if (totalBidbackStakes[auctionKey(auctionId)] == 0) {
                bidbackPercentages[auctionKey(auctionId)][
                    userAddress
                ] = 0;
            } else {
                bidbackPercentages[auctionKey(auctionId)][userAddress] =
                    (ONE_HUNDRED_PERCENT.mul(bidbackStakes[auctionKey(auctionId)][userAddress]))
                                        .div(totalBidbackStakes[auctionKey(auctionId)]);
            }
        }
    }

    function computePirsPercentages(uint256 auctionId) private {
        for (
            uint256 i = 0;
            i < pirsUsers[auctionKey(auctionId)].length;
            i++
        ) {
            address userAddress = pirsUsers[auctionKey(auctionId)][i];

            if (totalPirsStakes[auctionKey(auctionId)] == 0) {
                pirsPercentages[auctionKey(auctionId)][userAddress] = 0;
            } else {
                pirsPercentages[auctionKey(auctionId)][userAddress] =
                    (ONE_HUNDRED_PERCENT.mul(pirsStakes[auctionKey(auctionId)][userAddress]))
                                        .div(totalPirsStakes[auctionKey(auctionId)]);
            }
        }
    }

    function getRewardAmount(uint256 auctionId, uint256 rate)
        internal
        view
        returns (uint256)
    {
        uint256 totalRate = rewardsRatesProvider.getRewardsRate(auctionId);

        return totalRate == 0 ? 0 : (ONE_HUNDRED_PERCENT * rate) / totalRate;
    }

    function hasPIRSStakes(uint256 auctionId)
        public
        view
        override
        returns (bool)
    {
        return totalPirsStakes[auctionKey(auctionId)] > 0;
    }

    function hasBidbackStakes(uint256 auctionId)
        public
        view
        override
        returns (bool)
    {
        return totalBidbackStakes[auctionKey(auctionId)] > 0;
    }

    function claimBidback(uint256 auctionId) external {
        require(
            bidbackPercentages[auctionKey(auctionId)][msg.sender] > 0,
            "NOTHING_TO_CLAIM"
        );

        (
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
            "AUCTION_RUNNING"
        );

        uint256 bidbackRate = getRewardAmount(
            auctionId,
            rewardsRatesProvider.getBidbackRate(auctionId)
        );

        uint256 bidbackTotalEarnings = (auctionRewardsAmount[auctionKey(auctionId)] * bidbackRate) / ONE_HUNDRED_PERCENT;

        uint256 bidbackEarnings = (bidbackTotalEarnings.mul(bidbackPercentages[auctionKey(auctionId)][msg.sender]))
                                                       .div(ONE_HUNDRED_PERCENT);

        bidbackPercentages[auctionKey(auctionId)][msg.sender] = 0;

        IERC20 bidbackToken = IERC20(tokenPriceAddress);

        require(
            bidbackToken.transfer(msg.sender, bidbackEarnings),
            "FAIL_TRANSFER_BIDBACK"
        );

        uint256 harvestAmount = bidbackStakes[auctionKey(auctionId)][msg.sender];
        uint256 contractAmount = stakeToken.balanceOf(address(this));
        
        bidbackStakes[auctionKey(auctionId)][msg.sender] = 0;
        
        if (contractAmount < harvestAmount) {
            harvestAmount = contractAmount;
        }

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "FAIL_TRANSFER_BIDBACK_WITHDRAW"
        );

        emit BidbackClaimed(auctionId, msg.sender, bidbackEarnings);

        if(address(proxyHook) != address(0)) {
            proxyHook.onBidbackClaimed(auctionId, bidbackEarnings);
        }
    }

    function claimPirs(uint256 auctionId) external {
        require(
            pirsPercentages[auctionKey(auctionId)][msg.sender] > 0,
            "NOTHING_TO_CLAIM"
        );

        (
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
            "AUCTION_RUNNING"
        );

        uint256 pirsRate = getRewardAmount(
            auctionId,
            rewardsRatesProvider.getPIRSRate(auctionId)
        );

        uint256 pirsTotalEarnings = auctionRewardsAmount[auctionKey(auctionId)]
            .mul(pirsRate)
            .div(ONE_HUNDRED_PERCENT);

        uint256 pirsEarnings = pirsTotalEarnings
            .mul(pirsPercentages[auctionKey(auctionId)][msg.sender])
            .div(ONE_HUNDRED_PERCENT);

        pirsPercentages[auctionKey(auctionId)][msg.sender] = 0;

        IERC20 pirsToken = IERC20(tokenPriceAddress);

        require(
            pirsToken.transfer(msg.sender, pirsEarnings),
            "FAIL_TRANSFER_PIRS"
        );

        uint256 harvestAmount = pirsStakes[auctionKey(auctionId)][msg.sender];
        uint256 contractAmount = stakeToken.balanceOf(address(this));

        if (contractAmount < harvestAmount) {
            harvestAmount = contractAmount;
        }

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "FAIL_TRANSFER_PIRS_STAKES_WITHDRAW"
        );

        emit PIRSClaimed(auctionId, msg.sender, pirsEarnings);

        if(address(proxyHook) != address(0)) {
            proxyHook.onPIRSClaimed(auctionId, pirsEarnings);
        }
    }

    function emergencyTransfer(address tokenAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
        inEmergencyOwner()
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
