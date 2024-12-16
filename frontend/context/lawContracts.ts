export const lawContracts = [
  {
    contract: "AgDao", 
    description: "description of law here", 
    address: "0x001A6a16D2fc45248e00351314bCE898B7d8578f",
    accessRoleId: 4n
  }, 
  {
    contract: "AgCoins", 
    description: "description of law here",
    address: "0xC45B6b4013fd888d18F1d94A32bc4af882cDCF86",
    accessRoleId: 4n
  }, 
  {
    contract: "Public_assignRole", 
    description: "Anyone can request a member role",
    address: "0x7Dcbd2DAc6166F77E8e7d4b397EB603f4680794C",
    accessRoleId: 4n
  }, 
  {
    contract: "Senior_assignRole", 
    description: "Propose to assign a senior role",
    address: "0x420bf9045BFD5449eB12E068AEf31251BEb576b1",
    accessRoleId: 1n
  }, 
  {
    contract: "Senior_revokeRole", 
    description: "Propose to revoke a senior role",
    address: "0x3216EB8D8fF087536835600a7e0B32687744Ef65",
    accessRoleId: 1n
  }, 
  {
    contract: "Member_assignWhale", 
    description: "Assign or revoke a whale role",
    address: "0xbb45079e74399e7238AAF63C764C3CeE7D77712F",
    accessRoleId: 3n
  }, 
  {
    contract:  "Whale_proposeLaw", 
    description: "Propose to (de)activate law",
    address: "0x0Ea769CD03D6159088F14D3b23bF50702b5d4363",
    accessRoleId: 2n
  },
 {
    contract: "Senior_acceptProposedLaw", 
    description: "Accept to (de)activate law",
    address: "0xa2c0C9d9762c51DA258d008C92575A158121c87d",
    accessRoleId: 1n
  },
 {
    contract: "Admin_setLaw", 
    description: "Implement the (de)activation of a law",
    address: "0xfb7291B8FbA99C9FC29E95797914777562983D71",
    accessRoleId: 0n
  },
 {
    contract: "Member_proposeCoreValue", 
    description: "Propose Core Value",
    address: "0x8383547475d9ade41cE23D9Aa4D81E85D1eAdeBD",
    accessRoleId: 3n
  },
 {
    contract: "Whale_acceptCoreValue", 
    description: "Accept core value",
    address: "0xBfa0747E3AC40c628352ff65a1254cC08f1957Aa",
    accessRoleId: 2n
  },
 {
    contract: "Whale_revokeMember", 
    description: "Revoke a member role",
    address: "0x71504Ced3199f8a0B32EaBf4C274D1ddD87Ecc4d",
    accessRoleId: 2n
  },
 {
    contract: "Public_challengeRevoke", 
    description: "Challenge a revoke decisions",
    address: "0x0735199AeDba32A4E1BaF963A3C5C1D2930BdfFd",
    accessRoleId: 4n
  },
 {
    contract: "Senior_reinstateMember", 
    description: "Reinstate a member role",
    address: "0x57C9a89c8550fAf69Ab86a9A4e5c96BcBC270af9",
    accessRoleId: 1n
  },
]