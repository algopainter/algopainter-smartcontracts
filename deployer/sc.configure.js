const { mongourl, chainID, blockExplorer, mnemonic, rpcUrl, account, gasLimit, web3, contractsAddress } = require("./settings.js");

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterRewardsRates = require('../build/contracts/AlgoPainterRewardsRates.json');
const AlgoPainterRewardsDistributor = require('../build/contracts/AlgoPainterRewardsDistributor.json');
const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');
const AlgoPainterPersonalItem = require('../build/contracts/AlgoPainterPersonalItem.json');
const AlgoPainterNFTCreators = require('../build/contracts/AlgoPainterNFTCreators.json');

const Mongoose = require('mongoose');
const SettingsContext = require('./db.settings.js');

const Configurator = function () {
  this.write = true;

  this.sendTransaction = async (tx) => {
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

    return await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);
  }

  this.nftCreators = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter NFT Creators');
    console.log('=====================================================================================');

    const nftCreators = new web3.eth.Contract(AlgoPainterNFTCreators.abi, contractsAddress.AlgoPainterNFTCreators).methods;
    if (this.write) {
      const grantRoleAuctionTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterAuctionSystem);
      const grantRolePersonalTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);

      await this.sendTransaction(grantRoleAuctionTx);
      await this.sendTransaction(grantRolePersonalTx);
    }

    return {
      grantRoleAuctionTx: contractsAddress.AlgoPainterAuctionSystem,
      grantRolePersonalTx: contractsAddress.AlgoPainterPersonalItem
    }
  }

  this.personalItem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter Personal Item');
    console.log('=====================================================================================');

    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contractsAddress.AlgoPainterPersonalItem).methods;

    if (this.write) {
      const approveAuctionSystemTx = personal.setApprovalForAll(contractsAddress.AlgoPainterAuctionSystem, true);
      const setBidBackPirsContractTx = personal.setAlgoPainterRewardsRatesAddress(contractsAddress.AlgoPainterRewardsRates);

      await this.sendTransaction(approveAuctionSystemTx);
      await this.sendTransaction(setBidBackPirsContractTx);
    }

    return {
      setAlgoPainterRewardsRatesAddress: await (personal.getAlgoPainterRewardsRatesAddress().call()),
    }
  }

  this.auctionSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Auction System');
    console.log('=====================================================================================');

    const auction = new web3.eth.Contract(AlgoPainterAuctionSystem.abi, contractsAddress.AlgoPainterAuctionSystem).methods;
    const gwei = new web3.eth.Contract(AlgoPainterGweiItem.abi, contractsAddress.AlgoPainterGweiItem).methods;
    const expressions = new web3.eth.Contract(AlgoPainterExpressionsItem.abi, contractsAddress.AlgoPainterExpressionsItem).methods;
    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contractsAddress.AlgoPainterPersonalItem).methods;

    if (this.write) {
      const setupTx = auction.setup(
        account,
        contractsAddress.AlgoPainterRewardsDistributor,
        250,
        250,
        [contractsAddress.AlgoPainterToken],
        contractsAddress.AlgoPainterRewardsRates
      );

      const gweiSetApprovalForAllTx = gwei.setApprovalForAll(contractsAddress.AlgoPainterAuctionSystem, true);
      const expressionsSetApprovalForAllTx = expressions.setApprovalForAll(contractsAddress.AlgoPainterAuctionSystem, true);
      const personalSetApprovalForAllTx = personal.setApprovalForAll(contractsAddress.AlgoPainterAuctionSystem, true);
      const setAlgoPainterNFTCreatorsTx = auction.setAlgoPainterNFTCreators(contractsAddress.AlgoPainterNFTCreators);

      await this.sendTransaction(setupTx);
      await this.sendTransaction(gweiSetApprovalForAllTx);
      await this.sendTransaction(expressionsSetApprovalForAllTx);
      await this.sendTransaction(personalSetApprovalForAllTx);
      await this.sendTransaction(setAlgoPainterNFTCreatorsTx);
    }

    return {
      setAddressFee: await (auction.getAddressFee().call()),
      setAuctionFeeRate: await (auction.getAuctionFeeRate().call()),
      setBidFeeRate: await (auction.getBidFeeRate().call()),
      setAllowedTokens: await (auction.getAllowedTokens().call()),
      setAuctionHook: await (auction.getAuctionHook().call()),
      setRewardsRates: await (auction.getRewardsRates().call()),
      setAlgoPainterNFTCreators: await (auction.getAlgoPainterNFTCreators().call()),
    }
  }

  this.rewardRatesSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring BidBack PIRS');
    console.log('=====================================================================================');

    const rewardRates = new web3.eth.Contract(AlgoPainterRewardsRates.abi, contractsAddress.AlgoPainterRewardsRates).methods;

    if (this.write) {
      const grantRoleAuctionTx = rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterAuctionSystem);
      const grantRolePersonalItemTx = rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);
      const setAuctionSystemAddressTx = rewardRates.setAuctionSystemAddress(contractsAddress.AlgoPainterAuctionSystem);
      const setMaxPIRSRateTx = rewardRates.setMaxPIRSRate(3000);
      const setMaxCreatorRoyaltiesRateTx = rewardRates.setMaxCreatorRoyaltiesRate(3000);
      const setCreatorRoyaltiesRateTx = rewardRates.setCreatorRoyaltiesRate(contractsAddress.AlgoPainterGweiItem, 500);
      const setCreatorRoyaltiesRateTx2 = rewardRates.setCreatorRoyaltiesRate(contractsAddress.AlgoPainterExpressionsItem, 500);
      const setMaxBidbackRateTx = rewardRates.setMaxBidbackRate(3000);

      await this.sendTransaction(grantRoleAuctionTx);
      await this.sendTransaction(grantRolePersonalItemTx);
      await this.sendTransaction(setAuctionSystemAddressTx);
      await this.sendTransaction(setMaxCreatorRoyaltiesRateTx);
      await this.sendTransaction(setCreatorRoyaltiesRateTx);
      await this.sendTransaction(setCreatorRoyaltiesRateTx2);
      await this.sendTransaction(setMaxPIRSRateTx);
      await this.sendTransaction(setMaxBidbackRateTx);
    }
    return {
      grantRoleAuctionTx: contractsAddress.AlgoPainterAuctionSystem,
      setMaxCreatorRoyaltiesRate: await rewardRates.getMaxCreatorRoyaltiesRate().call(),
      setCreatorRoyaltiesRateGwei: await rewardRates.getCreatorRoyaltiesByTokenAddress(contractsAddress.AlgoPainterGweiItem).call(),
      setCreatorRoyaltiesRateExpressions: await rewardRates.getCreatorRoyaltiesByTokenAddress(contractsAddress.AlgoPainterExpressionsItem).call(),
      setMaxPIRSRate: await rewardRates.getMaxInvestorPirsRate().call(),
      setMaxBidbackRate: await rewardRates.getMaxBidbackRate().call(),
    }
  }

  this.rewardsDistributorSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Rewards');
    console.log('=====================================================================================');
    const rewardsDistributorSystemManager = new web3.eth.Contract(AlgoPainterRewardsDistributor.abi, contractsAddress.AlgoPainterRewardsDistributor).methods;

    if (this.write) {
      const setAllowedSenderTx = rewardsDistributorSystemManager.setAllowedSender(contractsAddress.AlgoPainterAuctionSystem)
      const setStakeTokenTx = rewardsDistributorSystemManager.setStakeToken(contractsAddress.AlgoPainterToken);
      const setAuctionSystemAddressTx = rewardsDistributorSystemManager.setAuctionSystemAddress(contractsAddress.AlgoPainterAuctionSystem);
      const setRewardsRatesProviderAddressTx = rewardsDistributorSystemManager.setRewardsRatesProviderAddress(contractsAddress.AlgoPainterRewardsRates);

      await this.sendTransaction(setAllowedSenderTx);
      await this.sendTransaction(setStakeTokenTx);
      await this.sendTransaction(setAuctionSystemAddressTx);
      await this.sendTransaction(setRewardsRatesProviderAddressTx);
    }
    return {
      setStakeToken: await rewardsDistributorSystemManager.getStakeToken().call(),
      setAuctionSystemAddress: await rewardsDistributorSystemManager.getAuctionSystemAddress().call(),
      setRewardsRatesProviderAddress: await rewardsDistributorSystemManager.getRewardsRatesProviderAddress().call()
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
              label: 'BTCB',
              tokenAddress: '0x6ce8da28e2f864420840cf74474eff5fd80e65b8',
              decimalPlaces: 18,
              img: '/images/BTC.svg',
            },
            {
              value: '3',
              name: 'AlgoPainter Token',
              tokenAddress: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
              label: 'ALGOP',
              decimalPlaces: 18,
              img: '/images/ALGOP.svg'
            },
            {
              value: '6',
              name: 'DAI',
              tokenAddress: '0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867',
              label: 'DAI',
              decimalPlaces: 18,
              img: '/images/DAI.svg'
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

  return this;
}();

(async () => {
  try {
    Configurator.write = false;

    console.log(contractsAddress);

    // console.log(await Configurator.nftCreators());
    // console.log(await Configurator.personalItem());
    // console.log(await Configurator.auctionSystem());
    // console.log(await Configurator.rewardRatesSystem());
    // console.log(await Configurator.rewardsDistributorSystem());
    // console.log(await Configurator.reloadSettings());

  } catch (error) {
    console.error(error);
  }
})();