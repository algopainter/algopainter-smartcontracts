contract('AlgoPainterAuctionSystem', accounts => {
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
    await contracts.Gwei.mint(
      1,
      'new text',
      false,
      0,
      2,
      web3.utils.toWei('300', 'ether'),
      'URI',
      { from: USER_ONE }
    );
    await contracts.RewardsRates.setPIRSRate(contracts.Gwei.address, 1, PIRS_RATE);
    await assertBalance(USER_ONE, web3.utils.toWei('9700', 'ether'));
    await assertBalance(GWEI_DEV, web3.utils.toWei('300', 'ether')); //Gwei Dev
  });

  it('should create an auction', async () => {
    const now = parseInt((await contracts.AuctionSystem.getNow()).toString());
    const expirationTime = (now + 60).toString();

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

    await assertBalance(USER_ONE, web3.utils.toWei('9700', 'ether')); // 3% fee to open an auction
  });

  it('should send bids', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(
      contracts.Gwei.address,
      1
    );
    let feeAddressBalance = 0;
    let auctionBalance = 0;

    try {
      await contracts.AuctionSystem.bid(
        auctionId,
        web3.utils.toWei('99', 'ether'),
        { from: USER_TWO }
      );
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('LOW_BID_MINIMUM_AMOUNT');
    }

    await contracts.AuctionSystem.bid(
      auctionId,
      web3.utils.toWei('100', 'ether'),
      { from: USER_TWO }
    );

    await assertBalance(USER_TWO, web3.utils.toWei('9897.5', 'ether'));

    feeAddressBalance = await contracts.ALGOP.balanceOf(DEV_FEE_ACCOUNT);
    auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);

    expect(feeAddressBalance.toString()).to.be.equal('2500000000000000000', 'fail to check feeAddressBalance #1');
    expect(auctionBalance.toString()).to.be.equal('100000000000000000000', 'fail to check auctionBalance #1');

    try {
      await contracts.AuctionSystem.bid(
        auctionId,
        web3.utils.toWei('100', 'ether'),
        { from: USER_THREE }
      );
    } catch (e) {
      expect(e.reason).to.be.equal('LOW_BID');
    }

    await contracts.AuctionSystem.bid(
      auctionId,
      web3.utils.toWei('101', 'ether'),
      { from: USER_THREE }
    );

    await assertBalance(USER_THREE, web3.utils.toWei('9896.475', 'ether'));
    
    feeAddressBalance = await contracts.ALGOP.balanceOf(DEV_FEE_ACCOUNT);
    auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);

    expect(feeAddressBalance.toString()).to.be.equal('5025000000000000000', 'fail to check feeAddressBalance #2');
    expect(auctionBalance.toString()).to.be.equal('201000000000000000000', 'fail to check auctionBalance #2');

    await contracts.AuctionSystem.bid(
      auctionId,
      web3.utils.toWei('101.1', 'ether'),
      { from: USER_FOUR }
    );

    await assertBalance(USER_FOUR, web3.utils.toWei('9896.3725', 'ether'));

    feeAddressBalance = await contracts.ALGOP.balanceOf(DEV_FEE_ACCOUNT);
    auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);

    expect(feeAddressBalance.toString()).to.be.equal('7552500000000000000', 'fail to check feeAddressBalance #3');
    expect(auctionBalance.toString()).to.be.equal('302100000000000000000', 'fail to check auctionBalance #3');

    let auctionInfo = await contracts.AuctionSystem.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(USER_FOUR, 'fail to check highestBidder');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('101.1', 'ether'), 'fail to check highestBid');

    //Bid again while being the winner
    await contracts.AuctionSystem.bid(
      auctionId,
      web3.utils.toWei('101.2', 'ether'),
      { from: USER_FOUR }
    );

    await assertBalance(USER_FOUR, web3.utils.toWei('9792.6425', 'ether'));

    feeAddressBalance = await contracts.ALGOP.balanceOf(DEV_FEE_ACCOUNT);
    auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);

    expect(feeAddressBalance.toString()).to.be.equal('10082500000000000000', 'fail to check feeAddressBalance #4');
    expect(auctionBalance.toString()).to.be.equal('403300000000000000000', 'fail to check auctionBalance #4');

    auctionInfo = await contracts.AuctionSystem.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(USER_FOUR, 'fail to check highestBidder #4');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('101.2', 'ether'), 'fail to check highestBid #4');

    await assertBalance(USER_THREE, web3.utils.toWei('9896.4750', 'ether'));

    let userThreeClaimableAmount = await contracts.AuctionSystem.getClaimableAmount(
      auctionId,
      USER_THREE
    );
  
    expect(userThreeClaimableAmount.toString()).to.be.equal(web3.utils.toWei('101', 'ether'), 'fail to claimable amount USER_THREE #5');

    await contracts.AuctionSystem.bid(
      auctionId,
      web3.utils.toWei('210', 'ether'),
      { from: USER_THREE }
    );

    await assertBalance(USER_THREE, web3.utils.toWei('9681.225', 'ether'));

    feeAddressBalance = await contracts.ALGOP.balanceOf(DEV_FEE_ACCOUNT);
    auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);

    expect(feeAddressBalance.toString()).to.be.equal('15332500000000000000', 'fail to check feeAddressBalance #5');
    expect(auctionBalance.toString()).to.be.equal('613300000000000000000', 'fail to check auctionBalance #5');

    auctionInfo = await contracts.AuctionSystem.getAuctionInfo(auctionId);

    expect(auctionInfo.highestBidder).to.be.equal(USER_THREE, 'fail to check highestBidder #5');
    expect(auctionInfo.highestBid.toString()).to.be.equal(web3.utils.toWei('210', 'ether'), 'fail to check highestBid #5');

    userThreeClaimableAmount = await contracts.AuctionSystem.getClaimableAmount(
      auctionId,
      USER_THREE
    );

    expect(userThreeClaimableAmount.toString()).to.be.equal(web3.utils.toWei('101', 'ether'), 'fail to claimable amount USER_THREE #5');
    await assertBalance(USER_THREE, web3.utils.toWei('9681.225', 'ether'));
  });

  it('should end an auction', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(
      contracts.Gwei.address,
      1
    );

    try {
      await contracts.AuctionSystem.endAuction(
        auctionId,
        { from: USER_ONE }
      );
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AUCTION_STILL_RUNNING');
    }

    sleep.sleep(60);

    let creatorBalance = await contracts.ALGOP.balanceOf(GWEI_CREATOR);
    expect(creatorBalance.toString()).to.be.equal('0', 'fail to check creator Balance');
    const previousRewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystemHook.address);
    expect(previousRewardsSystemBalance.toString()).to.be.equal('0', 'fail to check rewardsSystemBalance');

    await contracts.AuctionSystem.endAuction(
      auctionId,
      { from: USER_ONE }
    );

    const auctionInfo = await contracts.AuctionSystem.getAuctionInfo(auctionId);

    const auctionBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystem.address);
    const rewardsSystemBalance = await contracts.ALGOP.balanceOf(contracts.AuctionSystemHook.address);

    const creatorAddress = await contracts.NFTCreators.getCreatorNotPayable(contracts.Gwei.address, 1);

    expect(creatorAddress.toString()).to.be.equal(GWEI_CREATOR, 'fail to check creatorAddress');
    await assertBalance(GWEI_CREATOR, web3.utils.toWei('10.5', 'ether'));
    await assertBalance(DEV_FEE_ACCOUNT, web3.utils.toWei('20.5825', 'ether'));
    expect(auctionBalance.toString()).to.be.equal('403300000000000000000', 'fail to check auctionBalance');
    expect(rewardsSystemBalance.toString()).to.be.equal('0', 'fail to check rewardsSystemBalance');

    const nftOwner = await contracts.Gwei.ownerOf(1);

    expect(nftOwner).to.be.equal(auctionInfo.highestBidder, 'fail to check nftOwner');
  });

  it('should withdraw remaining amounts', async () => {
    const auctionId = await contracts.AuctionSystem.getAuctionId(
      contracts.Gwei.address,
      1
    );

    await assertBalance(USER_TWO, web3.utils.toWei('9897.5', 'ether'));
    await assertBalance(USER_THREE, web3.utils.toWei('9681.225', 'ether'));
    await assertBalance(USER_FOUR, web3.utils.toWei('9792.6425', 'ether'));

    await contracts.AuctionSystem.withdraw(auctionId, { from: USER_TWO });
    await contracts.AuctionSystem.withdraw(auctionId, { from: USER_FOUR  });

    await assertBalance(USER_TWO, web3.utils.toWei('9997.5', 'ether'));
    await assertBalance(USER_THREE, web3.utils.toWei('9681.225', 'ether'));
    await assertBalance(USER_FOUR, web3.utils.toWei('9994.9425', 'ether'));
  });
});
