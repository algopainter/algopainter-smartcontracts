const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AuctionSystemManagerMOCK = artifacts.require('AuctionSystemManagerMOCK');
var sleep = require('sleep');

contract('AlgoPainterAuctionSystem', accounts => {
  let algop = null;
  let busd = null;
  let eth = null;
  let gwei = null;
  let auction = null;
  let auctionSystemManager = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    busd = await AlgoPainterToken.new("BUSD", "BUSD");
    eth = await AlgoPainterToken.new("ETH", "ETH");
    auctionSystemManager = await AuctionSystemManagerMOCK.new();

    gwei = await AlgoPainterGweiItem.new(algop.address, accounts[8]);

    auction = await AlgoPainterAuctionSystem.new();

    const amount = web3.utils.toWei('300', 'ether');

    const balance = await algop.balanceOf(accounts[0]);
    expect(balance.toString()).to.be.equal('100000000000000000000000000');

    await algop.approve(gwei.address, amount);
    await gwei.mint(1, 'new text', false, 0, 2, amount, 'URI');

    const balanceUpdated = await algop.balanceOf(accounts[0]);
    expect(balanceUpdated.toString()).to.be.equal('99999700000000000000000000');
  });

  it('should setup auction system', async () => {
    await auction.setup(accounts[9], auctionSystemManager.address, 1000, 250, [algop.address, busd.address, eth.address], auctionSystemManager.address);

    expect(await auction.getAddressFee()).to.be.equal(accounts[9]);
    expect((await auction.getAuctionFeeRate()).toString()).to.be.equal('1000');
    expect((await auction.getBidFeeRate()).toString()).to.be.equal('250');

    const allowedTokens = await auction.getAllowedTokens();

    expect(allowedTokens.length).to.be.equal(3);
    expect(allowedTokens[0]).to.be.equal(algop.address);
    expect(allowedTokens[1]).to.be.equal(busd.address);
    expect(allowedTokens[2]).to.be.equal(eth.address);

    expect(await auction.getAuctionSystemManager()).to.be.equal(auctionSystemManager.address);
  });

  it('should create an auction', async () => {
    const now = parseInt((await auction.getNow()).toString());
    const expirationTime = (now + 20).toString();

    try {
      await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterAuctionSystem:ERC721_NOT_APPROVED');
    }

    await gwei.setApprovalForAll(auction.address, true);
    await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address);

    const auctionId = await auction.getAuctionId(gwei.address, 1);

    const auctionInfo = await auction.getAuctionInfo(auctionId);

    expect(auctionInfo.tokenType.toString()).to.be.equal('0', 'fail to check tokenType');
    expect(auctionInfo.tokenAddress).to.be.equal(gwei.address, 'fail to check tokenAddress');
    expect(auctionInfo.tokenId.toString()).to.be.equal('1', 'fail to check tokenId');
    expect(auctionInfo.minimumAmount.toString()).to.be.equal(web3.utils.toWei('100', 'ether'), 'fail to check minimumAmount');
    expect(auctionInfo.auctionEndTime.toString()).to.be.equal(expirationTime, 'fail to check auctionEndTime');
    expect(auctionInfo.tokenPriceAddress).to.be.equal(algop.address, 'fail to check tokenPriceAddress');
  });

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

    try
    {
      await auction.bid(auctionId, web3.utils.toWei('10', 'ether'), { from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterAuctionSystem:LOW_BID_MINIMUM_AMOUNT');
    }

    await auction.bid(auctionId, web3.utils.toWei('100', 'ether'), { from: accounts[1] });
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('2500000000000000000', 'fail to check feeAddressBalance #1');
    expect(auctionBalance.toString()).to.be.equal('97500000000000000000', 'fail to check auctionBalance #1');

    try {
      await auction.bid(auctionId, web3.utils.toWei('90', 'ether'), { from: accounts[2] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterAuctionSystem:LOW_BID');
    }

    await auction.bid(auctionId, web3.utils.toWei('101', 'ether'), { from: accounts[2] });
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('5025000000000000000', 'fail to check feeAddressBalance #2');
    expect(auctionBalance.toString()).to.be.equal('195975000000000000000', 'fail to check auctionBalance #2');

    await auction.bid(auctionId, web3.utils.toWei('101.1', 'ether'), { from: accounts[3] });

    const auctionInfo = await auction.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(accounts[3], 'fail to check highestBidder');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('101.1000', 'ether'), 'fail to check highestBid');
    feeAddressBalance = await algop.balanceOf(accounts[9]);
    auctionBalance = await algop.balanceOf(auction.address);

    expect(feeAddressBalance.toString()).to.be.equal('7552500000000000000', 'fail to check feeAddressBalance #3');
    expect(auctionBalance.toString()).to.be.equal('294547500000000000000', 'fail to check auctionBalance #3');
  });

  it('should end an auction', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    try {
      await auction.endAuction(auctionId);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterAuctionSystem:NOT_YET_ENDED');
    }

    console.log('Waiting 20s to finish the auction');
    sleep.sleep(20);

    const previousRewardsSystemBalance = await algop.balanceOf(auctionSystemManager.address);
    expect(previousRewardsSystemBalance.toString()).to.be.equal('0', 'fail to check rewardsSystemBalance');

    await auction.endAuction(auctionId);

    const feeAddressBalance = await algop.balanceOf(accounts[9]);
    const auctionBalance = await algop.balanceOf(auction.address);
    const rewardsSystemBalance = await algop.balanceOf(auctionSystemManager.address);

    expect(feeAddressBalance.toString()).to.be.equal('17662500000000000000', 'fail to check feeAddressBalance');
    expect(auctionBalance.toString()).to.be.equal('193447500000000000000', 'fail to check auctionBalance');
    expect(rewardsSystemBalance.toString()).to.be.equal('9099000000000000000', 'fail to check rewardsSystemBalance');

    const auctionInfo = await auction.getAuctionInfo(auctionId);

    const nftOwner = await gwei.ownerOf(1);

    expect(nftOwner).to.be.equal(auctionInfo.highestBidder, 'fail to check nftOwner');
  });

  it('should withdraw remaining amounts', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    let account1Balance = await algop.balanceOf(accounts[1]);
    let account2Balance = await algop.balanceOf(accounts[2]);
    let account3Balance = await algop.balanceOf(accounts[3]);

    expect(account1Balance.toString()).to.be.equal('900000000000000000000', 'fail to check account1Balance');
    expect(account2Balance.toString()).to.be.equal('899000000000000000000', 'fail to check account2Balance');
    expect(account3Balance.toString()).to.be.equal('898900000000000000000', 'fail to check account3Balance');

    await auction.withdraw(auctionId, { from: accounts[1] });
    await auction.withdraw(auctionId, { from: accounts[2] });

    try {
      await auction.withdraw(auctionId, { from: accounts[3] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterAuctionSystem:NOTHING_TO_WITHDRAW');
    }

    account1Balance = await algop.balanceOf(accounts[1]);
    account2Balance = await algop.balanceOf(accounts[2]);
    account3Balance = await algop.balanceOf(accounts[3]);

    expect(account1Balance.toString()).to.be.equal('997500000000000000000', 'fail to check account1Balance');
    expect(account2Balance.toString()).to.be.equal('997475000000000000000', 'fail to check account2Balance');
    expect(account3Balance.toString()).to.be.equal('898900000000000000000', 'fail to check account3Balance');
  });
});
