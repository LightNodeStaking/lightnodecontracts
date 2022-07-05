const { expect } = require("chai");
const { ethers } = require("hardhat");
const Table = require("cli-table3");

describe("Oracle Test Suite", () => {
    let oracle;
    let deployer, voting;
    let table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    before(async () => {
        [deployer, voting] = await ethers.getSigners();
        const OracleFactory = await ethers.getContractFactory("Oracle");
        oracle = await OracleFactory.deploy();
        await oracle.deployed();

        table.push(["Oracle Address is: ", oracle.address]);
        console.log(table.toString());
        // 1000 and 500 stand for 10% yearly increase, 5% moment decrease
        // await oracle.initialize_v2(1000, 500);
    });

    describe("setBeaconSpec", () => {
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
});
