contract('AlgoPainterPersonalItem', accounts => {
  const AlgoPainterToken = artifacts.require('AlgoPainterToken');
  const AlgoPainterPersonalItem = artifacts.require('AlgoPainterPersonalItem');
  const AlgoPainterRewardsRates = artifacts.require('AlgoPainterRewardsRates');
  const AlgoPainterRewardsDistributor = artifacts.require('AlgoPainterRewardsDistributor');
  const AlgoPainterStorage = artifacts.require('AlgoPainterStorage');
  const AlgoPainterSecurity = artifacts.require('AlgoPainterSecurity');
  const AlgoPainterAuctionSystemHook = artifacts.require('AlgoPainterAuctionHook');
  const AlgoPainterAuctionSystem = artifacts.require('AlgoPainterAuctionSystem');
  const AlgoPainterNFTCreators = artifacts.require('AlgoPainterNFTCreators');

  const contracts = {
    ALGOP: null,
    AuctionSystem: null,
    AuctionSystemHook: null,
    RewardsRates: null,
    RewardsDistributor: null,
    RewardsDistributorHook: null,
    Storage: null,
    Security: null,
    NFTCreators: null,
    Instance: null
  }

  const NFT_CREATOR = accounts[7];

  it('should deploy the contracts', async () => {
    contracts.ALGOP = await AlgoPainterToken.new("AlgoPainter Token", "ALGOP");
    contracts.NFTCreators = await AlgoPainterNFTCreators.new();
    contracts.Storage = await AlgoPainterStorage.new();
    contracts.Security = await AlgoPainterSecurity.new(contracts.Storage.address);
    contracts.AuctionSystemHook = await AlgoPainterAuctionSystemHook.new();
    contracts.AuctionSystem = await AlgoPainterAuctionSystem.new(
      '1209600',
      accounts[9],
      1000,
      250,
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
      contracts.AuctionSystemHook.address,
      contracts.AuctionSystem.address,
      web3.utils.randomHex(20),
      web3.utils.randomHex(20),
      500,
      500
    );

    // //configure Auction System
    // await contracts.AuctionSystem.setRates(contracts.RewardsRates.address);
    // await contracts.AuctionSystem.setRewardsDistributorAddress(contracts.RewardsDistributor.address);
    // await contracts.AuctionSystem.setCreators(contracts.NFTCreators.address);

    // //configure Auction Hook
    // await contracts.AuctionSystemHook.grantRole(
    //   await contracts.AuctionSystemHook.HOOK_CALLER_ROLE(),
    //   contracts.AuctionSystem.address
    // );
    // await contracts.AuctionSystemHook.setAll([
    //     contracts.RewardsRates.address,
    //     contracts.RewardsDistributor.address,
    //     contracts.NFTCreators.address,
    //     contracts.Storage.address,
    //     contracts.Security.address
    // ]);

    // //configure Rates
    // await contracts.RewardsRates.grantRole(
    //   await contracts.RewardsRates.CONFIGURATOR_ROLE(),
    //   contracts.AuctionSystemHook.address
    // );
    
    // //configure Rewards
    // await contracts.RewardsDistributor.setRewardsRatesProviderAddress(contracts.RewardsRates.address);
    // await contracts.RewardsDistributor.grantRole(
    //   await contracts.RewardsDistributor.CONFIGURATOR_ROLE(),
    //   contracts.AuctionSystemHook.address
    // );

    // //configure NFTCreators
    // await contracts.NFTCreators.grantRole(
    //   await contracts.NFTCreators.CONFIGURATOR_ROLE(),
    //   contracts.AuctionSystemHook.address
    // );
    // await contracts.NFTCreators.setCreator(
    //   contracts.Gwei.address,
    //   NFT_CREATOR
    // );

    // //configure Storage
    // await contracts.Storage.grantRole(
    //   await contracts.Storage.CONFIGURATOR_ROLE(),
    //   contracts.AuctionSystemHook.address
    // );
    // await contracts.Storage.grantRole(
    //   await contracts.Storage.CONFIGURATOR_ROLE(),
    //   contracts.Security.address
    // );

    contracts.Instance = await AlgoPainterPersonalItem.new(
      contracts.NFTCreators,
      contracts.RewardsRates,
      contracts.AuctionSystem.address,
      accounts[9]
    );
    // await contracts.RewardsRates.grantRole(
    //   await contracts.RewardsRates.CONFIGURATOR_ROLE(),
    //   contracts.Instance.address
    // );
    // await contracts.Instance.setAlgoPainterRewardsRatesAddress(contracts.RewardsRates.address);
    // await contracts.Instance.setApprovalForAll(contracts.AuctionSystem.address, true);
    // await contracts.Instance.setMintToken(contracts.ALGOP.address);
    // await contracts.Instance.setMintCostToken(web3.utils.toWei('100', 'ether'));
    // await contracts.NFTCreators.grantRole(
    //   await contracts.NFTCreators.CONFIGURATOR_ROLE(),
    //   contracts.Instance.address
    // );
  });

  // it('should add account[1] as a validator', async () => {
  //   const validatorRole = await contracts.Instance.VALIDATOR_ROLE();
  //   await contracts.Instance.grantRole(
  //     validatorRole, 
  //     accounts[1]
  //   );

  //   expect(await instance.hasRole(
  //     validatorRole, 
  //     accounts[1]
  //   )).to.be.equal(true, 'fail to check accounts[1] as a validator');
  // });

  // it('should mint a new paint', async () => {
  //   const owner = accounts[2];

  //   const amount = await contracts.Instance.mintCostToken();
  //   const amountEth = await contracts.Instance.mintCost();
  //   expect(amountEth.toString()).to.be.equal(web3.utils.toWei('0.1', 'ether'));
  //   contracts.ALGOP.transfer(owner, amount, { from: accounts[0] });
  //   await contracts.ALGOP.approve(instance.address, amount, { from: owner });

  //   expect((await rewardRates.getCreatorRate(instance.address, 1)).toString()).to.be.equal('0');
  //   expect((await algop.balanceOf(owner)).toString()).to.be.equal(amount.toString());
  //   await instance.mint('mouse', '0xf1be2b4d52e8d3f4ad91afbba597a59fac5bf234031758e0af99ff875be1a13b', 800, 'https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ', { value: amountEth, from: owner });
  //   const returnedTokenURI = await instance.tokenURI(1);
  //   expect((await algop.balanceOf(owner)).toString()).to.be.equal('0');
  //   expect(returnedTokenURI).to.be.equal('https://ipfs.io/ipfs/QmTtDYysSdzBsnrQiaQbEKc443MFMQKPsHJisyRqU89YrZ');
  //   expect(await instance.getName()).to.be.equal('Personal Item by AlgoPainter');
  //   expect((await rewardRates.getCreatorRate(instance.address, 1)).toString()).to.be.equal('800');
  //   expect((await rewardRates.getCreatorRoyaltiesByTokenAddress(await instance.getTokenHashForAuction(1))).toString()).to.be.equal('800');
  // });

  // it('should update a token URI based on a valid signature', async () => {
  //   const tokenId = 1;
  //   const tokenURI = 'NEW_URI'
  //   const owner = accounts[2];

  //   //hashing the content used to mint a paint
  //   const hash = await instance.hashTokenURI(tokenId, tokenURI);

  //   //creating a validator signature
  //   const signature = await web3.eth.sign(hash, accounts[1]);
  //   await instance.updateTokenURI(tokenId, tokenURI, signature, { from: owner });

  //   const returnedTokenURI = await instance.tokenURI(1);
  //   expect(returnedTokenURI).to.be.equal('NEW_URI');
  // });

  // it('should fail to update a token URI based on an invalid validator', async () => {
  //   const tokenId = 1;
  //   const tokenURI = 'NEW_URI'
  //   const owner = accounts[2];

  //   const hash = await instance.hashTokenURI(tokenId, tokenURI);

  //   const signature = await web3.eth.sign(hash, accounts[3]);
  //   try {
  //     await instance.updateTokenURI(tokenId, tokenURI, signature, { from: owner });
  //     throw {};
  //   } catch (e) {
  //     expect(e.reason).to.be.equal('INVALID_VALIDATOR', 'fail to check failure');
  //   }
  // });

  // it('should fail to update a token URI based on an invalid signature', async () => {
  //   const tokenURI = 'NEW_URI'
  //   const tokenId = 1;
  //   const owner = accounts[2];

  //   const signature = '0x0';

  //   try {
  //     await instance.updateTokenURI(tokenId, tokenURI, signature, { from: owner });
  //     throw {};
  //   } catch (e) {
  //     expect(e.reason).to.be.equal('INVALID_SIGNATURE', 'fail to check failure');
  //   }
  // });

  // it('should fail to update a token URI based on an invalid sender', async () => {
  //   const tokenURI = 'NEW_URI'
  //   const tokenId = 1;

  //   const signature = '0x0';

  //   try {
  //     await instance.updateTokenURI(tokenId, tokenURI, signature);
  //     throw {};
  //   } catch (e) {
  //     expect(e.reason).to.be.equal('INVALID_SENDER', 'fail to check failure');
  //   }
  // });
});
