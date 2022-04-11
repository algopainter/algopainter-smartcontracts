// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAuctionRewardsRatesHook.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAuctionRewardsDistributor.sol";
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
    IAuctionRewardsDistributor distributor;
    IAuctionRewardsRatesHook public proxyHook;

    uint256 maxCreatorRoyaltiesRates;
    uint256 maxInvestorPirsRate;
    uint256 maxBidbackRate;
    bool canResetCreatorRate;

    mapping(address => mapping(uint256 => uint256))
        public bidbackRatePerAuction;
    mapping(address => mapping(uint256 => bool)) isBidbackSet;

    mapping(address => mapping(uint256 => uint256)) PIRSRatePerNFT;
    mapping(address => mapping(uint256 => bool)) isPIRSSet;

    mapping(bytes32 => uint256) public creatorRoyaltiesRates;
    mapping(bytes32 => bool) isCreatorRoyaltiesSet;

    constructor(
        uint256 _emergencyTimeInterval,
        uint256 _maxCreatorRoyaltiesRates,
        uint256 _maxPirsRate,
        uint256 _maxBidbackRate,
        address _rewardsDistributor,
        address _auctionSystem,
        address _gwei,
        address _expression,
        uint256 _gweiRate,
        uint256 _expressionRate
    ) AlgoPainterContractBase(_emergencyTimeInterval) {
        canResetCreatorRate = false;
        grantRole(CONFIGURATOR_ROLE, _auctionSystem);
        setAuctionSystemAddress(_auctionSystem);
        setAuctionDistributorAddress(_rewardsDistributor);
        setMaxPIRSRate(_maxPirsRate);
        setMaxCreatorRoyaltiesRate(_maxCreatorRoyaltiesRates);
        setMaxBidbackRate(_maxBidbackRate);
        setCreatorRoyaltiesRate(bytes32(bytes20(_gwei)), _gweiRate);
        setCreatorRoyaltiesRate(bytes32(bytes20(_expression)), _expressionRate);
    }

    function toggleCanSetCreatorRate() public onlyRole(CONFIGURATOR_ROLE) {
        canResetCreatorRate = !canResetCreatorRate;
    }

    function setAuctionDistributorAddress(address _distributorAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        distributor = IAuctionRewardsDistributor(_distributorAddress);
    }

    function getAuctionDistributorAddress() public view returns (address) {
        return address(distributor);
    }

    function setAuctionSystemAddress(address _auctionSystemAddress)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        auctionSystem = IAlgoPainterAuctionSystem(_auctionSystemAddress);
    }

    function setHook(address _adr)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        proxyHook = IAuctionRewardsRatesHook(_adr);
    }

    function setMaxCreatorRoyaltiesRate(uint256 _maxCreatorRoyaltiesRate)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        maxCreatorRoyaltiesRates = _maxCreatorRoyaltiesRate;
    }

    function setMaxPIRSRate(uint256 _maxInvestorPirsRate)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        maxInvestorPirsRate = _maxInvestorPirsRate;
    }

    function setMaxBidbackRate(uint256 _maxBidbackRate)
        public
        onlyRole(CONFIGURATOR_ROLE)
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
            "BIDBACK_ALREADY_SET"
        );

        require(
            msg.sender == address(auctionSystem),
            "SENDER_IS_NOT_AUCTION_CONTRACT"
        );

        require(
            _bidbackRate <= maxBidbackRate,
            "BIDBACK_IS_GREATER_THAN_ALLOWED"
        );

        bidbackRatePerAuction[address(auctionSystem)][
            _auctionId
        ] = _bidbackRate;
        isBidbackSet[address(auctionSystem)][_auctionId] = true;

        emit BidbackUpdated(_auctionId, _bidbackRate);

        if(address(proxyHook) != address(0)) {
            proxyHook.onSetBidbackRate(_auctionId, _bidbackRate);
        }
    }

    function setPIRSRate(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _investorPirsRate
    ) public override {
        require(
            isPIRSSet[_tokenAddress][_tokenId] == false,
            "PIRS_ALREADY_SET"
        );

        require(
            _investorPirsRate <= maxInvestorPirsRate,
            "PIRS_IS_GREATER_THAN_ALLOWED"
        );

        PIRSRatePerNFT[_tokenAddress][_tokenId] = _investorPirsRate;
        isPIRSSet[_tokenAddress][_tokenId] = true;

        emit InvestorPirsUpdated(_tokenAddress, _tokenId, _investorPirsRate);

        if(address(proxyHook) != address(0)) {
            proxyHook.onSetPIRSRate(_tokenAddress, _tokenId, _investorPirsRate);
        }
    }

    function isCreatorRateSet(address _adr, uint256 _token)
        public
        view
        override
        returns (bool)
    {
        bytes32 hashKey = bytes32(bytes20(_adr));

        if (isCreatorRoyaltiesSet[hashKey]) {
            return true;
        }

        hashKey = keccak256(abi.encodePacked(_adr, _token));
        return isCreatorRoyaltiesSet[hashKey];
    }

    function setCreatorRoyaltiesRate(
        bytes32 _hashAddress,
        uint256 _creatorRoyaltiesRate
    ) public override onlyRole(CONFIGURATOR_ROLE) {
        if (canResetCreatorRate == false) {
            require(
                isCreatorRoyaltiesSet[_hashAddress] == false,
                "CREATOR_ROYALTIES_ALREADY_SET"
            );
        }

        require(
            _creatorRoyaltiesRate <= maxCreatorRoyaltiesRates,
            "CREATOR_ROYALTIES_IS_GREATER_THAN_ALLOWED"
        );

        creatorRoyaltiesRates[_hashAddress] = _creatorRoyaltiesRate;
        isCreatorRoyaltiesSet[_hashAddress] = true;

        emit CreatorRoyaltiesUpdated(_hashAddress, _creatorRoyaltiesRate);

        if(address(proxyHook) != address(0)) {
            proxyHook.onSetCreatorRoyaltiesRate(_hashAddress, _creatorRoyaltiesRate);
        }
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
        (, address tAddress, uint256 tId, , , , , , ) = auctionSystem
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
        (, address _tokenAddress, uint256 tokenId, , , , , , ) = auctionSystem
            .getAuctionInfo(_auctionId);

        return getCreatorRate(_tokenAddress, tokenId);
    }

    function getCreatorRate(address nftAddress, uint256 token)
        public
        view
        override
        returns (uint256)
    {
        bytes32 hashKey = bytes32(bytes20(nftAddress));

        if (isCreatorRoyaltiesSet[hashKey]) {
            return creatorRoyaltiesRates[hashKey];
        }

        hashKey = keccak256(abi.encodePacked(nftAddress, token));
        return creatorRoyaltiesRates[hashKey];
    }

    function getMaxCreatorRoyaltiesRate()
        public
        view
        override
        returns (uint256)
    {
        return maxCreatorRoyaltiesRates;
    }

    function getMaxInvestorPirsRate() public view override returns (uint256) {
        return maxInvestorPirsRate;
    }

    function getMaxBidbackRate() public view override returns (uint256) {
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
