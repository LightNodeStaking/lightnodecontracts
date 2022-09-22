const { expect } = require("chai");
const { ethers } = require("hardhat");

const pad = (hex, bytesLength) => {
    const absentZeroes = bytesLength * 2 + 2 - hex.length
    if (absentZeroes > 0) hex = '0x' + '0'.repeat(absentZeroes) + hex.substr(2)
    return hex
}

describe("LightNode Test Suite", () => {
    let lightNode, slETH, oracle, depositContract, nodeOperatorsRegistry, elRewardsVault;
    let deployer, treasury, insuranceFund, manager, depositor;
    let user1, user2, user3, user4;

    before(async() => {
        [deployer, treasury, insuranceFund, manager, depositor, user1, user2, user3, user4] = await ethers.getSigners();

        const OracleFactory = await ethers.getContractFactory("Oracle");
        oracle = await OracleFactory.deploy();
        await oracle.deployed();

        const DepositContract = await ethers.getContractFactory("DepositContract");
        depositContract = await DepositContract.deploy();
        await depositContract.deployed();

        const LightNode = await ethers.getContractFactory("LightNode");
        lightNode = await LightNode.deploy(
            depositContract.address,
            oracle.address,
            treasury.address,
            insuranceFund.address
        );

        await lightNode.deployed();

        console.log("LightNode deployed at ", lightNode.address);
        
        slETH = lightNode;

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
        expect(await lightNode.getDepositContract()).to.equal(depositContract.address);
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

        const manageOprRole = await nodeOperatorsRegistry.MANAGE_OPERATOR_ROLE();
        await nodeOperatorsRegistry.grantRole(manageOprRole, manager.address);
        await nodeOperatorsRegistry.connect(manager).addNodeOperator("1", user4.address);
        await nodeOperatorsRegistry.connect(manager).setNodeOperatorStakingLimit(0, 100000000);

        const manageWithdrawal = await lightNode.MANAGE_WITHDRAWAL_KEY();
        await lightNode.grantRole(manageWithdrawal, manager.address);
        await lightNode.connect(manager).setWithdrawalCredentials(pad('0x0202', 32));
        
        const manageSigningKeys = await nodeOperatorsRegistry.MANAGE_SIGNING_KEYS();
        await nodeOperatorsRegistry.grantRole(manageSigningKeys, manager.address);

        await nodeOperatorsRegistry
            .connect(manager).addSigningKeys(0, 1, pad("0x010203", 48), pad("0x01", 96));

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
        expect(await lightNode.getBufferedEther()).to.equal(ethers.utils.parseEther("1"));
        expect(await lightNode.getTotalPooledEther()).to.equal(ethers.utils.parseEther("33"));

        expect(await slETH.balanceOf(user1.address)).to.equal(ethers.utils.parseUnits("9", 18)); // 1+8 ETH
        expect(await slETH.balanceOf(user2.address)).to.equal(ethers.utils.parseUnits("10", 18)); // 2+8 ETH
        expect(await slETH.balanceOf(user3.address)).to.equal(ethers.utils.parseUnits("8", 18));
        expect(await slETH.balanceOf(user4.address)).to.equal(ethers.utils.parseUnits("6", 18));
    });
});
