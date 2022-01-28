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
    AlgoPainterPersonalItem: '0x1A6762DF60395CC1dDDa935e152Fa12D7a8f5966'.toLowerCase(),
    AlgoPainterAuctionSystem: '0xeD2b4A5c6843aE7C6Bdb4F4807926a8bF7Cfa6b8'.toLowerCase(),
    AlgoPainterRewardsRates: '0x07F578672Fa45Bb0904fdC386A8c92de8A1175c5'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x4b6ce3F2757AfeaF5a26A653E62F77C73aE0D436'.toLowerCase(),
    AlgoPainterNFTCreators: '0x31A8e303c6443a8B93302A3C1813EDe34E5bdC79'.toLowerCase()
  }
}