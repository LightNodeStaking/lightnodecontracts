const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");

describe("Multi- Signature Wallet Testing", function () {
    let multiSignWallet;

    //Table
    ta = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {

        [ownerAcc, ownerAcc1, ownerAcc2, ownerAcc3, notOwner] = await ethers.getSigners();

        const contractWallet = await hre.ethers.getContractFactory("MultiSignWallet");
        multiSignWallet = await contractWallet.connect(ownerAcc).deploy(ownerAcc.address);

        ta.push(
            ['Owner Address is: ', ownerAcc.address],
            ['Contract deployed at: ', multiSignWallet.address],
            ['Owner1 Address is: ', ownerAcc1.address],
            ['Owner2 Address is: ', ownerAcc2.address],
            ['Owner2 Address is: ', ownerAcc3.address],
            ['Not Owner Address is: ', notOwner.address]
        )
        // let contractOwner = await multiSignWallet.owner()
        // console.log("Owner is: ", contractOwner)

    })

    it('Contract deployment', async function () {
        console.log(ta.toString());
    })

    it('Adding Owners', async function () {
        //add Owners
        await multiSignWallet.connect(ownerAcc).addOwner(ownerAcc1.address, 'true');
        console.log("OwnerAcc 1 added to owner list: " + ownerAcc1.address)

        await multiSignWallet.connect(ownerAcc1).addOwner(ownerAcc2.address, "true");
        console.log("OwnerAcc 2 added to owner list: " + ownerAcc2.address)

        //await multiSignWallet.connect(notOwner).addOwner(ownerAcc1.address, 'true');
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).addOwner(ownerAcc1.address, 'true'));

        //remove Owners
        await multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc.address, "true");
        console.log("OwnerAcc removed from owner list: " + ownerAcc.address)

        await multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc2.address, "true");
        console.log("OwnerAcc 2 removed from owner list: " + ownerAcc2.address)

        //await multiSignWallet.connect(notOwner).removeOwner(ownerAcc2.address, "true");
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).removeOwner(ownerAcc2.address, "true"));
    })

    it('Submit Tx / Approve Tx / Exceute Tx / Revoke Tx', async function () {
        //add Owners
        await multiSignWallet.connect(ownerAcc).addOwner(ownerAcc1.address, 'true');
        await multiSignWallet.connect(ownerAcc1).addOwner(ownerAcc2.address, "true");
        await multiSignWallet.connect(ownerAcc2).addOwner(ownerAcc3.address, "true");

        //Submit Transaction
        console.log("Submit Transaction")


        console.log("Approve Transaction")

        console.log("Exceute Transaction")

        console.log("Revoke Transaction")

    })

})