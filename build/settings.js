require('dotenv').config();

const Web3Class = require('web3');
const mnemonic = process.env.PRIVATE_KEY;
const rpcUrl = process.env.RPC_URL;
const account = process.env.ACCOUNT;
const gasLimit = 10000000;
const web3 = new Web3Class(rpcUrl);

module.exports = {
  mnemonic,
  rpcUrl,
  account,
  gasLimit,
  web3,
  contracts : {
    AlgoPainterFran: '0xf3956C698C0719aCDb2F3beE95c87b879c9ec07E',
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterAuctionSystem: '0xd1059352D83B2bC857eE6497005432440Ae2ccbE',
    AlgoPainterBidBackPirs: '0x9bF9f033A463a3442bcb1A43E42BfDfcCf8EB036',
    AlgoPainterRewardsSystem: '0x1276b224046aC25487BdB3d5Fc00123008E0256d'
  }
}