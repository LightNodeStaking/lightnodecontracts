const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NodeOperatorsRegistry Test Suite", () => {
    let lightNode, oracle, nodeOperatorsRegistry;

    const depositContractAddr = "0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC";

    before(async() => {
        const [deployer, treasury, insuranceFund, manager] = await ethers.getSigners();

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

        const OperatorFactory = await ethers.getContractFactory("NodeOperatorsRegistry");
        nodeOperatorsRegistry = await OperatorFactory.deploy(lightNode.address);
        await nodeOperatorsRegistry.deployed();

        console.log("NodeOperatorsRegistry deployed at ", nodeOperatorsRegistry.address);
    });
});
