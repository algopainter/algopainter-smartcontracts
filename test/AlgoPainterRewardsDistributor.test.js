const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AlgoPainterRewardsDistributor = artifacts.require('AlgoPainterRewardsDistributor');
const AuctionRewardsRatesProviderMOCK = artifacts.require('AuctionRewardsRatesMOCK');
const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

const sleep = require('sleep');

contract('AlgoPainterRewardsDistributor', (accounts) => {
  const AUCTION_FEE_ACCOUNT = accounts[9];
  const GWEI_OWNER_ACCOUNT = accounts[8];

  let algopToken;
  let gwei;
  let auctionSystem;
  let rewardsDistributor;
  let rewardsRatesMOCK;
  let nftCreators = null;

  it('Setup auction and rewards system', async () => {
    algopToken = await AlgoPainterToken.new('ALGOP', 'ALGOP');
    gwei = await AlgoPainterGweiItem.new(algopToken.address, GWEI_OWNER_ACCOUNT);
    auctionSystem = await AlgoPainterAuctionSystem.new();
    rewardsDistributor = await AlgoPainterRewardsDistributor.new();
    rewardsRatesMOCK = await AuctionRewardsRatesProviderMOCK.new();
    nftCreators = await AlgoPainterNFTCreators.new();

    await algopToken.approve(gwei.address, web3.utils.toWei('200000', 'ether'));
    await gwei.mint(1, 'new text', false, 0, 2, web3.utils.toWei('300', 'ether'), 'URI');
    await gwei.setApprovalForAll(auctionSystem.address, true);

    await auctionSystem.setup(AUCTION_FEE_ACCOUNT, rewardsDistributor.address, 1000, 500, [algopToken.address], rewardsRatesMOCK.address);
    await auctionSystem.setAlgoPainterNFTCreators(nftCreators.address);
    await rewardsRatesMOCK.grantRole(await rewardsRatesMOCK.CONFIGURATOR_ROLE(), auctionSystem.address);
    await nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE(), auctionSystem.address);

    await rewardsDistributor.setAuctionSystemAddress(auctionSystem.address);
    await rewardsDistributor.setStakeToken(algopToken.address);
    await rewardsDistributor.setRewardsRatesProviderAddress(rewardsRatesMOCK.address);

    const baseAmount = web3.utils.toWei('1000000', 'ether');

    await algopToken.transfer(accounts[1], baseAmount);
    await algopToken.transfer(accounts[2], baseAmount);
    await algopToken.transfer(accounts[3], baseAmount);
  });

  it('Only setup contract can call rewards system', async () => {
    const now = parseInt((await auctionSystem.getNow()).toString());

    try {
      await auctionSystem.createAuction(
        0,
        gwei.address,
        1,
        web3.utils.toWei('100', 'ether'),
        (now + 30).toString(),
        algopToken.address,
        3000
      );

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsDistributor:INVALID_SENDER');
    }

    await rewardsDistributor.setAllowedSender(auctionSystem.address);

    await auctionSystem.createAuction(
      0,
      gwei.address,
      1,
      web3.utils.toWei('100', 'ether'),
      (now + 30).toString(),
      algopToken.address,
      3000
    );
  });

  it('Users without bids can\'t stake on bidback', async () => {
    try {
      await rewardsDistributor.stakeBidback(0, web3.utils.toWei('100', 'ether'));

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsDistributor:USER_NOT_A_BIDDER');
    }
  });

  it('Each bidback stake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal('0');

    await algopToken.approve(auctionSystem.address, web3.utils.toWei('200', 'ether'), { from: accounts[1] });
    await auctionSystem.bid(auctionId, web3.utils.toWei('100', 'ether'), { from: accounts[1] })

    const stakeAmount = web3.utils.toWei('100', 'ether');
    await algopToken.approve(rewardsDistributor.address, stakeAmount, { from: accounts[1] });
    await rewardsDistributor.stakeBidback(auctionId, stakeAmount, { from: accounts[1] });

    await algopToken.approve(rewardsDistributor.address, stakeAmount, { from: accounts[1] });
    await rewardsDistributor.stakeBidback(auctionId, stakeAmount, { from: accounts[1] });

    const rewardsSystemBalance2 = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));

    const totalBidbackStakes = await rewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await rewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await rewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));
    expect(bidbackUsers).to.deep.equal([accounts[1]]);

    expect(bidbackUsersList).to.deep.equal([accounts[1]]);
    expect(bidBackPercentages.length).to.be.equal(1);
    expect(bidBackPercentages[0].toString()).to.be.equal('10000');

    await algopToken.approve(auctionSystem.address, web3.utils.toWei('300', 'ether'), { from: accounts[2] });
    await auctionSystem.bid(auctionId, web3.utils.toWei('200', 'ether'), { from: accounts[2] })

    await algopToken.approve(auctionSystem.address, web3.utils.toWei('300', 'ether'), { from: accounts[3] });
    await auctionSystem.bid(auctionId, web3.utils.toWei('250', 'ether'), { from: accounts[3] })

    const stakeAmount2 = web3.utils.toWei('300', 'ether');
    await algopToken.approve(rewardsDistributor.address, stakeAmount2, { from: accounts[2] });
    await rewardsDistributor.stakeBidback(auctionId, stakeAmount2, { from: accounts[2] });

    const stakeAmount3 = web3.utils.toWei('300', 'ether');
    await algopToken.approve(rewardsDistributor.address, stakeAmount3, { from: accounts[3] });
    await rewardsDistributor.stakeBidback(auctionId, stakeAmount3, { from: accounts[3] });
    await rewardsDistributor.unstakeBidback(auctionId, stakeAmount3, { from: accounts[3] });

    const rewardsSystemBalance3 = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance3.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));

    const totalBidbackStakes2 = await rewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers2 = await rewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList2, percentages: bidBackPercentages2 } = await rewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes2.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));
    expect(bidbackUsers2).to.deep.equal([accounts[1], accounts[2], accounts[3]]);

    expect(bidbackUsersList2).to.deep.equal([accounts[1], accounts[2], accounts[3]]);
    expect(bidBackPercentages2.length).to.be.equal(3);
    expect(bidBackPercentages2[0].toString()).to.be.equal('4000');
    expect(bidBackPercentages2[1].toString()).to.be.equal('6000');
    expect(bidBackPercentages2[2].toString()).to.be.equal('0');

    const account0Balance = await algopToken.balanceOf(accounts[1]);
    const account1Balance = await algopToken.balanceOf(accounts[2]);

    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('999695', 'ether'));
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('999490', 'ether'));
  });

  it('Each bidback unstake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const unstakeAmount = web3.utils.toWei('100', 'ether');
    await rewardsDistributor.unstakeBidback(auctionId, unstakeAmount, { from: accounts[1] });

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    const account0Balance = await algopToken.balanceOf(accounts[1]);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('999795', 'ether'));

    const totalBidbackStakes = await rewardsDistributor.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await rewardsDistributor.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await rewardsDistributor.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));
    expect(bidbackUsers).to.deep.equal([accounts[1], accounts[2], accounts[3]]);

    expect(bidbackUsersList).to.deep.equal([accounts[1], accounts[2], accounts[3]]);
    expect(bidBackPercentages.length).to.be.equal(3);
    expect(bidBackPercentages[0].toString()).to.be.equal('2500');
    expect(bidBackPercentages[1].toString()).to.be.equal('7500');
    expect(bidBackPercentages[2].toString()).to.be.equal('0');
  });

  it('Users can\'t claim bidback on auction that has not yet ended', async () => {
    try {
      await rewardsDistributor.claimBidback(0, { from: accounts[1] });
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsDistributor:AUCTION_STILL_RUNNING');
    }
  });

  function toReadableObj(obj) {
    const newObj = {};
    Object.keys(obj).forEach(key => {
      if(isNaN(key))
        newObj[key] = obj[key].toString();
    });
    return newObj;
  }

  it('Check Auction rewards before distribute', async () => {
    console.log('Gwei Address: ', gwei.address);
    var hashKey = await nftCreators.getHashKey(gwei.address, 1);
    console.log('Creator HashKey: ', hashKey);
    var nftCreator = await nftCreators.getCreatorNotPayable(hashKey);
    console.log('Creator: ', nftCreator);
    console.log('Balance Of ' + nftCreator + ': ', (await algopToken.balanceOf(nftCreator)).toString());
    var auctionInfo = toReadableObj(await auctionSystem.getAuctionInfo(0));
    console.log('Auction Info', auctionInfo);
    var auctionRewards = toReadableObj(await auctionSystem.getAuctionAmountInfo(0, auctionInfo.highestBid))
    console.log('Auction Rewards', auctionRewards);
  });

  it('Users can\'t stake or unstake bidback on an ended auction', async () => {
    sleep.sleep(30);

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));
    
    var hashKey = await nftCreators.getHashKey(gwei.address, 1);
    var nftCreator = await nftCreators.getCreatorNotPayable(hashKey);
    var creatorBalanceBeforeEnd = (await algopToken.balanceOf(nftCreator)).toString();

    expect(creatorBalanceBeforeEnd).to.be.equal('96999700000000000000000000');

    await auctionSystem.endAuction(0);

    var creatorBalanceAfterEnd = (await algopToken.balanceOf(nftCreator)).toString();
    expect(creatorBalanceAfterEnd).to.be.equal('96999800000000000000000000');

    const rewardsSystemBalanceUpdated = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalanceUpdated.toString()).to.be.equal(web3.utils.toWei('525', 'ether'));

    try {
      await algopToken.approve(rewardsDistributor.address, web3.utils.toWei('100', 'ether'));
      await rewardsDistributor.stakeBidback(0, web3.utils.toWei('100', 'ether'), { from: accounts[1] });
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsDistributor:AUCTION_ENDED');
    }

    try {
      await rewardsDistributor.unstakeBidback(0, web3.utils.toWei('100', 'ether'), { from: accounts[2] });
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsDistributor:AUCTION_ENDED');
    }
  });

  it('Claim bidback', async () => {
    const account0Balance = await algopToken.balanceOf(accounts[1]);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('999795', 'ether'));

    await rewardsDistributor.claimBidback(0, { from: accounts[1] });

    const account0BalanceUpdated = await algopToken.balanceOf(accounts[1]);
    expect(account0BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('999913.75', 'ether'));

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('406.25', 'ether'));

    const account1Balance = await algopToken.balanceOf(accounts[2]);
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('999490', 'ether'));

    await rewardsDistributor.claimBidback(0, { from: accounts[2] });

    const account1BalanceUpdated = await algopToken.balanceOf(accounts[2]);
    expect(account1BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('999846.25', 'ether'));

    const rewardsSystemBalance2 = await algopToken.balanceOf(rewardsDistributor.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('50', 'ether'));
  });
});
