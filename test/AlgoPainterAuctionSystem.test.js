var sleep = require('sleep');

contract.only('AlgoPainterAuctionSystem', accounts => {
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
  const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
  const AuctionHookMOCK = artifacts.require('AuctionHookMOCK');
  const AuctionRewardsRatesMOCK = artifacts.require('AuctionRewardsRatesMOCK');
  const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

  let algop = null;
  let busd = null;
  let eth = null;
  let gwei = null;
  let auction = null;
  let auctionHook = null;
  let rewardRatesMOCK = null;
  let nftCreators = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    busd = await AlgoPainterToken.new("BUSD", "BUSD");
    eth = await AlgoPainterToken.new("ETH", "ETH");
    auctionHook = await AuctionHookMOCK.new();
    rewardRatesMOCK = await AuctionRewardsRatesMOCK.new();
    nftCreators = await AlgoPainterNFTCreators.new();

    gwei = await AlgoPainterGweiItem.new(algop.address, accounts[8]);

    auction = await AlgoPainterAuctionSystem.new('1209600');

    const amount = web3.utils.toWei('300', 'ether');

    const balance = await algop.balanceOf(accounts[0]);
    expect(balance.toString()).to.be.equal('100000000000000000000000000');

    await algop.approve(gwei.address, amount);
    await gwei.mint(1, 'new text', false, 0, 2, amount, 'URI');

    const balanceUpdated = await algop.balanceOf(accounts[0]);
    expect(balanceUpdated.toString()).to.be.equal('99999700000000000000000000');
    await rewardRatesMOCK.grantRole(await rewardRatesMOCK.CONFIGURATOR_ROLE(), auction.address);
    await nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE(), auction.address);
    await nftCreators.setCreator(gwei.address, accounts[7])
  });

  it('should setup auction system', async () => {
    await auction.setup(accounts[9], auctionHook.address, 1000, 250, [algop.address, busd.address, eth.address], rewardRatesMOCK.address);

    await auction.setAlgoPainterNFTCreators(nftCreators.address);

    expect(await auction.getAddressFee()).to.be.equal(accounts[9]);
    expect((await auction.getAuctionFeeRate()).toString()).to.be.equal('1000');
    expect((await auction.getBidFeeRate()).toString()).to.be.equal('250');

    const allowedTokens = await auction.getAllowedTokens();

    expect(allowedTokens.length).to.be.equal(3);
    expect(allowedTokens[0]).to.be.equal(algop.address);
    expect(allowedTokens[1]).to.be.equal(busd.address);
    expect(allowedTokens[2]).to.be.equal(eth.address);

    expect(await auction.getAuctionHook()).to.be.equal(auctionHook.address);
    expect(await auction.getRewardsRates()).to.be.equal(rewardRatesMOCK.address);
  });

  it('should create an auction', async () => {
    const now = parseInt((await auction.getNow()).toString());
    const expirationTime = (now + 30).toString();

    try {
      await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address, 3000);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('ERC721_NOT_APPROVED');
    }

    await gwei.setApprovalForAll(auction.address, true);

    try {
      await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address, 3000);
    } catch(e) {
      console.log(e);
    }

    const auctionId = await auction.getAuctionId(gwei.address, 1);

    const auctionInfo = await auction.getAuctionInfo(auctionId);

    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenAddress).to.be.equal(gwei.address, 'fail to check tokenAddress');
    expect(auctionInfo.tokenId.toString()).to.be.equal('1', 'fail to check tokenId');
    expect(auctionInfo.minimumAmount.toString()).to.be.equal(web3.utils.toWei('100', 'ether'), 'fail to check minimumAmount');
    expect(auctionInfo.auctionEndTime.toString()).to.be.equal(expirationTime, 'fail to check auctionEndTime');
    expect(auctionInfo.tokenPriceAddress).to.be.equal(algop.address, 'fail to check tokenPriceAddress');
  });

  async function printAccountsBalance(msg) {
    console.log('===============================================================');
    console.log(msg);
    console.log('accounts[1]: ', (await algop.balanceOf(accounts[1])).toString());
    console.log('accounts[2]: ', (await algop.balanceOf(accounts[2])).toString());
    console.log('accounts[3]: ', (await algop.balanceOf(accounts[3])).toString());
    console.log('===============================================================');
  }

  it('should send bids', async () => {
    const transferAmount = web3.utils.toWei('1000', 'ether');
    await algop.transfer(accounts[1], transferAmount);
    await algop.transfer(accounts[2], transferAmount);
    await algop.transfer(accounts[3], transferAmount);

    await algop.approve(auction.address, transferAmount, { from: accounts[1] });
    await algop.approve(auction.address, transferAmount, { from: accounts[2] });
    await algop.approve(auction.address, transferAmount, { from: accounts[3] });

    const auctionId = await auction.getAuctionId(gwei.address, 1);
    let feeAddressBalance = 0;
    let auctionBalance = 0;

    try {
      await auction.bid(auctionId, web3.utils.toWei('10', 'ether'), { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('LOW_BID_MINIMUM_AMOUNT');
    }

    await printAccountsBalance('Initial Balance before bids');

    await auction.bid(auctionId, web3.utils.toWei('100', 'ether'), { from: accounts[1] });

    await printAccountsBalance('Account[1] bid 100');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('2500000000000000000', 'fail to check feeAddressBalance #1');
    expect(auctionBalance.toString()).to.be.equal('100000000000000000000', 'fail to check auctionBalance #1');

    try {
      await auction.bid(auctionId, web3.utils.toWei('90', 'ether'), { from: accounts[2] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('LOW_BID');
    }

    await auction.bid(auctionId, web3.utils.toWei('101', 'ether'), { from: accounts[2] });
    await printAccountsBalance('Account[2] bid 101');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('5025000000000000000', 'fail to check feeAddressBalance #2');
    expect(auctionBalance.toString()).to.be.equal('201000000000000000000', 'fail to check auctionBalance #2');

    await auction.bid(auctionId, web3.utils.toWei('101.1', 'ether'), { from: accounts[3] });
    await printAccountsBalance('Account[3] bid 101.1');

    let auctionInfo = await auction.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(accounts[3], 'fail to check highestBidder');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('101.1000', 'ether'), 'fail to check highestBid');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('7552500000000000000', 'fail to check feeAddressBalance #3');
    expect(auctionBalance.toString()).to.be.equal('302100000000000000000', 'fail to check auctionBalance #3');

    //Bid again while beign the winner
    await auction.bid(auctionId, web3.utils.toWei('101.2', 'ether'), { from: accounts[3] });
    await printAccountsBalance('Account[3] bid 101.2');
    auctionInfo = await auction.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(accounts[3], 'fail to check highestBidder #4');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('101.200', 'ether'), 'fail to check highestBid #4');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('10082500000000000000', 'fail to check feeAddressBalance #4');
    expect(auctionBalance.toString()).to.be.equal('403300000000000000000', 'fail to check auctionBalance #4');

    expect((await algop.balanceOf(accounts[2])).toString()).to.be.equal('896475000000000000000', 'fail to check accounts[2] #5');
    let acc2ClaimableAmount = await auction.getClaimableAmount(auctionId, accounts[2]);
    expect(acc2ClaimableAmount.toString()).to.be.equal(web3.utils.toWei('101', 'ether'), 'fail to claimable amount accounts[2] #5');

    await auction.bid(auctionId, web3.utils.toWei('210', 'ether'), { from: accounts[2] });
    auctionInfo = await auction.getAuctionInfo(auctionId);
    await printAccountsBalance('Account[2] bid 210');

    expect(auctionInfo.highestBidder).to.be.equal(accounts[2], 'fail to check highestBidder #5');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('210', 'ether'), 'fail to check highestBid #5');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    acc2ClaimableAmount = await auction.getClaimableAmount(auctionId, accounts[2]);
    expect(acc2ClaimableAmount.toString()).to.be.equal('101000000000000000000', 'fail to claimable amount accounts[2] #5');
    expect((await algop.balanceOf(accounts[2])).toString()).to.be.equal('681225000000000000000', 'fail to check accounts[2] #5');
    expect(feeAddressBalance.toString()).to.be.equal('15332500000000000000', 'fail to check feeAddressBalance #5');
    expect(auctionBalance.toString()).to.be.equal('613300000000000000000', 'fail to check auctionBalance #5');
  });

  it('should end an auction', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    try {
      await auction.endAuction(auctionId);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AUCTION_STILL_RUNNING');
    }

    //Waiting 30s to finish the auction
    sleep.sleep(30);

    let acount8Balance = await algop.balanceOf(accounts[7]);
    expect(acount8Balance.toString()).to.be.equal('0', 'fail to check creator Balance');
    const previousRewardsSystemBalance = await algop.balanceOf(auctionHook.address);
    expect(previousRewardsSystemBalance.toString()).to.be.equal('0', 'fail to check rewardsSystemBalance');

    await auction.endAuction(auctionId);

    const auctionInfo = await auction.getAuctionInfo(auctionId);

    const creatorAddressBalance = await algop.balanceOf(accounts[7]);
    const feeAddressBalance = await algop.balanceOf(accounts[9]);
    const auctionBalance = await algop.balanceOf(auction.address);
    const rewardsSystemBalance = await algop.balanceOf(auctionHook.address);

    const creatorAddress = await nftCreators.getCreatorNotPayable(gwei.address, 1);

    expect(creatorAddress.toString()).to.be.equal(accounts[7], 'fail to check creatorAddress');
    expect(creatorAddressBalance.toString()).to.be.equal('21000000000000000000', 'fail to check creatorAddressBalance');
    expect(feeAddressBalance.toString()).to.be.equal('36332500000000000000', 'fail to check feeAddressBalance');
    expect(auctionBalance.toString()).to.be.equal('403300000000000000000', 'fail to check auctionBalance');
    expect(rewardsSystemBalance.toString()).to.be.equal('105000000000000000000', 'fail to check rewardsSystemBalance');

    const nftOwner = await gwei.ownerOf(1);

    expect(nftOwner).to.be.equal(auctionInfo.highestBidder, 'fail to check nftOwner');
  });

  it('should withdraw remaining amounts', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    let account1Balance = await algop.balanceOf(accounts[1]);
    let account2Balance = await algop.balanceOf(accounts[2]);
    let account3Balance = await algop.balanceOf(accounts[3]);

    expect(account1Balance.toString()).to.be.equal('897500000000000000000', 'fail to check account1Balance');
    expect(account2Balance.toString()).to.be.equal('681225000000000000000', 'fail to check account2Balance');
    expect(account3Balance.toString()).to.be.equal('792642500000000000000', 'fail to check account3Balance');

    await auction.withdraw(auctionId, { from: accounts[1] });
    await auction.withdraw(auctionId, { from: accounts[3] });

    account1Balance = await algop.balanceOf(accounts[1]);
    account2Balance = await algop.balanceOf(accounts[2]);
    account3Balance = await algop.balanceOf(accounts[3]);

    expect(account1Balance.toString()).to.be.equal('997500000000000000000', 'fail to check account1Balance');
    expect(account2Balance.toString()).to.be.equal('681225000000000000000', 'fail to check account2Balance');
    expect(account3Balance.toString()).to.be.equal('994942500000000000000', 'fail to check account3Balance');
  });
});
