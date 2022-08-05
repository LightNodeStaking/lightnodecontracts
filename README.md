# LightNode Ethereum Staking Protocol

Built on Ethereum, LightNode is a network of smart contracts that facilitate user deposits to the pool and track blockchain rewards.
LightNode’s staking technology tokenizes staked ether in the form of slETH ("staked Ether") and accrues rewards based on the amount of Ethereum staked.
Additionally, there will be wrapper protocols in place to allow users the use of a static, yield generating token with DeFi protocols. Since slETH is a 1:1 peg of Ether, it can be redeemed for the value they represent after Phase 2 of Ethereum 2.0.

## Contracts

#### LightNode

LightNode is the core contract which acts as a liquid staking pool. The contract is responsible for Ether deposits and withdrawals, minting and burning liquid tokens, delegating funds to node operators, applying fees, and accepting updates from the oracle contract.

LightNode also acts as an ERC20 token which represents staked ether, slETH. Tokens are minted upon deposit and burned when redeemed. slETH tokens are pegged 1:1 to the Ethers that are held by LightNode. slETH token’s balances are updated when the oracle reports change in total stake every day.

#### NodeOperatorRegistry

Node Registry act as validators on the Beacon chain for the benefit of the protocol. We can or DAO can selects node operators and adds their addresses to the NodeOperatorsRegistry contract. Authorized operators have to generate a set of keys for the validation and also provide them with the smart contract. As Ether is received from users, it is distributed in chunks of 32 Ether between all active Node Operators. The contract contains a list of operators, their keys, and the logic for distributing rewards between them. We can deactivate misbehaving operators when reported.

#### Oracle

Oracle is a contract where oracles send addresses' balances controlled on the ETH 2.0 side. Reward accumulation and can go down due to slashing and staking penalties. Oracles are assigned by the devs or DAO.

#### slETH

SLETH is somewhat a typical ERC20 and an abstarct contract. Let's say user deposit the 1 ETH to the staking contract, in return user will recieve 1 SLETH given ETH:SLETH maintaining 1:1 ratio. If user swap their SLETH back to ETH, SLETH in swapping scenarion will get burn. We would also need to update the Node operator and oracle with user's updated amount. 

## Deployments

### Görli testnet
* LightNode and slETH token: [`0x07b39f4fde4a38bace212b546dac87c58dfe3fdc`](https://goerli.etherscan.io/address/0x07b39f4fde4a38bace212b546dac87c58dfe3fdc)
* Node Operators registry: [`0x9962eE09d104B338f97F07Ab32F579a94e174025`](https://goerli.etherscan.io/address/0x9962eE09d104B338f97F07Ab32F579a94e174025)
* Oracle: [`0x9a5FdF8146467d70634fc48bEF67dD14B5A08757`](https://goerli.etherscan.io/address/0x9a5FdF8146467d70634fc48bEF67dD14B5A08757)
* WslETH token: [`0x9ACE9542FC7758C0287a61340d3d2280561da5BB`](https://goerli.etherscan.io/address/0x9ACE9542FC7758C0287a61340d3d2280561da5BB)
* Deposit Security Module: [`0x7431e1BFDaD7732B6D0Fc6eE93539b192bc3d125`](https://goerli.etherscan.io/address/0x7431e1BFDaD7732B6D0Fc6eE93539b192bc3d125)
