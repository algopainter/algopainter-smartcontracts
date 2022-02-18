contract.only('AlgoPainterArtistCollection', accounts => {
  const AlgoPainterArtistCollection = artifacts.require('AlgoPainterArtistCollection');
  const AlgoPainterArtistCollectionItem = artifacts.require('AlgoPainterArtistCollectionItem');
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
  const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');
  const AlgoPainterRewardsRates = artifacts.require('AlgoPainterRewardsRates');
  const AuctionHookMOCK = artifacts.require('AuctionHookMOCK');

  let algop = null;
  let gwei = null;
  let auction = null;
  let auctionHook = null;
  let rewardRates = null;
  let nftCreators = null;
  let artistCollection = null;
  let artistCollectionItem = null;

  const DEV_FEE = '250'; // 2.5%
  const NFT_CREATOR = accounts[7];
  const ARTIST = accounts[9];
  const DEV_FEE_ACCOUNT = accounts[8];
  const CREATOR_RATE = '500'; // 5%
  const PIRS_RATE = '1500'; // 15%
  const BIDBACK_RATE = '1000'; // 10%

  const USER_ONE = accounts[1];
  const USER_TWO = accounts[2];
  const USER_THREE = accounts[3];
  const USER_FOUR = accounts[4];

  it('Should deploy the contracts', async () => {
    algop = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    auctionHook = await AuctionHookMOCK.new();
    nftCreators = await AlgoPainterNFTCreators.new();
    auction = await AlgoPainterAuctionSystem.new(
      '1209600',
      DEV_FEE_ACCOUNT,
      DEV_FEE,
      DEV_FEE,
      [algop.address]
    );

    rewardRates = await AlgoPainterRewardsRates.new(
      '1209600',
      3000,
      3000,
      3000,
      auctionHook.address,
      auction.address,
      web3.utils.randomHex(20),
      web3.utils.randomHex(20),
      0,
      0
    );

    artistCollection = await AlgoPainterArtistCollection.new(
      "1200000",
      rewardRates.address,
      DEV_FEE_ACCOUNT,
      web3.utils.toWei('0.1', 'ether'),
      '1209600',
      '1',
      '1000',
      [algop.address]
    );

    artistCollectionItem = await AlgoPainterArtistCollectionItem.new(
      nftCreators.address,
      rewardRates.address,
      artistCollection.address,
      auction.address,
      DEV_FEE_ACCOUNT,
      '1000',
      '0'
    );

    await auction.setup(
      auctionHook.address,
      rewardRates.address,
      nftCreators.address
    );

    await algop.transfer(USER_ONE, web3.utils.toWei('10000', 'ether'));
    await algop.transfer(USER_TWO, web3.utils.toWei('10000', 'ether'));
    await algop.transfer(USER_THREE, web3.utils.toWei('10000', 'ether'));
    await algop.transfer(USER_FOUR, web3.utils.toWei('10000', 'ether'));
    await algop.approve(artistCollectionItem.address, web3.utils.toWei('10000', 'ether'), { from: USER_ONE });
    await algop.approve(artistCollectionItem.address, web3.utils.toWei('10000', 'ether'), { from: USER_TWO });
    await algop.approve(auction.address, web3.utils.toWei('10000', 'ether'), { from: USER_ONE });
    await algop.approve(auction.address, web3.utils.toWei('10000', 'ether'), { from: USER_TWO });
    await algop.approve(auction.address, web3.utils.toWei('10000', 'ether'), { from: USER_THREE });
    await algop.approve(auction.address, web3.utils.toWei('10000', 'ether'), { from: USER_FOUR });

    await rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE(), artistCollectionItem.address);
    await nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE(), artistCollectionItem.address);

  });

  it("Should create a collection", async () => {
    const now = parseInt((await artistCollection.getNow()).toString());
    const startTime = (now + 1).toString();
    const expirationTime = (now + 1000000).toString();

    await artistCollection.createCollection(
      ARTIST,
      [startTime, expirationTime],
      web3.utils.padLeft(web3.utils.asciiToHex("Collection Name"), '64'),
      500,
      web3.utils.toWei('100', 'ether'),
      algop.address,
      1,
      2,
      [1, 5, web3.utils.toWei('100', 'ether'), 6, 10, web3.utils.toWei('200', 'ether')],
      10,
      {
        from: ARTIST,
        value: web3.utils.toWei('0.1')
      }
    );

    expect((await artistCollection.getCountCollections()).toString()).to.be.equal('1');

    const collectionData = await artistCollection.getCollection(0);

    expect(web3.utils.hexToAscii(collectionData.name.toString())).contains("Collection Name");
    expect(ARTIST).to.be.equal(collectionData.artist.toString());
    expect(ARTIST).to.be.equal(collectionData.walletAddress.toString());
    expect(startTime).to.be.equal(collectionData.startDT.toString());
    expect(expirationTime).to.be.equal(collectionData.endDT.toString());
    expect('500').to.be.equal(collectionData.creatorPercentage.toString());
    expect(web3.utils.toWei('100', 'ether')).to.be.equal(collectionData.startingPrice.toString());
    expect(algop.address).to.be.equal(collectionData.tokenPrice.toString());
    expect('1').to.be.equal(collectionData.priceType.toString());
    expect(6).to.be.equal(collectionData.prices.length);
    expect('2').to.be.equal(collectionData.paramsCount.toString());
    expect('10').to.be.equal(collectionData.nfts.toString());
  });

  it("Should be able to interact with ArtistCollectionItem", async () => {
    const mintValue = await artistCollectionItem.getMintValue(0);
    expect(web3.utils.toWei('110', 'ether')).to.be.equal(mintValue.toString());

    const collectionTokens = await artistCollectionItem.getCollectionTokens(0);
    expect(collectionTokens.length).to.be.equal(0);

    const getRemainingTokens = await artistCollectionItem.getRemainingTokens(0);
    expect(getRemainingTokens.toString()).to.be.equal('10');
  });

  it('Should be able to mint images on created collection', async () => {
    const amount = await artistCollectionItem.getMintValue(0);
    await algop.approve(artistCollectionItem.address, amount, { from: USER_ONE });

    expect((await rewardRates.getCreatorRate(artistCollectionItem.address, 1)).toString()).to.be.equal('0');
    await artistCollectionItem.mint(
      'mouse',
      0,
      [web3.utils.randomHex(32), web3.utils.randomHex(32)],
      'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
      web3.utils.toWei('110', 'ether'),
      { from: USER_ONE }
    );

    expect((await algop.balanceOf(USER_ONE)).toString()).to.be.equal(web3.utils.toWei('9890', 'ether'));
    expect(await artistCollectionItem.tokenURI(1)).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
    expect((await rewardRates.getCreatorRate(artistCollectionItem.address, 1)).toString()).to.be.equal('500');
    expect((await rewardRates.getCreatorRoyaltiesByTokenAddress(await artistCollectionItem.getTokenHashForAuction(1))).toString()).to.be.equal('500');
    expect((await nftCreators.getCreatorNotPayable(artistCollectionItem.address, 1))).to.be.equal(ARTIST);
  });
});