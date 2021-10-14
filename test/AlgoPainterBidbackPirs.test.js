const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
const AlgoPainterGweiItem = artifacts.require('AlgoPainterGweiItem');
const AlgoPainterBidbackPirs = artifacts.require('AlgoPainterBidBackPirs');
const AlgoPainterToken = artifacts.require('AlgoPainterToken');

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

    const amount = web3.utils.toWei('300', 'ether');

    await algop.approve(gwei.address, amount);
    await gwei.mint(1, 'new text', false, 0, 2, amount, 'URI');

  });


  it('Should set max creator pirs and a creator pirs for a collection', async () => {

    try {
      await bidbackPirs.setMaxCreatorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154', 30);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setMaxCreatorPirsPercentage error');
    }

    expect((await bidbackPirs.getMaxCreatorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154')).toString()).to.be.equal('30', 'fail to check maxCreatorPirsPercentage');

    try {
      await bidbackPirs.setCreatorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154', 25);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setCreatorPirsPercentage error');
    }

    expect((await bidbackPirs.getCreatorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154')).toString()).to.be.equal('25', 'fail to check creatorPirsPercentage');

  });


  it('Should set max investor pirs for all collections and a investor pirs for a specific image in a collection', async () => {

    try {
      await bidbackPirs.setMaxInvestorPirsPercentage(30);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setMaxInvestorPirsPercentage error');
    }

    expect((await bidbackPirs.getMaxInvestorPirsPercentage()).toString()).to.be.equal('30', 'fail to check maxInvestorPirsPercentage');

    try {
      await bidbackPirs.setInvestorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154', 0, 25);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setInvestorPirsPercentage error');
    }

    expect((await bidbackPirs.getInvestorPirsPercentage('0xC250988ec44b90F81214C5030c947026b2A9b154', 0)).toString()).to.be.equal('25', 'fail to check creatorPirsPercentage');

  });


  it('Should set max bidback for all auctions and a bidback for a specific auction', async () => {

    const auctionId = await auction.getAuctionId(gwei.address, 1);
    const auctionSystemAddress = await bidbackPirs.setAuctionSystemAddress(auction.address);

    console.log('auction.address', auction.address);

    try {
      await bidbackPirs.setMaxBidbackPercentage(10);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setMaxBidbackPercentage error');
    }

    expect((await bidbackPirs.getMaxBidbackPercentage()).toString()).to.be.equal('10', 'fail to check maxBidbackPercentage');
  
    try {
      await bidbackPirs.setBidbackPercentage(auctionId, 10);
    } catch (e) {
      console.log('e.reason', e.reason);
      console.log('e', e);
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setBidbackPercentage error');
    }

    expect((await bidbackPirs.getBidbackPercentage(auctionId)).toString()).to.be.equal('10', 'fail to check bidbackPercentage');

  });

});