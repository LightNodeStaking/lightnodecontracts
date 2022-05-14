const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");
const BigNumber = require('big-number');

describe("Multi- Signature Wallet Testing", function () {
    let multiSignWallet, tokenMock;
    let decimal = 1e18
    //Table
    ta = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {

        [ownerAcc1, ownerAcc2, ownerAcc3, ownerAcc4, notOwner, mockCoin, toAdddress1, toAdddress2, toAdddress3, toAdddress4] = await ethers.getSigners();

        let owners = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address];
        let required = 3;

        const contractWallet = await hre.ethers.getContractFactory("MultiSignWallet");
        multiSignWallet = await contractWallet.connect(ownerAcc1).deploy(owners, required);

        const mockToken = await hre.ethers.getContractFactory("Mocktoken");
        tokenMock = await mockToken.connect(mockCoin).deploy(mockCoin.address);

        let tokenvalue = ethers.utils.parseEther('1000')
        await tokenMock.transfer(multiSignWallet.address, tokenvalue.toString());

        console.log("Amount of token: " + tokenvalue)

        ta.push(
            ['Contract deployed at: ', multiSignWallet.address],
            ['Owner 1 Address is: ', ownerAcc1.address],
            ['Owner 2 Address is: ', ownerAcc2.address],
            ['Owner 3 Address is: ', ownerAcc3.address],
            ['Owner 4 Address is: ', ownerAcc4.address],
            ['Not Owner Address is: ', notOwner.address],
            ['To 1 Address is: ', toAdddress1.address],
            ['To 2 Address is: ', toAdddress2.address],
            ['To 3 Address is: ', toAdddress3.address],
            ['To 4 Address is: ', toAdddress4.address]
        )
    })

    it('Contract deployment', async function () {
        console.log(ta.toString());
    })

    it('Adding Owners/Removing Owners', async function () {
        // //add Owners
        // let required = 2;
        // let addOwners = [ownerAcc3.address, ownerAcc4.address]
        // owners = [ownerAcc1.address, ownerAcc2.address];
        // await expect(multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required)).to.emit(multiSignWallet, "AddOwner").withArgs(ownerAcc1.address, addOwners[0, 1]);

        // let getOwners = await multiSignWallet.getOwners();
        // console.log("Owner List: ", getOwners);

        // // remove Owners
        // await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc3.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[0]);
        // await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc4.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[1]);

    })

    it('Submit Tx / Approve Tx / Revoke Tx / Execute Tx', async function () {
        //add Owners
        let required, ownerList, valueTo;
        required = 3;
        ownerList = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address]

        //Submit Transaction

        console.log(('Transaction 1 submit, approve, execute: '))
        valueTo = ethers.utils.parseEther('1');


        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(toAdddress1.address, 0, "0x00"));
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(toAdddress1.address, valueTo, "0x00")).to.emit(multiSignWallet, "Submit").withArgs(0);
        await expect(multiSignWallet.connect(ownerAcc2).approveTx(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[1], 0);
        await expect(multiSignWallet.connect(ownerAcc4).approveTx(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[3], 0);
        let txDetails = await multiSignWallet.getTransaction(0);
        console.log("TEST: ", txDetails)
        // //await expect(multiSignWallet.connect(ownerAcc1).revokeTx(0)).to.emit(multiSignWallet, "Revoke").withArgs(ownerList[0], 0);
        await expect(multiSignWallet.connect(ownerAcc4).executeTx(0)).to.emit(multiSignWallet, "Execute").withArgs(ownerList[3], 0);



        // console.log(('Transaction 2 submit, approve, execute: '))
        // valueTo = '0'
        // await expect(multiSignWallet.connect(ownerAcc2).submitTx(toAdddress2.address, valueTo, "0x01")).to.emit(multiSignWallet, "Submit").withArgs(1);
        // await expect(multiSignWallet.connect(ownerAcc3).approveTx(1)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[2], 1);
        // await expect(multiSignWallet.connect(ownerAcc4).approveTx(1)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[3], 1);
        // await expect(multiSignWallet.connect(ownerAcc4).executeTx(1)).to.emit(multiSignWallet, "Execute").withArgs(ownerList[3], 1);
        // // txDetails = await multiSignWallet.getTransaction(1);
        // // console.log(txDetails);

        // console.log(('Transaction 3 submit, approve, execute: '))
        // valueTo = '0'
        // await expect(multiSignWallet.connect(ownerAcc3).submitTx(toAdddress2.address, valueTo, "0x02")).to.emit(multiSignWallet, "Submit").withArgs(2);
        // await expect(multiSignWallet.connect(ownerAcc1).approveTx(2)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[0], 2);
        // await expect(multiSignWallet.connect(ownerAcc4).approveTx(2)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[3], 2);
        // await expect(multiSignWallet.connect(ownerAcc4).executeTx(2)).to.emit(multiSignWallet, "Execute").withArgs(ownerList[3], 2);

        // console.log(('Transaction 4 submit, approve, execute: '))
        // valueTo = '0'
        // await expect(multiSignWallet.connect(ownerAcc3).submitTx(toAdddress2.address, valueTo, "0x03")).to.emit(multiSignWallet, "Submit").withArgs(3);
        // await expect(multiSignWallet.connect(ownerAcc1).approveTx(3)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[0], 3);
        // await expect(multiSignWallet.connect(ownerAcc4).approveTx(3)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[3], 3);
        // await expect(multiSignWallet.connect(ownerAcc4).executeTx(3)).to.emit(multiSignWallet, "Execute").withArgs(ownerList[3], 3);


    })

})