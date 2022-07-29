require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");

require("dotenv").config();

const {
  ETHERSCAN_API_KEY, 
  DEPLOYER_PRIVATE_KEY,
  TREASURY_PRIVATE_KEY,
  INSURANCE_FUND_PRIVATE_KEY,
  MAINNET_URL,
  GOERLI_URL,
  REPORT_GAS
} = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    },
  },
  networks: {
    hardhat: {
      forking: { // mainnet fork
        enabled: true,
        url: MAINNET_URL || "",
      }
    },
    goerli: {
      url: GOERLI_URL || "",
      accounts:
        [DEPLOYER_PRIVATE_KEY, TREASURY_PRIVATE_KEY, INSURANCE_FUND_PRIVATE_KEY]
    },
  },
  gasReporter: {
    enabled: REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
