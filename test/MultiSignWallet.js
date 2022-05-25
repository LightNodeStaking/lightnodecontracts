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
        // let addOwners;
        // let required = 1;
        // addOwners = [ownerAcc3.address, ownerAcc4.address]
        // owners = [ownerAcc1.address, ownerAcc2.address];
        // await expect(multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required)).to.emit(multiSignWallet, "AddOwner").withArgs(ownerAcc1.address, addOwners[0, 1]);

        // let getOwners = await multiSignWallet.getOwners();
        // console.log("Owner List: ", getOwners);

        // let removeOwners //un comment this to remove owners
        // await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc3.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[0]);
        // await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc4.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[1]);

    })

    it('Submit Tx / Approve Tx / Execute Tx', async function () {
        //add Owners
        let ownerList, valueTo, txIndex;
        //ownerList = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address];

        owners = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address];

        //Submit Transaction

        console.log(('Transactions submit, approve, execute: '))
        valueTo = ethers.utils.parseEther('0'); //sending 0 ether to address
        valueData = "0x00";
        txIndex = 0;

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(toAdddress1.address, valueTo, valueData)); //Not_Owner try to submit tx - fails
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(toAdddress1.address, valueTo, valueData)).to.emit(multiSignWallet, "Submit").withArgs(txIndex);
        await expect(multiSignWallet.connect(ownerAcc2).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[1], txIndex);
        await expect(multiSignWallet.connect(ownerAcc3).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[2], txIndex);

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approveTx(txIndex)); // Not Owner Try to approve Tx - failed
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).executeTx(txIndex)); // Not Owner try to Execute Tx - failed

        let txDetails = await multiSignWallet.getTransaction(txIndex);
        console.log("Tx 0 details: ", txDetails);
        let exe = await multiSignWallet.isExecuted(txIndex)
        console.log("Tx executed testing: ", exe);

        console.log(('Transaction 1 submit, approve, execute: '))
        valueTo = ethers.utils.parseEther('10'); //sending 10 ether to address
        valueData = "0x01";
        txIndex = 1;

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(toAdddress1.address, valueTo, valueData));
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(toAdddress1.address, valueTo, valueData)).to.emit(multiSignWallet, "Submit").withArgs(txIndex);
        await expect(multiSignWallet.connect(ownerAcc2).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[1], txIndex);
        await expect(multiSignWallet.connect(ownerAcc4).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[3], txIndex);

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approveTx(txIndex)); // Not Owner Try to approve Tx - failed
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).executeTx(txIndex)); // Not Owner try to Execute Tx - failed

        txDetails = await multiSignWallet.getTransaction(txIndex);
        console.log("Tx 1 details: ", txDetails);
        exe = await multiSignWallet.isExecuted(txIndex)
        console.log("Tx executed testing: ", exe);

        console.log(('Transaction 2 submit, approve, execute: '))
        valueTo = ethers.utils.parseEther('16'); //sending 16 ether to address
        valueData = "0x11";
        txIndex = 2;

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(toAdddress1.address, valueTo, valueData));
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(toAdddress1.address, valueTo, valueData)).to.emit(multiSignWallet, "Submit").withArgs(txIndex);
        await expect(multiSignWallet.connect(ownerAcc2).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[1], txIndex);
        await expect(multiSignWallet.connect(ownerAcc4).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[3], txIndex);

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approveTx(txIndex)); // Not Owner Try to approve Tx - failed
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).executeTx(txIndex)); // Not Owner try to Execute Tx - failed

        txDetails = await multiSignWallet.getTransaction(txIndex);
        console.log("Tx 2 details: ", txDetails);
        exe = await multiSignWallet.isExecuted(txIndex)
        console.log("Tx executed testing: ", exe);

        console.log(('Transaction 3 submit, approve, execute: '))
        valueTo = ethers.utils.parseEther('25'); //sending 25 ether to address
        valueData = "0x25";
        txIndex = 3;

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(toAdddress1.address, valueTo, valueData));
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(toAdddress1.address, valueTo, valueData)).to.emit(multiSignWallet, "Submit").withArgs(txIndex);
        await expect(multiSignWallet.connect(ownerAcc2).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[1], txIndex);
        await expect(multiSignWallet.connect(ownerAcc4).approveTx(txIndex)).to.emit(multiSignWallet, "Approve").withArgs(owners[3], txIndex);

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approveTx(txIndex)); // Not Owner Try to approve Tx - failed
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).executeTx(txIndex)); // Not Owner try to Execute Tx - failed

        txDetails = await multiSignWallet.getTransaction(txIndex);
        console.log("Tx 3 details: ", txDetails);
        exe = await multiSignWallet.isExecuted(txIndex)
        console.log("Tx executed testing: ", exe);

    })
    it('Changing Number of approvals', async function () {
        owners = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address];
        required = 3

        //console.log('Number of confirmation required: ', required);

        let approval = await multiSignWallet.required();

        console.log("Number of confirmation before: ", approval);

        await multiSignWallet.connect(ownerAcc1).changeRequirement(2);
        approval = await multiSignWallet.required();
        console.log("Number of confirmation after: ", approval);
    })

})