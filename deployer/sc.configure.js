const { mongourl, chainID, blockExplorer, mnemonic, rpcUrl, account, gasLimit, web3, accounts, contractsAddress } = require("./settings.js");

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

  this.nftCreators = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter NFT Creators');
    console.log('=====================================================================================');

    const nftCreators = new web3.eth.Contract(AlgoPainterNFTCreators.abi, contractsAddress.AlgoPainterNFTCreators).methods;
    if (this.write) {
      const grantRoleAuctionTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterAuctionSystem);
      const grantRoleRewardsDistributorTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterRewardsDistributor);
      const grantRoleRewardsRatesTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterRewardsRates);
      const grantRolePersonalTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);
      const setCreatorGweiTx = nftCreators.setCreator(contractsAddress.AlgoPainterGweiItem, accounts.gweiCreator);
      const setCreatorExpressionTx = nftCreators.setCreator(contractsAddress.AlgoPainterExpressionsItem, accounts.expressionsCreator);

      await this.sendTransaction('grantRoleAuctionTx', grantRoleAuctionTx);
      await this.sendTransaction('grantRolePersonalTx', grantRolePersonalTx);
      await this.sendTransaction('grantRoleRewardsDistributorTx', grantRoleRewardsDistributorTx);
      await this.sendTransaction('grantRoleRewardsRatesTx', grantRoleRewardsRatesTx);
      await this.sendTransaction('setCreatorGweiTx', setCreatorGweiTx);
      await this.sendTransaction('setCreatorExpressionTx', setCreatorExpressionTx);
    }

    return {
      grantRoleAuctionTx: contractsAddress.AlgoPainterAuctionSystem,
      grantRolePersonalTx: contractsAddress.AlgoPainterPersonalItem,
      setCreatorGweiTx: await (nftCreators.getCreatorNotPayable(contractsAddress.AlgoPainterGweiItem, 0).call()),
      setCreatorExpressionTx: await nftCreators.getCreatorNotPayable(contractsAddress.AlgoPainterExpressionsItem, 0).call()
    }
  }

  this.personalItem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter Personal Item');
    console.log('=====================================================================================');

    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contractsAddress.AlgoPainterPersonalItem).methods;
    const nftCreators = new web3.eth.Contract(AlgoPainterNFTCreators.abi, contractsAddress.AlgoPainterNFTCreators).methods;
    const rewardRates = new web3.eth.Contract(AlgoPainterRewardsRates.abi, contractsAddress.AlgoPainterRewardsRates).methods;
    
    if (this.write) {
      // const setAlgoPainterNFTCreatorsTx = personal.setAlgoPainterNFTCreators(contractsAddress.AlgoPainterNFTCreators);
      // const setAlgoPainterRewardsRatesAddressTx = personal.setAlgoPainterRewardsRatesAddress(contractsAddress.AlgoPainterRewardsRates);
      const approveAuctionSystemTx = personal.setApprovalForAll(contractsAddress.AlgoPainterAuctionSystem, true);
      const grantRolePersonalTx = nftCreators.grantRole(await nftCreators.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);
      const grantRolePersonalItemTx = rewardRates.grantRole(await rewardRates.CONFIGURATOR_ROLE().call(), contractsAddress.AlgoPainterPersonalItem);

      // await this.sendTransaction('setAlgoPainterNFTCreatorsTx', setAlgoPainterNFTCreatorsTx);
      // await this.sendTransaction('setAlgoPainterRewardsRatesAddressTx', setAlgoPainterRewardsRatesAddressTx);
      await this.sendTransaction('approveAuctionSystemTx', approveAuctionSystemTx);
      await this.sendTransaction('grantRolePersonalTx', grantRolePersonalTx);
      await this.sendTransaction('grantRolePersonalItemTx', grantRolePersonalItemTx);
    }

    return {
      algoPainterRewardsRates: await (personal.algoPainterRewardsRates().call()),
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

      await this.sendTransaction('setupTx', setupTx);
      await this.sendTransaction('gweiSetApprovalForAllTx', gweiSetApprovalForAllTx);
      await this.sendTransaction('expressionsSetApprovalForAllTx', expressionsSetApprovalForAllTx);
      await this.sendTransaction('personalSetApprovalForAllTx', personalSetApprovalForAllTx);
      await this.sendTransaction('setAlgoPainterNFTCreatorsTx', setAlgoPainterNFTCreatorsTx);
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

  this.auctionSystemAddToken = async () => {
    console.log('=====================================================================================');
    console.log('Adding Tokens to Auction System');
    console.log('=====================================================================================');
    const auction = new web3.eth.Contract(AlgoPainterAuctionSystem.abi, contractsAddress.AlgoPainterAuctionSystem).methods;

    if (this.write) {
      const addTokensBTCTx = auction.addAllowedToken("0x6ce8da28e2f864420840cf74474eff5fd80e65b8");
      const addTokensBUSDTx = auction.addAllowedToken('0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee');
      const addTokensDAITx = auction.addAllowedToken("0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867");

      await this.sendTransaction('addTokensBTCTx', addTokensBTCTx);
      await this.sendTransaction('addTokensBUSDTx', addTokensBUSDTx);
      await this.sendTransaction('addTokensDAITx', addTokensDAITx);
    }

    return {
      addAllowedToken: await (auction.getAllowedTokens().call()),
    }
  }

  this.rewardRatesSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Rewards Rates');
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
      const setAuctionDistributoAddressTx = rewardRates.setAuctionDistributorAddress(contractsAddress.AlgoPainterRewardsDistributor);

      await this.sendTransaction('grantRoleAuctionTx', grantRoleAuctionTx);
      await this.sendTransaction('grantRolePersonalItemTx', grantRolePersonalItemTx);
      await this.sendTransaction('setAuctionSystemAddressTx', setAuctionSystemAddressTx);
      await this.sendTransaction('setMaxCreatorRoyaltiesRateTx', setMaxCreatorRoyaltiesRateTx);
      await this.sendTransaction('setCreatorRoyaltiesRateTx', setCreatorRoyaltiesRateTx);
      await this.sendTransaction('setCreatorRoyaltiesRateTx2', setCreatorRoyaltiesRateTx2);
      await this.sendTransaction('setMaxPIRSRateTx', setMaxPIRSRateTx);
      await this.sendTransaction('setMaxBidbackRateTx', setMaxBidbackRateTx);
      await this.sendTransaction('setAuctionDistributoAddressTx', setAuctionDistributoAddressTx);
    }
    return {
      grantRoleAuctionTx: contractsAddress.AlgoPainterAuctionSystem,
      setAuctionDistributoAddressTx: await rewardRates.getAuctionDistributorAddress().call(),
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

      await this.sendTransaction('setAllowedSenderTx', setAllowedSenderTx);
      await this.sendTransaction('setStakeTokenTx', setStakeTokenTx);
      await this.sendTransaction('setAuctionSystemAddressTx', setAuctionSystemAddressTx);
      await this.sendTransaction('setRewardsRatesProviderAddressTx', setRewardsRatesProviderAddressTx);
    }
    return {
      setStakeToken: await rewardsDistributorSystemManager.stakeToken().call(),
      setAuctionSystemAddress: await rewardsDistributorSystemManager.auctionSystem().call(),
      setRewardsRatesProviderAddress: await rewardsDistributorSystemManager.rewardsRatesProvider().call()
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
    console.log(await Configurator.personalItem());
    console.log(await Configurator.auctionSystem());
    console.log(await Configurator.auctionSystemAddToken());
    console.log(await Configurator.rewardRatesSystem());
    console.log(await Configurator.rewardsDistributorSystem());
    console.log(await Configurator.reloadSettings());
    console.log(contractsAddress);

  } catch (error) {
    console.error(error);
  }
})();