<p align="center">

<br />
<div align="center">
  <a href="https://github.com/7Cedars/separated-powers"> 
    <img src="../public/logo.png" alt="Logo" width="300" height="300">
  </a>

<h2 align="center">Separated Powers </h2>
  <p align="center">
    A protocol providing restricted governance processes for DAOs. 
    <br />
    <br />
    <!--NB: TO DO --> 
    <a href="../README.md">Conceptual overview</a>
    ·
    <a href="#whats-included">What's included</a> ·
    <a href="#prerequisites">Prerequisites</a> ·
    <a href="#getting-started">Getting Started</a>
  </p>
  <br />
  <br />
</div>

## What's included
- A fully functional proof-of-concept of the Separation of Governance protocol. 
- Example laws, showcasing concrete possibilities for structuring DAO governance.
- An example implementation of a DAO building on the Separation of Governance protocol: Aligned Grants DAO, or AgDao.   

### AgDao is deployed on the Arbitrum Sepolia testnet: 
Contracts have not been verified, but can be interacted with through [our bespoke user interface](https://separated-powers.vercel.app/).   

[AgDao](https://sepolia.arbiscan.io/address/0x001A6a16D2fc45248e00351314bCE898B7d8578f) - An example Dao implementation. This Dao aims to fund accounts that are aligned to its core values. <br>
[AgCoins](https://sepolia.arbiscan.io/address/0xC45B6b4013fd888d18F1d94A32bc4af882cDCF86) - A mock coin contract. <br>

#### Laws 
[Public_assignRole](https://sepolia.arbiscan.io/address/0x7Dcbd2DAc6166F77E8e7d4b397EB603f4680794C) - Allows anyone to claim a member role. <br> 
[Senior_assignRole](https://sepolia.arbiscan.io/address/0x420bf9045BFD5449eB12E068AEf31251BEb576b1) - Allows senior to vote in assigning senior role. <br> 
[Senior_revokeRole](https://sepolia.arbiscan.io/address/0x3216EB8D8fF087536835600a7e0B32687744Ef65)- Allows seniors to on revoking a senior role. <br> 
[Member_assignWhale](https://sepolia.arbiscan.io/address/0xbb45079e74399e7238AAF63C764C3CeE7D77712F) - Allows members to asses if account has sufficient tokens to get whale role. <br> 
[Whale_proposeLaw](https://sepolia.arbiscan.io/address/0x0Ea769CD03D6159088F14D3b23bF50702b5d4363) - Allows whales to propose a law. <br> 
[Senior_acceptProposedLaw](https://sepolia.arbiscan.io/address/0xa2c0C9d9762c51DA258d008C92575A158121c87d) - Allows seniors to accept a proposed law. <br> 
[Admin_setLaw](https://sepolia.arbiscan.io/address/0xfb7291B8FbA99C9FC29E95797914777562983D71) - Allows admin to implement a proposed law. <br> 
[Member_proposeCoreValue](https://sepolia.arbiscan.io/address/0x8383547475d9ade41cE23D9Aa4D81E85D1eAdeBD) - Allows member to propose a core value. <br> 
[Whale_acceptCoreValue](https://sepolia.arbiscan.io/address/0xBfa0747E3AC40c628352ff65a1254cC08f1957Aa) - Allows a whale to accept a proposed value as core requirement for funding accounts. <br> 
[Whale_revokeMember](https://sepolia.arbiscan.io/address/0x71504Ced3199f8a0B32EaBf4C274D1ddD87Ecc4d) - Allows  whale to revoke and blacklist a member for funding non-aligned accounts. <br> 
[Public_challengeRevoke](https://sepolia.arbiscan.io/address/0x0735199AeDba32A4E1BaF963A3C5C1D2930BdfFd)- Allows a revoked member to challenge the revoke decision. <br> 
[Senior_reinstateMember](https://sepolia.arbiscan.io/address/0x57C9a89c8550fAf69Ab86a9A4e5c96BcBC270af9) - Allows seniors to accept a challenge and reinstate a member. <br> 

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
│    │    │    ├── Admin_setLaw.sol             # See description of laws above. 
│    │    │    ├── Member_assignRole.sol        # 
│    │    │    ├── Member_challengeRevoke.sol   #  
│    │    │    ├── Member_proposeCoreValue.sol  #  
│    │    │    ├── Senior_acceptProposedLaw.sol #  
│    │    │    └── ...   
│    │    ├── AgCoins.sol                       #  
│    │    └── AgDao.sol                         # Deploys the AgDao example implementation of SeparatedPowers. Also deploys laws that make up AgDao's governance.  
│    ├── interfaces                             # Interfaces of the protocol. 
│    │    ├── IAuthoritiesManager.sol           #  
│    │    ├── ILaw.sol                          #  
│    │    ├── ILawsManager.sol                  #  
│    │    └── ISeparatedPowers.sol              # Deploys the AgDao example implementation of SeparatedPowers. Also deploys laws that make up AgDao's governance. 
│    ├── AuthoritiesManager.sol                 # Manages roles and voting in the protocol.  
│    ├── Law.sol                                # Base implementation of a Law. Needs to be inherited by law implementations. 
│    ├── LawsManager.sol                        # Manages the activation (whitelisting) and deactivation of laws. 
│    └── SeparatedPowers.sol                    # The core protocol. Inherits LawsManager.sol and AuthoritiesManager.sol
|
├── test                                        # Tests 
│    ├── fuzz/implementation                    # Fuzz tests on example implementation
│    │    └── SettingLaw_fuzz.t.t.sol           # 
│    └── unit                                   # Unit tests
│         ├── implementation                    # Tests on example implementation 
|         │      ├── AgDaoTest.t.sol            #
|         │      ├── DeployAgDaoTest.t.sol      #         
|         │      └── Whale_assignRoleTest.t.sol #  
|         ├── AuthoritiesManagerTest.t.sol      # Tests of core protocol. 
│         ├── LawTest.t.sol                     #
│         ├── LawsManagerTest.t.sol             # 
│         └── SeparatedPowersTest.t.sol         #         
|        
├── .env.example                   
├── foundry.toml                   
├── LICENSE                                     # MIT license 
├── README.md                                   # This file
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
     



