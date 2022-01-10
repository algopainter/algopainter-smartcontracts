const { mnemonic, rpcUrl, account, gasLimit, web3, contractsAddress } = require("./settings.js");

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

  console.log(contract.contractName, dplyResult);

  return dplyResult;
}

(async function(){
  try {
    //deploy(AlgoPainterToken.abi, AlgoPainterToken.bytecode, [ "AlgoPainter Token", "ALGOP" ]).then(result => console.log('AlgoPainterToken:', result));
    //await deploy(AlgoPainterNFTCreators);
    //await deploy(AlgoPainterAuctionSystem, [ '1209600' ]);
    //await deploy(AlgoPainterRewardsRates);
    //await deploy(AlgoPainterRewardsDistributor, [ '1209600' ]);
    // await deploy(AlgoPainterPersonalItem, [ 
    //   contractsAddress.AlgoPainterToken, 
    //   account, 
    //   contractsAddress.AlgoPainterNFTCreators, 
    //   contractsAddress.AlgoPainterRewardsRates 
    // ]);
  } catch(e) {
    console.error(e)
  }
})();

