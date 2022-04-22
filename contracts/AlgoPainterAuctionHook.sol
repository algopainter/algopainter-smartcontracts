// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";
import "./interfaces/IAuctionRewardsDistributor.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAlgoPainterStorage.sol";
import "./interfaces/ISecurity.sol";

contract AlgoPainterAuctionHook is
    AlgoPainterSimpleAccessControl,
    IAuctionHook
{
    bytes32 public constant HOOK_CALLER_ROLE = keccak256("HOOK_CALLER_ROLE");

    IAuctionRewardsRates public proxyRates;
    IAuctionRewardsDistributor public proxyDistributor;
    IAlgoPainterNFTCreators public proxyNFTCreators;
    IAlgoPainterStorage public proxyStorage;
    ISecurity public proxySecurity;

    function setStorage(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyStorage = IAlgoPainterStorage(adr);
    }

    function setRates(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyRates = IAuctionRewardsRates(adr);
    }

    function setDistributor(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyDistributor = IAuctionRewardsDistributor(adr);
    }

    function setNFTCreators(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyNFTCreators = IAlgoPainterNFTCreators(adr);
    }

    function setSecurity(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxySecurity = ISecurity(adr);
    }

    function setAll(address[] calldata addresses)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        setRates(addresses[0]);
        setDistributor(addresses[1]);
        setNFTCreators(addresses[2]);
        setStorage(addresses[3]);
        setSecurity(addresses[4]);
    }

    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        uint256 bidbackRate,
        uint256 creatorRate,
        uint256 pirsRate,
        address tokenPriceAddress,
        uint256 price
    ) public override onlyRole(HOOK_CALLER_ROLE) {
        require(
            !proxySecurity.isBanned(tx.origin) ||
                !proxySecurity.isBannedByContract(msg.sender, tx.origin),
            "BLACKLISTED"
        );

        bool nftPIRSRate = proxyRates.hasPIRSRateSetPerImage(
            nftAddress,
            nftTokenId
        );

        if (!nftPIRSRate) {
            proxyRates.setPIRSRate(nftAddress, nftTokenId, pirsRate);
        }

        proxyRates.setBidbackRate(auctionId, bidbackRate);

        bool hasCreatorRateSet = proxyRates.isCreatorRateSet(
            nftAddress,
            nftTokenId
        );

        if (!hasCreatorRateSet) {
            proxyRates.setCreatorRoyaltiesRate(
                keccak256(abi.encodePacked(nftAddress, nftTokenId)),
                creatorRate
            );
        }
    }

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        require(
            !proxySecurity.isBanned(tx.origin) ||
                !proxySecurity.isBannedByContract(msg.sender, tx.origin),
            "BLACKLISTED"
        );
        proxyDistributor.addEligibleBidder(auctionId, bidder);
    }

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        proxyDistributor.remAccountFromBidRewards(auctionId, owner);
    }

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount,
        uint256 creatorAmount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        proxyDistributor.setAuctionRewardsDistributable(
            auctionId,
            rewardsAmount
        );
    }

    function onAuctionCancelled(uint256 auctionId, address owner)
        external
        override
        onlyRole(HOOK_CALLER_ROLE)
    {}
}
