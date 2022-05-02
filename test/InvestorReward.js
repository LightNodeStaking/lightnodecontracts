const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Admin/Investor Reward Testing", function () {
    let investorReward;

    //Table 
    table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {
        [ownerAcc, investorAcc1, investorAcc2, ownerAcc2] = await ethers.getSigners();

        // deploying admin contract
        const AdminContract = await hre.ethers.getContractFactory("InvestoReward");
        investorReward = await AdminContract.connect(ownerAcc).deploy();

        //address shown 
        table.push(
            ["Admin Address is: ", ownerAcc.address],
            ["Admin contract deploy at: ", investorReward.address],
            ["Investor1 address is: ", investorAcc1.address],
            ["Admin2 address is: ", ownerAcc2.address]
        )
    })
    it("Contracts deployment", async function () {
        console.log(table.toString());
    })
    it("Add/Remove Investor ", async function () {

        //const newOwner = await investorReward.admin();

        await investorReward.connect(ownerAcc).addInvestor(investorAcc1.address);
        await expectRevert.unspecified(investorReward.connect(ownerAcc).addInvestor(ownerAcc.address))

        await expect(investorReward.connect(ownerAcc).removeInvestor(investorAcc1.address)).to.ok;
        await expectRevert.unspecified(investorReward.connect(ownerAcc).removeInvestor(investorAcc2.address));
    })

    it('Add/edit Percentage ', async function () {
        await investorReward.connect(ownerAcc).addInvestor(investorAcc1.address);
        await expectRevert.unspecified(investorReward.connect(ownerAcc).addInvestor(ownerAcc.address));

        //adding percentage for Investor 1
        let percentage = '1';
        await investorReward.connect(ownerAcc).addPercentage(investorAcc1.address, percentage);
        console.log("Investor 1 Percentage is " + percentage + "%");
        console.log("investor 1 = " + investorAcc1.address);
        await expectRevert.unspecified(investorReward.connect(investorAcc1).addPercentage(investorAcc1.address, percentage));
        await expect(investorReward.connect(investorAcc1).addPercentage(investorAcc1.address)).to.ok;

        //changing percentage for Investor 1
        percentage = '5';
        await investorReward.connect(ownerAcc).editPercentage(investorAcc1.address, percentage);
        console.log("Investor 1 Percentage is " + percentage + "%");
        console.log("investor 1 = " + investorAcc1.address);
        await expectRevert.unspecified(investorReward.connect(investorAcc1).editPercentage(investorAcc1.address, percentage));
        await expect(investorReward.connect(investorAcc1).editPercentage(investorAcc1.address)).to.ok;

        const previousOwner = await investorReward.admin();
        //Transfer Ownership
        await investorReward.connect(ownerAcc).transferOwnership(ownerAcc2.address);
        const newOwner = await investorReward.admin();
        console.log("Previous Owner address: " + previousOwner);
        console.log("New Owner address: " + newOwner);

        //New owner adding Investor
        await investorReward.connect(ownerAcc2).removeInvestor(investorAcc1.address);
        await expectRevert.unspecified(investorReward.connect(ownerAcc).addInvestor(investorAcc2.address));
        await expect(investorReward.connect(ownerAcc).removeInvestor(investorAcc2.address)).to.ok;
    })
})
