const { mnemonic, rpcUrl, account, gasLimit, web3 } = require("./settings.js");

const AlgoPainterToken = require('../build/contracts/AlgoPainterToken.json');
const AlgoPainterGweiItem = require('../build/contracts/AlgoPainterGweiItem.json');
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

  const createTransaction = await web3.eth.accounts.signTransaction(
    {
      from: account,
      data: deployTx.encodeABI(),
      gas: web3.utils.toHex(gasLimit),
      gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei'))
    },
    mnemonic
  );

  return await web3.eth.sendSignedTransaction(createTransaction.rawTransaction);
}

//deploy(AlgoPainterToken.abi, AlgoPainterToken.bytecode, [ "AlgoPainter Token", "ALGOP" ]).then(result => console.log('AlgoPainterToken:', result));
//deploy(AlgoPainterAuctionSystem.abi, AlgoPainterAuctionSystem.bytecode).then(result => console.log('AlgoPainterAuctionSystem:', result));
//deploy(AlgoPainterBidBackPirs.abi, AlgoPainterBidBackPirs.bytecode).then(result => console.log('AlgoPainterBidBackPirs:', result));
//deploy(AlgoPainterRewardsSystem.abi, AlgoPainterRewardsSystem.bytecode).then(result => console.log('AlgoPainterRewardsSystem:', result));
