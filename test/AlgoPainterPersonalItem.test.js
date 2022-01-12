contract.only('AlgoPainterPersonalItem', accounts => {
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AlgoPainterPersonalItem = artifacts.require('AlgoPainterPersonalItem');
  const AlgoPainterRewardsRates = artifacts.require('AlgoPainterRewardsRates');
  const AuctionHookMOCK = artifacts.require('AuctionHookMOCK');
  const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
  const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

  let algop = null;
  let auction = null;
  let rewardRates = null;
  let nftCreators = null;
  let instance = null;

  it('should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    nftCreators = await AlgoPainterNFTCreators.new();
    rewardRates = await AlgoPainterRewardsRates.new();
    auction = await AlgoPainterAuctionSystem.new('1209600');
    auctionHook = await AuctionHookMOCK.new();
    instance = await AlgoPainterPersonalItem.new(algop.address, nftCreators.address, rewardRates.address, accounts[9]);

    await auction.setup(accounts[9], auctionHook.address, 1000, 250, [algop.address], rewardRates.address);

    await rewardRates.setAuctionSystemAddress(auction.address);
    await rewardRates.setMaxCreatorRoyaltiesRate(3000);
    await instance.setAlgoPainterRewardsRatesAddress(rewardRates.address);
    await instance.setApprovalForAll(auction.address, true);
    await nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE(), instance.address);
    await rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE(), instance.address);
  });

  it('should add account[1] as a validator', async () => {
    const validatorRole = await instance.VALIDATOR_ROLE();
    await instance.grantRole(validatorRole, accounts[1]);

    expect(await instance.hasRole(validatorRole, accounts[1])).to.be.equal(true, 'fail to check accounts[1] as a validator');
  });

  it('should mint a new paint', async () => {
    const owner = accounts[2];

    const amount = await instance.getCurrentAmount(2, await instance.totalSupply());
    algop.transfer(owner, amount, { from: accounts[0] });
    await algop.approve(instance.address, amount, { from: owner });

    await instance.mint('mouse', '0xf1be2b4d52e8d3f4ad91afbba597a59fac5bf234031758e0af99ff875be1a13b', 800, 'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ', { from: owner });
    const returnedTokenURI = await instance.tokenURI(1);

    expect(returnedTokenURI).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
    expect(await instance.getName(3)).to.be.equal('Personal Item by AlgoPainter');

    expect((await instance.getCollectedTokenAmount(2)).toString()).to.be.equal('100000000000000000000');
    expect((await instance.getTokenAmountToBurn(2)).toString()).to.be.equal('50000000000000000000');
    expect((await rewardRates.getCreatorRoyaltiesByTokenAddress(await instance.getTokenHashForAuction(1))).toString()).to.be.equal('800');
  });

  it('should update a token URI based on a valid signature', async () => {
    const tokenId = 1;
    const tokenURI = 'NEW_URI'
    const owner = accounts[2];

    //hashing the content used to mint a paint
    const hash = await instance.hashTokenURI(tokenId, tokenURI);

    //creating a validator signature
    const signature = await web3.eth.sign(hash, accounts[1]);
    await instance.updateTokenURI(tokenId, tokenURI, signature, { from: owner });

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
      await instance.updateTokenURI(1, tokenURI, signature, { from: owner });
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
      await instance.updateTokenURI(tokenId, tokenURI, signature, { from: owner });
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
