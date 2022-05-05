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

        [ownerAcc1, ownerAcc2, ownerAcc3, ownerAcc4, notOwner] = await ethers.getSigners();

        let owners = [ownerAcc1.address, ownerAcc2.address];
        const required = 2;

        const contractWallet = await hre.ethers.getContractFactory("MultiSignWallet");
        multiSignWallet = await contractWallet.connect(ownerAcc1).deploy(owners, required);


        ta.push(
            ['Owner 1 Address is: ', ownerAcc1.address],
            ['Contract deployed at: ', multiSignWallet.address],
            ['Owner 2 Address is: ', ownerAcc2.address],
            ['Owner 3 Address is: ', ownerAcc3.address],
            ['Owner 4 Address is: ', ownerAcc4.address],
            ['Not Owner Address is: ', notOwner.address]
        )
        // const ownerOne = await multiSignWallet.owners(0)
        // console.log("Owner 1 is: ", ownerOne)
        // const ownerTwo = await multiSignWallet.owners(1)
        // console.log("Owner 2 is: ", ownerTwo)


    })

    it('Contract deployment', async function () {
        console.log(ta.toString());
    })

    it('Adding Owners', async function () {
        //add Owners
        let required = 2;
        let addOwners = [ownerAcc3.address, ownerAcc4.address]
        await multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required);

        const ownerOne = await multiSignWallet.owners(0)
        console.log("Owner 1 is: ", ownerOne)

        const ownerTwo = await multiSignWallet.owners(1)
        console.log("Owner 2 is: ", ownerTwo)

        const ownerThree = await multiSignWallet.owners(2)
        console.log("Owner 3 is: ", ownerThree)

        const ownerFour = await multiSignWallet.owners(3)
        console.log("Owner 4 is: ", ownerFour)

        // remove Owners
        await multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc3.address);
        await multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc4.address);

        const removeOwnerThree = await multiSignWallet.owners(2)
        console.log("Remove Owner 3: ", removeOwnerThree)
        const removeOwnerFour = await multiSignWallet.owners(3)
        console.log("Remove Owner 4: ", removeOwnerFour)

    })

    it('Submit Tx / Approve Tx / Exceute Tx / Revoke Tx', async function () {
        //add Owners
        let required = 2;
        let addOwners = [ownerAcc3.address, ownerAcc4.address]
        await multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required);

        //Submit Transaction
        console.log("Submiting Transaction")
        await multiSignWallet.connect(ownerAcc1).submitTx(ownerAcc1.address, 0, "0x00");
        //await multiSignWallet.connect(notOwner).submitTx(ownerAcc1.address, 0, "0x00");
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(ownerAcc2.address, 1, "0x00"))

        //Approve Transaction
        console.log("Approve Transaction")
        await multiSignWallet.connect(ownerAcc2).approve(0)
        await expectRevert.unspecified(multiSignWallet.connect(ownerAcc2).approve(0))
        await multiSignWallet.connect(ownerAcc3).approve(0)

        console.log("Execute Transaction")
        await multiSignWallet.connect(ownerAcc1).execute(0)
        await multiSignWallet.connect(ownerAcc2).execute(0)
        await multiSignWallet.connect(ownerAcc3).execute(0)

    })

})