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
const emergencyInterval = '1209600';

const accounts = {
  dev: account,
  gweiCreator: process.env.GWEI_ACCOUNT,
  expressionsCreator: process.env.EXPRESSIONS_ACCOUNT,
}

const fees = {
  dev: 250,
  auction: 250,
  bid: 250,
  maxCreatorRate: 3000,
  maxPIRSRate: 3000,
  maxBidbackRate: 3000,
  personalItemMintCost: web3.utils.toWei('0.1', 'ether'),
  gweiCreator: 0,
  expressionCreator: 500,
}

const auctionTokens = [
  process.env.GWEI_ACCOUNT, 
  process.env.GWEI_ACCOUNT, 
  process.env.GWEI_ACCOUNT,
]

module.exports = {
  mongourl,
  mnemonic,
  blockExplorer,
  rpcUrl,
  chainID,
  account,
  gasLimit,
  web3,
  accounts,
  fees,
  auctionTokens,
  emergencyInterval,
  contractsAddress : {
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterPersonalItem: '0xDf5deD9d029EFC05C94b3d459fa944Cc8d2A9547'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x2C6f0dACF0929a8ca6F625801eB7f7c32e4e4fba'.toLowerCase(),
    AlgoPainterRewardsRates: '0x346b65C0fBD1E33E717D8Ae4e8328f4979F5330C'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x18Dae96f4C11b0c08936F11B3875B245d1AC6A8a'.toLowerCase(),
    AlgoPainterNFTCreators: '0x33E5D1319779d165744C03a0519D695Bf0beEc83'.toLowerCase()
  }
}