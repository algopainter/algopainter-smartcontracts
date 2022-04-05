// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./accessControl/AlgoPainterSimpleAccessControl.sol";
import "./interfaces/IAuctionHook.sol";
import "./interfaces/IAuctionRewardsRates.sol";
import "./interfaces/IAlgoPainterNFTCreators.sol";
import "./interfaces/IAlgoPainterRewardsDistributor.sol";
import "./interfaces/IAlgoPainterAuctionSystem.sol";
import "./interfaces/IAlgoPainterStorage.sol";

contract AlgoPainterAuctionHook is
    AlgoPainterSimpleAccessControl,
    IAuctionHook
{
    bytes32 public constant HOOK_CALLER_ROLE = keccak256("HOOK_CALLER_ROLE");

    IAuctionRewardsRates public proxyRates;
    IAlgoPainterRewardsDistributor public proxyDistributor;
    IAlgoPainterNFTCreators public proxyNFTCreators;
    IAlgoPainterAuctionSystem public proxyAuction;
    IAlgoPainterStorage public proxyStorage;

    function setStorage(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyStorage = IAlgoPainterStorage(adr);
    }

    function setRates(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyRates = IAuctionRewardsRates(adr);
    }

    function setDistributor(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyDistributor = IAlgoPainterRewardsDistributor(adr);
    }

    function setNFTCreators(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyNFTCreators = IAlgoPainterNFTCreators(adr);
    }

    function setAuction(address adr) public onlyRole(CONFIGURATOR_ROLE) {
        proxyAuction = IAlgoPainterAuctionSystem(adr);
    }

    function setAll(address[] calldata addresses)
        public
        onlyRole(CONFIGURATOR_ROLE)
    {
        setRates(addresses[0]);
        setDistributor(addresses[1]);
        setNFTCreators(addresses[2]);
        setAuction(addresses[3]);
        setStorage(addresses[4]);
    }

    function onAuctionCreated(
        uint256 auctionId,
        address owner,
        address nftAddress,
        uint256 nftTokenId,
        address tokenPriceAddress
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        IAuctionHook proxyHook = IAuctionHook(address(proxyDistributor));
        proxyHook.onAuctionCreated(
            auctionId,
            owner,
            nftAddress,
            nftTokenId,
            tokenPriceAddress
        );
    }

    function onBid(
        uint256 auctionId,
        address bidder,
        uint256 amount,
        uint256 feeAmount,
        uint256 netAmount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        IAuctionHook proxyHook = IAuctionHook(address(proxyDistributor));
        proxyHook.onBid(auctionId, bidder, amount, feeAmount, netAmount);
    }

    function onBidWithdraw(
        uint256 auctionId,
        address owner,
        uint256 amount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        IAuctionHook proxyHook = IAuctionHook(address(proxyDistributor));
        proxyHook.onBidWithdraw(auctionId, owner, amount);
    }

    function onAuctionEnded(
        uint256 auctionId,
        address winner,
        uint256 bidAmount,
        uint256 feeAmount,
        uint256 rewardsAmount,
        uint256 netAmount
    ) external override onlyRole(HOOK_CALLER_ROLE) {
        IAuctionHook proxyHook = IAuctionHook(address(proxyDistributor));
        proxyHook.onAuctionEnded(
            auctionId,
            winner,
            bidAmount,
            feeAmount,
            rewardsAmount,
            netAmount
        );
    }

    function onAuctionCancelled(uint256 auctionId, address owner)
        external
        override
        onlyRole(HOOK_CALLER_ROLE)
    {
        IAuctionHook proxyHook = IAuctionHook(address(proxyDistributor));
        proxyHook.onAuctionCancelled(
            auctionId,
            owner
        );
    }
}
