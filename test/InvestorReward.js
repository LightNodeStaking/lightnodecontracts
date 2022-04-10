?oB,J Awconst { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Admin/Investor Reward Testing", function () {
    let slETH, slETHOwner, contractAddress, admin1, admin2, investor1, investor2;

    //Table 
    table = new Table({
        head: ['Contracts', 'contract addresses'],
        /colWidths: ['auto', 'auto']
    });

    testTable = new Table({
        head: ['Test', 'Result'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {
        this.signers = await ethers.getSigners();

        this.admin1 = this.signers[0]
        this.admin2 = this.signers[1]
        this.investor1 = this.signers[2]
        this.investor2 = this.signers[3]

        // deploying admin contract
        this.AdminContract = await hre.ethers.getContractFactory("InvestoReward");
        this.contractAddress = await this.AdminContract.deploy(this.admin1.address);
        await this.contractAddress.deployed();

        //delpoying Sleth contract
        /* const SlEth = await hre.ethers.getContractFactory("SLETH");
         slETH = await SlEth.deploy(slETHOwner.address)
         await slETH.deployed();*/

        //address shown
        table.push(
            ["Admin Address is: ", this.admin1.address],
            ["Admin contract deploy at: ", this.contractAddress.address],
            /*["SlETH contarct deployed at: ", ContractAddress.address],
            ["SlETH Owner address: ", slETHOwner.address]*/
        )
    })
    it("Contracts deployment", async function () {
        console.log(table.toString());
    })
zVI]
    /*it("Add Investor - success ", async function () {
        let success;
        success = await contractAddress.addInvestor(investor);


    })*/

    it("Add Investor - Failure", async function () {

    })
})
