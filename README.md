# lightnodecontracts
Node version. Make sure have the latest lts
v16.13.2 (npm v8.1.2)

Run the command: npm install to get started

Hardhat command:
mpx hardhat compile,
npx hardhat test (For testing),
npx hardhat clean (To clean cache)

NodeOperatorRegistry

Node Registry act as validators on the Beacon chain for the benefit of the protocol. We can or DAO can selects node operators and adds their addresses to the NodeOperatorsRegistry contract. Authorized operators have to generate a set of keys for the validation and also provide them with the smart contract. As Ether is received from users, it is distributed in chunks of 32 Ether between all active Node Operators. The contract contains a list of operators, their keys, and the logic for distributing rewards between them. We can deactivate misbehaving operators when reported.

Oracle

Oracle is a contract where oracles send addresses' balances controlled on the ETH 2.0 side. Reward accumulation and can go down due to slashing and staking penalties. Oracles are assigned by the devs or DAO.

Staking

Staking contract is in the iteration 1. This contract will be the contract that the user will interact with to deposit the ETH 1.0. This contract will accumlate the eth and then be called by oracle to post to ETH 2.0. This contract will be SLeth as well. As you can see SlETH is the erc20 token repersenting the token in return. 

SLETH

SLETH is somewhat a typical ERC20 and an abstarct contract. Let's say user deposit the 1 ETH to the staking contract, in return user will recieve 1 SLETH given ETH:SLETH maintaining 1:1 ratio. If user swap their SLETH back to ETH, SLETH in swapping scenarion will get burn. We would also need to update the Node operator and oracle with user's updated amount. 

Current to do:

-As mentioned above staking contract is iteration 1, there are still few functions that needs to be added. Function to push beacon. 

-We also need to pegged SLETH to ETH. Currently Lido failed to manage this pegged. More fresearch need in this case.

More things need to be added as devs go.
