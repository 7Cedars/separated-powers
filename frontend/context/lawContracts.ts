export const lawContracts = [
  {
    contract: "AgDao", 
    description: "description of law here", 
    address: "0x65E5D71a1CB97A79b99AaeffD85C8cd7851a6dcc",
    accessRoleId: 4n
  }, 
  {
    contract: "AgCoins", 
    description: "description of law here",
    address: "0xe9D450BBcE3f1c4524FcAC0190C9F75b6c67833B",
    accessRoleId: 4n
  }, 
  {
    contract: "Public_assignRole", 
    description: "description of law here",
    address: "0xeE14631377c5F6eA1E7D7c6E8fC0E0Bc1a6B4510",
    accessRoleId: 4n
  }, 
  {
    contract: "Senior_assignRole", 
    description: "description of law here",
    address: "0x8b36Df588203fbC2Ebd23B89e8f4D14d490F41A1",
    accessRoleId: 1n
  }, 
  {
    contract: "Senior_revokeRole", 
    description: "description of law here",
    address: "0x22014CE40508CC070c2bF2b2D75E5fC51bFDF960",
    accessRoleId: 1n
  }, 
  {
    contract: "Member_assignWhale", 
    description: "description of law here",
    address: "0x506b07016EC69a21063496E478bCB5D6e3567B8F",
    accessRoleId: 3n
  }, 
  {
    contract:  "Whale_proposeLaw", 
    description: "description of law here",
    address: "0x90fb199016cA962B347Cb7D1A3A4b0050f61a775",
    accessRoleId: 2n
  },
 {
    contract: "Senior_acceptProposedLaw", 
    description: "description of law here",
    address: "0x12A100d0F2AE7670DE7F1C3E4B69ee01283488bb",
    accessRoleId: 1n
  },
 {
    contract: "Admin_setLaw", 
    description: "description of law here",
    address: "0x27f5C8aD8d8A8911fbf7fdb8A76D859Fce6A0906",
    accessRoleId: 0n
  },
 {
    contract: "Member_proposeCoreValue", 
    description: "Propose Core Value",
    address: "0x2fc25E90Fb26289575DCa2a4308c4166Ba8c7c13",
    accessRoleId: 3n
  },
 {
    contract: "Whale_acceptCoreValue", 
    description: "description of law here",
    address: "0x1545EFE993D1022b0b05382dB657170Ab4b4001A",
    accessRoleId: 2n
  },
 {
    contract: "Whale_revokeMember", 
    description: "description of law here",
    address: "0x4F6158CEB0120791DEB1816b0F778Ec731266B41",
    accessRoleId: 2n
  },
 {
    contract: "Public_challengeRevoke", 
    description: "description of law here",
    address: "0x6A3A88c3683a0c489A29F1AD6C1E8aF1b34E793a",
    accessRoleId: 4n
  },
 {
    contract: "Senior_reinstateMember", 
    description: "description of law here",
    address: "0x10745151DA767dc97487Fc9d0F715248c0402f2d",
    accessRoleId: 1n
  },
]

// [2374496] → new AgDao: 0x65E5D71a1CB97A79b99AaeffD85C8cd7851a6dcc
//     ├─ emit RoleSet(roleId: 0, account: 0x328735d26e5Ada93610F0006c32abE2278c46211, accessChanged: true)
//     ├─ emit SeparatedPowers__Initialized(contractAddress: AgDao: [0x65E5D71a1CB97A79b99AaeffD85C8cd7851a6dcc])
//     └─ ← [Return] 11502 bytes of code

//   [483443] → new AgCoins: 0xe9D450BBcE3f1c4524FcAC0190C9F75b6c67833B
//     ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: AgDao: [0x65E5D71a1CB97A79b99AaeffD85C8cd7851a6dcc], value: 57896044618658097711785492504343953926634992332820282019728792003956564819967 [5.789e76])
//     └─ ← [Return] 1956 bytes of code

//   [792685] → new Public_assignRole: 0xeE14631377c5F6eA1E7D7c6E8fC0E0Bc1a6B4510
//     └─ ← [Return] 2938 bytes of code

//   [934584] → new Senior_assignRole: 0x8b36Df588203fbC2Ebd23B89e8f4D14d490F41A1
//     └─ ← [Return] 3538 bytes of code

//   [896496] → new Senior_revokeRole: 0x22014CE40508CC070c2bF2b2D75E5fC51bFDF960
//     └─ ← [Return] 3569 bytes of code

  // [884716] → new Member_assignWhale: 0x506b07016EC69a21063496E478bCB5D6e3567B8F
  //   └─ ← [Return] 3289 bytes of code

  // [771991] → new Whale_proposeLaw: 0x90fb199016cA962B347Cb7D1A3A4b0050f61a775
  //   └─ ← [Return] 3058 bytes of code

  // [829421] → new Senior_acceptProposedLaw: 0x12A100d0F2AE7670DE7F1C3E4B69ee01283488bb
  //   └─ ← [Return] 3245 bytes of code

  // [733830] → new Admin_setLaw: 0x27f5C8aD8d8A8911fbf7fdb8A76D859Fce6A0906
  //   └─ ← [Return] 2989 bytes of code

  // [810927] → new Member_proposeCoreValue: 0x2fc25E90Fb26289575DCa2a4308c4166Ba8c7c13
  //   └─ ← [Return] 3140 bytes of code

  // [931455] → new Whale_acceptCoreValue: 0x1545EFE993D1022b0b05382dB657170Ab4b4001A
  //   └─ ← [Return] 3533 bytes of code

  // [931313] → new Whale_revokeMember: 0x4F6158CEB0120791DEB1816b0F778Ec731266B41
  //   └─ ← [Return] 3743 bytes of code

  // [920014] → new Public_challengeRevoke: 0x6A3A88c3683a0c489A29F1AD6C1E8aF1b34E793a
  //   └─ ← [Return] 3363 bytes of code

  // [965756] → new Senior_reinstateMember: 0x10745151DA767dc97487Fc9d0F715248c0402f2d
  //   └─ ← [Return] 3926 bytes of code