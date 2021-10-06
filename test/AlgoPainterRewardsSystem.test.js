const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AlgoPainterRewardsSystem = artifacts.require('AlgoPainterRewardsSystem');

contract('AlgoPainterRewardsSystem', (accounts) => {
  const AUCTION_FEE_ACCOUNT = accounts[9];
  const GWEI_OWNER_ACCOUNT = accounts[8];

  let algopToken;
  let gwei;
  let auctionSystem;
  let rewardsSystemManager;

  it('Setup auction and rewards system', async () => {
    algopToken = await AlgoPainterToken.new('ALGOP', 'ALGOP');
    gwei = await AlgoPainterGweiItem.new(algopToken.address, GWEI_OWNER_ACCOUNT);
    auctionSystem = await AlgoPainterAuctionSystem.new();
    rewardsSystemManager = await AlgoPainterRewardsSystem.new();

    await algopToken.approve(gwei.address, web3.utils.toWei('100000', 'ether'));
    await gwei.mint(1, 'new text', false, 0, 2, web3.utils.toWei('300', 'ether'), 'URI');
    await gwei.setApprovalForAll(auctionSystem.address, true);
    
    await auctionSystem.setup(AUCTION_FEE_ACCOUNT, 1000, 500, [algopToken.address], rewardsSystemManager.address);

    await rewardsSystemManager.setRewardsTokenAddress(algopToken.address);

    const baseAmount = web3.utils.toWei('1000000', 'ether');

    await algopToken.transfer(accounts[1], baseAmount);
    await algopToken.transfer(accounts[2], baseAmount);
    await algopToken.transfer(accounts[3], baseAmount);
  });

  it('Only setup contract can call rewards system', async () => {
    try {
      const now = await auctionSystem.getNow();

      await auctionSystem.createAuction(
        0,
        gwei.address,
        1,
        web3.utils.toWei('100', 'ether'),
        (now + 20).toString(),
        algopToken.address,
        1000
      );

      throw {};
    } catch (error) {
      expect(error.reason).to.be.equal('AlgoPainterRewardsSystem: INVALID_SENDER');
    }

    await rewardsSystemManager.setAllowedSender(auctionSystem.address);
    
    const now = await auctionSystem.getNow();

    await auctionSystem.createAuction(
      0,
      gwei.address,
      1,
      web3.utils.toWei('100', 'ether'),
      (now + 20).toString(),
      algopToken.address,
      1000
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
    
    const bidAmount = web3.utils.toWei('100', 'ether');
    await algopToken.approve(auctionSystem.address, bidAmount);
    await auctionSystem.bid(auctionId, bidAmount)

    const stakeAmount = web3.utils.toWei('200', 'ether');
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

    const bidAmount2 = web3.utils.toWei('200', 'ether');
    await algopToken.approve(auctionSystem.address, bidAmount2, { from: accounts[1] });
    await auctionSystem.bid(auctionId, bidAmount2, { from: accounts[1] })

    const stakeAmount2 = web3.utils.toWei('300', 'ether');
    await algopToken.approve(rewardsSystemManager.address, stakeAmount2, { from: accounts[1] });
    await rewardsSystemManager.stakeBidback(auctionId, stakeAmount2, { from: accounts[1] });

    const rewardsSystemBalance3 = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance3.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));

    const totalBidbackStakes2 = await rewardsSystemManager.getTotalBidbackStakes(auctionId);
    const bidbackUsers2 = await rewardsSystemManager.getBidbackUsers(auctionId);
    const { users: bidbackUsersList2, percentages: bidBackPercentages2 } = await rewardsSystemManager.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes2.toString()).to.be.equal(web3.utils.toWei('500', 'ether'));
    expect(bidbackUsers2).to.deep.equal([accounts[0], accounts[1]]);
    
    expect(bidbackUsersList2).to.deep.equal([accounts[0], accounts[1]]);
    expect(bidBackPercentages2.length).to.be.equal(2);
    expect(bidBackPercentages2[0].toString()).to.be.equal('4000');
    expect(bidBackPercentages2[1].toString()).to.be.equal('6000');

    const account0Balance = await algopToken.balanceOf(accounts[0]);
    const account1Balance = await algopToken.balanceOf(accounts[1]);

    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('96999400', 'ether'));
    expect(account1Balance.toString()).to.be.equal(web3.utils.toWei('999500', 'ether'));
  });

  it('Each bidback unstake must compute all bidback reward percentages', async () => {
    const auctionId = 0;

    const unstakeAmount = web3.utils.toWei('100', 'ether');
    await rewardsSystemManager.unstakeBidback(auctionId, unstakeAmount);

    const rewardsSystemBalance = await algopToken.balanceOf(rewardsSystemManager.address);
    expect(rewardsSystemBalance.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));

    const account0Balance = await algopToken.balanceOf(accounts[0]);
    expect(account0Balance.toString()).to.be.equal(web3.utils.toWei('96999500', 'ether'));

    const totalBidbackStakes = await rewardsSystemManager.getTotalBidbackStakes(auctionId);
    const bidbackUsers = await rewardsSystemManager.getBidbackUsers(auctionId);
    const { users: bidbackUsersList, percentages: bidBackPercentages } = await rewardsSystemManager.getBidbackPercentages(auctionId);

    expect(totalBidbackStakes.toString()).to.be.equal(web3.utils.toWei('400', 'ether'));
    expect(bidbackUsers).to.deep.equal([accounts[0], accounts[1]]);
    
    expect(bidbackUsersList).to.deep.equal([accounts[0], accounts[1]]);
    expect(bidBackPercentages.length).to.be.equal(2);
    expect(bidBackPercentages[0].toString()).to.be.equal('2500');
    expect(bidBackPercentages[1].toString()).to.be.equal('7500');
  });
});
