// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAlgoPainterRewardsDistributor.sol";
import "./AlgoPainterContractBase.sol";

contract AlgoPainterRewardsRates is
    AlgoPainterContractBase,
    IAuctionRewardsRates
{
    using SafeMath for uint256;
    event BidbackUpdated(uint256 _auctionId, uint256 _bidbackRate);

    event InvestorPirsUpdated(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    );

    event CreatorRoyaltiesUpdated(
        bytes32 _tokenAddress,
        uint256 _creatorRoyaltiesRate
    );

    IAlgoPainterAuctionSystem auctionSystem;
    IAlgoPainterRewardsDistributor distributor;

    uint256 maxCreatorRoyaltiesRates;
    uint256 maxInvestorPirsRate;
    uint256 maxBidbackRate;
    bool canResetCreatorRate;

    mapping(address => mapping(uint256 => uint256)) public bidbackRatePerAuction;
    mapping(address => mapping(uint256 => bool)) isBidbackSet;

    mapping(address => mapping(uint256 => uint256)) PIRSRatePerNFT;
    mapping(address => mapping(uint256 => bool)) isPIRSSet;

    mapping(bytes32 => uint256) public creatorRoyaltiesRates;
    mapping(bytes32 => bool) isCreatorRoyaltiesSet;

    mapping(bytes32 => uint256) rates;

    constructor(uint256 _emergencyTimeInterval) AlgoPainterContractBase(_emergencyTimeInterval) {
        canResetCreatorRate = false;
    }

    function setRate(bytes32 hashKey, uint256 rate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rates[hashKey] = rate;
    }

    function getRate(bytes32 hashKey)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        return rates[hashKey];
    }

    function toggleCanSetCreatorRate() public onlyRole(DEFAULT_ADMIN_ROLE) {
        canResetCreatorRate = !canResetCreatorRate;
    }

    function setAuctionDistributorAddress(address _distributorAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        distributor = IAlgoPainterRewardsDistributor(_distributorAddress);
    }

    function getAuctionDistributorAddress() public view returns (address) {
        return address(distributor);
    }

    function setAuctionSystemAddress(address _auctionSystemAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionSystem = IAlgoPainterAuctionSystem(_auctionSystemAddress);
    }

    function setMaxCreatorRoyaltiesRate(uint256 _maxCreatorRoyaltiesRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxCreatorRoyaltiesRates = _maxCreatorRoyaltiesRate;
    }

    function setMaxPIRSRate(uint256 _maxInvestorPirsRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxInvestorPirsRate = _maxInvestorPirsRate;
    }

    function setMaxBidbackRate(uint256 _maxBidbackRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxBidbackRate = _maxBidbackRate;
    }

    function setBidbackRate(uint256 _auctionId, uint256 _bidbackRate)
        public
        override
        onlyRole(CONFIGURATOR_ROLE)
    {
        require(
            isBidbackSet[address(auctionSystem)][_auctionId] == false,
            "AlgoPainterRewardsRates:BIDBACK_ALREADY_SET"
        );

        require(
            msg.sender == address(auctionSystem),
            "AlgoPainterRewardsRates:SENDER_IS_NOT_AUCTION_CONTRACT"
        );

        require(
            _bidbackRate <= maxBidbackRate,
            "AlgoPainterRewardsRates:BIDBACK_IS_GREATER_THAN_ALLOWED"
        );

        bidbackRatePerAuction[address(auctionSystem)][_auctionId] = _bidbackRate;
        isBidbackSet[address(auctionSystem)][_auctionId] = true;

        emit BidbackUpdated(_auctionId, _bidbackRate);
    }

    function setPIRSRate(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    ) public {
        require(
            isPIRSSet[_tokenAddress][_tokenId] == false,
            "AlgoPainterRewardsRates:INVESTOR_PIRS_ALREADY_SET"
        );

        require(
            _investorPirsRate <= maxInvestorPirsRate,
            "AlgoPainterRewardsRates:INVESTOR_PIRS_IS_GREATER_THAN_ALLOWED"
        );

        PIRSRatePerNFT[_tokenAddress][_tokenId] = _investorPirsRate;
        isPIRSSet[_tokenAddress][_tokenId] = true;

        emit InvestorPirsUpdated(_tokenAddress, _tokenId, _investorPirsRate);
    }

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) public override onlyRole(CONFIGURATOR_ROLE) {
        if (canResetCreatorRate == false) {
            require(
                isCreatorRoyaltiesSet[_hashAddress] == false,
                "AlgoPainterRewardsRates:CREATOR_ROYALTIES_ALREADY_SET"
            );
        }

        require(
            _creatorRoyaltiesRate <= maxCreatorRoyaltiesRates,
            "AlgoPainterRewardsRates:CREATOR_ROYALTIES_IS_GREATER_THAN_ALLOWED"
        );

        creatorRoyaltiesRates[_hashAddress] = _creatorRoyaltiesRate;
        isCreatorRoyaltiesSet[_hashAddress] = true;

        emit CreatorRoyaltiesUpdated(_hashAddress, _creatorRoyaltiesRate);
    }

    function getCreatorRoyaltiesByTokenAddress(bytes32 _hashAddress)
        public
        view
        returns (uint256)
    {
        return creatorRoyaltiesRates[_hashAddress];
    }

    function getBidbackRate(uint256 _auctionId)
        public
        view
        override
        returns (uint256)
    {
        return bidbackRatePerAuction[address(auctionSystem)][_auctionId];
    }

    function getPIRSRate(uint256 _auctionId)
        public
        view
        override
        returns (uint256)
    {
        (, , address tAddress, uint256 tId, , , , , , ) = auctionSystem
            .getAuctionInfo(_auctionId);

        return PIRSRatePerNFT[tAddress][tId];
    }

    function getPIRSRatePerImage(address _tokenAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return PIRSRatePerNFT[_tokenAddress][_tokenId];
    }

    function hasPIRSRateSetPerImage(address _tokenAddress, uint256 _tokenId)
        public
        view
        override
        returns (bool)
    {
        return isPIRSSet[_tokenAddress][_tokenId];
    }

    function getCreatorRoyaltiesRate(uint256 _auctionId)
        public
        view
        override
        returns (uint256)
    {
        (, , address _tokenAddress, , , , , , , ) = auctionSystem
            .getAuctionInfo(_auctionId);

        return creatorRoyaltiesRates[bytes32(bytes20(_tokenAddress))];
    }

    function getMaxCreatorRoyaltiesRate() public view returns (uint256) {
        return maxCreatorRoyaltiesRates;
    }

    function getMaxInvestorPirsRate() public view returns (uint256) {
        return maxInvestorPirsRate;
    }

    function getMaxBidbackRate() public view returns (uint256) {
        return maxBidbackRate;
    }

    function getRewardsRate(uint256 _auctionId)
        external
        view
        override
        returns (uint256)
    {
        uint256 taxes = 0;

        if (distributor.hasPIRSStakes(_auctionId)) {
            taxes = taxes.add(getPIRSRate(_auctionId));
        }

        if (distributor.hasBidbackStakes(_auctionId)) {
            taxes = taxes.add(getBidbackRate(_auctionId));
        }

        return taxes;
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