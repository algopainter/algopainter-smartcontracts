const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterBidbackPirs = artifacts.require('AlgoPainterBidBackPirs');
const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AuctionSystemManagerMOCK = artifacts.require('AuctionSystemManagerMOCK');

contract('AlgoPainterBidBackPirs', accounts => {
  let algop = null;
  let auction = null;
  let bidbackPirs = null;
  let gwei = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    auction = await AlgoPainterAuctionSystem.new();
    bidbackPirs = await AlgoPainterBidbackPirs.new();
    gwei = await AlgoPainterGweiItem.new(algop.address, accounts[8]);
    auctionSystemManager = await AuctionSystemManagerMOCK.new();

    await auction.setup(accounts[9], auctionSystemManager.address, 1000, 250, [algop.address], auctionSystemManager.address, bidbackPirs.address);

    await bidbackPirs.setAuctionSystemAddress(auction.address);

    const amount = web3.utils.toWei('300', 'ether');

    await algop.approve(gwei.address, amount);
    await gwei.mint(1, 'new text', false, 0, 2, amount, 'URI');

    const now = parseInt((await auction.getNow()).toString());
    const expirationTime = (now + 20).toString();

    await gwei.setApprovalForAll(auction.address, true);
    await auction.createAuction(0, gwei.address, 1, web3.utils.toWei('100', 'ether'), expirationTime, algop.address);
  });

  it('Should set max creator pirs and a creator pirs for a collection', async () => {
    await bidbackPirs.setMaxCreatorPirsRate(gwei.address, 30);

    const maxPirs = await bidbackPirs.getMaxCreatorPirsRate(gwei.address);
    expect(maxPirs.toString()).to.be.equal('30', 'fail to check maxCreatorPirsRate');

    const unsettedPirs = await bidbackPirs.getCreatorPirsRate(0);
    expect(unsettedPirs.toString()).to.be.equal('0', 'fail to check creatorPirsRate');

    await bidbackPirs.setCreatorPirsRate(gwei.address, 15);

    const updatedPirs = await bidbackPirs.getCreatorPirsRate(0);
    expect(updatedPirs.toString()).to.be.equal('15', 'fail to check creatorPirsRate');
  });

  it('Should set max investor pirs for all collections and a investor pirs for a specific image in a collection', async () => {
    await bidbackPirs.setMaxInvestorPirsRate(30);

    const maxPirs = await bidbackPirs.getMaxInvestorPirsRate();
    expect(maxPirs.toString()).to.be.equal('30', 'fail to check maxInvestorPirsRate');

    const unsettedPirs = await bidbackPirs.getInvestorPirsRate(0);
    expect(unsettedPirs.toString()).to.be.equal('0', 'fail to check creatorPirsRate');

    await bidbackPirs.setInvestorPirsRate(gwei.address, 1, 25);

    const updatedPirs = await bidbackPirs.getInvestorPirsRate(0);
    expect(updatedPirs.toString()).to.be.equal('25', 'fail to check creatorPirsRate');
  });

  it('Should set max bidback for all auctions and a bidback for a specific auction', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    await bidbackPirs.setMaxBidbackRate(10);

    const maxBidback = await bidbackPirs.getMaxBidbackRate();
    expect(maxBidback.toString()).to.be.equal('10', 'fail to check maxBidbackRate');
  
    await bidbackPirs.setBidbackRate(parseInt(auctionId.toString()), 10);

    const bidback = await bidbackPirs.getBidbackRate(auctionId);
    expect(bidback.toString()).to.be.equal('10', 'fail to check bidbackRate');
  });

  it('Should return the sum of all rewards', async () => {
    const auctionId = await auction.getAuctionId(gwei.address, 1);

    const rewardsRate = await bidbackPirs.getRewardsRate(auctionId);
    expect(rewardsRate.toString()).to.be.equal('50', 'fail to check rewards rate');
  });
});
