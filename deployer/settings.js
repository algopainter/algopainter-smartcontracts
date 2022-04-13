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
    AlgoPainterPersonalItem: '0xBbb5843f5f5eB9DBc14C10e8b8278eE20e68BB35'.toLowerCase(),
    AlgoPainterAuctionSystem: '0x53B288e199649E2Fdc371B1F331b8b2A1dFFCC1a'.toLowerCase(),
    AlgoPainterRewardsRates: '0xb784d074F52018AD35AEE897f75C4a37c52E4b1c'.toLowerCase(),
    AlgoPainterRewardsDistributor: '0x7Af2b51175eCAAF29d97dFc459C7c35D9D9891dB'.toLowerCase(),
    AlgoPainterArtistCollection: '0x00d24cE10aa99a8991eDfcd0a0D7106e40A306c3'.toLowerCase(),
    AlgoPainterArtistCollectionItem: '0x0424Ae45DAd79461c4D0941c8CfbbF42eE6f8cB5'.toLowerCase(),
    AlgoPainterStorage: '0x8Ce52E1592B1819B7A9cD6B661574E5fDC68F514'.toLowerCase(),
    AlgoPainterSecurity: ''.toLowerCase(),
    AlgoPainterAuctionHook: ''.toLowerCase(),
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