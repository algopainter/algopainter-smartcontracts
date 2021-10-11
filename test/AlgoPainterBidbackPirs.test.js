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

  it('Should get bidback and investor and creator PIRS', async () => {

    const auctionId = await auction.getAuctionId(gwei.address, 1);

    try {
      await bidbackPirs.setBidbackAndInvestorPirsPercentage(auctionId, 10, 10);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setBidbackAndInvestorPirsPercentage error');
    }

    const auctionBidback = await bidbackPirs.getBidbackPercentage(auctionId);

    expect(auctionBidback.toString()).to.be.equal('10', 'fail to check auctionBidback');

    const auctionInvestorPirs = await bidbackPirs.getInvestorPirsPercentage(auctionId);

    expect(auctionInvestorPirs.toString()).to.be.equal('10', 'fail to check auctionInvestorPirs');

    try {
      await bidbackPirs.setCreatorPirsPercentage(0, 1, 10);
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterBidbackPirs setCreatorPirsPercentage error');
    }

    const auctionCreatorPirs = await bidbackPirs.getCreatorPirsPercentage(0, 1);

    expect(auctionCreatorPirs.toString()).to.be.equal('10', 'fail to check auctionCreatorPirs');

  });
});
