const sleep = require('sleep');

contract.only('AlgoPainterRewardsDistributor', (accounts) => {
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
  const BIDBACK_RATE = '3000'; // 3000%

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

  it('Only setup contract can call rewards system', async () => {
    const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
    const expirationTime = (now + 60).toString();

    // await contracts.RewardsDistributor.setAllowedSender(contracts.AuctionSystem.address);

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
  });

  it('Users without bids can\'t stake on bidback', async () => {
    try {
      await contracts.RewardsDistributor.stakeBidback(0, web3.utils.toWei('100', 'ether'));

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('USER_NOT_BIDDER');
    }
  });

  it('Each bidback stake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const rewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal('0');

    await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('200', 'ether'), { from: USER_ONE });
    await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('100', 'ether'), { from: USER_ONE })

    const stakeAmount = web3.utils.toWei('100', 'ether');
    await contracts.ALGOP.approve(contracts.RewardsDistributor.address, stakeAmount, { from: USER_ONE });
    await contracts.RewardsDistributor.stakeBidback(auctionId, stakeAmount, { from: USER_ONE });

    await contracts.ALGOP.approve(contracts.RewardsDistributor.address, stakeAmount, { from: USER_ONE });
    await contracts.RewardsDistributor.stakeBidback(auctionId, stakeAmount, { from: USER_ONE });

    const rewardsSystemBalance2 = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));

    const totalBidbackStakes = await contracts.RewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await contracts.RewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await contracts.RewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));
    expect(bidbackUsers).to.deep.equal([USER_ONE]);

    expect(bidbackUsersList).to.deep.equal([USER_ONE]);
    expect(bidBackPercentages.length).to.be.equal(1);
    expect(bidBackPercentages[0].toString()).to.be.equal('10000');

    await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('300', 'ether'), { from: USER_TWO });
    await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('200', 'ether'), { from: USER_TWO })

    await contracts.ALGOP.approve(contracts.AuctionSystem.address, web3.utils.toWei('300', 'ether'), { from: USER_THREE });
    await contracts.AuctionSystem.bid(auctionId, web3.utils.toWei('250', 'ether'), { from: USER_THREE })

    const stakeAmount2 = web3.utils.toWei('300', 'ether');
    await contracts.ALGOP.approve(contracts.RewardsDistributor.address, stakeAmount2, { from: USER_TWO });
    await contracts.RewardsDistributor.stakeBidback(auctionId, stakeAmount2, { from: USER_TWO });

    const stakeAmount3 = web3.utils.toWei('300', 'ether');
    await contracts.ALGOP.approve(contracts.RewardsDistributor.address, stakeAmount3, { from: USER_THREE });
    await contracts.RewardsDistributor.stakeBidback(auctionId, stakeAmount3, { from: USER_THREE });
    await contracts.RewardsDistributor.unstakeBidback(auctionId, stakeAmount3, { from: USER_THREE });

    const rewardsSystemBalance3 = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance3.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));

    const totalBidbackStakes2 = await contracts.RewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers2 = await contracts.RewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList2, percentages: bidBackPercentages2 } = await contracts.RewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes2.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));
    expect(bidbackUsers2).to.deep.equal([USER_ONE, USER_TWO, USER_THREE]);

    expect(bidbackUsersList2).to.deep.equal([USER_ONE, USER_TWO, USER_THREE]);
    expect(bidBackPercentages2.length).to.be.equal(3);
    expect(bidBackPercentages2[0].toString()).to.be.equal('4000');
    expect(bidBackPercentages2[1].toString()).to.be.equal('6000');
    expect(bidBackPercentages2[2].toString()).to.be.equal('0');

    const account0Balance = await contracts.ALGOP.balanceOf(USER_ONE);
    const account1Balance = await contracts.ALGOP.balanceOf(USER_TWO);

    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('9397.5', 'ether'));
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('9495', 'ether'));
  });

  it('Each bidback unstake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const unstakeAmount = web3.utils.toWei('100', 'ether');
    await contracts.RewardsDistributor.unstakeBidback(auctionId, unstakeAmount, { from: USER_ONE });

    const rewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    const account0Balance = await contracts.ALGOP.balanceOf(USER_ONE);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('9497.5', 'ether'));

    const totalBidbackStakes = await contracts.RewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await contracts.RewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await contracts.RewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));
    expect(bidbackUsers).to.deep.equal([USER_ONE, USER_TWO, USER_THREE]);

    expect(bidbackUsersList).to.deep.equal([USER_ONE, USER_TWO, USER_THREE]);
    expect(bidBackPercentages.length).to.be.equal(3);
    expect(bidBackPercentages[0].toString()).to.be.equal('2500');
    expect(bidBackPercentages[1].toString()).to.be.equal('7500');
    expect(bidBackPercentages[2].toString()).to.be.equal('0');
  });

  it('Users can\'t claim bidback on auction that has not yet ended', async () => {
    try {
      await contracts.RewardsDistributor.claimBidback(0, { from: USER_ONE });
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AUCTION_RUNNING');
    }
  });

  function toReadableObj(obj) {
    const newObj = {};
    Object.keys(obj).forEach(key => {
      if (isNaN(key))
        newObj[key] = obj[key].toString();
    });
    return newObj;
  }

  it('Check Auction rewards before distribute', async () => {
    // console.log('Gwei Address: ', contracts.Gwei.address);
    var hashKey = await contracts.NFTCreators.getHashKey(contracts.Gwei.address);
    // console.log('Creator HashKey: ', hashKey);
    var nftCreator = await contracts.NFTCreators.getCreatorNotPayable(contracts.Gwei.address, 1);
    // console.log('Creator: ', contracts.NFTCreators);
    // console.log('Balance Of ' + contracts.NFTCreators + ': ', (await contracts.ALGOP.balanceOf(contracts.NFTCreators)).toString());
    var auctionInfo = toReadableObj(await contracts.AuctionSystem.getAuctionInfo(0));
    // console.log('Auction Info', auctionInfo);
    var auctionRewards = toReadableObj(await contracts.AuctionSystem.getAuctionAmountInfo(0, auctionInfo.highestBid))
    // console.log('Auction Rewards', auctionRewards);
  });

  it('Users can\'t stake or unstake bidback on an ended auction', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(contracts.Gwei.address, 1);

    sleep.sleep(60);

    const rewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    var hashKey = await contracts.NFTCreators.getHashKey(contracts.Gwei.address, 1);
    var nftCreator = await contracts.NFTCreators.getCreatorNotPayable(contracts.Gwei.address, 1);
    var creatorBalanceBeforeEnd = (await contracts.ALGOP.balanceOf(contracts.NFTCreators.address)).toString();

    expect(creatorBalanceBeforeEnd).to.be.equal('0');

    await contracts.AuctionSystem.endAuction(auctionId, { from: USER_ONE });

    var creatorBalanceAfterEnd = (await contracts.ALGOP.balanceOf(contracts.NFTCreators.address)).toString();
    expect(creatorBalanceAfterEnd).to.be.equal('0');

    const rewardsSystemBalanceUpdated = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalanceUpdated.toString()).to.be.equal(web3.utils.toWei('475', 'ether'));

    try {
      await contracts.ALGOP.approve(contracts.RewardsDistributor.address, web3.utils.toWei('100', 'ether'));
      await contracts.RewardsDistributor.stakeBidback(0, web3.utils.toWei('100', 'ether'), { from: USER_ONE });
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AUCTION_ENDED');
    }
  });

  it('Claim bidback', async () => {
    const account0Balance = await contracts.ALGOP.balanceOf(USER_ONE);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('9653.75', 'ether'));

    await contracts.RewardsDistributor.claimBidback(0, { from: USER_ONE });

    const account0BalanceUpdated = await contracts.ALGOP.balanceOf(USER_ONE);
    expect(account0BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('9772.5', 'ether'));

    const rewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('356.25', 'ether'));

    const account1Balance = await contracts.ALGOP.balanceOf(USER_TWO);
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('9495', 'ether'));

    await contracts.RewardsDistributor.claimBidback(0, { from: USER_TWO });

    const account1BalanceUpdated = await contracts.ALGOP.balanceOf(USER_TWO);
    expect(account1BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('9851.25', 'ether'));

    const rewardsSystemBalance2 = await contracts.ALGOP.balanceOf(contracts.RewardsDistributor.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('0', 'ether'));
  });
});
