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
      web3.utils.toWei('17000', 'ether'),
      algop.address,
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

    await algop.transfer(ARTIST, web3.utils.toWei('40000', 'ether'));
    await algop.transfer(USER_ONE, web3.utils.toWei('40000', 'ether'));
    await algop.transfer(USER_TWO, web3.utils.toWei('40000', 'ether'));
    await algop.transfer(USER_THREE, web3.utils.toWei('40000', 'ether'));
    await algop.transfer(USER_FOUR, web3.utils.toWei('40000', 'ether'));
    await algop.approve(artistCollection.address, web3.utils.toWei('17000', 'ether'), { from: ARTIST });
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
      web3.utils.toWei('0.1', 'ether'),
      algop.address,
      1,
      [1, 5, web3.utils.toWei('0.1', 'ether'), 6, 10, web3.utils.toWei('200', 'ether')],
      10,
      'QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
      {
        from: ARTIST
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
    expect(web3.utils.toWei('0.1', 'ether')).to.be.equal(collectionData.startingPrice.toString());
    expect(algop.address).to.be.equal(collectionData.tokenPrice.toString());
    expect('1').to.be.equal(collectionData.priceType.toString());
    expect(6).to.be.equal(collectionData.prices.length);
    expect('10').to.be.equal(collectionData.nfts.toString());
    expect('QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ').to.be.equal(collectionData.descriptor.toString());
  });

  it("Should be able to interact with ArtistCollectionItem", async () => {
    const mintValue = await artistCollectionItem.getMintValue(0);
    expect(web3.utils.toWei('0.110', 'ether')).to.be.equal(mintValue.toString());

    const collectionTokens = await artistCollectionItem.getCollectionTokens(0);
    expect(collectionTokens.length).to.be.equal(0);

    const getRemainingTokens = await artistCollectionItem.getRemainingTokens(0);
    expect(getRemainingTokens.toString()).to.be.equal('10');
  });

  it('Should be able to mint images on created collection', async () => {
    const amount = await artistCollectionItem.getMintValue(0);
    await algop.approve(artistCollectionItem.address, amount, { from: USER_ONE });

    expect((await rewardRates.getCreatorRate(artistCollectionItem.address, 1)).toString()).to.be.equal('0');

    // const validate = await artistCollectionItem.validateMint(
    //   'mouse',
    //   0,
    //   ['0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0xe61d9a3d3848fb2cdd9a2ab61e2f21a10ea431275aed628a0557f9dee697c37a','0xc0a1b4161f24688435c57ea81f26cd24d704bcd2560e2f5758e69582b4085494','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x99a4d6753a5d526f0442c260e94d9c15b48cec7c4c2ea9bd6cc6971d15b50c47','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034'],
    //   'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
    //   web3.utils.toWei('110', 'ether'),
    //   { from: USER_ONE }
    // );

    // expect(validate).to.be.equal('VALID');

    await artistCollectionItem.mint(
      'mouse',
      0,
      ['0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0xe61d9a3d3848fb2cdd9a2ab61e2f21a10ea431275aed628a0557f9dee697c37a','0xc0a1b4161f24688435c57ea81f26cd24d704bcd2560e2f5758e69582b4085494','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x99a4d6753a5d526f0442c260e94d9c15b48cec7c4c2ea9bd6cc6971d15b50c47','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034'],
      'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
      web3.utils.toWei('110', 'ether'),
      { from: USER_ONE }
    );

    expect((await algop.balanceOf(USER_ONE)).toString()).to.be.equal(web3.utils.toWei('39999.89', 'ether'));
    expect(await artistCollectionItem.tokenURI(1)).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
    expect((await rewardRates.getCreatorRate(artistCollectionItem.address, 1)).toString()).to.be.equal('500');
    expect((await rewardRates.getCreatorRoyaltiesByTokenAddress(await artistCollectionItem.getTokenHashForAuction(1))).toString()).to.be.equal('500');
    expect((await nftCreators.getCreatorNotPayable(artistCollectionItem.address, 1))).to.be.equal(ARTIST);
  });
});