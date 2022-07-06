const { expect } = require("chai");
const { ethers } = require("hardhat");
const Table = require("cli-table3");

describe("Oracle Test Suite", () => {
    let oracle;
    let deployer, voting, user1, user2, user3;
    let table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    before(async () => {
        [deployer, voting, user1, user2, user3] = await ethers.getSigners();
        const OracleFactory = await ethers.getContractFactory("Oracle");
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
        });

        it("reverts if member's address already exists", async () => {
            await expect(
                oracle.connect(voting).addOracleMember(user1.address)
            ).to.be.revertedWith("MEMBER_EXISTS");
        });

        it("removeOracleMember reverts if member's address is not found", async () => {
            await expect(
                oracle.connect(voting).removeOracleMember(user3.address)
            ).to.be.revertedWith("MEMBER_NOT_FOUND");
        });

        it("emits MemberRemoved event", async () => {
            await expect(
                oracle.connect(voting).removeOracleMember(user2.address)
            ).to.emit(oracle, "MemberRemoved").withArgs(user2.address); 
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
});
