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
    AlgoPainterToken: '0xbee554dbbc677eb9fb711f5e939a2f2302598c75',
    AlgoPainterGweiItem: '0x4b7ef899cbb24689a47a66d3864f57ec13e01b35',
    AlgoPainterExpressionsItem: '0xb413ccfd8e7d75d8642c81ab012235fedd946eeb',
    AlgoPainterPersonalItem: '0xfc58afce38b4ad43f346857374e408be2016be9e'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x20be675b1f372d6e8bc0e470447d93fe130092fb'.toLowerCase(),
    AlgoPainterRewardsRates: '0xe3a717bd29d391e630080529f1a9c48a3b928ba9'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x1be650986635edca1c1287dc2b3234eb44fc60a8'.toLowerCase(),
    AlgoPainterNFTCreators: '0x5a14450488ba98c612b08f5e29802686854b5078'.toLowerCase()
  }
}