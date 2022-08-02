
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");
const BigNumber = require('bignumber.js');

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  let owner;
  [owner, treasury, insuranceFund] = await ethers.getSigners();

  /* const Oracle = await hre.ethers.getContractFactory("Oracle");
  const oracle = await Oracle.deploy();
  await oracle.deployed();

  console.log("Oracle deployed at:", oracle.address); */

  /* const depositContractAddr = "0x07b39f4fde4a38bace212b546dac87c58dfe3fdc";
  const oracleAddr = "0x9a5FdF8146467d70634fc48bEF67dD14B5A08757";

  console.log(treasury.address, insuranceFund.address);
  const LightNode = await hre.ethers.getContractFactory("LightNode");
  const lightNode = await LightNode.deploy(
    depositContractAddr,
    oracleAddr,
    treasury.address,
    insuranceFund.address
  );
  await lightNode.deployed();

  console.log("LightNode deployed at:", lightNode.address); */
  
  const lightNodeAddr = "0x6F26B417f2622eD65A964b37Db815998849C2518";
  /* const NodeOperatorsRegistry = await hre.ethers.getContractFactory("NodeOperatorsRegistry");
  const nodeOperatorsRegistry = await NodeOperatorsRegistry.deploy(
    lightNodeAddr
  );
  await nodeOperatorsRegistry.deployed();

  console.log("NodeOperatorsRegistry deployed at:", nodeOperatorsRegistry.address); */

  const ExecutionLayerRewardsVault = await hre.ethers.getContractFactory("ExecutionLayerRewardsVault");
  const executionLayerRewardsVault = await ExecutionLayerRewardsVault.deploy(
    lightNodeAddr,
    treasury.address
  );
  await executionLayerRewardsVault.deployed();

  console.log("ExecutionLayerRewardsVault deployed at:", executionLayerRewardsVault.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
