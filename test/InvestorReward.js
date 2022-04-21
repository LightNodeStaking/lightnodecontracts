const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Admin/Investor Reward Testing", function () {
    let slETH, slETHOwner, contractAddress, admin1, admin2, investor1, investor2;

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
        this.signers = await ethers.getSigners()

        this.admin1 = this.signers[0]
        this.admin2 = this.signers[1]
        this.investor1 = this.signers[2]
        this.investor2 = this.signers[3]

        // deploying admin contract
        const AdminContract = await hre.ethers.getContractFactory("InvestoReward")
        await AdminContract.deploy(this.admin1.address)


        //delpoying Sleth contract
        /* const SlEth = await hre.ethers.getContractFactory("SLETH");
         slETH = await SlEth.deploy(slETHOwner.address)
         await slETH.deployed();*/

        //address shown
        table.push(
            ["Admin Address is: ", this.admin1],
            ["Admin contract deploy at: ", this.contractAddress],
            /*["SlETH contarct deployed at: ", ContractAddress.address],
            ["SlETH Owner address: ", slETHOwner.address]*/
        )
    })
    it("Contracts deployment", async function () {
        console.log(table.toString());
    })
    it("Add Investor - success ", async function () {
        /*let success;
        success = await this.contractAddress.addInvestor(this.admin1);*/
    })

    it("Add Investor - Failure", async function () {

    })
})
