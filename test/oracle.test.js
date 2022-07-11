const { expect } = require("chai");
const { ethers } = require("hardhat");
const Table = require("cli-table3");

const GENESIS_TIME = 1606824000
const EPOCH_LENGTH = 32 * 12

describe("Oracle Test Suite", () => {
    let oracle;
    let deployer, voting, user1, user2, user3, user4;
    let table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    before(async () => {
        [deployer, voting, user1, user2, user3, user4] = await ethers.getSigners();
        const OracleFactory = await ethers.getContractFactory("OracleMock");
        oracle = await OracleFactory.deploy();
        await oracle.deployed();

        table.push(["Oracle Address is: ", oracle.address]);
        console.log(table.toString());
        // 1000 and 500 stand for 10% yearly increase, 5% moment decrease
        // await oracle.initialize_v2(1000, 500);
    });

    describe("BeaconSpec", () => {
        it("reverts if the caller has no right role", async() => {
            await expect(
                oracle.connect(voting).setBeaconSpec(0, 1, 1, 1)
            ).to.be.reverted;
        });

        it("setBeaconSpec", async () => {
            const setBeaconSpecRole = await oracle.SET_BEACON_SPEC();
            await oracle.connect(deployer).grantRole(setBeaconSpecRole, voting.address);
    
            await expect(
                oracle.connect(voting).setBeaconSpec(0, 1, 1, 1)
            ).to.be.revertedWith("BAD_EPOCHS_PER_FRAME");
    
            await expect(
                oracle.connect(voting).setBeaconSpec(1, 0, 1, 1)
            ).to.be.revertedWith("BAD_SLOTS_PER_EPOCH");
    
            await expect(
                oracle.connect(voting).setBeaconSpec(1, 1, 0, 1)
            ).to.be.revertedWith("BAD_SECONDS_PER_SLOT");
    
            await expect(
                oracle.connect(voting).setBeaconSpec(1, 1, 1, 0)
            ).to.be.revertedWith("BAD_GENESIS_TIME");
    
            await expect(
                oracle.connect(voting).setBeaconSpec(1, 1, 1, 1)
            ).to.emit(oracle, "BeaconSpecSet").withArgs(1, 1, 1, 1);
        });

        it("getBeaconSpec", async () => {
            const beaconSpec = await oracle.getBeaconSpec();
            expect(beaconSpec.epochsPerFrame).to.equal(1);
            expect(beaconSpec.slotsPerEpoch).to.equal(1);
            expect(beaconSpec.secondsPerSlot).to.equal(1);
            expect(beaconSpec.genesisTime).to.equal(1);
        });
    });

    describe("OracleMember", () => {
        before(async() => {
            const manageMembersRole = await oracle.MANAGE_MEMBERS();
            await oracle.connect(deployer).grantRole(manageMembersRole, voting.address);
        });

        it("reverts if the caller has no right role", async() => {
            await expect(
                oracle.connect(user1).addOracleMember(user1.address)
            ).to.be.reverted;
        });

        it("reverts if member's address is zero", async () => {
            await expect(
                oracle.connect(voting).addOracleMember("0x0000000000000000000000000000000000000000")
            ).to.be.revertedWith("BAD_ARGUMENT");
        });

        it("emits MemberAdded event", async () => {
            await expect(
                oracle.connect(voting).addOracleMember(user1.address)
            ).to.emit(oracle, "MemberAdded").withArgs(user1.address); 

            await expect(
                oracle.connect(voting).addOracleMember(user2.address)
            ).to.emit(oracle, "MemberAdded").withArgs(user2.address); 

            await expect(
                oracle.connect(voting).addOracleMember(user3.address)
            ).to.emit(oracle, "MemberAdded").withArgs(user3.address);
        });

        it("reverts if member's address already exists", async () => {
            await expect(
                oracle.connect(voting).addOracleMember(user1.address)
            ).to.be.revertedWith("MEMBER_EXISTS");
        });

        it("removeOracleMember reverts if member's address is not found", async () => {
            await expect(
                oracle.connect(voting).removeOracleMember(user4.address)
            ).to.be.revertedWith("MEMBER_NOT_FOUND");
        });

        it("emits MemberRemoved event", async () => {
            await expect(
                oracle.connect(voting).removeOracleMember(user3.address)
            ).to.emit(oracle, "MemberRemoved").withArgs(user3.address); 
        });
    });

    describe("Quorum", () => {
        before(async() => {
            const manageQuorumRole = await oracle.MANAGE_QUORUM();
            await oracle.connect(deployer).grantRole(manageQuorumRole, voting.address);
        });

        it("reverts if the caller has no right role", async() => {
            await expect(
                oracle.connect(user1).setQuorum(2)
            ).to.be.reverted;
        });

        it("reverts if quorum number is zero", async() => {
            await expect(
                oracle.connect(voting).setQuorum(0)
            ).to.be.revertedWith("QUORUM_WONT_BE_MADE");
        });

        it("emit QuorumChanged event", async() => {
            await expect(
                oracle.connect(voting).setQuorum(2)
            ).to.emit(oracle, "QuorumChanged").withArgs(2);
        });

        it("getQuorum", async() => {
            expect(
                await oracle.connect(voting).getQuorum()
            ).to.be.equal(2);
        });
    });

    describe("EpochId", () => {
        before(async() => {
            await oracle.setTime(GENESIS_TIME);
            await oracle.connect(voting).setBeaconSpec(1, 32, 12, GENESIS_TIME);
            await oracle.initialize_v2(1000, 500);
            await oracle.connect(voting).setQuorum(2);

            await oracle.connect(user1).reportBeacon(1, 31, 1);
            await oracle.connect(user2).reportBeacon(1, 32, 1);
        });

        it("getCurrentEpochId", async() => {
            expect(await oracle.getCurrentEpochId()).to.equal(0);
            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH - 1);
            expect(await oracle.getCurrentEpochId()).to.equal(0);
            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH * 123 + 1);
            expect(await oracle.getCurrentEpochId()).to.equal(123);
        });

        it("getExpectedEpochId and getLastCompletedEpochId", async() => {
            expect(await oracle.getExpectedEpochId()).to.equal(1);
            expect(await oracle.getLastCompletedEpochId()).to.equal(0);

            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH - 1);
            expect(await oracle.getExpectedEpochId()).to.equal(1);

            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH * 123 + 1);
            await oracle.connect(voting).setQuorum(1);
            await oracle.connect(voting).removeOracleMember(user2.address);
            // cant test for now, related staking contract
            /* await oracle.connect(user1).reportBeacon(123, 32, 1);
            expect(await oracle.getExpectedEpochId()).to.equal(124);
            expect(await oracle.getLastCompletedEpochId()).to.equal(123); */
        });

        it("getCurrentFrame", async() => {
            await oracle.connect(voting).setBeaconSpec(10, 32, 12, GENESIS_TIME);
            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH * 10 - 1);
            let result = await oracle.getCurrentFrame();
            expect(result.frameEpochId).to.equal(0);
            expect(result.frameStartTime).to.equal(GENESIS_TIME);
            expect(result.frameEndTime).to.equal(GENESIS_TIME + EPOCH_LENGTH * 10 - 1);
            
            await oracle.setTime(GENESIS_TIME + EPOCH_LENGTH * 123);
            result = await oracle.getCurrentFrame();
            expect(result.frameEpochId).to.equal(120);
            expect(result.frameStartTime).to.equal(GENESIS_TIME + EPOCH_LENGTH * 120);
            expect(result.frameEndTime).to.equal(GENESIS_TIME + EPOCH_LENGTH * 130 - 1);
        });
    });
});
