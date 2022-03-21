const { mongourl, chainID, blockExplorer, mnemonic, rpcUrl, account, gasLimit, web3, accounts, contractsAddress } = require("./settings.js");

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterRewardsRates = require('../build/contracts/AlgoPainterRewardsRates.json');
const AlgoPainterRewardsDistributor = require('../build/contracts/AlgoPainterRewardsDistributor.json');
const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');
const AlgoPainterPersonalItem = require('../build/contracts/AlgoPainterPersonalItem.json');
const AlgoPainterNFTCreators = require('../build/contracts/AlgoPainterNFTCreators.json');
const AlgoPainterArtistCollection = require('../build/contracts/AlgoPainterArtistCollection.json');
const AlgoPainterArtistCollectionItem = require('../build/contracts/AlgoPainterArtistCollectionItem.json');

const Mongoose = require('mongoose');
const SettingsContext = require('./db.settings.js');

const Configurator = function () {
  this.write = true;

  this.sendTransaction = async (name, tx) => {
    const createTransaction = await web3.eth.accounts.signTransaction(
      {
        to: tx._parent._address,
        data: tx.encodeABI(),
        gas: web3.utils.toHex(await tx.estimateGas({ from: account })),
        gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
        value: 0
      },
      mnemonic
    );

    const transaction = await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);

    console.log(name, transaction.gasUsed);

    return transaction
  }

  this.auctionSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Auction System');
    console.log('=====================================================================================');

    const auction = new web3.eth.Contract(AlgoPainterAuctionSystem.abi, contractsAddress.AlgoPainterAuctionSystem).methods;

    if (this.write) {
      const setupTx = auction.setup(
        contractsAddress.AlgoPainterRewardsDistributor,
        contractsAddress.AlgoPainterRewardsRates,
        contractsAddress.AlgoPainterNFTCreators,
      );

      await this.sendTransaction('setupTx', setupTx);
    }

    return {
      setup: [
        contractsAddress.AlgoPainterRewardsDistributor,
        contractsAddress.AlgoPainterRewardsRates,
        contractsAddress.AlgoPainterNFTCreators
      ]
    }
  }

  this.rewardsDistributorSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Rewards');
    console.log('=====================================================================================');

    const rewardsDistributorSystemManager = new web3.eth.Contract(AlgoPainterRewardsDistributor.abi, contractsAddress.AlgoPainterRewardsDistributor).methods;

    if (this.write) {
      const setRewardsRatesProviderAddressTx = rewardsDistributorSystemManager.setRewardsRatesProviderAddress(contractsAddress.AlgoPainterRewardsRates);

      await this.sendTransaction('setRewardsRatesProviderAddressTx', setRewardsRatesProviderAddressTx);
    }
    return {
      setRewardsRatesProviderAddress: await rewardsDistributorSystemManager.rewardsRatesProvider().call()
    }
  }

  this.rewardRatesSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Rewards Rates');
    console.log('=====================================================================================');

    const rewardRates = new web3.eth.Contract(AlgoPainterRewardsRates.abi, contractsAddress.AlgoPainterRewardsRates).methods;

    if (this.write) {
      const grantRolePersonalItemTx = rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);
      const grantRoleArtistCollectionItemTx = rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterArtistCollectionItem);

      await this.sendTransaction('grantRolePersonalItemTx', grantRolePersonalItemTx);
      await this.sendTransaction('grantRoleArtistCollectionItemTx', grantRoleArtistCollectionItemTx);
    }
    return {
      grantRolePersonalItemTx: contractsAddress.AlgoPainterPersonalItem,
      grantRoleArtistCollectionItemTx: contractsAddress.AlgoPainterArtistCollectionItem,
    }
  }

  this.nftCreators = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter NFT Creators');
    console.log('=====================================================================================');

    const nftCreators = new web3.eth.Contract(AlgoPainterNFTCreators.abi, contractsAddress.AlgoPainterNFTCreators).methods;
    if (this.write) {
      const grantRolePersonalTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);
      const grantRoleArtistItemTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterArtistCollectionItem);

      await this.sendTransaction('grantRoleArtistItemTx', grantRoleArtistItemTx);
      await this.sendTransaction('grantRolePersonalTx', grantRolePersonalTx);
    }

    return {
      grantRoleArtistItemTx: contractsAddress.AlgoPainterArtistCollectionItem,
      grantRolePersonalTx: contractsAddress.AlgoPainterPersonalItem,
    }
  }

  this.personalItem =  async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter Personal Item');
    console.log('=====================================================================================');

    const personalItem = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contractsAddress.AlgoPainterPersonalItem).methods;
    if (this.write) {
      const setMintCostTx = personalItem.setMintCost(0);
      const setMintTokenTx = personalItem.setMintToken(contractsAddress.AlgoPainterToken);
      const setMintCostTokenTx = personalItem.setMintCostToken(web3.utils.toWei('17000'));

      await this.sendTransaction('setMintCostTx', setMintCostTx);
      await this.sendTransaction('setMintTokenTx', setMintTokenTx);
      await this.sendTransaction('setMintCostTokenTx', setMintCostTokenTx);
    }

    return {
      setMintCostTx: await personalItem.mintCost().call(),
      setMintTokenTx: await personalItem.mintToken().call(),
      setMintCostTokenTx: await personalItem.mintCostToken().call(),
    }
  }

  this.reloadSettings = async () => {
    console.log('=====================================================================================');
    console.log('Reloading Settings');
    console.log('=====================================================================================');

    Mongoose.connect(mongourl, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });

    try {
      if (this.write) {
        const currentBlock = await web3.eth.getBlockNumber();
        await SettingsContext.deleteOne();
        await SettingsContext.create({
          tokens: [
            {
              value: '1',
              name: 'AlgoPainter Token',
              tokenAddress: contractsAddress.AlgoPainterToken,
              label: 'ALGOP',
              decimalPlaces: 18,
              img: '/images/ALGOP.svg'
            },
            {
              value: '2',
              name: 'BUSD',
              tokenAddress: contractsAddress.BUSDToken,
              label: 'BUSD',
              decimalPlaces: 18,
              img: '/images/BUSD.svg'
            }
          ],
          smartcontracts: [
            {
              address: contractsAddress.AlgoPainterAuctionSystem,
              name: 'AlgoPainterAuctionSystem',
              symbol: 'APAS',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterAuctionSystem.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterRewardsDistributor,
              name: 'AlgoPainterRewardsDistributor',
              symbol: 'APRS',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterRewardsDistributor.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterRewardsRates,
              name: 'AlgoPainterRewardsRates',
              symbol: 'APBPS',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterRewardsRates.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterGweiItem,
              name: 'AlgoPainterGweiItem',
              symbol: 'APGI',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterGweiItem.abi,
              inUse: false
            },
            {
              address: contractsAddress.AlgoPainterExpressionsItem,
              name: 'AlgoPainterExpressionsItem',
              symbol: 'APEXPI',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterExpressionsItem.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterPersonalItem,
              name: 'AlgoPainterPersonalItem',
              symbol: 'APPI',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterPersonalItem.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterNFTCreators,
              name: 'AlgoPainterNFTCreators',
              symbol: 'APNFTC',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterPersonalItem.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterArtistCollection,
              name: 'AlgoPainterArtistCollection',
              symbol: 'APAC',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterArtistCollection.abi,
              inUse: true
            },
            {
              address: contractsAddress.AlgoPainterArtistCollectionItem,
              name: 'AlgoPainterArtistCollectionItem',
              symbol: 'APACI',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterArtistCollectionItem.abi,
              inUse: true
            }
          ]
        });
      }
  
      return await SettingsContext.findOne();
    } catch(e) {
      return e;
    } finally {
      Mongoose.disconnect();
    }
  }

  this.customCall = async(address, abi, method) => {
    const instance = new web3.eth.Contract(abi, address).methods;
    return eval(method);
  }

  return this;
}();

(async () => {
  try {
    Configurator.write = true;

     console.log(await Configurator.nftCreators());
    // console.log(await Configurator.auctionSystem());
    // console.log(await Configurator.rewardsDistributorSystem());
     console.log(await Configurator.rewardRatesSystem());
    // console.log(await Configurator.personalItem());
     console.log(await Configurator.reloadSettings());
     console.log(contractsAddress);

  } catch (error) {
    console.error(error);
  }
})();