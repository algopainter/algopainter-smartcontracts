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
    AlgoPainterPersonalItem: '0xf80B41eC4807189469263CcD42eA514C28e47DeE'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x63ebE1D1b61eeaDc58081dEc41aB7B29882f9786'.toLowerCase(),
    AlgoPainterRewardsRates: '0xdfd3beb61efEdd281e9c658d3c47938d8b16e2E3'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x565D34a4C3b8Deb675ced1322DaDDcf0be0287eC'.toLowerCase(),
    AlgoPainterNFTCreators: '0xE7A5a70295B64AB905D8b7699eF1D0C957149c85'.toLowerCase()
  }
}