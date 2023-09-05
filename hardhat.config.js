require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('dotenv').config({path:__dirname+'/.env'})
require('@openzeppelin/hardhat-upgrades');

const { POLYGON_API_URL, BASE_GOERLI_API_URL, SEPOLIA_API_URL, GOERLI_API_URL, PRIVATE_KEY, REPORT_GAS } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    goerli: {
      url: GOERLI_API_URL,
      accounts: [
        PRIVATE_KEY
      ]
    },
    sepolia: {
      timeout: 1000000000,
      url: SEPOLIA_API_URL,
      accounts: [
        PRIVATE_KEY
      ]
    },
    polygon: {
      timeout: 100000000,
      url: POLYGON_API_URL,
      accounts: [
        PRIVATE_KEY
      ]
    },
    base_goerli: {
      url: BASE_GOERLI_API_URL,
      accounts: [
        PRIVATE_KEY
      ]
    }
  },
  gasReporter: {
    enabled: !!(REPORT_GAS)
  }
};
