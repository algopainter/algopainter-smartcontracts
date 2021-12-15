const { mnemonic, rpcUrl, account, gasLimit, web3, contracts } = require("./settings.js");

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterBidBackPirs = require('../build/contracts/AlgoPainterBidBackPirs.json');
const AlgoPainterRewardsSystem = require('../build/contracts/AlgoPainterRewardsSystem.json');
const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');
const AlgoPainterPersonalItem = require('../build/contracts/AlgoPainterPersonalItem.json');

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

  this.personalItem = async () => {
    console.log('=====================================================================================');
    console.log('Configuring Algo Painter Personal Item');
    console.log('=====================================================================================');

    const personal = new web3.eth.Contract(AlgoPainterPersonalItem.abi, contracts.AlgoPainterPersonalItem).methods;

    if (this.write) {
      const approveAuctionSystemTx = personal.setApprovalForAll(contracts.AlgoPainterAuctionSystem);
      const setBidBackPirsContractTx = personal.setAlgoPainterBidBackPirsAddress(contracts.AlgoPainterBidBackPirs);

      await this.sendTransaction(approveAuctionSystemTx, approveAuctionSystemTx.estimateGas({ from: account }));
      await this.sendTransaction(setBidBackPirsContractTx, setBidBackPirsContractTx.estimateGas({ from: account }));
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

      await this.sendTransaction(setupTx, setupTx.estimateGas({ from: account }));
      await this.sendTransaction(gweiSetApprovalForAllTx, setupTx.estimateGas({ from: account }));
      await this.sendTransaction(expressionsSetApprovalForAllTx, setupTx.estimateGas({ from: account }));
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

      await this.sendTransaction(setAuctionSystemAddressTx, setAuctionSystemAddressTx.estimateGas({ from: account }));
      await this.sendTransaction(setMaxCreatorRoyaltiesRateTx, setMaxCreatorRoyaltiesRateTx.estimateGas({ from: account }));
      await this.sendTransaction(setCreatorRoyaltiesRateTx, setCreatorRoyaltiesRateTx.estimateGas({ from: account }));
      await this.sendTransaction(setCreatorRoyaltiesRateTx2, setCreatorRoyaltiesRateTx2.estimateGas({ from: account }));
      await this.sendTransaction(setMaxInvestorPirsRateTx, setMaxInvestorPirsRateTx.estimateGas({ from: account }));
      await this.sendTransaction(setMaxBidbackRateTx, setMaxBidbackRateTx.estimateGas({ from: account }));
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
    
    console.log(await Configurator.personalItem());
    console.log(await Configurator.auctionSystem());
    console.log(await Configurator.bidbackPirsSystem());
    console.log(await Configurator.rewardsSystem());

  } catch (error) {
    console.error(error);
  }
})();