const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");


const EVM_REVERT = 'invalid number value';


describe("Sleth's tests", function () {
    const name = 'Lightnode staked Ether';
    const symbol = 'slETH';
    const decimals = '18';
    //const totalSupply = "1000000000000000000000000";
    let slEth, SlEthOwner, stakingOwner, devFee;


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
        [SlEthOwner, stakingOwner, devFee, acc1, acc2, acc3] = await ethers.getSigners();

        //deploying SLeth contract
        const SlEth = await hre.ethers.getContractFactory("SlethMock");
        slEth = await SlEth.deploy(SlEthOwner.address);

        table.push(
            ["SLETH token deployed at: ", slEth.address],
            ["SlEth owner is: ", SlEthOwner.address],
        )
    })
    it('Contracts deployment', async function () {
        console.log(table.toString());
    })

    it('slETH token deployment', async function () {
        let totalSupply = '0';
        const tokenName = await slEth.name();
        expect(tokenName).to.equal(name);
        const tokenSymbol = await slEth.symbol();
        expect(tokenSymbol).to.equal(symbol);
        const tokenDecimlas = await slEth.decimals();
        expect(tokenDecimlas.toString()).to.equal(decimals);
        const tokenTotalSupply = (await slEth.totalSupply()).toString();
        expect(tokenTotalSupply).to.equal(totalSupply)


        testTable.push(
            ["SLETH token's name ", tokenName],
            ["SLETH token's symbol", symbol],
            ["SLETH token's decimals", tokenDecimlas],
            ["SLETH token totalSupply", tokenTotalSupply],
            ["SLETH token's owner", SlEthOwner.address]
        )
        console.log(testTable.toString())
    });
    it('Assign and sending tokens', async function () {
        let balanceOf;
        await slEth.setTotalPooledEther(2000);
        await slEth.mintShares(SlEthOwner.address, 2000);
        balanceOf = await slEth.balanceOf(SlEthOwner.address);
        console.log('balance of Sleth Owner: ', balanceOf);

        await slEth.connect(SlEthOwner).transfer(acc1.address, 750);
        balanceOf = await slEth.balanceOf(acc1.address);
        console.log('balance of Acc1: ', balanceOf);

        await slEth.connect(acc1).transfer(acc2.address, 500);
        balanceOf = await slEth.balanceOf(acc2.address);
        console.log('balance of Acc2: ', balanceOf);

        await slEth.connect(acc2).transfer(acc3.address, 250);
        balanceOf = await slEth.balanceOf(acc3.address);
        console.log('balance of Acc3: ', balanceOf);

        await slEth.connect(acc3).transfer(acc1.address, 50);
        balanceOf = await slEth.balanceOf(acc1.address);
        console.log('balance of Acc3: ', balanceOf);

    })
    it('failure', async function () {
        await slEth.setTotalPooledEther(1000);
        await slEth.mintShares(acc1.address, 1000);
        const invalidAamount = "10000000000000000000000000"; //100million
        await expectRevert.unspecified(slEth.connect(acc1).transfer(acc2.address, invalidAamount), "ERC20: transfer amount exceeds balance");
    });
    it('rejects invalid recipients', async () => {
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer("0x0000000000000000000000000000000000000000", "1000000000000000000000000"));
    });
    it('Approving tokens', async function () {

        await slEth.connect(SlEthOwner).approve(acc1.address, "100000000000000000000000");
        const allowance = await slEth.allowance(SlEthOwner.address, acc1.address)
        expect(allowance.toString()).to.equal("100000000000000000000000")
    })

    it('failure', async function () {
        await expectRevert.unspecified(slEth.approve("0x0000000000000000000000000000000000000000", "100000000000000000000000"))
    })

    it('failure', async function () {
        //attempt to transfer too many tokens.
        const invalidAmount = "10000000000000000000000000" //greater than total supply -100million
        await expectRevert.unspecified(slEth.connect(acc2).transferFrom(SlEthOwner.address, acc2.address, invalidAmount));
        await expectRevert.unspecified(slEth.connect(acc1).transferFrom(acc2.address, "0x0000000000000000000000000000000000000000", "100000000000000000000"))
    })

    it("Pausable / Unpausable Contract testing", async function () {

        await slEth.setTotalPooledEther(2000);
        await slEth.mintShares(SlEthOwner.address, 2000);

        console.log('When contract is unpausable: ');
        let value = await slEth.paused();
        expect(value).to.equal(false);
        console.log("Is Contract Pausable: ", value);

        const owner = await slEth.tokenAccount();
        console.log('Owner is: ', owner);

        let allowance, balanceOf;
        await slEth.connect(SlEthOwner).transfer(acc1.address, "100");
        await slEth.connect(SlEthOwner).approve(acc1.address, "100");
        allowance = await slEth.allowance(SlEthOwner.address, acc1.address);
        expect(allowance.toString()).to.equal("100");
        balanceOf = await slEth.balanceOf(acc1.address);
        console.log("balance of acc1: ", balanceOf);

        await slEth.connect(SlEthOwner).transfer(acc2.address, "500");
        await slEth.connect(SlEthOwner).approve(acc2.address, "500");
        allowance = await slEth.allowance(SlEthOwner.address, acc2.address);
        expect(allowance.toString()).to.equal("500");
        balanceOf = await slEth.balanceOf(acc2.address);
        console.log("balance of acc2: ", balanceOf);

        console.log('When contract is pausable: ');
        //making contract pausable and emmiting the event.
        await expect(slEth.connect(SlEthOwner).pause()).to.emit(slEth, "Paused");
        value = await slEth.paused();
        expect(value).to.equal(true);
        console.log("Is Contract Pausable: ", value);

        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer(acc1.address, "100"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).approve(acc1.address, "100"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transferFrom(SlEthOwner.address, acc1.address, "100"));

        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer(acc2.address, "150"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).approve(acc2.address, "150"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transferFrom(SlEthOwner.address, acc2.address, "150"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner)._mint(acc1.address, "10"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner)._burn(acc1.address, "10"));

        //making contract unpausable and emmiting the event.
        console.log('When contract is unpausable: ');
        await expect(slEth.connect(SlEthOwner).unpause()).to.emit(slEth, "Unpaused");
        value = await slEth.paused();
        expect(value).to.equal(false);
        console.log("Is Contract Pausable: ", value);

        await slEth.connect(SlEthOwner).transfer(acc1.address, "160");
        await slEth.connect(SlEthOwner).approve(acc1.address, "160");
        allowance = await slEth.allowance(SlEthOwner.address, acc1.address);
        expect(allowance.toString()).to.equal("160");
        balanceOf = await slEth.balanceOf(acc1.address);
        console.log("balance of acc1: ", allowance);

        await slEth.connect(SlEthOwner).transfer(acc2.address, "111");
        await slEth.connect(SlEthOwner).approve(acc2.address, "111");
        allowance = await slEth.allowance(SlEthOwner.address, acc2.address);
        expect(allowance.toString()).to.equal("111");
        balanceOf = await slEth.balanceOf(acc2.address);
        console.log("balance of acc2: ", allowance);

        await slEth.connect(SlEthOwner)._mint(acc1.address, '10');
        await slEth.connect(SlEthOwner)._burn(acc1.address, "10");
    })
});
