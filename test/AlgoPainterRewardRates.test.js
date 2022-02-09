contract('AlgoPainterRewardsRates', accounts => {
  const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
  const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
  const AlgoPainterRewardsRates = artifacts.require('AlgoPainterRewardsRates');
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AuctionHookMOCK = artifacts.require('AuctionHookMOCK');
  const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

  let algop = null;
  let auction = null;
  let rewardRates = null;
  let gwei = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    auction = await AlgoPainterAuctionSystem.new('1209600');
    nftCreators = await AlgoPainterNFTCreators.new();
    gwei = await AlgoPainterGweiItem.new(algop.address, accounts[8]);
    auctionHook = await AuctionHookMOCK.new();
    rewardRates = await AlgoPainterRewardsRates.new(
      '1209600',
      3000,
      3000,
      3000,
      auctionHook.address,
      auction.address,
      gwei.address,
      web3.utils.randomHex(20),
      500,
      500
    );

    await auction.setup(accounts[9], auctionHook.address, 1000, 250, [algop.address], rewardRates.address);

    const amount = web3.utils.toWei('300', 'ether');

    await algop.approve(gwei.address, amount);
    await gwei.mint(1, 'new text', false, 0, 2, amount, 'URI');
    await gwei.setApprovalForAll(auction.address, true);
    await auction.setAlgoPainterNFTCreators(nftCreators.address);
    await nftCreators.setCreator(gwei.address, accounts[8]);
  });

  it('Should set max investor pirs for all collections and a investor pirs for a specific image in a collection', async () => {
    //await rewardRates.setMaxPIRSRate(3000);

    const maxPirs = await rewardRates.getMaxInvestorPirsRate();
    expect(maxPirs.toString()).to.be.equal('3000', 'fail to check maxInvestorPirsRate');

    const unsettedPirs = await rewardRates.getPIRSRatePerImage(gwei.address, 1);
    expect(unsettedPirs.toString()).to.be.equal('0', 'fail to check creatorRoyaltiesRate');

    await rewardRates.setPIRSRate(gwei.address, 1, 250);

    const updatedPirs = await rewardRates.getPIRSRatePerImage(gwei.address, 1);
    expect(updatedPirs.toString()).to.be.equal('250', 'fail to check creatorRoyaltiesRate');
  });

  it('Should set max bidback for all auctions and a bidback for an auction', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    // await rewardRates.setMaxBidbackRate(3000);

    const maxBidback = await rewardRates.getMaxBidbackRate();
    expect(maxBidback.toString()).to.be.equal('3000', 'fail to check maxBidbackRate');

    const now = parseInt((await auction.getNow()).toString());
    const expirationTime = (now + 20).toString();

    try {
      await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address, 4000);
    } catch (e) {
      expect(e.reason).to.be.equal("AlgoPainterRewardsRates:BIDBACK_IS_GREATER_THAN_ALLOWED");
    }

    await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address, 2000);

    const bidback = await rewardRates.getBidbackRate(auctionId);
    expect(bidback.toString()).to.be.equal('2000', 'fail to check bidbackRate');
  });

  it('Should set max creator pirs and a creator pirs for a collection', async () => {
    // await rewardRates.setMaxCreatorRoyaltiesRate(3000);

    const maxPirs = await rewardRates.getMaxCreatorRoyaltiesRate();
    expect(maxPirs.toString()).to.be.equal('3000', 'fail to check maxCreatorRoyaltiesRate');

    // const unsettedPirs = await rewardRates.getCreatorRoyaltiesRate(0);
    // expect(unsettedPirs.toString()).to.be.equal('0', 'fail to check creatorRoyaltiesRate');

    // await rewardRates.setCreatorRoyaltiesRate(gwei.address, 150);

    const updatedPirs = await rewardRates.getCreatorRoyaltiesRate(0);
    expect(updatedPirs.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');

    const updatedPirsByAddress = await rewardRates.getCreatorRoyaltiesByTokenAddress(gwei.address);
    expect(updatedPirsByAddress.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');

    const updatedPirsByAddress2 = await rewardRates.getCreatorRate(gwei.address, 0);
    expect(updatedPirsByAddress2.toString()).to.be.equal('500', 'fail to check creatorRoyaltiesRate');
  });

  it('Should return the sum of all rewards', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    const pirsRate = await rewardRates.getPIRSRate(auctionId);
    const bidbackRate = await rewardRates.getBidbackRate(auctionId);
    const rewardsRate = await rewardRates.getRewardsRate(auctionId);
    expect(rewardsRate.toString()).to.be.equal('2250', 'fail to check rewards rate');
    expect(pirsRate.toString()).to.be.equal('250', 'fail to check rewards rate');
    expect(bidbackRate.toString()).to.be.equal('2000', 'fail to check rewards rate');
  });
});
