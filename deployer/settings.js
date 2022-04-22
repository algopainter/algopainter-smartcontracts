require('dotenv').config('../.env');

const Web3Class = require('web3');
const mnemonic = process.env.PRIVATE_KEY;
const rpcUrl = process.env.RPC_URL;
const chainID = process.env.CHAIN_ID;
const account = process.env.ACCOUNT;
const mongourl = process.env.MONGO_URL;
const env = process.env.ENV;
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

const contractsAddress = {
  production: {
    BUSDToken: '0xe9e7cea3dedca5984780bafc599bd69add087d56',
    AlgoPainterToken: '0xbee554dbbc677eb9fb711f5e939a2f2302598c75',
    AlgoPainterGweiItem: '0x4b7ef899cbb24689a47a66d3864f57ec13e01b35',
    AlgoPainterExpressionsItem: '0xb413ccfd8e7d75d8642c81ab012235fedd946eeb',
    AlgoPainterPersonalItem: '0x03f9598461490505b1b1f8007eadc9409ee3650e'.toLowerCase(),
    //AlgoPainterAuctionSystem: '0xc5d1240fddcce3ed87298ad58bbfb2681048e7fa'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x0a2D62c70cAa0933666624d2b9740826c8f232a0'.toLowerCase(),
    AlgoPainterRewardsRates: '0x1637023587fd78de4c2de3ef9c6441624d438761'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x90a1e949d675509172a14092309e5262d0d54ed5'.toLowerCase(),
    AlgoPainterNFTCreators: '0x5a14450488ba98c612b08f5e29802686854b5078'.toLowerCase(),
    AlgoPainterArtistCollection: '0xe28C8E83dc7E90439dD6D911eEaF66626e3CFCe2'.toLowerCase(),
    AlgoPainterArtistCollectionItem: '0x2eFaB249cd75e21833F509c1D186E04fd00a9A6b'.toLowerCase(),
    AlgoPainterStorage: '0xE09B84f3A4724033f5f6C5e4e407Cf6aAc555098'.toLowerCase(),
  },
  testnet: {
    BUSDToken: '0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee',
    AlgoPainterToken: '0x01a9188076f1231df2215f67b6a63231fe5e293e',
    AlgoPainterGweiItem: '0x8cfd89020019ba3da8b13cc2f3e0e5baaf82f578',
    AlgoPainterExpressionsItem: '0xbe9cac059835236da5e91cd72688c43886b63419',
    AlgoPainterNFTCreators: '0x31a8e303c6443a8b93302a3c1813ede34e5bdc79'.toLowerCase(),
    AlgoPainterPersonalItem: '0x9dd43f26ea4f6736b9b4d523a89d5ca4ec970297'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x58af4eda4d18bd56c4d929410549b293fa8831b3'.toLowerCase(),
    AlgoPainterRewardsRates: '0x9484305787eb1dd21e1cb8cc5f5074afc5fc0499'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x64c3892de29965a2829a596f0ef5a3109554ddef'.toLowerCase(),
    AlgoPainterArtistCollection: '0x3469c794e8f4b188d8ce2f5b2d4da1ded4df0e97'.toLowerCase(),
    AlgoPainterArtistCollectionItem: '0x799d63b20fa68970ce7cfc340ed92b2214878219'.toLowerCase(),
    AlgoPainterStorage: '0x8Ce52E1592B1819B7A9cD6B661574E5fDC68F514'.toLowerCase(),
    AlgoPainterSecurity: '0x7cedcea099774862b05633a9f689457339be3e1f'.toLowerCase(),
    AlgoPainterAuctionHook: '0xaff6b05c652cafae61a6e8eb5d5ff4a936ac1e8c'.toLowerCase(),
  }
};

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
  env,
  contractsAddress : contractsAddress[env]
}