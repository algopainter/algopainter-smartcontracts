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
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterAuctionSystem: '0x5c35a85636d691eacd66d3d2c8a0f57f3ea13530',
    AlgoPainterBidBackPirs: '0x355528b5a623f9bd7e7c19d2fd883de78158e765',
    AlgoPainterRewardsSystem: '0x7279c3c7b02c7ea2d458114f60df8e5d1a57de29'
  }
}