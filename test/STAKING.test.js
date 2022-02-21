const Token = artifacts.require("./SLETH");
const Staking = artifacts.require("./Staking");
require('chai').use(require('chai-as-promised')).should();

const ether =(n)=>{
    return new web3.utils.BN(
       web3.utils.toWei(n.toString(), 'ether')
    );
};
//const tokens = (n)=> ether(n);

contract ('Staking ETH', ([deployer, owner, devAddress, tokenAccount, user1, user2, user3])=>{
    const feesPercentage = '75';
    let EthStake;
    let slETH;
    let ETHERAddress='0x0000000000000000000000000000000000000000';
    beforeEach(async()=>{
        slETH = await Token.new(tokenAccount);
        EthStake = await Staking.new(owner, devAddress, slETH.address);
    }) 

    describe('Checking staking contract variables', ()=>{
        it('gas fee', async()=>{
            const result = await EthStake.fee();
            result.toString().should.equal(feesPercentage.toString());
        })
        it('Ether address', async()=>{
            const result = await EthStake.ETHER();
            console.log(`Ether address should be 0x0: ${result}`);
        })
    })
    describe('Ether deposit', ()=>{
        let amount;
        let balance;
        beforeEach(async()=>{
            amount = ether(1);
            await EthStake.stakeETHER({from:user1, value:amount});
            //amount = ether(0);
            //await EthStake.stakeETHER({from:user2, value:ether(0)}).should.be.rejectedWith('invalid number value');
        })
        it('Track ether', async()=>{
            balance = await EthStake.stakingBalance(ETHERAddress, user1);
            balance.toString().should.equal(amount.toString());
            amount = ether(0);
            balance = await EthStake.stakingBalance(ETHERAddress, user2);
            //user2 balance should be zero.
            console.log('User2 balance should be 0: ' + balance)
            balance.toString().should.equal(amount.toString());
        })
        it('tracking sLETH', async()=>{
            amount = ether(1);
            balance = await slETH._balances(user1);
            balance.toString().should.equal(amount.toString());
            balance = await slETH._balances(user2);
            amount = ether(0);
            balance.toString().should.equal(amount.toString());
        })
    })
    describe('Tracking rewards', async()=>{
        let amount;
        let balance;
        let balacneInEth;
        beforeEach(async()=>{
            amount = ether(1);
            await EthStake.stakeETHER({from:user1, value:amount});
            amount = ether(10);
            await EthStake.stakeETHER({from:user2, value:amount});
            amount = ether(15);
            await EthStake.stakeETHER({from:user3, value:amount});
            amount = ether(100);
            await EthStake.setReward(amount, {from:owner});
        })

        it('Total reward in same epoch', async()=>{
            balance = await EthStake.totalReward();
            balacneInEth = balance/1e18;
            console.log(`Total reward in this EPOCh: ${balacneInEth}`);
        })

        it('Users rewards', async()=>{
            //user1 rewards
            let bool = await EthStake.isStaking(user1);
            console.log(`User1 staking staus: ${bool}`);
            await EthStake.calculateRewards(user1);
            //await EthStake.claimReward({from:user1})
            balance = await EthStake.rewardBalance(user1);
            balacneInEth = balance/1e18;
            console.log(`User1 reward in this EPOCh: ${balacneInEth}`);
            //user2 rewards
            bool = await EthStake.isStaking(user2);
            console.log(`User2 staking staus: ${bool}`);
            await EthStake.calculateRewards(user2);
            balance = await EthStake.rewardBalance(user2);
            balacneInEth = balance/1e18;
            console.log(`User2 reward in this EPOCh: ${balacneInEth}`);
            //user3 rewards
            bool = await EthStake.isStaking(user3);
            console.log(`User3 staking staus: ${bool}`);
            await EthStake.calculateRewards(user3);
            balance = await EthStake.rewardBalance(user3);
            balacneInEth = balance/1e18;
            console.log(`Uer3 reward in this EPOCh: ${balacneInEth}`);
            balance = await EthStake.rewardFee();
            balacneInEth = balance/1e18;
            console.log(`Uer3 reward in this EPOCh: ${balacneInEth}`);
        })
    })
})
//2775000000000000000