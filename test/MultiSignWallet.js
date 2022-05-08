const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");
const { noop } = require("lodash");

describe("Multi- Signature Wallet Testing", function () {
    let multiSignWallet, tokenMock;

    //Table
    ta = new Table({
        head: ['Contracts', 'contract addresses'],
        colWidths: ['auto', 'auto']
    });

    beforeEach(async function () {

        [ownerAcc1, ownerAcc2, ownerAcc3, ownerAcc4, notOwner, mockCoin] = await ethers.getSigners();

        let owners = [ownerAcc1.address, ownerAcc2.address];
        let required = 2;

        const contractWallet = await hre.ethers.getContractFactory("MultiSignWallet");
        multiSignWallet = await contractWallet.connect(ownerAcc1).deploy(owners, required);
        const mockToken = await hre.ethers.getContractFactory("Mocktoken");
        tokenMock = await mockToken.connect(mockCoin).deploy(mockCoin.address);

        ta.push(
            ['Owner 1 Address is: ', ownerAcc1.address],
            ['Contract deployed at: ', multiSignWallet.address],
            ['Owner 2 Address is: ', ownerAcc2.address],
            ['Owner 3 Address is: ', ownerAcc3.address],
            ['Owner 4 Address is: ', ownerAcc4.address],
            ['Not Owner Address is: ', notOwner.address]
        )
    })

    it('Contract deployment', async function () {
        console.log(ta.toString());
    })

    it('Adding Owners/Removing Owners', async function () {
        //add Owners
        let required = 2;
        let addOwners = [ownerAcc3.address, ownerAcc4.address]
        owners = [ownerAcc1.address, ownerAcc2.address];
        await expect(multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required)).to.emit(multiSignWallet, "AddOwner").withArgs(ownerAcc1.address, addOwners[0, 1]);

        const ownerOne = await multiSignWallet.owners(0)
        console.log("Owner 1 is: ", ownerOne)

        const ownerTwo = await multiSignWallet.owners(1)
        console.log("Owner 2 is: ", ownerTwo)

        const ownerThree = await multiSignWallet.owners(2)
        console.log("Owner 3 is: ", ownerThree)

        const ownerFour = await multiSignWallet.owners(3)
        console.log("Owner 4 is: ", ownerFour)

        // remove Owners
        await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc3.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[0]);
        await expect(multiSignWallet.connect(ownerAcc1).removeOwner(ownerAcc4.address)).to.emit(multiSignWallet, "RemoveOwner").withArgs(owners[0], addOwners[1]);

        const removeOwnerThree = await multiSignWallet.owners(2)
        console.log("Remove Owner 3: ", removeOwnerThree)
        const removeOwnerFour = await multiSignWallet.owners(3)
        console.log("Remove Owner 4: ", removeOwnerFour)

    })

    it('Submit Tx / Approve Tx / Revoke Tx', async function () {
        //add Owners
        let required = 2;
        let addOwners = [ownerAcc3.address, ownerAcc4.address]
        await multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required);

        let ownerList = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address]

        //Submit Transaction
        console.log("Submiting Transaction")
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(ownerAcc1.address, 0, "0x00")).to.emit(multiSignWallet, "Submit").withArgs(0);
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(ownerAcc2.address, 1, "0x00"));
        await expectRevert.unspecified(multiSignWallet.connect(ownerAcc1).submitTx(notOwner.address, 0, "0x00"));
        //await multiSignWallet.connect(notOwner).submitTx(ownerAcc1.address, 0, "0x00");
        //await multiSignWallet.connect(ownerAcc1).submitTx(notOwner.address, 0, "0x00");

        //Approve Transaction
        console.log("Approve Transaction")
        await expect(multiSignWallet.connect(ownerAcc2).approve(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[1], 0);
        await expect(multiSignWallet.connect(ownerAcc3).approve(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[2], 0);
        await expectRevert.unspecified(multiSignWallet.connect(ownerAcc2).approve(0));
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approve(0));

        //Revoke Transaction
        console.log("Revoke Transaction")
        await multiSignWallet.connect(ownerAcc2).revoke(0)

    })

    it('Exceute Txs', async function () {
        //add Owners
        let required = 2;
        let addOwners = [ownerAcc3.address, ownerAcc4.address]
        await multiSignWallet.connect(ownerAcc1).addOwner(addOwners, required);

        let ownerList = [ownerAcc1.address, ownerAcc2.address, ownerAcc3.address, ownerAcc4.address]
        let value = "1"

        console.log('Submit Tx / Approve Tx / Execute Tx - First Transaction: ')
        //Submit Transaction and event
        await expect(multiSignWallet.connect(ownerAcc1).submitTx(ownerAcc3.address, value, "0x00")).to.emit(multiSignWallet, "Submit").withArgs(0);
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).submitTx(ownerAcc2.address, 1, "0x00"));
        await expectRevert.unspecified(multiSignWallet.connect(ownerAcc1).submitTx(notOwner.address, 0, "0x00"));

        //Approve Transaction and event
        await expect(multiSignWallet.connect(ownerAcc2).approve(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[1], 0);
        await expect(multiSignWallet.connect(ownerAcc3).approve(0)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[2], 0);
        await expectRevert.unspecified(multiSignWallet.connect(ownerAcc2).approve(0));
        await expectRevert.unspecified(multiSignWallet.connect(notOwner).approve(0));

        //Execute Transaction 
        console.log("Execute Transaction")
        let totalSupply = 1000 * 1e18;
        await expect(tokenMock.connect(mockCoin)._mint())
        await expect(multiSignWallet.connect(ownerAcc3).execute(0)).to.emit(multiSignWallet, "Execute").withArgs(ownerList[2], 0);

        const txDetails = await multiSignWallet.getTransaction(0)
        expect(txDetails.to).to.equal(ownerList[2]);
        expect(txDetails.value).to.equal(value);
        expect(txDetails.data).to.equal("0x00");
        expect(txDetails.executed).to.equal(true);

        await expectRevert.unspecified(multiSignWallet.connect(notOwner).execute(0));
        // await multiSignWallet.connect(notOwner).execute(0)


        // console.log('Submit Tx / Approve Tx / Execute Tx - Second Transaction: ')
        // //submit Transaction
        // value = '1000000000000000000'
        // await expect(multiSignWallet.connect(ownerAcc2).submitTx(ownerAcc1.address, value, '0x01')).to.emit(multiSignWallet, "Submit").withArgs(1);
        // //Approve Transaction and event
        // await expect(multiSignWallet.connect(ownerAcc1).approve(1)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[0], 1);
        // await expect(multiSignWallet.connect(ownerAcc3).approve(1)).to.emit(multiSignWallet, "Approve").withArgs(ownerList[2], 1);
        // //Execute Transaction
        // await expect(multiSignWallet.connect(ownerAcc1).execute("1")).to.emit(multiSignWallet, "Execute").withArgs(ownerList[0], 1);
        // //await multiSignWallet.connect(ownerAcc1).execute(1)
        // let secTxDetails = await multiSignWallet.getTransaction(1)
        // expect(secTxDetails.to).to.equal(ownerList[0]);
        // expect(secTxDetails.value).to.equal(5);
        // expect(secTxDetails.data).to.equal("0x01");
        // expect(secTxDetails.executed).to.equal(true);
        //await expectRevert.unspecified(multiSignWallet.connect(notOwner).execute(0));

        // let getOwners = await multiSignWallet.getOwners();
        // console.log("Owner List: ", getOwners);

        // let transactionCount = await multiSignWallet.getTransactionCount();
        // console.log("Transaction Count List: ", transactionCount);
    })

})