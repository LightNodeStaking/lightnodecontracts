const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LightNode Test Suite", () => {
    let lightNode, oracle, nodeOperatorsRegistry, elRewardsVault;
    let deployer, treasury, insuranceFund, manager, depositor;
    let user1, user2, user3, user4;
    
    const depositContractAddr = "0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC";

    before(async() => {
        [deployer, treasury, insuranceFund, manager, depositor, user1, user2, user3, user4] = await ethers.getSigners();

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

        const ExecutionLayerRewardsVault = await ethers.getContractFactory("ExecutionLayerRewardsVault");
        elRewardsVault = await ExecutionLayerRewardsVault.deploy(
            lightNode.address,
            treasury.address
        );
        await elRewardsVault.deployed();
    });

    it("set NodeOperatorsRegistry", async() => {
        const manageRole = await lightNode.MANAGE_PROTOCOL_CONTRACTS_ROLE();
        await lightNode.grantRole(manageRole, manager.address);
        expect(
            await lightNode.connect(manager).setNodeOperatorsRegistry(nodeOperatorsRegistry.address)
        ).to.emit(lightNode, "NodeOperatorsSet").withArgs(nodeOperatorsRegistry.address);
    });

    it("getOracle()", async() => {
        expect(await lightNode.getOracle()).to.equal(oracle.address);
    });
    
    it("getTreasury()", async() => {
        expect(await lightNode.getTreasury()).to.equal(treasury.address);
    });
    
    it("getInsuranceFund()", async() => {
        expect(await lightNode.getInsuranceFund()).to.equal(insuranceFund.address);
    });

    it("getDepositContract()", async() => {
        expect(await lightNode.getDepositContract()).to.equal(depositContractAddr);
    });

    it("set ExecutionLayerRewardsVault", async () => {
        const elRewardsVaultRole = await lightNode.SET_EL_REWARDS_VAULT_ROLE();
        await lightNode.grantRole(elRewardsVaultRole, manager.address);
        expect(
            await lightNode.connect(manager).setELRewardsVault(elRewardsVault.address)
        ).to.emit(lightNode, "ELRewardsVaultSet").withArgs(elRewardsVault.address);
    });

    it("deposit", async() => {
        const depositRole = await lightNode.DEPOSIT_ROLE();
        await lightNode.grantRole(depositRole, depositor.address);

        const manageSigningKeys = await nodeOperatorsRegistry.MANAGE_SIGNING_KEYS();
        await nodeOperatorsRegistry.grantRole(manageSigningKeys, manager.address);

        await nodeOperatorsRegistry
            .connect(manager).addSigningKeys(0, 1, "0x010203", "0x01");

        // send +1 ETH
        await user1.sendTransaction({
            to: lightNode.address,
            value: ethers.utils.parseEther("1"),
        });

        await lightNode.connect(depositor)['depositBufferedEther()']();

        let stat = await lightNode.getBeaconStat();
        expect(stat.depositedValidators).to.equal(0);
        expect(stat.beaconBalance).to.equal(0);
        expect(await lightNode.getBufferedEther()).to.equal(ethers.utils.parseEther("1"));
        expect(await lightNode.getTotalPooledEther()).to.equal(ethers.utils.parseEther("1"));
        // user2 deposit +2 ETH
        await lightNode
            .connect(user2)
            .submit(ethers.constants.AddressZero, { value: ethers.utils.parseEther("2")});
        await lightNode.connect(depositor)['depositBufferedEther()']();

        stat = await lightNode.getBeaconStat();
        expect(stat.depositedValidators).to.equal(0);
        expect(stat.beaconBalance).to.equal(0);
        expect(await lightNode.getBufferedEther()).to.equal(ethers.utils.parseEther("3"));
        expect(await lightNode.getTotalPooledEther()).to.equal(ethers.utils.parseEther("3"));

        // send total +30 ETH
        await user1.sendTransaction({
            to: lightNode.address,
            value: ethers.utils.parseEther("8"),
        });
        await user2.sendTransaction({
            to: lightNode.address,
            value: ethers.utils.parseEther("8"),
        });
        await user3.sendTransaction({
            to: lightNode.address,
            value: ethers.utils.parseEther("8"),
        });
        await user4.sendTransaction({
            to: lightNode.address,
            value: ethers.utils.parseEther("6"),
        });
        await lightNode.connect(depositor)['depositBufferedEther()']();

        stat = await lightNode.getBeaconStat();
        expect(stat.depositedValidators).to.equal(1);
        expect(stat.beaconBalance).to.equal(0);
        expect(await lightNode.getBufferedEther()).to.equal(ethers.utils.parseEther("33"));
        expect(await lightNode.getTotalPooledEther()).to.equal(ethers.utils.parseEther("33"));
    });
});
