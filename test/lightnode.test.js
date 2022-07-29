const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LightNode Test Suite", () => {
    let lightNode, oracle;
    let deployer;

    const depositContractAddr = "0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC";

    before(async() => {
        [deployer, treasury, insuranceFund] = await ethers.getSigners();

        const OracleFactory = await ethers.getContractFactory("Oracle");
        oracle = await OracleFactory.deploy();
        await oracle.deployed();

        const LightNode = await ethers.getContractFactory("LightNode");
        lightNode = await LightNode.deploy(
            depositContractAddr,
            oracle.address,
            treasury.address,
            insuranceFund.address
        );

        await lightNode.deployed();

        console.log("LightNode deployed at ", lightNode.address);
    });

    it("getOracle()", async() => {
        expect(await lightNode.getOracle()).to.equal(oracle.address);
    });
});
