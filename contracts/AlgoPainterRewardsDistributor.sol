// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./AlgoPainterContractBase.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterRewardsDistributor.sol";

contract AlgoPainterRewardsDistributor is
    AlgoPainterContractBase,
    IAlgoPainterRewardsDistributor,
    IAuctionHook
{
    uint256 constant ONE_HUNDRED_PERCENT = 10**4;

    IERC20 public stakeToken;
    address public allowedSender;
    IAlgoPainterAuctionSystem public auctionSystem;
    IAuctionRewardsRates public rewardsRatesProvider;

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

    constructor(uint256 _emergencyTimeInterval)
        AlgoPainterContractBase(_emergencyTimeInterval)
    {}

    function auctionKey(uint256 auctionId) private view returns (bytes32){
        return keccak256(abi.encodePacked(address(auctionSystem), auctionId));
    }

    function setStakeToken(address _tokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakeToken = IERC20(_tokenAddress);
    }

    function setAllowedSender(address _allowedSender)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowedSender = _allowedSender;
    }

    function setAuctionSystemAddress(address _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystem = IAlgoPainterAuctionSystem(_auctionSystemAddress);
    }

    function setRewardsRatesProviderAddress(
        address _rewardsRatesProviderAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsRatesProvider = IAuctionRewardsRates(
            _rewardsRatesProviderAddress
        );
    }

    function getTotalBidbackStakes(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        return totalBidbackStakes[auctionKey(auctionId)];
    }

    function getTotalPirsStakes(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        return totalPirsStakes[auctionKey(auctionId)];
    }

    function getBidbackUsers(uint256 auctionId)
        public
        view
        returns (address[] memory)
    {
        return bidbackUsers[auctionKey(auctionId)];
    }

    function getBidbackPercentages(uint256 auctionId)
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

    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        address tokenPriceAddress
    ) external override {}

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external override {
        require(msg.sender == allowedSender, "INVALID_SENDER");

        auctionUsersWithBids[auctionKey(auctionId)][bidder] = true;
    }

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external override {
        require(msg.sender == allowedSender, "INVALID_SENDER");

        removeUserFromBidback(auctionId, owner);
        auctionUsersWithBids[auctionKey(auctionId)][owner] = false;

        if (bidbackStakes[auctionKey(auctionId)][owner] > 0) {
            unstakeBidback(
                auctionId,
                bidbackStakes[auctionKey(auctionId)][owner]
            );
        }
    }

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount
    ) external override {
        require(msg.sender == allowedSender, "INVALID_SENDER");

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
        auctionRewardsAmount[auctionKey(auctionId)] = rewardsAmount;
    }

    function onAuctionCancelled(uint256 auctionId, address owner)
        external
        override
    {
        // require(
        //     msg.sender == allowedSender,
        //     "INVALID_SENDER"
        // );
    }

    function removeUserFromBidback(uint256 auctionId, address user) private {
        bidbackUsersMapping[auctionKey(auctionId)][user] = false;

        for (
            uint256 i = 0;
            i < bidbackUsers[auctionKey(auctionId)].length;
            i++
        ) {
            if (bidbackUsers[auctionKey(auctionId)][i] == user) {
                delete bidbackUsers[auctionKey(auctionId)][i];
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
            "AUCTION_ENDED"
        );

        require(block.timestamp <= auctionEndTime, "AUCTION_EXPIRED");

        require(
            auctionUsersWithBids[auctionKey(auctionId)][msg.sender],
            "USER_NOT_BIDDER"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "FAIL_STAKE"
        );

        totalBidbackStakes[auctionKey(auctionId)] =
            totalBidbackStakes[auctionKey(auctionId)] +
            amount;
        bidbackStakes[auctionKey(auctionId)][msg.sender] =
            bidbackStakes[auctionKey(auctionId)][msg.sender] +
            amount;

        if (
            !bidbackUsersMapping[auctionKey(auctionId)][msg.sender]
        ) {
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
    }

    function unstakeBidback(uint256 auctionId, uint256 amount) public {
        require(
            amount <=
                bidbackStakes[auctionKey(auctionId)][msg.sender],
            "UNSTAKE_TOO_MUCH"
        );

        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(stakeToken.transfer(msg.sender, amount), "FAIL_UNSTAKE");

        bidbackStakes[auctionKey(auctionId)][msg.sender] =
            bidbackStakes[auctionKey(auctionId)][msg.sender] -
            amount;
        totalBidbackStakes[auctionKey(auctionId)] =
            totalBidbackStakes[auctionKey(auctionId)] -
            amount;

        computeBidbackPercentages(auctionId);

        emit BidbackUnstaked(
            auctionId,
            msg.sender,
            bidbackStakes[auctionKey(auctionId)][msg.sender]
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

        require(block.timestamp <= auctionEndTime, "AUCTION_ENDED");

        require(
            oldOwnersUsersMapping[tokenAddress][tokenId][msg.sender],
            "NOT_ELIGIBLE"
        );

        require(
            stakeToken.transferFrom(msg.sender, address(this), amount),
            "FAIL_STAKE"
        );

        totalPirsStakes[auctionKey(auctionId)] =
            totalPirsStakes[auctionKey(auctionId)] +
            amount;
        pirsStakes[auctionKey(auctionId)][msg.sender] =
            pirsStakes[auctionKey(auctionId)][msg.sender] +
            amount;

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
    }

    function unstakePirs(uint256 auctionId, uint256 amount) external {
        require(
            amount <= pirsStakes[auctionKey(auctionId)][msg.sender],
            "UNSTAKE_HIGH"
        );

        uint256 currentStakeBalance = stakeToken.balanceOf(address(this));

        if (currentStakeBalance < amount) {
            amount = currentStakeBalance;
        }

        require(stakeToken.transfer(msg.sender, amount), "FAIL_UNSTAKE");

        pirsStakes[auctionKey(auctionId)][msg.sender] =
            pirsStakes[auctionKey(auctionId)][msg.sender] -
            (amount);
        totalPirsStakes[auctionKey(auctionId)] =
            totalPirsStakes[auctionKey(auctionId)] -
            (amount);

        computePirsPercentages(auctionId);

        emit PIRSUnstaked(
            auctionId,
            msg.sender,
            pirsStakes[auctionKey(auctionId)][msg.sender]
        );
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
                bidbackPercentages[auctionKey(auctionId)][
                    userAddress
                ] =
                    (ONE_HUNDRED_PERCENT *
                        (
                            bidbackStakes[auctionKey(auctionId)][
                                userAddress
                            ]
                        )) /
                    (totalBidbackStakes[auctionKey(auctionId)]);
            }
        }
    }

    function computePirsPercentages(uint256 auctionId) private {
        for (
            uint256 i = 0;
            i < pirsUsers[auctionKey(auctionId)].length;
            i++
        ) {
            address userAddress = pirsUsers[auctionKey(auctionId)][
                i
            ];

            if (totalPirsStakes[auctionKey(auctionId)] == 0) {
                pirsPercentages[auctionKey(auctionId)][
                    userAddress
                ] = 0;
            } else {
                pirsPercentages[auctionKey(auctionId)][
                    userAddress
                ] =
                    (ONE_HUNDRED_PERCENT *
                        (
                            pirsStakes[auctionKey(auctionId)][
                                userAddress
                            ]
                        )) /
                    (totalPirsStakes[auctionKey(auctionId)]);
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
        return pirsUsers[auctionKey(auctionId)].length > 0;
    }

    function hasBidbackStakes(uint256 auctionId)
        public
        view
        override
        returns (bool)
    {
        return bidbackUsers[auctionKey(auctionId)].length > 0;
    }

    function claimBidback(uint256 auctionId) external {
        require(
            bidbackPercentages[auctionKey(auctionId)][msg.sender] >
                0,
            "NOTHING_TO_CLAIM"
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
            "AUCTION_RUNNING"
        );

        uint256 bidbackRate = getRewardAmount(
            auctionId,
            rewardsRatesProvider.getBidbackRate(auctionId)
        );

        uint256 bidbackTotalEarnings = (auctionRewardsAmount[auctionKey(auctionId)] * bidbackRate) / ONE_HUNDRED_PERCENT;

        uint256 bidbackEarnings = (bidbackTotalEarnings *
            bidbackPercentages[auctionKey(auctionId)][msg.sender]) /
            ONE_HUNDRED_PERCENT;

        bidbackPercentages[auctionKey(auctionId)][msg.sender] = 0;

        IERC20 bidbackToken = IERC20(tokenPriceAddress);

        require(
            bidbackToken.transfer(msg.sender, bidbackEarnings),
            "FAIL_TRANSFER_BIDBACK"
        );

        uint256 harvestAmount = bidbackStakes[auctionKey(auctionId)][msg.sender];
        uint256 contractAmount = stakeToken.balanceOf(address(this));

        if (contractAmount < harvestAmount) harvestAmount = contractAmount;

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "FAIL_TRANSFER_BIDBACK_WITHDRAW"
        );

        bidbackStakes[auctionKey(auctionId)][msg.sender] = 0;

        emit BidbackClaimed(auctionId, msg.sender, bidbackEarnings);
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

        uint256 pirsTotalEarnings = auctionRewardsAmount[auctionKey(auctionId)] * pirsRate / ONE_HUNDRED_PERCENT;

        uint256 pirsEarnings = pirsTotalEarnings
            * pirsPercentages[auctionKey(auctionId)][msg.sender]
            / ONE_HUNDRED_PERCENT;

        pirsPercentages[auctionKey(auctionId)][msg.sender] = 0;

        IERC20 pirsToken = IERC20(tokenPriceAddress);

        require(
            pirsToken.transfer(msg.sender, pirsEarnings),
            "FAIL_TRANSFER_PIRS"
        );

        uint256 harvestAmount = pirsStakes[auctionKey(auctionId)][
            msg.sender
        ];
        uint256 contractAmount = stakeToken.balanceOf(address(this));

        if (contractAmount < harvestAmount) harvestAmount = contractAmount;

        require(
            stakeToken.transfer(msg.sender, harvestAmount),
            "FAIL_TRANSFER_PIRS_STAKES_WITHDRAW"
        );

        emit PIRSClaimed(auctionId, msg.sender, pirsEarnings);
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
            if (contractTokenBalance > 0) {
                token.transferFrom(self, msg.sender, contractTokenBalance);
            }
        }
    }
}
