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

const accounts = {
  dev: account,
  gweiCreator: process.env.GWEI_ACCOUNT,
  expressionsCreator: process.env.EXPRESSIONS_ACCOUNT,
}

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
  contractsAddress : {
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterPersonalItem: '0x75Ae22228130Ea23dFF1819a7c792Af0a8996956'.toLowerCase(),
    AlgoPainterAuctionSystem: '0xEB15E3bBD845f9b11173d034E47158554876283a'.toLowerCase(),
    AlgoPainterRewardsRates: '0x70C3Ed753B9cE007849953a32b2f0c9c8CBceF08'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0xE4bC1BC1C0d0E59FA5178AF14cCf6aCcEA35ABE0'.toLowerCase(),
    AlgoPainterNFTCreators: '0xD3eEdeb21ED73e365E90e0FB9Bc6e591FCeA412D'.toLowerCase()
  }
}