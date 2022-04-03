const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Admin/Investor Reward Testing", function () {
    let slETH, slETHOwner, ContractAddress, adminAddress1, adminAddress2, investorAddress1, investorAddress2;

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
        [slETHOwner, adminAddress1, adminAddress2, investorAddress1, investorAddress2] = await ethers.getSigners();

        // deploying admin contract
        const AdminContract = await hre.ethers.getContractFactory("InvestoReward");
        ContractAddress = await AdminContract.deploy(adminAddress1.address);
        await ContractAddress.deployed();

        //delpoying Sleth contract
        const SlEth = await hre.ethers.getContractFactory("SLETH");
        slETH = await SlEth.deploy(slETHOwner.address)
        await slETH.deployed();

        //address shown
        table.push(
            ["Admin Address is: ", adminAddress1.address],
            ["Admin contract deploy at: ", ContractAddress.address],
            ["SlETH contarct deployed at: ", ContractAddress.address],
            ["SlETH Owner address: ", slETHOwner.address]
        )
    })
    it("Contracts deployment", async function () {
        console.log(table.toString());
    })

    it("Add Investor - success ", async function () {
        let sucess;
        sucess = await ContractAddress


    })

    it("Add Investor - Failure", async function () {

    })
})