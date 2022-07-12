const { ethers } = require("hardhat");

const networkConfig = {
  4: {
    name: "rinkeby",
  },
  31337: {
    name: "hardhat",
  },
};

const developementChains = ["hardhat", "localhost"];

module.exports = {
  networkConfig,
  developementChains,
};
