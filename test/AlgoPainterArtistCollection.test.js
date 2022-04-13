contract('AlgoPainterArtistCollection', accounts => {
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
  const AlgoPainterArtistCollection = artifacts.require('AlgoPainterArtistCollection');
  const AlgoPainterArtistCollectionItem = artifacts.require('AlgoPainterArtistCollectionItem');

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
    Security: null,
    ArtistCollection: null,
    ArtistCollectionItem: null
  }

  const DEV_FEE = '250'; // 2.5%
  const NFT_CREATOR = accounts[7];
  const ARTIST = accounts[9];
  const DEV_FEE_ACCOUNT = accounts[8];
  const CREATOR_RATE = '500'; // 5%

  const USER_ONE = accounts[1];
  const USER_TWO = accounts[2];
  const USER_THREE = accounts[3];
  const USER_FOUR = accounts[4];

  it('Should initiate contracts', async () => {
    contracts.ALGOP = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    contracts.Gwei = await AlgoPainterGweiItem.new(contracts.ALGOP.address, ARTIST);
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
    contracts.ArtistCollection = await AlgoPainterArtistCollection.new(
      '1200000',
      contracts.RewardsRates.address,
      DEV_FEE_ACCOUNT,
      web3.utils.toWei('17000', 'ether'),
      contracts.ALGOP.address,
      '1209600',
      '1',
      '1000',
      [contracts.ALGOP.address]
    );
    contracts.ArtistCollectionItem = await AlgoPainterArtistCollectionItem.new(
      contracts.NFTCreators.address,
      contracts.RewardsRates.address,
      contracts.ArtistCollection.address,
      contracts.AuctionSystem.address,
      DEV_FEE_ACCOUNT,
      '1000',
      '0'
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
    await contracts.NFTCreators.setCreator(contracts.Gwei.address, NFT_CREATOR);

    //configure Storage
    await contracts.Storage.grantRole(await contracts.Storage.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
    await contracts.Storage.grantRole(await contracts.Storage.CONFIGURATOR_ROLE(), contracts.Security.address);

    //configure Artist Collection
    await contracts.ArtistCollection.grantRole(await contracts.ArtistCollection.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
    await contracts.ArtistCollection.grantRole(await contracts.ArtistCollection.CONFIGURATOR_ROLE(), contracts.Security.address);

    //configure Artist Collection Item
    await contracts.ArtistCollectionItem.grantRole(await contracts.ArtistCollectionItem.CONFIGURATOR_ROLE(), contracts.AuctionSystemHook.address);
    await contracts.ArtistCollectionItem.grantRole(await contracts.ArtistCollectionItem.CONFIGURATOR_ROLE(), contracts.Security.address);
    await contracts.ArtistCollectionItem.grantRole(await contracts.ArtistCollectionItem.CONFIGURATOR_ROLE(), contracts.Security.address);

    //configurations for unit test
    await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true);
    await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_ONE });
    await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_TWO });
    await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_THREE });
    await contracts.Gwei.setApprovalForAll(contracts.AuctionSystem.address, true, { from: USER_FOUR });
    await contracts.Gwei.setApprovalForAll(contracts.ArtistCollection.address, true, { from: ARTIST });
    await contracts.Gwei.setApprovalForAll(USER_ONE, true);
    await contracts.Gwei.setApprovalForAll(USER_TWO, true);
    await contracts.Gwei.setApprovalForAll(USER_THREE, true);
    await contracts.Gwei.setApprovalForAll(USER_FOUR, true);
    await contracts.Gwei.manageWhitelist([USER_ONE, USER_TWO], true);

    await contracts.ALGOP.transfer(ARTIST, web3.utils.toWei('40000', 'ether'));
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
    await contracts.ALGOP.approve(contracts.ArtistCollection.address, web3.utils.toWei('17000', 'ether'), { from: ARTIST });
  });

  it("Should create a collection", async () => {
    const now = parseInt((await contracts.ArtistCollection.getNow()).toString());
    const startTime = (now + 1).toString();
    const expirationTime = (now + 1000000).toString();

    await contracts.ArtistCollection.createCollection(
      ARTIST,
      [startTime, expirationTime],
      web3.utils.padLeft(web3.utils.asciiToHex("Collection Name"), '64'),
      500,
      web3.utils.toWei('0.1', 'ether'),
      contracts.ALGOP.address,
      1,
      [1, 5, web3.utils.toWei('0.1', 'ether'), 6, 10, web3.utils.toWei('200', 'ether')],
      10,
      'QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
      {
        from: ARTIST
      }
    );

    expect((await contracts.ArtistCollection.getCountCollections()).toString()).to.be.equal('1');

    const collectionData = await contracts.ArtistCollection.getCollection(0);

    expect(web3.utils.hexToAscii(collectionData.name.toString())).contains("Collection Name");
    expect(ARTIST).to.be.equal(collectionData.artist.toString());
    expect(ARTIST).to.be.equal(collectionData.walletAddress.toString());
    expect(startTime).to.be.equal(collectionData.startDT.toString());
    expect(expirationTime).to.be.equal(collectionData.endDT.toString());
    expect('500').to.be.equal(collectionData.creatorPercentage.toString());
    expect(web3.utils.toWei('0.1', 'ether')).to.be.equal(collectionData.startingPrice.toString());
    expect(contracts.ALGOP.address).to.be.equal(collectionData.tokenPrice.toString());
    expect('1').to.be.equal(collectionData.priceType.toString());
    expect(6).to.be.equal(collectionData.prices.length);
    expect('10').to.be.equal(collectionData.nfts.toString());
    expect('QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ').to.be.equal(collectionData.descriptor.toString());
  });

  it("Should be able to interact with ArtistCollectionItem", async () => {
    const mintValue = await contracts.ArtistCollectionItem.getMintValue(0);
    expect(web3.utils.toWei('0.110', 'ether')).to.be.equal(mintValue.toString());

    const collectionTokens = await contracts.ArtistCollectionItem.getCollectionTokens(0);
    expect(collectionTokens.length).to.be.equal(0);

    const getRemainingTokens = await contracts.ArtistCollectionItem.getRemainingTokens(0);
    expect(getRemainingTokens.toString()).to.be.equal('10');
  });

  it('Should be able to mint images on created collection', async () => {
    const amount = await contracts.ArtistCollectionItem.getMintValue(0);
    await contracts.ALGOP.approve(contracts.ArtistCollectionItem.address, amount, { from: USER_ONE });

    expect((await contracts.RewardsRates.getCreatorRate(contracts.ArtistCollectionItem.address, 1)).toString()).to.be.equal('0');

    await await contracts.ArtistCollectionItem.mint(
      'mouse',
      0,
      ['0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0xe61d9a3d3848fb2cdd9a2ab61e2f21a10ea431275aed628a0557f9dee697c37a','0xc0a1b4161f24688435c57ea81f26cd24d704bcd2560e2f5758e69582b4085494','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x99a4d6753a5d526f0442c260e94d9c15b48cec7c4c2ea9bd6cc6971d15b50c47','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6','0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034','0x6273151f959616268004b58dbb21e5c851b7b8d04498b4aabee12291d22fc034'],
      'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ',
      web3.utils.toWei('110', 'ether'),
      { from: USER_ONE }
    );

    expect((await contracts.ALGOP.balanceOf(USER_ONE)).toString()).to.be.equal(web3.utils.toWei('39999.89', 'ether'));
    expect(await contracts.ArtistCollectionItem.tokenURI(1)).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
    expect((await contracts.RewardsRates.getCreatorRate(contracts.ArtistCollectionItem.address, 1)).toString()).to.be.equal('500');
    expect((await contracts.RewardsRates.getCreatorRoyaltiesByTokenAddress(await contracts.ArtistCollectionItem.getTokenHashForAuction(1))).toString()).to.be.equal('500');
    expect((await contracts.NFTCreators.getCreatorNotPayable(contracts.ArtistCollectionItem.address, 1))).to.be.equal(ARTIST);
    expect((await contracts.ArtistCollectionItem.getTokenSenquentialNumber(0, 1)).toString()).to.be.equal('1');
  });
});