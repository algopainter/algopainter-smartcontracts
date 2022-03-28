const { mnemonic, rpcUrl, fees, account, gasLimit, web3, contractsAddress, emergencyInterval } = require("./settings.js");

/*
  web3.utils.soliditySha3(
    "John",
    "Smith",
    33,
    "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
  );
*/

const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
const AlgoPainterPersonalItem = require('../build/contracts/AlgoPainterPersonalItem.json');
const AlgoPainterExpressionsItem = require('../build/contracts/AlgoPainterExpressionsItem.json');
const AlgoPainterNFTCreators = require('../build/contracts/AlgoPainterNFTCreators.json');
const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterRewardsRates = require('../build/contracts/AlgoPainterRewardsRates.json');
const AlgoPainterRewardsDistributor = require('../build/contracts/AlgoPainterRewardsDistributor.json');
const AlgoPainterArtistCollection = require('../build/contracts/AlgoPainterArtistCollection.json');
const AlgoPainterArtistCollectionItem = require('../build/contracts/AlgoPainterArtistCollectionItem.json');

const deploy = async (contract, args) => {
  const instance = new web3.eth.Contract(contract.abi);
  instance.setProvider(web3.currentProvider);
  const deployTx = instance.deploy({
    data: contract.bytecode,
    arguments: args
  });

  const estimatedGas = await deployTx.estimateGas({ from: account });

  const createTransaction = await web3.eth.accounts.signTransaction(
    {
      from: account,
      data: deployTx.encodeABI(),
      gas: estimatedGas,
      gasPrice: web3.utils.toHex(web3.utils.toWei('20', 'gwei'))
    },
    mnemonic
  );

  var dplyResult = await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);

  console.log(contract.contractName, { gasUsed: dplyResult.gasUsed, contractAddress: dplyResult.contractAddress });

  return dplyResult;
}

(async function () {
  try {
    
    // await deploy(AlgoPainterNFTCreators);
    // const auctionSystemDeployTransaction = await deploy(AlgoPainterAuctionSystem, [
    //   emergencyInterval,
    //   account,
    //   fees.auction,
    //   fees.bid,
    //   [contractsAddress.AlgoPainterToken, contractsAddress.BUSDToken]
    // ]);
    
    // const algoPainterRewardsDistributorTransaction = await deploy(AlgoPainterRewardsDistributor, [
    //   emergencyInterval,
    //   auctionSystemDeployTransaction.contractAddress,
    //   contractsAddress.AlgoPainterToken
    // ]);

    // const algoPainterRewardsRatesTransaction = await deploy(AlgoPainterRewardsRates, [
    //   emergencyInterval,
    //   fees.maxCreatorRate,
    //   fees.maxPIRSRate,
    //   fees.maxBidbackRate,
    //   algoPainterRewardsDistributorTransaction.contractAddress,
    //   auctionSystemDeployTransaction.contractAddress,
    //   contractsAddress.AlgoPainterGweiItem,
    //   contractsAddress.AlgoPainterExpressionsItem,
    //   fees.gweiCreator,
    //   fees.expressionCreator
    // ]);

    // const algoPainterPersonalItemTransaction = await deploy(AlgoPainterPersonalItem, [
    //   contractsAddress.AlgoPainterNFTCreators,
    //   algoPainterRewardsRatesTransaction.contractAddress,
    //   auctionSystemDeployTransaction.contractAddress,
    //   account
    // ]);

    const algoPainterArtistCollectionTransaction = await deploy(AlgoPainterArtistCollection, [
      emergencyInterval,
      //algoPainterRewardsRatesTransaction.contractAddress,
      contractsAddress.AlgoPainterRewardsRates,
      account,
      web3.utils.toWei('17000', 'ether'),
      contractsAddress.AlgoPainterToken,
      '7776000',
      '1',
      '1000',
      [contractsAddress.AlgoPainterToken, contractsAddress.BUSDToken]
    ]);

    const algoPainterArtistCollectionItemTransaction = await deploy(AlgoPainterArtistCollectionItem, [
      contractsAddress.AlgoPainterNFTCreators,
      //algoPainterRewardsRatesTransaction.contractAddress,
      contractsAddress.AlgoPainterRewardsRates,
      algoPainterArtistCollectionTransaction.contractAddress,
      contractsAddress.AlgoPainterAuctionSystem,
      account,
      fees.auction,
      '0'
    ]);
  } catch (e) {
    console.error(e)
  }
})();

