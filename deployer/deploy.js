const { mnemonic, rpcUrl, account, gasLimit, web3 } = require("./settings.js");

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

const AlgoPainterAuctionSystem = require('../build/contracts/AlgoPainterAuctionSystem.json');
const AlgoPainterBidBackPirs = require('../build/contracts/AlgoPainterBidBackPirs.json');
const AlgoPainterRewardsSystem = require('../build/contracts/AlgoPainterRewardsSystem.json');

const deploy = async (abi, bytecode, args) => {
  const contract = new web3.eth.Contract(abi);
  const deployTx = contract.deploy({
    data: bytecode,
    arguments: args
  });

  const estimatedGas = deployTx.estimateGas({ from: account });

  const createTransaction = await web3.eth.accounts.signTransaction(
    {
      from: account,
      data: deployTx.encodeABI(),
      gas: web3.utils.toHex(gasLimit),
      gasPrice: web3.utils.toHex(estimatedGas)
    },
    mnemonic
  );

  return await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);
}

//deploy(AlgoPainterToken.abi, AlgoPainterToken.bytecode, [ "AlgoPainter Token", "ALGOP" ]).then(result => console.log('AlgoPainterToken:', result));
//deploy(AlgoPainterPersonalItem.abi, AlgoPainterPersonalItem.bytecode).then(result => console.log('AlgoPainterPersonalItem:', result));
//deploy(AlgoPainterAuctionSystem.abi, AlgoPainterAuctionSystem.bytecode).then(result => console.log('AlgoPainterAuctionSystem:', result));
//deploy(AlgoPainterBidBackPirs.abi, AlgoPainterBidBackPirs.bytecode).then(result => console.log('AlgoPainterBidBackPirs:', result));
//deploy(AlgoPainterRewardsSystem.abi, AlgoPainterRewardsSystem.bytecode).then(result => console.log('AlgoPainterRewardsSystem:', result));
