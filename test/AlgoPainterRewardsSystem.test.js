const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AlgoPainterRewardsSystem = artifacts.require('AlgoPainterRewardsSystem');
const AuctionRewardsRatesProviderMOCK = artifacts.require('AuctionRewardsRatesProviderMOCK');

const sleep = require('sleep');

contract('AlgoPainterRewardsSystem', (accounts) => {
  const AUCTION_FEE_ACCOUNT = accounts[9];
  const GWEI_OWNER_ACCOUNT = accounts[8];

  let algopToken;
  let gwei;
  let auctionSystem;
  let rewardsSystemManager;
  let ratesProviderMOCK;

  it('Setup auction and rewards system', async () => {
    algopToken = await AlgoPainterToken.new('ALGOP', 'ALGOP');
    gwei = await AlgoPainterGweiItem.new(algopToken.address, GWEI_OWNER_ACCOUNT);
    auctionSystem = await AlgoPainterAuctionSystem.new();
    rewardsSystemManager = await AlgoPainterRewardsSystem.new();
    ratesProviderMOCK = await AuctionRewardsRatesProviderMOCK.new();

    await algopToken.approve(gwei.address, web3.utils.toWei('200000', 'ether'));
    await gwei.mint(1, 'new text', false, 0, 2, web3.utils.toWei('300', 'ether'), 'URI');
    await gwei.setApprovalForAll(auctionSystem.address, true);
    
    await auctionSystem.setup(AUCTION_FEE_ACCOUNT, rewardsSystemManager.address, 1000, 500, [algopToken.address], rewardsSystemManager.address, ratesProviderMOCK.address);

    await rewardsSystemManager.setRewardsTokenAddress(algopToken.address);
    await rewardsSystemManager.setAuctionSystemAddress(auctionSystem.address);
    await rewardsSystemManager.setRewardsRatesProviderAddress(ratesProviderMOCK.address);
    await rewardsSystemManager.setRewardsTotalRatesProviderAddress(ratesProviderMOCK.address);

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
      );

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: INVALID_SENDER');
    }

    await rewardsSystemManager.setAllowedSender(auctionSystem.address);
    
    await auctionSystem.createAuction(
      0,
      gwei.address,
      1,
      web3.utils.toWei('100', 'ether'),
      (now + 30).toString(),
      algopToken.address,
    );
  });

  it('Users without bids can\'t stake on bidback', async () => {
    try {
      await rewardsSystemManager.stakeBidback(0, web3.utils.toWei('100', 'ether'));

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: USER_NOT_A_BIDDER');
    }
  });

  it('Each bidback stake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance.toString()).to.be.equal('0');
    
    await algopToken.approve(auctionSystem.address, web3.utils.toWei('200', 'ether'));
    await auctionSystem.bid(auctionId, web3.utils.toWei('100', 'ether'))

    const stakeAmount = web3.utils.toWei('100', 'ether');
    await algopToken.approve(rewardsSystemManager.address, stakeAmount);
    await rewardsSystemManager.stakeBidback(auctionId, stakeAmount);

    await algopToken.approve(rewardsSystemManager.address, stakeAmount);
    await rewardsSystemManager.stakeBidback(auctionId, stakeAmount);

    const rewardsSystemBalance2 = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));

    const totalBidbackStakes = await rewardsSystemManager.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await rewardsSystemManager.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await rewardsSystemManager.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('200', 'ether'));
    expect(bidbackUsers).to.deep.equal([accounts[0]]);
    
    expect(bidbackUsersList).to.deep.equal([accounts[0]]);
    expect(bidBackPercentages.length).to.be.equal(1);
    expect(bidBackPercentages[0].toString()).to.be.equal('10000');

    await algopToken.approve(auctionSystem.address, web3.utils.toWei('300', 'ether'), { from: accounts[1] });
    await auctionSystem.bid(auctionId, web3.utils.toWei('200', 'ether'), { from: accounts[1] })

    await algopToken.approve(auctionSystem.address, web3.utils.toWei('300', 'ether'), { from: accounts[2] });
    await auctionSystem.bid(auctionId, web3.utils.toWei('250', 'ether'), { from: accounts[2] })

    const stakeAmount2 = web3.utils.toWei('300', 'ether');
    await algopToken.approve(rewardsSystemManager.address, stakeAmount2, { from: accounts[1] });
    await rewardsSystemManager.stakeBidback(auctionId, stakeAmount2, { from: accounts[1] });

    const stakeAmount3 = web3.utils.toWei('300', 'ether');
    await algopToken.approve(rewardsSystemManager.address, stakeAmount3, { from: accounts[2] });
    await rewardsSystemManager.stakeBidback(auctionId, stakeAmount3, { from: accounts[2] });
    await rewardsSystemManager.unstakeBidback(auctionId, stakeAmount3, { from: accounts[2] });

    const rewardsSystemBalance3 = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance3.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));

    const totalBidbackStakes2 = await rewardsSystemManager.getTotalBidbackStakes(auctionId);
    const bidbackUsers2 = await rewardsSystemManager.getBidbackUsers(auctionId);
    const { users: bidbackUsersList2, percentages: bidBackPercentages2 } = await rewardsSystemManager.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes2.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));
    expect(bidbackUsers2).to.deep.equal([accounts[0], accounts[1], accounts[2]]);
    
    expect(bidbackUsersList2).to.deep.equal([accounts[0], accounts[1], accounts[2]]);
    expect(bidBackPercentages2.length).to.be.equal(3);
    expect(bidBackPercentages2[0].toString()).to.be.equal('4000');
    expect(bidBackPercentages2[1].toString()).to.be.equal('6000');
    expect(bidBackPercentages2[2].toString()).to.be.equal('0');

    const account0Balance = await algopToken.balanceOf(accounts[0]);
    const account1Balance = await algopToken.balanceOf(accounts[1]);

    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('96999395', 'ether'));
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('999490', 'ether'));
  });

  it('Each bidback unstake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const unstakeAmount = web3.utils.toWei('100', 'ether');
    await rewardsSystemManager.unstakeBidback(auctionId, unstakeAmount);

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    const account0Balance = await algopToken.balanceOf(accounts[0]);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('96999495', 'ether'));

    const totalBidbackStakes = await rewardsSystemManager.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await rewardsSystemManager.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await rewardsSystemManager.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));
    expect(bidbackUsers).to.deep.equal([accounts[0], accounts[1], accounts[2]]);
    
    expect(bidbackUsersList).to.deep.equal([accounts[0], accounts[1], accounts[2]]);
    expect(bidBackPercentages.length).to.be.equal(3);
    expect(bidBackPercentages[0].toString()).to.be.equal('2500');
    expect(bidBackPercentages[1].toString()).to.be.equal('7500');
    expect(bidBackPercentages[2].toString()).to.be.equal('0');
  });

  it('Users can\'t claim bidback on auction that has not yet ended', async () => {
    try {
      await rewardsSystemManager.claimBidback(0);
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: NOT_YET_ENDED');
    }
  });

  it('Users can\'t stake or unstake bidback on an ended auction', async () => {
    sleep.sleep(20);

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    await auctionSystem.endAuction(0);

    const rewardsSystemBalanceUpdated = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalanceUpdated.toString()).to.be.equal(web3.utils.toWei('550', 'ether'));

    try {
      await algopToken.approve(rewardsSystemManager.address, web3.utils.toWei('100', 'ether'));
      await rewardsSystemManager.stakeBidback(0, web3.utils.toWei('100', 'ether'));
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: AUCTION_ENDED');
    }

    try {
      await rewardsSystemManager.unstakeBidback(0, web3.utils.toWei('100', 'ether'));
      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: AUCTION_ENDED');
    }
  });

  it('Claim bidback', async () => {
    const account0Balance = await algopToken.balanceOf(accounts[0]);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('96999570', 'ether'));

    await rewardsSystemManager.claimBidback(0);

    const account0BalanceUpdated = await algopToken.balanceOf(accounts[0]);
    expect(account0BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('96999688.75', 'ether'));

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('431.25', 'ether'));

    const account1Balance = await algopToken.balanceOf(accounts[1]);
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('999490', 'ether'));

    await rewardsSystemManager.claimBidback(0, { from: accounts[1] });

    const account1BalanceUpdated = await algopToken.balanceOf(accounts[1]);
    expect(account1BalanceUpdated.toString()).to.be.equal(web3.utils.toWei('999846.25', 'ether'));

    const rewardsSystemBalance2 = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance2.toString()).to.be.equal(web3.utils.toWei('75', 'ether'));
  });
});
