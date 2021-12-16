const { mongourl, chainID, blockExplorer, mnemonic, rpcUrl, account, gasLimit, web3, contracts } = require("./settings.js");

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterBidBackPirs = require('../build/contracts/AlgoPainterBidBackPirs.json');
const AlgoPainterRewardsSystem = require('../build/contracts/AlgoPainterRewardsSystem.json');
const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');
const AlgoPainterPersonalItem = require('../build/contracts/AlgoPainterPersonalItem.json');

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

  this.personalItem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter Personal Item');
    console.log('=====================================================================================');

    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contracts.AlgoPainterPersonalItem).methods;

    if (this.write) {
      const approveAuctionSystemTx = personal.setApprovalForAll(contracts.AlgoPainterAuctionSystem, true);
      const setBidBackPirsContractTx = personal.setAlgoPainterBidBackPirsAddress(contracts.AlgoPainterBidBackPirs);

      await this.sendTransaction(approveAuctionSystemTx);
      await this.sendTransaction(setBidBackPirsContractTx);
    }

    return {
      setAlgoPainterBidBackPirsAddress: await (personal.getAlgoPainterBidBackPirsAddress().call()),
    }
  }

  this.auctionSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Auction System');
    console.log('=====================================================================================');

    const auction = new web3.eth.Contract(AlgoPainterAuctionSystem.abi, contracts.AlgoPainterAuctionSystem).methods;
    const gwei = new web3.eth.Contract(AlgoPainterGweiItem.abi, contracts.AlgoPainterGweiItem).methods;
    const expressions = new web3.eth.Contract(AlgoPainterExpressionsItem.abi, contracts.AlgoPainterExpressionsItem).methods;
    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contracts.AlgoPainterPersonalItem).methods;

    if (this.write) {
      const setupTx = auction.setup(
        account,
        contracts.AlgoPainterRewardsSystem,
        250,
        250,
        [contracts.AlgoPainterToken],
        contracts.AlgoPainterRewardsSystem,
        contracts.AlgoPainterBidBackPirs
      );

      const gweiSetApprovalForAllTx = gwei.setApprovalForAll(contracts.AlgoPainterAuctionSystem, true);
      const expressionsSetApprovalForAllTx = expressions.setApprovalForAll(contracts.AlgoPainterAuctionSystem, true);
      const personalSetApprovalForAllTx = personal.setApprovalForAll(contracts.AlgoPainterAuctionSystem, true);

      await this.sendTransaction(setupTx);
      await this.sendTransaction(gweiSetApprovalForAllTx);
      await this.sendTransaction(expressionsSetApprovalForAllTx);
      await this.sendTransaction(personalSetApprovalForAllTx);
    }

    return {
      setAddressFee: await (auction.getAddressFee().call()),
      setAuctionFeeRate: await (auction.getAuctionFeeRate().call()),
      setBidFeeRate: await (auction.getBidFeeRate().call()),
      setAllowedTokens: await (auction.getAllowedTokens().call()),
      setAuctionSystemManager: await (auction.getAuctionSystemManager().call()),
    }
  }

  this.bidbackPirsSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring BidBack PIRS');
    console.log('=====================================================================================');

    const bidbackPirs = new web3.eth.Contract(AlgoPainterBidBackPirs.abi, contracts.AlgoPainterBidBackPirs).methods;

    if (this.write) {
      const setAuctionSystemAddressTx = bidbackPirs.setAuctionSystemAddress(contracts.AlgoPainterAuctionSystem);
      const setMaxInvestorPirsRateTx = bidbackPirs.setMaxInvestorPirsRate(3000);
      const setMaxCreatorRoyaltiesRateTx = bidbackPirs.setMaxCreatorRoyaltiesRate(3000);
      const setCreatorRoyaltiesRateTx = bidbackPirs.setCreatorRoyaltiesRate(contracts.AlgoPainterGweiItem, 500);
      const setCreatorRoyaltiesRateTx2 = bidbackPirs.setCreatorRoyaltiesRate(contracts.AlgoPainterExpressionsItem, 500);
      const setMaxBidbackRateTx = bidbackPirs.setMaxBidbackRate(3000);

      await this.sendTransaction(setAuctionSystemAddressTx);
      await this.sendTransaction(setMaxCreatorRoyaltiesRateTx);
      await this.sendTransaction(setCreatorRoyaltiesRateTx);
      await this.sendTransaction(setCreatorRoyaltiesRateTx2);
      await this.sendTransaction(setMaxInvestorPirsRateTx);
      await this.sendTransaction(setMaxBidbackRateTx);
    }
    return {
      setMaxCreatorRoyaltiesRate: await bidbackPirs.getMaxCreatorRoyaltiesRate().call(),
      setCreatorRoyaltiesRateGwei: await bidbackPirs.getCreatorRoyaltiesByTokenAddress(contracts.AlgoPainterGweiItem).call(),
      setCreatorRoyaltiesRateExpressions: await bidbackPirs.getCreatorRoyaltiesByTokenAddress(contracts.AlgoPainterExpressionsItem).call(),
      setMaxInvestorPirsRate: await bidbackPirs.getMaxInvestorPirsRate().call(),
      setMaxBidbackRate: await bidbackPirs.getMaxBidbackRate().call(),
    }
  }

  this.rewardsSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Rewards');
    console.log('=====================================================================================');
    const rewardsSystemManager = new web3.eth.Contract(AlgoPainterRewardsSystem.abi, contracts.AlgoPainterRewardsSystem).methods;

    if (this.write) {
      const setAllowedSenderTx = rewardsSystemManager.setAllowedSender(contracts.AlgoPainterAuctionSystem)
      const setRewardsTokenAddressTx = rewardsSystemManager.setRewardsTokenAddress(contracts.AlgoPainterToken);
      const setAuctionSystemAddressTx = rewardsSystemManager.setAuctionSystemAddress(contracts.AlgoPainterAuctionSystem);
      const setRewardsRatesProviderAddressTx = rewardsSystemManager.setRewardsRatesProviderAddress(contracts.AlgoPainterBidBackPirs);
      const setRewardsTotalRatesProviderAddressTx = rewardsSystemManager.setRewardsTotalRatesProviderAddress(contracts.AlgoPainterBidBackPirs);

      await this.sendTransaction(setAllowedSenderTx);
      await this.sendTransaction(setRewardsTokenAddressTx);
      await this.sendTransaction(setAuctionSystemAddressTx);
      await this.sendTransaction(setRewardsRatesProviderAddressTx);
      await this.sendTransaction(setRewardsTotalRatesProviderAddressTx);
    }
    return {
      setRewardsTokenAddress: await rewardsSystemManager.getRewardsTokenAddress().call(),
      setAuctionSystemAddress: await rewardsSystemManager.getAuctionSystemAddress().call(),
      setRewardsRatesProviderAddress: await rewardsSystemManager.getRewardsRatesProviderAddress().call(),
      setRewardsTotalRatesProviderAddress: await rewardsSystemManager.getRewardsTotalRatesProviderAddress().call(),
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
              address: contracts.AlgoPainterAuctionSystem,
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
              address: contracts.AlgoPainterRewardsSystem,
              name: 'AlgoPainterRewardsSystem',
              symbol: 'APRS',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterRewardsSystem.abi,
              inUse: true
            },
            {
              address: contracts.AlgoPainterBidBackPirs,
              name: 'AlgoPainterBidBackPirs',
              symbol: 'APBPS',
              network: chainID,
              rpc: rpcUrl,
              startingBlock: currentBlock,
              blockExplorer: blockExplorer,
              abi: AlgoPainterBidBackPirs.abi,
              inUse: true
            },
            {
              address: contracts.AlgoPainterGweiItem,
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
              address: contracts.AlgoPainterExpressionsItem,
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
              address: contracts.AlgoPainterPersonalItem,
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
    Configurator.write = true;

    console.log(contracts);

    // console.log(await Configurator.personalItem());
    // console.log(await Configurator.auctionSystem());
    // console.log(await Configurator.bidbackPirsSystem());
    // console.log(await Configurator.rewardsSystem());
    console.log(await Configurator.reloadSettings());

  } catch (error) {
    console.error(error);
  }
})();