export const lawContracts = [
  {
    contract: "AgDao", 
    description: "description of law here", 
    address: "0x94Fff4779b8Cb2Ef0f8ec56A299DE77337AC6Ad7",
    accessRoleId: 4n
  }, 
  {
    contract: "AgCoins", 
    description: "description of law here",
    address: "0x747cFCBD2ED3b9B8957565923646AF5A052061f1",
    accessRoleId: 4n
  }, 
  {
    contract: "Public_assignRole", 
    description: "Anyone can request a member role",
    address: "0xfb87dB1576054C5C632dF4B87802E850F824B3f2",
    accessRoleId: 4n
  }, 
  {
    contract: "Senior_assignRole", 
    description: "Propose to assign a senior role",
    address: "0x2af29163AD35b0343dEe41e8497713DB8a7E718E",
    accessRoleId: 1n
  }, 
  {
    contract: "Senior_revokeRole", 
    description: "Propose to revoke a senior role",
    address: "0xf85e0De9A0A1d55B47D1f8Bbe96452fe97A29552",
    accessRoleId: 1n
  }, 
  {
    contract: "Member_assignWhale", 
    description: "Assign or revoke a whale role",
    address: "0x7F74756788Dd81997Af7B2A4d291E973aD5Dfde0",
    accessRoleId: 3n
  }, 
  {
    contract:  "Whale_proposeLaw", 
    description: "Propose to (de)activate law",
    address: "0xEDEb04270f7c23f80E3a4f6f6Be71Ec23dcDAc1C",
    accessRoleId: 2n
  },
 {
    contract: "Senior_acceptProposedLaw", 
    description: "Accept to (de)activate law",
    address: "0xc3a6f9573f4Db4b60cbD9Ef66d67669eC9Ab55E2",
    accessRoleId: 1n
  },
 {
    contract: "Admin_setLaw", 
    description: "Implement the (de)activation of a law",
    address: "0xa87697369C1C707E57DfF642D8f7308b6050b39f",
    accessRoleId: 0n
  },
 {
    contract: "Member_proposeCoreValue", 
    description: "Propose Core Value",
    address: "0x49D0dDc72F33621E3956cD4Fc51E812427D1052e",
    accessRoleId: 3n
  },
 {
    contract: "Whale_acceptCoreValue", 
    description: "Accept core value",
    address: "0x940b3009Cc6B5E847766d47b88bF0809D14caB3a",
    accessRoleId: 2n
  },
 {
    contract: "Whale_revokeMember", 
    description: "Revoke a member role",
    address: "0x81a54AdF57C6e74200E3d53C44BB2880D743C51E",
    accessRoleId: 2n
  },
 {
    contract: "Public_challengeRevoke", 
    description: "Challenge a revoke decisions",
    address: "0x634519d3190c450660069F420eeb2B092d29D96a",
    accessRoleId: 4n
  },
 {
    contract: "Senior_reinstateMember", 
    description: "Reinstate a member role",
    address: "0x53ae4CCD9daC82b5D11911B456b3c71838Bf823D",
    accessRoleId: 1n
  },
]