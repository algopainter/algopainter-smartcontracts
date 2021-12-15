const AlgoPainterToken = artifacts.require('AlgoPainterToken');
const AlgoPainterPersonalItem = artifacts.require('AlgoPainterPersonalItem');
const AlgoPainterBidbackPirs = artifacts.require('AlgoPainterBidBackPirs');
const AuctionSystemManagerMOCK = artifacts.require('AuctionSystemManagerMOCK');
const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');

contract('AlgoPainterPersonalItem', accounts => {
  let algop = null;
  let auction = null;
  let bidbackPirs = null;
  let instance = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    instance = await AlgoPainterPersonalItem.new();
    auction = await AlgoPainterAuctionSystem.new();
    bidbackPirs = await AlgoPainterBidbackPirs.new();
    auctionSystemManager = await AuctionSystemManagerMOCK.new();

    await auction.setup(accounts[9], auctionSystemManager.address, 1000, 250, [algop.address], auctionSystemManager.address, bidbackPirs.address);

    await bidbackPirs.setAuctionSystemAddress(auction.address);
    await bidbackPirs.setMaxCreatorRoyaltiesRate(3000);
    await instance.setAlgoPainterBidBackPirsAddress(bidbackPirs.address);
    await instance.setApprovalForAll(auction.address, true);

  });

  it('should add account[1] as a validator', async () => {
    const validatorRole = await instance.VALIDATOR_ROLE();
    await instance.grantRole(validatorRole, accounts[1]);

    expect(await instance.hasRole(validatorRole, accounts[1])).to.be.equal(true, 'fail to check accounts[1] as a validator');
  });

  it('should mint a new paint', async () => {
    const owner = accounts[2];

    await instance.mint('new text', '0xa2b445f459650c4c6a137f24cda570068149b25b8e203f242ba728274ef5b945', 400, 'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ', { from: owner });
    const returnedTokenURI = await instance.tokenURI(1);

    expect(returnedTokenURI).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
    expect(await instance.getName(3)).to.be.equal('Personal Item by AlgoPainter');
  });

  it('should update a token URI based on a valid signature', async () => {
    const tokenId = 1;
    const tokenURI = 'NEW_URI'
    const owner = accounts[2];

    //hashing the content used to mint a paint
    const hash = await instance.hashTokenURI(tokenId, tokenURI);

    //creating a validator signature
    const signature = await web3.eth.sign(hash, accounts[1]);
    await instance.updateTokenURI(tokenId, tokenURI, signature, {from: owner});

    const returnedTokenURI = await instance.tokenURI(1);
    expect(returnedTokenURI).to.be.equal('NEW_URI');
  });

  it('should fail to update a token URI based on an invalid validator', async () => {
    const tokenId = 1;
    const tokenURI = 'NEW_URI'
    const owner = accounts[2];

    const hash = await instance.hashTokenURI(tokenId, tokenURI);

    const signature = await web3.eth.sign(hash, accounts[3]);
    try {
      await instance.updateTokenURI(1, tokenURI, signature, {from: owner});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterPersonalItem:INVALID_VALIDATOR', 'fail to check failure');
    }
  });

  it('should fail to update a token URI based on an invalid signature', async () => {
    const tokenURI = 'NEW_URI'
    const tokenId = 1;
    const owner = accounts[2];

    const signature = '0x0';

    try {
      await instance.updateTokenURI(tokenId, tokenURI, signature, {from: owner});
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterPersonalItem:INVALID_SIGNATURE', 'fail to check failure');
    }
  });

  it('should fail to update a token URI based on an invalid sender', async () => {
    const tokenURI = 'NEW_URI'
    const tokenId = 1;

    const signature = '0x0';

    try {
      await instance.updateTokenURI(tokenId, tokenURI, signature);
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal('AlgoPainterPersonalItem:INVALID_SENDER', 'fail to check failure');
    }
  });
});
