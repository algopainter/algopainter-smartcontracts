require('dotenv').config();

const Web3Class = require('web3');
const mnemonic = process.env.PRIVATE_KEY;
const rpcUrl = process.env.RPC_URL;
const chainID = process.env.CHAIN_ID;
const account = process.env.ACCOUNT;
const mongourl = process.env.MONGO_URL;
const blockExplorer = process.env.BLOCKEXPLORER;
const gasLimit = 10000000;
const web3 = new Web3Class(rpcUrl);

module.exports = {
  mongourl,
  mnemonic,
  blockExplorer,
  rpcUrl,
  chainID,
  account,
  gasLimit,
  web3,
  contracts : {
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterPersonalItem: '0xf80c1D8b52B24855F4827e2B6745eBD557eDffE1'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x5e09451531a08Da2a19597FC8B84637E977B2E6f'.toLowerCase(),
    AlgoPainterBidBackPirs: '0xc518d36625c5BC34D6e03D430A8b3A33e40d52c3'.toLowerCase(),
    AlgoPainterRewardsSystem: '0x71b286635546E142d29F81c3259983C201a48Cef'.toLowerCase()
  }
}