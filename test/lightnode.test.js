const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LightNode Test Suite", () => {
    let lightNode, oracle, nodeOperatorsRegistry;
    let deployer;

    const depositContractAddr = "0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC";

    before(async() => {
        [deployer, treasury, insuranceFund, manager] = await ethers.getSigners();

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

        const NodeOperatorsRegistry = await ethers.getContractFactory("NodeOperatorsRegistry");
        nodeOperatorsRegistry = await NodeOperatorsRegistry.deploy(lightNode.address);
        await nodeOperatorsRegistry.deployed();
    });

    describe("set NodeOperatorsRegistry", () => {
        it("reverts if the caller does not have right role", async() => {
            await expect(
                lightNode.setNodeOperatorsRegistry(nodeOperatorsRegistry.address)
            ).to.be.reverted;
        });

        it("set NodeOperatorsRegistry", async() => {
            const manageRole = await lightNode.MANAGE_PROTOCOL_CONTRACTS_ROLE();
            await lightNode.grantRole(manageRole, manager.address);
            expect(
                await lightNode.connect(manager).setNodeOperatorsRegistry(nodeOperatorsRegistry.address)
            ).to.emit(lightNode, "NodeOperatorsSet").withArgs(nodeOperatorsRegistry.address);
        });
    });

    it("getOracle()", async() => {
        expect(await lightNode.getOracle()).to.equal(oracle.address);
    });
});
