const slEth = artifacts.require("SLETH");
const stakingETh = artifacts.require("Staking");

module.exports = async function(depolyer){
    const accounts = await web3.eth.getAccounts();
    const owner = accounts[1]
    const devAccount = accounts[2];
    const tokenAccount = accounts[3];
    const SlEth = await depolyer.deploy(slEth, tokenAccount);
    await depolyer.deploy(stakingETh, owner, devAccount, SlEth.address);

};