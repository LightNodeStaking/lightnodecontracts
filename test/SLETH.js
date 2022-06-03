const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert } = require('@openzeppelin/test-helpers');
const Table = require("cli-table3");


const EVM_REVERT = 'invalid number value';


describe("Sleth's tests", function () {
    const name = 'Lightnode staked Ether';
    const symbol = 'slETH';
    const decimals = '18';
    const totalSupply = "1000000000000000000000000";
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
        [SlEthOwner, stakingOwner, devFee, acc1, acc2] = await ethers.getSigners();

        //deploying SLeth contract
        const SlEth = await hre.ethers.getContractFactory("SLETH");
        slEth = await SlEth.deploy(SlEthOwner.address);
        //await slEth.deployed();

        //Transfering 10000 token to acc1
        await slEth.connect(SlEthOwner).transfer(acc1.address, "100000000000000000000000")
        table.push(
            ["SLETH token deployed at: ", slEth.address],
            ["SlEth owner is: ", SlEthOwner.address],
        )
    })
    it('Contracts deployment', async function () {
        console.log(table.toString());
    })

    it('slETH token deployment', async function () {
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
    it('sending tokens', async function () {
        let balanceOf;
        balanceOf = await slEth.balanceOf(SlEthOwner.address);
        expect(balanceOf.toString()).to.equal("900000000000000000000000")
        //balanceOf.toString().should.equal(tokens(900000).toString())
        balanceOf = await slEth.balanceOf(acc1.address)
        expect(balanceOf.toString()).to.equal("100000000000000000000000");
    })
    it('failure', async function () {
        const invalidAamount = "10000000000000000000000000"; //100million
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer(acc2.address, invalidAamount), "ERC20: transfer amount exceeds balance");
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

        console.log('When contract is unpausable: ');
        let value = await slEth.paused();
        expect(value).to.equal(false);
        console.log("Is Contract Pausable: ", value);

        const owner = await slEth.tokenAccount();
        console.log('Owner is: ', owner);

        await slEth.connect(SlEthOwner).transfer(acc1.address, "100");
        await slEth.connect(SlEthOwner).approve(acc1.address, "100");
        let allowance = await slEth.allowance(SlEthOwner.address, acc1.address)
        expect(allowance.toString()).to.equal("100");
        console.log("balance of acc1: ", allowance.toString());

        await slEth.connect(SlEthOwner).transfer(acc2.address, "1000");
        await slEth.connect(SlEthOwner).approve(acc2.address, "1000");
        allowance = await slEth.allowance(SlEthOwner.address, acc2.address)
        expect(allowance.toString()).to.equal("1000");
        console.log("balance of acc2: ", allowance.toString());

        console.log('When contract is pausable: ');
        //making contract pausable and emmiting the event.
        await expect(slEth.connect(SlEthOwner).pause()).to.emit(slEth, "Paused")
        value = await slEth.paused();
        expect(value).to.equal(true);
        console.log("Is Contract Pausable: ", value);

        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer(acc1.address, "100"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).approve(acc1.address, "100"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transferFrom(SlEthOwner.address, acc1.address, "100"));

        await expectRevert.unspecified(slEth.connect(SlEthOwner).transfer(acc2.address, "11210"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).approve(acc2.address, "11210"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner).transferFrom(SlEthOwner.address, acc2.address, "11210"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner)._mint(acc1.address, "10"));
        await expectRevert.unspecified(slEth.connect(SlEthOwner)._burn(acc1.address, "10"));

        //making contract unpausable and emmiting the event.
        console.log('When contract is unpausable: ');
        await expect(slEth.connect(SlEthOwner).unpause()).to.emit(slEth, "Unpaused");
        value = await slEth.paused();
        expect(value).to.equal(false);
        console.log("Is Contract Pausable: ", value);

        await slEth.connect(SlEthOwner).transfer(acc1.address, "150");
        await slEth.connect(SlEthOwner).approve(acc1.address, "150");
        allowance = await slEth.allowance(SlEthOwner.address, acc1.address)
        expect(allowance.toString()).to.equal("150");
        console.log("balance of acc1: ", allowance.toString());

        await slEth.connect(SlEthOwner).transfer(acc2.address, "1105");
        await slEth.connect(SlEthOwner).approve(acc2.address, "1105");
        allowance = await slEth.allowance(SlEthOwner.address, acc2.address)
        expect(allowance.toString()).to.equal("1105");
        console.log("balance of acc2: ", allowance.toString());

        await slEth.connect(SlEthOwner)._mint(acc1.address, '10');
        await slEth.connect(SlEthOwner)._burn(acc1.address, "10");
    })
});
