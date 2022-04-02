
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");
const BigNumber = require('bignumber.js');

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  let SlEthOwner, stakingOwner, devFee ;
  [SlEthOwner, stakingOwner, devFee] = await ethers.getSigners();
//console.log(defoOwner.address)

  // deploying defo contract
  const SlEth = await hre.ethers.getContractFactory("SLETH");
  const slEth = await SlEth.deploy(SlEthOwner.address);
  await slEth.deployed();
  console.log("slEth token deployed at:", slEth.address);
  console.log("slEth Owner is: " + SlEthOwner.address);

  const StakingContract = await hre.ethers.getContractFactory("Staking");
  const stakingContract = await StakingContract.deploy
                  ( stakingOwner.address,
                    devFee.address,
                    slEth.address );
  await stakingContract.deployed();
  console.log("Staking contract deployed at:", stakingContract.address);
  console.log("Staking Owner Owner is: " + stakingOwner.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
