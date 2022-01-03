require('dotenv').config('../.env');

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
  contractsAddress : {
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterPersonalItem: '0x1458b39262543cd76252174C8F4aD84601Dd0604'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x6795D070847dB7fcd0a63FCf9532DB1f78cE8F7d'.toLowerCase(),
    AlgoPainterRewardsRates: '0x53Aac215874f18fd819a978a7b0C4268DC40891D'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0xE8b0D7867Cf5319DF6c1251CACb346Aa58267475'.toLowerCase(),
    AlgoPainterNFTCreators: '0x9f529CC68932bd816D49d5BA4d18F8E55dFD1f75'.toLowerCase()
  }
}