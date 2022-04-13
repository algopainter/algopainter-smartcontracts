contract('AlgoPainterRewardsRates', accounts => {
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

  it('Should set max investor pirs for all collections and a investor pirs for a specific image in a collection', async () => {
    await contracts.RewardsRates.setMaxPIRSRate(3000); // 

    const maxPirs = await contracts.RewardsRates.getMaxInvestorPirsRate();
    expect(maxPirs.toString()).to.be.equal('3000', 'fail to check maxInvestorPirsRate');

    const unsettedPirs = await contracts.RewardsRates.getPIRSRatePerImage(contracts.Gwei.address, 1);
    expect(unsettedPirs.toString()).to.be.equal('0', 'fail to check creatorRoyaltiesRate');

    await contracts.RewardsRates.setPIRSRate(contracts.Gwei.address, 1, 250);

    const updatedPirs = await contracts.RewardsRates.getPIRSRatePerImage(contracts.Gwei.address, 1);
    expect(updatedPirs.toString()).to.be.equal('250', 'fail to check creatorRoyaltiesRate');
  });

  it('Should mint a gwei nft', async () => {
    await contracts.Gwei.mint(1, 'new text', false, 0, 2, web3.utils.toWei('300', 'ether'), 'URI', { from: USER_ONE });
    await assertBalance(USER_ONE, web3.utils.toWei('9700', 'ether'));
    await assertBalance(GWEI_DEV, web3.utils.toWei('300', 'ether')); //Gwei Dev
  });

  it('Should set max bidback for all auctions and a bidback for an auction', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

    await contracts.RewardsRates.setMaxBidbackRate(3000);

    const maxBidback = await contracts.RewardsRates.getMaxBidbackRate();
    expect(maxBidback.toString()).to.be.equal('3000', 'fail to check maxBidbackRate');

    const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
    const expirationTime = (now + 10).toString();

    try {
      await contracts.AuctionSystem.createAuction(
        contracts.Gwei.address, 
        1, 
        web3.utils.toWei('100', 'ether'), 
        expirationTime, 
        contracts.ALGOP.address, 
        4000, 
        CREATOR_RATE, 
        PIRS_RATE, 
        { from: USER_ONE }
      );
    } catch (e) {
      expect(e.reason).to.be.equal("BIDBACK_IS_GREATER_THAN_ALLOWED");
    }

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

    const bidback = await contracts.RewardsRates.getBidbackRate(auctionId);
    expect(bidback.toString()).to.be.equal('1000', 'fail to check bidbackRate');
  });

  it('Should set max creator pirs and a creator pirs for a collection', async () => {
    await contracts.RewardsRates.setMaxCreatorRoyaltiesRate(3000);

    const maxPirs = await contracts.RewardsRates.getMaxCreatorRoyaltiesRate();
    expect(maxPirs.toString()).to.be.equal('3000', 'fail to check maxCreatorRoyaltiesRate');

    const unsettedPirs = await contracts.RewardsRates.getCreatorRoyaltiesRate(0);
    expect(unsettedPirs.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');

    await contracts.RewardsRates.setCreatorRoyaltiesRate(contracts.Gwei.address, 150);

    const updatedPirs = await contracts.RewardsRates.getCreatorRoyaltiesRate(0);
    expect(updatedPirs.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');

    const updatedPirsByAddress = await contracts.RewardsRates.getCreatorRoyaltiesByTokenAddress(contracts.Gwei.address);
    expect(updatedPirsByAddress.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');

    const updatedPirsByAddress2 = await contracts.RewardsRates.getCreatorRate(contracts.Gwei.address, 0);
    expect(updatedPirsByAddress2.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');
  });

  it('Should return the sum of all rewards', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

    const pirsRate = await contracts.RewardsRates.getPIRSRate(auctionId);
    const bidbackRate = await contracts.RewardsRates.getBidbackRate(auctionId);
    const rewardsRate = await contracts.RewardsRates.getRewardsRate(auctionId);
    expect(rewardsRate.toString()).to.be.equal('0', 'fail to check rewards rate');
    expect(pirsRate.toString()).to.be.equal('250', 'fail to check rewards rate');
    expect(bidbackRate.toString()).to.be.equal('1000', 'fail to check rewards rate');
  });
});
