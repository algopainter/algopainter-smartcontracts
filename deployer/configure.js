const { mnemonic, rpcUrl, account, gasLimit, web3, contracts } = require("./settings.js");

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterBidBackPirs = require('../build/contracts/AlgoPainterBidBackPirs.json');
const AlgoPainterRewardsSystem = require('../build/contracts/AlgoPainterRewardsSystem.json');
const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');

const Configurator = function () {
  this.write = true;

  this.sendTransaction = async (tx, gasEstimate) => {
    const createTransaction = await web3.eth.accounts.signTransaction(
      {
        to: tx._parent._address,
        data: tx.encodeABI(),
        gas: web3.utils.toHex(gasEstimate),
        gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
        value: 0
      },
      mnemonic
    );

    return await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);
  }

  this.auctionSystem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Auction System');
    console.log('=====================================================================================');

    const auction = new web3.eth.Contract(AlgoPainterAuctionSystem.abi, contracts.AlgoPainterAuctionSystem).methods;
    const gwei = new web3.eth.Contract(AlgoPainterGweiItem.abi, contracts.AlgoPainterGweiItem).methods;
    const expressions = new web3.eth.Contract(AlgoPainterExpressionsItem.abi, contracts.AlgoPainterExpressionsItem).methods;

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

      await this.sendTransaction(setupTx, 1000000);
      await this.sendTransaction(gweiSetApprovalForAllTx, 1000000);
      await this.sendTransaction(expressionsSetApprovalForAllTx, 1000000);
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
      const setMaxCreatorPirsRateTx = bidbackPirs.setMaxCreatorPirsRate(contracts.AlgoPainterGweiItem, 500);
      const setMaxCreatorPirsRateTx2 = bidbackPirs.setMaxCreatorPirsRate(contracts.AlgoPainterExpressionsItem, 500);
      const setCreatorPirsRateTx = bidbackPirs.setCreatorPirsRate(contracts.AlgoPainterGweiItem, 500);
      const setCreatorPirsRateTx2 = bidbackPirs.setCreatorPirsRate(contracts.AlgoPainterExpressionsItem, 500);
      const setMaxBidbackRateTx = bidbackPirs.setMaxBidbackRate(3000);

      await this.sendTransaction(setAuctionSystemAddressTx, 1000000);
      await this.sendTransaction(setMaxCreatorPirsRateTx, 1000000);
      await this.sendTransaction(setMaxCreatorPirsRateTx2, 1000000);
      await this.sendTransaction(setCreatorPirsRateTx, 1000000);
      await this.sendTransaction(setCreatorPirsRateTx2, 1000000);
      await this.sendTransaction(setMaxInvestorPirsRateTx, 1000000);
      await this.sendTransaction(setMaxBidbackRateTx, 1000000);
    }
    return {
      setMaxCreatorPirsRateGwei: await bidbackPirs.getMaxCreatorPirsRate(contracts.AlgoPainterGweiItem).call(),
      setMaxCreatorPirsRateExpressions: await bidbackPirs.getMaxCreatorPirsRate(contracts.AlgoPainterExpressionsItem).call(),
      setCreatorPirsRateGwei: await bidbackPirs.getCreatorPIRSByTokenAddress(contracts.AlgoPainterGweiItem).call(),
      setCreatorPirsRateExpressions: await bidbackPirs.getCreatorPIRSByTokenAddress(contracts.AlgoPainterExpressionsItem).call(),
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

      await this.sendTransaction(setAllowedSenderTx, 1000000);
      await this.sendTransaction(setRewardsTokenAddressTx, 1000000);
      await this.sendTransaction(setAuctionSystemAddressTx, 1000000);
      await this.sendTransaction(setRewardsRatesProviderAddressTx, 1000000);
      await this.sendTransaction(setRewardsTotalRatesProviderAddressTx, 1000000);
    }
    return {
      setRewardsTokenAddress: await rewardsSystemManager.getRewardsTokenAddress().call(),
      setAuctionSystemAddress: await rewardsSystemManager.getAuctionSystemAddress().call(),
      setRewardsRatesProviderAddress: await rewardsSystemManager.getRewardsRatesProviderAddress().call(),
      setRewardsTotalRatesProviderAddress: await rewardsSystemManager.getRewardsTotalRatesProviderAddress().call(),
    }
  }

  return this;
}();

(async () => {
  try {
    Configurator.write = true;
    
    console.log(await Configurator.auctionSystem());
    console.log(await Configurator.bidbackPirsSystem());
    console.log(await Configurator.rewardsSystem());

  } catch (error) {
    console.error(error);
  }
})();