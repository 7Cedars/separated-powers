export const lawContracts = [
  {
    contract: "AgDao", 
    description: "description of law here", 
    address: "0x58ed88cC6A21F809102F3Bdf57341de58177B16C",
    accessRoleId: 4n
  }, 
  {
    contract: "AgCoins", 
    description: "description of law here",
    address: "0xfe26d04937e06FF591Be62657B23784b089F816D",
    accessRoleId: 4n
  }, 
  {
    contract: "Public_assignRole", 
    description: "Anyone can request a member role",
    address: "0xFEd4a76A4294742429E1f9CB9430CBa66d45121C",
    accessRoleId: 4n
  }, 
  {
    contract: "Senior_assignRole", 
    description: "Propose to assign a senior role",
    address: "0x0073AEAD6AB1e82498A15300a36a0d95F5BE8Ee1",
    accessRoleId: 1n
  }, 
  {
    contract: "Senior_revokeRole", 
    description: "Propose to revoke a senior role",
    address: "0xaAEbc84F53c464A58576B6697a2B13073E22A5fE",
    accessRoleId: 1n
  }, 
  {
    contract: "Member_assignWhale", 
    description: "Assign or revoke a whale role",
    address: "0xEE159fe9cD4CB4596E9dD977035b4Afa7fe202CD",
    accessRoleId: 3n
  }, 
  {
    contract:  "Whale_proposeLaw", 
    description: "Propose to (de)activate law",
    address: "0x06E18077Bb24Ab20A365Fe3E0B3F3a9c48E502Fe",
    accessRoleId: 2n
  },
 {
    contract: "Senior_acceptProposedLaw", 
    description: "Accept to (de)activate law",
    address: "0x48725664e7607a4216C3F6dcdcB9f852f8144E58",
    accessRoleId: 1n
  },
 {
    contract: "Admin_setLaw", 
    description: "Implement the (de)activation of a law",
    address: "0xACEe308a942B3493B794638E433717ECfBCaaA85",
    accessRoleId: 0n
  },
 {
    contract: "Member_proposeCoreValue", 
    description: "Propose Core Value",
    address: "0x8E6090edE6c2F9C9F9bBCb75fbE37EBda5238B3c",
    accessRoleId: 3n
  },
 {
    contract: "Whale_acceptCoreValue", 
    description: "Accept core value",
    address: "0x6e0c3Bcf6f7845FCE2fF95a041295CDa7828AB3B",
    accessRoleId: 2n
  },
 {
    contract: "Whale_revokeMember", 
    description: "Revoke a member role",
    address: "0xDe53517CE791202bA3d3362B6b2F95710838310C",
    accessRoleId: 2n
  },
 {
    contract: "Public_challengeRevoke", 
    description: "Challenge a revoke decisions",
    address: "0x41d79A3E7268fD4cB69bC612706e5aE6CabcB79c",
    accessRoleId: 4n
  },
 {
    contract: "Senior_reinstateMember", 
    description: "Reinstate a member role",
    address: "0x87050ba7f4c38A23b97e693FaD6fE51D0e86557B",
    accessRoleId: 1n
  },
]