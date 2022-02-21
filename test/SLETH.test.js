const Token = artifacts.require("./SLETH");
require('chai').use(require('chai-as-promised')).should();

const tokens =(n)=>{
    return new web3.utils.BN(
       web3.utils.toWei(n.toString(), 'ether')
    );
};

const EVM_REVERT='invalid number value' ;

contract('Token', ([deployer, user1, user2])=>{
    const name = 'Lightnode staked Ether';
    const symbol = 'slETH';
    const decimals = '18';
    const totalSupply = tokens(1000000).toString();
    let slETH;

    beforeEach(async()=>{
        slETH = await Token.new(deployer);
    })

    describe('slETH token deployment', ()=>{
        it('Name is correct', async()=>{
            const result = await slETH.name();
            result.should.equal(name);
        });
        it("Symbol is correct", async()=>{
            const result = await slETH.symbol();
            result.should.equal(symbol);
        });
        it("Decimal is correct", async()=>{
            const result = await slETH.decimals();
            result.toString().should.equal(decimals);
        });
        it('assign total supply to the depolyer', async()=>{
            const result = await slETH._balances(deployer)
            result.toString().should.equal(totalSupply.toString())
        })
    });
    describe('sending tokens', ()=>{
        let amount
        let result

        describe('success', async()=>{
            beforeEach(async()=>{
                amount=tokens(100000)
                result = await slETH.transfer(user1, amount, {from: deployer})
            })
            it('transfer token balances', async()=>{
                let balanceOf
                balanceOf = await slETH.balanceOf(deployer)
                balanceOf.toString().should.equal(tokens(900000).toString())
                balanceOf = await slETH.balanceOf(user1)
                balanceOf.toString().should.equal(tokens(100000).toString())
            })
        })
        describe('failure', async()=>{
            it('rejects insufficent balances', async()=>{
                const invalidAamount = 10000000000000000000000000; //100million
                await slETH.transfer(user2, invalidAamount,{from:deployer}).should.be.rejectedWith(EVM_REVERT);
                })
            it('rejects invalid recipients', async()=>{
                await slETH.transfer(0x0, tokens(1000000),{from:user1}).should.be.rejected;
            })
        })
    })
    describe('Approving tokens', ()=>{
        let result
        let amount

        beforeEach(async()=>{
            amount = tokens(100)
            result = await slETH.approve(user1, amount, {from:deployer})
        })
        describe ('success', ()=>{
            it('allocates an allowance for delegated token', async()=>{
                const allowance = await slETH.allowance(deployer,user1)
                allowance.toString().should.equal(amount.toString())
            })
        })

        describe ('failure', ()=>{
          it('reject invalid spender', async()=>{
             await slETH.approve(0x0, amount, {from:deployer}).should.be.rejected
          })
        })
    })
    describe('Token transfersFrom', ()=>{
        let amount
        let result
        beforeEach(async()=>{
            amount=tokens(100)
            await slETH.approve(user1, amount, {from: deployer})
        })
        describe('success', async()=>{
            beforeEach(async()=>{
                result = await slETH.transferFrom(deployer, user1, amount, {from: user1})
            })
            it('transfer token balances', async()=>{
                let balanceOf
                balanceOf = await slETH.balanceOf(deployer)
                balanceOf.toString().should.equal(tokens(999900).toString())
                balanceOf = await slETH.balanceOf(user1)
                balanceOf.toString().should.equal(tokens(100).toString())
            })
            it('reset the allowance', async()=>{
                const allowance = await slETH.allowance(deployer,user1)
                allowance.toString().should.equal('0')
            })
        })
        describe('failure', async()=>{
            it('rejects insufficent balances', async()=>{
                //attempt to transfer too many tokens.
                const invalidAmount = 10000000000000000000000000 //greater than total supply -100million
                await slETH.transferFrom(deployer,user2,invalidAmount, {from: user2}).should.be.rejectedWith(EVM_REVERT)
               })
             it('rejects invalid recipients', async()=>{
                await slETH.transferFrom(0x0, amount,{from:user1}).should.be.rejected
            })
        })
    })
})
