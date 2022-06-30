const { expect } = require("chai");
const { ethers } = require("hardhat");
const Table = require("cli-table3");

describe("Oracle Test Suite", function() {
    let oracle;

    let table = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    before(async function() {
        const OracleFactory = await ethers.getContractFactory("Oracle");
        oracle = await OracleFactory.deploy();
        await oracle.deployed();

        table.push(["Oracle Address is: ", oracle.address])
    });

    it("Contracts deployment", async function () {
        console.log(table.toString());
    })
});
