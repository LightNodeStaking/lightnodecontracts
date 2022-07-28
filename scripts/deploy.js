
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");
const BigNumber = require('bignumber.js');

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  let oracle;
  let owner;
  [owner] = await ethers.getSigners();

  const Oracle = await hre.ethers.getContractFactory("Oracle");
  oracle = await Oracle.deploy();
  await oracle.deployed();

  console.log("Oracle deployed at:", oracle.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
