const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NodeOperatorsRegistry Test Suite", () => {
    let lightNode, oracle, nodeOperatorsRegistry;
    let deployer, treasury, insuranceFund, manager;

    const depositContractAddr = "0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC";

    before(async() => {
        [deployer, treasury, insuranceFund, manager, rewardAddr] = await ethers.getSigners();

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

    describe("addNodeOperator", () => {
        it("reverts if the caller does not have right role", async() => {
            await expect(
                nodeOperatorsRegistry.addNodeOperator("test opr", rewardAddr.address)
            ).to.be.reverted;
        });

        it("add node operator", async() => {
            const addNodeOprRole = await nodeOperatorsRegistry.ADD_NODE_OPERATOR_ROLE();
            await nodeOperatorsRegistry.grantRole(addNodeOprRole, manager.address);

            expect(
                await nodeOperatorsRegistry.connect(manager).addNodeOperator("test opr", rewardAddr.address)
            ).to.emit(nodeOperatorsRegistry, "NodeOperatorAdded")
            .withArgs(0, "test opr", rewardAddr.address, 0);
        });
    });

    describe("set node operator", () => { 
        let setNodeOprRole;

        it("setNodeOperatorActive", async() => {
            setNodeOprRole = await nodeOperatorsRegistry.SET_NODE_OPERATOR_ROLE();
            await nodeOperatorsRegistry.grantRole(setNodeOprRole, manager.address);

            expect(
                await nodeOperatorsRegistry.connect(manager).setNodeOperatorActive(0, true)
            ).to.emit(nodeOperatorsRegistry, "NodeOperatorActiveSet").withArgs(0, true);
        });

        it("setNodeOperatorName", async() => {
            expect(
                await nodeOperatorsRegistry.connect(manager).setNodeOperatorActive(0, "change opr name")
            ).to.emit(nodeOperatorsRegistry, "NodeOperatorNameSet").withArgs(0, "change opr name");
        });

        it("setNodeOperatorRewardAddress", async() => {
            expect(
                await nodeOperatorsRegistry.connect(manager).setNodeOperatorRewardAddress(0, rewardAddr.address)
            ).to.emit(nodeOperatorsRegistry, "NodeOperatorRewardAddressSet").withArgs(0, rewardAddr.address);
        });
    });
});
