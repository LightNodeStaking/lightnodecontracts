const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Admin/Investor Reward Testing", function () {
    let owner, admin1, admin2, investor1, investor2;

    //Table 
    table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    testTable = new Table({
        head: ['Test', 'Result'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {
        [ownerAcc, adminAcc1, adminAcc2, investorAcc1, investorAcc2] = await ethers.getSigners();

        // deploying admin contract
        const AdminContract = await hre.ethers.getContractFactory("InvestoReward");
        owner = await AdminContract.connect(ownerAcc).deploy();

        //delpoying Sleth contract
        /* const SlEth = await hre.ethers.getContractFactory("SLETH");
         slETH = await SlEth.deploy(slETHOwner.address)
         await slETH.deployed();*/

        //address shown 
        table.push(
            ["Admin Address is: ", ownerAcc.address],
            ["Admin contract deploy at: ", owner.address],
            /*["SlETH contarct deployed at: ", ContractAddress.address],
            ["SlETH Owner address: ", slETHOwner.address]*/
        )
    })
    it("Contracts deployment", async function () {
        console.log(table.toString());
    })
    it("Add Investor - success ", async function () {
        let success;
        await owner.connect(ownerAcc).addInvestor(owner.address);
        // expectRevert(await owner.addInvestor(owner.address), "ALREADY_INVESTOR").to.be;

    })

    it("Add Investor - Failure", async function () {

    })
})
