<p align="center">
  
  <h1 align="center"><b>Separated Powers - Solidity Protocol</b></h1>
<p align="center">
    <br />
    <br />
    <a href="#whats-included"><strong>What's included</strong></a> ·
    <a href="#prerequisites"><strong>Prerequisites</strong></a> ·
    <a href="#getting-started"><strong>Getting Started</strong></a> ·
  </p>
</p>

A protocol providing restricted governance processes for DAOs. 

## What's included

### Deployed @L2 Arbitrum Sepolia testnet: 
Currently the Arbitrum Sepolia testnet does not verify the contracts. This will be resolved asap.  

### Deployed @L2 Optimism Sepolia testnet: 
[AgDao](https://sepolia-optimism.etherscan.io/address/0x74A35C97DDD491561f9f528949102f18c5F80A48#code) - An example Dao implementation. <br>
[AgCoins](https://sepolia-optimism.etherscan.io/address/0x57ae5c4e22DF5C9781D3797e06008254a2EcA620#code) - A mock coin contract. <br>

#### Laws 
[Admin_setLaw](https://sepolia-optimism.etherscan.io/address/0x8A197D9088bC6c18A7D5815F71f44d6B2F516aaf#code) - A law that ... (description here) <br> 

[Member_assignRole](https://sepolia-optimism.etherscan.io/address/0x64cB61143913e5dEE986dAB30243c8CA54871a84#code) - A law that ... (description here) <br> 
[Member_proposeCoreValue](https://sepolia-optimism.etherscan.io/address/0x452Bc038be0586b67D5c26390D3b3286356d2c73#code)- A law that ... (description here) <br> 
[Member_challengeRevoke](https://sepolia-optimism.etherscan.io/address/0xf3cEd188d6BaFAF553B2f8CddDBC1400F6bbc6d7#code) - A law that ... (description here) <br> 

[Whale_assignRole](https://sepolia-optimism.etherscan.io/address/0x56Cb2F59B79D6a9703D7B3B0094BF0950C0c05d3#code) - A law that ... (description here) <br> 
[Whale_acceptCoreValue](https://sepolia-optimism.etherscan.io/address/0x99Ac9cC3A515A25e7509Fd59b7f5eAdccFFe1542#code) - A law that ... (description here) <br> 
[Whale_revokeMember](https://sepolia-optimism.etherscan.io/address/0x27f0E2031eAE1f04f9442f297e82669fB43B9d5b#code) - A law that ... (description here) <br> 
[Whale_proposeLaw](https://sepolia-optimism.etherscan.io/address/0xB63cdCc2d207AC6bd5bdB50113c392b95472360d#code) - A law that ... (description here) <br> 

[Senior_assignRole](https://sepolia-optimism.etherscan.io/address/0xAad0b239e00486Ca8DbE3017e49cADa8A5a747Ea#code) - A law that ... (description here) <br> 
[Senior_revokeRole](https://sepolia-optimism.etherscan.io/address/0x81db76351F1A94142e85c6F0Cb38743D7f6D0C26#code) - A law that ... (description here) <br> 
[Senior_reinstateMember](https://sepolia-optimism.etherscan.io/address/0xd750e239DCb3acf076819B44EE55F0B0310Ff660#code)- A law that ... (description here) <br> 
[Senior_acceptProposedLaw](https://sepolia-optimism.etherscan.io/address/0x92E3FbBf1839BA0265Fe704B1B9FfB7c63E95Ce9#code) - A law that ... (description here) <br> 


## Directory Structure

```
.
├── lib                                         # Installed dependencies. 
│    ├── forge-std                              # Forge  
│    └── openZeppelin-contracts                 # openZeppelin contracts  
|
├── script                                      # Deployment scripts
│    ├── ConstituteAgDao.s.sol                  #  
│    └── DeployAgDao.s.sol                      # Deploys the AgDao example implementation of SeparatedPowers. Also deploys laws that make up AgDao's governance. 
|
├── src                                         # Protocol resources
│    ├── implementation                         # AgDao example resources.
│    │    ├── laws                              # 
│    │    │    ├── Admin_setLaw.sol             # 
│    │    │    ├── Member_assignRole.sol        # 
│    │    │    ├── Member_challengeRevoke.sol   #  
│    │    │    ├── Member_proposeCoreValue.sol  #  
│    │    │    ├── Senior_acceptProposedLaw.sol #  
│    │    │    └── ...   
│    │    ├── AgCoins.sol                       #  
│    │    └── AgDao.sol                         # Deploys the AgDao example implementation of SeparatedPowers. Also deploys laws that make up AgDao's governance.  
│    ├── interfaces                             # interfaces of the protocol. 
│    │    ├── IAuthoritiesManager.sol           #  
│    │    ├── ILaw.sol                          #  
│    │    ├── ILawsManager.sol                  #  
│    │    └── ISeparatedPowers.sol              # Deploys the AgDao example implementation of SeparatedPowers. Also deploys laws that make up AgDao's governance. 
│    ├── AuthoritiesManager.sol                 # 
│    ├── Law.sol                                #
│    ├── LawsManager.sol                        # 
│    └── SeparatedPowers.sol                    # 
|
├── test                                        # Tests 
│    ├── fuzz/implementation                    # Fuzz tests on example implementation
│    │    └── SettingLaw_fuzz.t.t.sol           # Fuzz test of games, card dispenser and tournament logic. 
│    └── unit                                   # Unit tests
│         ├── implementation                    # AgDao example resources.
|         │      ├── AgDaoTest.t.sol            #
|         │      ├── DeployAgDaoTest.t.sol      #         
|         │      └── Whale_assignRoleTest.t.sol #  
|         ├── AuthoritiesManagerTest.t.sol      # 
│         ├── LawTest.t.sol                     #
│         ├── LawsManagerTest.t.sol             # 
│         └── SeparatedPowersTest.t.sol         #         
|        
├── .env.example                   
├── foundry.toml                   
├── LICENSE
├── README.md
├── Makefile.md                         # Commands to deploy contracts on mainnet sepolia and optimism sepolia.  
├── remappings.txt
└── ...


```

## Prerequisites

Foundry<br>

## Getting Started

1. Clone this repo locally and move to the solidity folder:

```sh
git clone https://github.com/7Cedars/separated-powers
cd separated-powers/solidity 
```

2. Copy `.env.example` to `.env` and update the variables.

```sh
cp env.example .env
```

3. run make. This will install all dependencies and run the tests. 

```sh
make
```

4. Run the tests without installing packages: 

```sh
forge test 
```
     



