//This is a happy scenario testing no mocks
contract('AlgoPainterEveryoneHappy', accounts => {
    const sleep = require('sleep');
    const AlgoPainterToken = artifacts.require('AlgoPainterToken');
    const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
    const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
    const AlgoPainterRewardsRates = artifacts.require('AlgoPainterRewardsRates');
    const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');
    const AlgoPainterRewardsDistributor = artifacts.require('AlgoPainterRewardsDistributor');
    const AlgoPainterStorage = artifacts.require('AlgoPainterStorage');
    const AlgoPainterSecurity = artifacts.require('AlgoPainterSecurity');
    const AlgoPainterAuctionSystemHook = artifacts.require('AlgoPainterAuctionHook');

    const contracts = {
        ALGOP: null,
        Gwei: null,
        AuctionSystem: null,
        AuctionSystemHook: null,
        RewardsRates: null,
        NFTCreators: null,
        RewardsDistributor: null,
        RewardsDistributorHook: null,
        Storage: null,
        Security: null
    }

    const DEV_FEE = '250'; // 2.5%
    const GWEI_CREATOR = accounts[7];
    const GWEI_DEV = accounts[9];
    const DEV_FEE_ACCOUNT = accounts[8];
    const CREATOR_RATE = '500'; // 5%
    const PIRS_RATE = '1500'; // 15%
    const BIDBACK_RATE = '1000'; // 10%

    const USER_ONE = accounts[1];
    const USER_TWO = accounts[2];
    const USER_THREE = accounts[3];
    const USER_FOUR = accounts[4];

    const assertBalance = async (account, amount) => {
        const balance = await contracts.ALGOP.balanceOf(account);
        return expect(balance.toString()).to.be.equal(amount, 'account ' + account.toString() + " is not valid, its " + balance.toString());
    }

    it('Should initiate contracts', async () => {
        contracts.ALGOP = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
        contracts.Gwei = await AlgoPainterGweiItem.new(contracts.ALGOP.address, GWEI_DEV);
        contracts.NFTCreators = await AlgoPainterNFTCreators.new();
        contracts.Storage = await AlgoPainterStorage.new();
        contracts.Security = await AlgoPainterSecurity.new(contracts.Storage.address);
        contracts.AuctionSystemHook = await AlgoPainterAuctionSystemHook.new();
        contracts.AuctionSystem = await AlgoPainterAuctionSystem.new(
            '1209600',
            DEV_FEE_ACCOUNT,
            DEV_FEE,
            DEV_FEE,
            [contracts.ALGOP.address],
            contracts.AuctionSystemHook.address
        );
        contracts.RewardsDistributor = await AlgoPainterRewardsDistributor.new(
            '1209600',
            contracts.AuctionSystem.address,
            contracts.ALGOP.address
        );
        contracts.RewardsRates = await AlgoPainterRewardsRates.new(
            '1209600',
            3000,
            3000,
            3000,
            contracts.RewardsDistributor.address,
            contracts.AuctionSystem.address,
            contracts.Gwei.address,
            web3.utils.randomHex(20),
            CREATOR_RATE,
            CREATOR_RATE
        );

        //configure Auction System
        await contracts.AuctionSystem.setRates(contracts.RewardsRates.address);
        await contracts.AuctionSystem.setRewardsDistributorAddress(contracts.RewardsDistributor.address);
        await contracts.AuctionSystem.setCreators(contracts.NFTCreators.address);

        //configure Auction Hook
        await contracts.AuctionSystemHook.grantRole(await contracts.AuctionSystemHook.HOOK_CALLER_ROLE(), contracts.AuctionSystem.address);
        await contracts.AuctionSystemHook.setAll([
            contracts.RewardsRates.address,
            contracts.RewardsDistributor.address,
            contracts.NFTCreators.address,
            contracts.Storage.address,
            contracts.Security.address
        ]);

        //configure Rates
        await contracts.RewardsRates.grantRole(await contracts.RewardsRates.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
        
        //configure Rewards
        await contracts.RewardsDistributor.setRewardsRatesProviderAddress(contracts.RewardsRates.address);
        await contracts.RewardsDistributor.grantRole(await contracts.RewardsDistributor.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);

        //configure NFTCreators
        await contracts.NFTCreators.grantRole(await contracts.NFTCreators.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
        await contracts.NFTCreators.setCreator(contracts.Gwei.address, GWEI_CREATOR);

        //configure Storage
        await contracts.Storage.grantRole(await contracts.Storage.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
        await contracts.Storage.grantRole(await contracts.Storage.CONFIGURATOR_ROLE(), contracts.Security.address);

        //configurations for unit test
        await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true);
        await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_ONE });
        await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_TWO });
        await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_THREE });
        await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_FOUR });
        await contracts.Gwei.setApprovalForAll(USER_ONE, true);
        await contracts.Gwei.setApprovalForAll(USER_TWO, true);
        await contracts.Gwei.setApprovalForAll(USER_THREE, true);
        await contracts.Gwei.setApprovalForAll(USER_FOUR, true);
        await contracts.Gwei.manageWhitelist([USER_ONE, USER_TWO], true);

        await contracts.ALGOP.transfer(USER_ONE, web3.utils.toWei('10000', 'ether'));
        await contracts.ALGOP.transfer(USER_TWO, web3.utils.toWei('10000', 'ether'));
        await contracts.ALGOP.transfer(USER_THREE, web3.utils.toWei('10000', 'ether'));
        await contracts.ALGOP.transfer(USER_FOUR, web3.utils.toWei('10000', 'ether'));
        await contracts.ALGOP.approve(contracts.Gwei.address, web3.utils.toWei('10000', 'ether'), { from: USER_ONE });
        await contracts.ALGOP.approve(contracts.Gwei.address, web3.utils.toWei('10000', 'ether'), { from: USER_TWO });
        await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('10000', 'ether'), { from: USER_ONE });
        await contracts.ALGOP.approve(contracts.RewardsDistributor.address, web3.utils.toWei('10000', 'ether'), { from: USER_ONE });
        await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('10000', 'ether'), { from: USER_TWO });
        await contracts.ALGOP.approve(contracts.RewardsDistributor.address, web3.utils.toWei('10000', 'ether'), { from: USER_TWO });
        await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('10000', 'ether'), { from: USER_THREE });
        await contracts.ALGOP.approve(contracts.RewardsDistributor.address, web3.utils.toWei('10000', 'ether'), { from: USER_THREE });
        await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('10000', 'ether'), { from: USER_FOUR });
        await contracts.ALGOP.approve(contracts.RewardsDistributor.address, web3.utils.toWei('10000', 'ether'), { from: USER_FOUR });

    });

    it('Should mint a gwei nft', async () => {
        await contracts.Gwei.mint(1, 'new text', false, 0, 2, web3.utils.toWei('300', 'ether'), 'URI', { from: USER_ONE });
        await contracts.RewardsRates.setPIRSRate(contracts.Gwei.address, 1, PIRS_RATE);
        await assertBalance(USER_ONE, web3.utils.toWei('9700', 'ether'));
        await assertBalance(GWEI_DEV, web3.utils.toWei('300', 'ether')); //Gwei Dev
    });

    it('Should successfully auction without rewards', async () => {
        const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
        const expirationTime = (now + 10).toString();

        await contracts.AuctionSystem.createAuction(
            contracts.Gwei.address, 
            1, 
            web3.utils.toWei('100', 'ether'), 
            expirationTime, 
            contracts.ALGOP.address, 
            BIDBACK_RATE, 
            CREATOR_RATE, 
            PIRS_RATE, 
            { from: USER_ONE }
        );

        const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

        await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('1000', 'ether'), { from: USER_TWO });

        sleep.sleep(10);

        await contracts.AuctionSystem.endAuction(auctionId, { from: USER_ONE });

        await assertBalance(USER_ONE, web3.utils.toWei('10625', 'ether'));
        await assertBalance(USER_TWO, web3.utils.toWei('8975', 'ether'));
        await assertBalance(GWEI_CREATOR, web3.utils.toWei('50', 'ether'));
    });

    it('Should successfully auction with BidBack rewards', async () => {
        const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
        const expirationTime = (now + 15).toString();

        await contracts.AuctionSystem.createAuction(
            contracts.Gwei.address, 
            1, 
            web3.utils.toWei('100', 'ether'), 
            expirationTime, 
            contracts.ALGOP.address, 
            BIDBACK_RATE, 
            CREATOR_RATE, 
            PIRS_RATE, 
            { from: USER_TWO }
        );

        const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

        await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('500', 'ether'), { from: USER_THREE });
        await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('1000', 'ether'), { from: USER_FOUR });

        await contracts.RewardsDistributor.stakeBidback(auctionId, web3.utils.toWei('500', 'ether'), { from: USER_THREE });

        sleep.sleep(15);

        await contracts.AuctionSystem.endAuction(auctionId, { from: USER_TWO });

        await assertBalance(USER_ONE, web3.utils.toWei('10625', 'ether'));
        await assertBalance(USER_THREE, web3.utils.toWei('8987.5', 'ether'));
        await assertBalance(USER_FOUR, web3.utils.toWei('8975', 'ether'));
        await assertBalance(GWEI_CREATOR, web3.utils.toWei('100', 'ether'));

        await contracts.RewardsDistributor.claimBidback(auctionId, { from: USER_THREE });

        await assertBalance(USER_THREE, web3.utils.toWei('9587.5', 'ether'));
        await assertBalance(USER_TWO, web3.utils.toWei('9800', 'ether'));
    });

    it('Should successfully auction with Pirs rewards', async () => {
        const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
        const expirationTime = (now + 15).toString();

        await contracts.AuctionSystem.createAuction(
            contracts.Gwei.address, 
            1, 
            web3.utils.toWei('100', 'ether'), 
            expirationTime, 
            contracts.ALGOP.address, 
            BIDBACK_RATE, 
            CREATOR_RATE, 
            PIRS_RATE, 
            { from: USER_FOUR }
        );

        await assertBalance(USER_ONE, web3.utils.toWei('10625', 'ether'));
        await assertBalance(USER_TWO, web3.utils.toWei('9800', 'ether'));
        await assertBalance(USER_THREE, web3.utils.toWei('9587.5', 'ether'));
        await assertBalance(USER_FOUR, web3.utils.toWei('8975', 'ether'));
        await assertBalance(GWEI_CREATOR, web3.utils.toWei('100', 'ether'));

        const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

        await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('500', 'ether'), { from: USER_TWO });
        await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('1000', 'ether'), { from: USER_THREE });

        await contracts.RewardsDistributor.stakePirs(auctionId, web3.utils.toWei('500', 'ether'), { from: USER_TWO });
        await contracts.RewardsDistributor.stakeBidback(auctionId, web3.utils.toWei('500', 'ether'), { from: USER_TWO });

        sleep.sleep(15);

        await contracts.AuctionSystem.withdraw(auctionId, { from: USER_TWO });

        await contracts.AuctionSystem.endAuction(auctionId, { from: USER_FOUR });
        await contracts.RewardsDistributor.claimPirs(auctionId, { from: USER_TWO });

        await assertBalance(USER_ONE, web3.utils.toWei('10625', 'ether'));
        await assertBalance(USER_TWO, web3.utils.toWei('9937.5', 'ether'));
        await assertBalance(USER_THREE, web3.utils.toWei('8562.5', 'ether'));
        await assertBalance(USER_FOUR, web3.utils.toWei('9750', 'ether'));
        await assertBalance(GWEI_CREATOR, web3.utils.toWei('150', 'ether'));
    });
});