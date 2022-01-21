const AlgoPainterAuctionSystem = artifacts.require("AlgoPainterAuctionSystem");

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(AlgoPainterAuctionSystem, accounts[0], accounts[0]);
};
