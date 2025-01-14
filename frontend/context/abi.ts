import { Abi } from "viem"

// import separatedPowers from "../../solidity/out/SeparatedPowers.sol/SeparatedPowers.json"
// import law from "../../solidity/out/Law.sol/Law.json"

// export const separatedPowersAbi: Abi = JSON.parse(JSON.stringify(separatedPowers.abi)) 
// export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 

export const separatedPowersAbi: Abi = [
  {
    "type": "constructor",
    "inputs": [
      { "name": "name_", "type": "string", "internalType": "string" },
      { "name": "uri_", "type": "string", "internalType": "string" }
    ],
    "stateMutability": "nonpayable"
  },
  { "type": "receive", "stateMutability": "payable" },
  {
    "type": "function",
    "name": "ADMIN_ROLE",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PUBLIC_ROLE",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "adoptLaw",
    "inputs": [
      { "name": "law", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "assignRole",
    "inputs": [
      { "name": "roleId", "type": "uint32", "internalType": "uint32" },
      { "name": "account", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "canCallLaw",
    "inputs": [
      { "name": "caller", "type": "address", "internalType": "address" },
      { "name": "targetLaw", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "cancel",
    "inputs": [
      { "name": "targetLaw", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      {
        "name": "descriptionHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "castVote",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" },
      { "name": "support", "type": "uint8", "internalType": "uint8" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "castVoteWithReason",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" },
      { "name": "support", "type": "uint8", "internalType": "uint8" },
      { "name": "reason", "type": "string", "internalType": "string" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "constitute",
    "inputs": [
      {
        "name": "constituentLaws",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "eip712Domain",
    "inputs": [],
    "outputs": [
      { "name": "fields", "type": "bytes1", "internalType": "bytes1" },
      { "name": "name", "type": "string", "internalType": "string" },
      { "name": "version", "type": "string", "internalType": "string" },
      { "name": "chainId", "type": "uint256", "internalType": "uint256" },
      {
        "name": "verifyingContract",
        "type": "address",
        "internalType": "address"
      },
      { "name": "salt", "type": "bytes32", "internalType": "bytes32" },
      {
        "name": "extensions",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "execute",
    "inputs": [
      { "name": "targetLaw", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      { "name": "description", "type": "string", "internalType": "string" }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getActiveLaw",
    "inputs": [
      { "name": "law", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "active", "type": "bool", "internalType": "bool" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getAmountRoleHolders",
    "inputs": [
      { "name": "roleId", "type": "uint32", "internalType": "uint32" }
    ],
    "outputs": [
      {
        "name": "amountMembers",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getProposalVotes",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [
      {
        "name": "againstVotes",
        "type": "uint256",
        "internalType": "uint256"
      },
      { "name": "forVotes", "type": "uint256", "internalType": "uint256" },
      { "name": "abstainVotes", "type": "uint256", "internalType": "uint256" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hasRoleSince",
    "inputs": [
      { "name": "account", "type": "address", "internalType": "address" },
      { "name": "roleId", "type": "uint32", "internalType": "uint32" }
    ],
    "outputs": [
      { "name": "since", "type": "uint48", "internalType": "uint48" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hasVoted",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" },
      { "name": "account", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hashProposal",
    "inputs": [
      { "name": "targetLaw", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      {
        "name": "descriptionHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "laws",
    "inputs": [
      { "name": "lawAddress", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "active", "type": "bool", "internalType": "bool" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "name",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "onERC1155BatchReceived",
    "inputs": [
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "uint256[]", "internalType": "uint256[]" },
      { "name": "", "type": "uint256[]", "internalType": "uint256[]" },
      { "name": "", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "onERC1155Received",
    "inputs": [
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "uint256", "internalType": "uint256" },
      { "name": "", "type": "uint256", "internalType": "uint256" },
      { "name": "", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "onERC721Received",
    "inputs": [
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "uint256", "internalType": "uint256" },
      { "name": "", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "proposalDeadline",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "propose",
    "inputs": [
      { "name": "targetLaw", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      { "name": "description", "type": "string", "internalType": "string" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "revokeLaw",
    "inputs": [
      { "name": "law", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "revokeRole",
    "inputs": [
      { "name": "roleId", "type": "uint32", "internalType": "uint32" },
      { "name": "account", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "roles",
    "inputs": [
      { "name": "roleId", "type": "uint32", "internalType": "uint32" }
    ],
    "outputs": [
      {
        "name": "amountMembers",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setUri",
    "inputs": [
      { "name": "newUri", "type": "string", "internalType": "string" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "state",
    "inputs": [
      { "name": "proposalId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "enum SeparatedPowersTypes.ProposalState"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "uri",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "version",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "pure"
  },
  {
    "type": "event",
    "name": "EIP712DomainChanged",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "FundsReceived",
    "inputs": [
      {
        "name": "value",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "LawAdopted",
    "inputs": [
      {
        "name": "law",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "LawRevoked",
    "inputs": [
      {
        "name": "law",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProposalCancelled",
    "inputs": [
      {
        "name": "proposalId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProposalCompleted",
    "inputs": [
      {
        "name": "initiator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "targetLaw",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "lawCalldata",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "descriptionHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProposalCreated",
    "inputs": [
      {
        "name": "proposalId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "initiator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "targetLaw",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "signature",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "executeCalldata",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "voteStart",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "voteEnd",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "description",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProposalExecuted",
    "inputs": [
      {
        "name": "targets",
        "type": "address[]",
        "indexed": false,
        "internalType": "address[]"
      },
      {
        "name": "values",
        "type": "uint256[]",
        "indexed": false,
        "internalType": "uint256[]"
      },
      {
        "name": "calldatas",
        "type": "bytes[]",
        "indexed": false,
        "internalType": "bytes[]"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RoleSet",
    "inputs": [
      {
        "name": "roleId",
        "type": "uint48",
        "indexed": true,
        "internalType": "uint48"
      },
      {
        "name": "account",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "access",
        "type": "bool",
        "indexed": true,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "SeparatedPowers__Initialized",
    "inputs": [
      {
        "name": "contractAddress",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "name",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "VoteCast",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "proposalId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "support",
        "type": "uint8",
        "indexed": true,
        "internalType": "uint8"
      },
      {
        "name": "reason",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  { "type": "error", "name": "FailedCall", "inputs": [] },
  { "type": "error", "name": "InvalidShortString", "inputs": [] },
  { "type": "error", "name": "SeparatedPowers__AccessDenied", "inputs": [] },
  {
    "type": "error",
    "name": "SeparatedPowers__AlreadyCastVote",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__CancelCallNotFromActiveLaw",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__ConstitutionAlreadyExecuted",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__IncorrectInterface",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__InvalidCallData",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__InvalidProposalId",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__InvalidVoteType",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__LawAlreadyActive",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__LawDidNotPassChecks",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__LawDoesNotNeedProposalVote",
    "inputs": []
  },
  { "type": "error", "name": "SeparatedPowers__LawNotActive", "inputs": [] },
  { "type": "error", "name": "SeparatedPowers__NoVoteNeeded", "inputs": [] },
  { "type": "error", "name": "SeparatedPowers__NotActiveLaw", "inputs": [] },
  {
    "type": "error",
    "name": "SeparatedPowers__OnlySeparatedPowers",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__ProposalAlreadyCompleted",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__ProposalCancelled",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__ProposalNotActive",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SeparatedPowers__UnexpectedProposalState",
    "inputs": []
  },
  {
    "type": "error",
    "name": "StringTooLong",
    "inputs": [{ "name": "str", "type": "string", "internalType": "string" }]
  }
]

export const lawAbi: Abi = [
  {
    "type": "constructor",
    "inputs": [
      { "name": "name_", "type": "string", "internalType": "string" },
      { "name": "description_", "type": "string", "internalType": "string" },
      {
        "name": "separatedPowers_",
        "type": "address",
        "internalType": "address"
      },
      { "name": "allowedRole_", "type": "uint32", "internalType": "uint32" },
      {
        "name": "config_",
        "type": "tuple",
        "internalType": "struct ILaw.LawConfig",
        "components": [
          { "name": "quorum", "type": "uint8", "internalType": "uint8" },
          { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
          {
            "name": "votingPeriod",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "needCompleted",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "needNotCompleted",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "delayExecution",
            "type": "uint48",
            "internalType": "uint48"
          },
          {
            "name": "throttleExecution",
            "type": "uint48",
            "internalType": "uint48"
          }
        ]
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "allowedRole",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "config",
    "inputs": [],
    "outputs": [
      { "name": "quorum", "type": "uint8", "internalType": "uint8" },
      { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
      { "name": "votingPeriod", "type": "uint32", "internalType": "uint32" },
      {
        "name": "needCompleted",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "needNotCompleted",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "delayExecution",
        "type": "uint48",
        "internalType": "uint48"
      },
      {
        "name": "throttleExecution",
        "type": "uint48",
        "internalType": "uint48"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "description",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "executeLaw",
    "inputs": [
      { "name": "initiator", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      {
        "name": "descriptionHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      { "name": "targets", "type": "address[]", "internalType": "address[]" },
      { "name": "values", "type": "uint256[]", "internalType": "uint256[]" },
      { "name": "calldatas", "type": "bytes[]", "internalType": "bytes[]" }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "executions",
    "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "outputs": [{ "name": "", "type": "uint48", "internalType": "uint48" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getInputParams",
    "inputs": [],
    "outputs": [
      { "name": "param0", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param1", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param2", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param3", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param4", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param5", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param6", "type": "bytes4", "internalType": "bytes4" },
      { "name": "param7", "type": "bytes4", "internalType": "bytes4" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getStateVars",
    "inputs": [],
    "outputs": [
      { "name": "var0", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var1", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var2", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var3", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var4", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var5", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var6", "type": "bytes4", "internalType": "bytes4" },
      { "name": "var7", "type": "bytes4", "internalType": "bytes4" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "inputParams",
    "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "name",
    "inputs": [],
    "outputs": [
      { "name": "", "type": "bytes32", "internalType": "ShortString" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "separatedPowers",
    "inputs": [],
    "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "simulateLaw",
    "inputs": [
      { "name": "initiator", "type": "address", "internalType": "address" },
      { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
      {
        "name": "descriptionHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      { "name": "targets", "type": "address[]", "internalType": "address[]" },
      { "name": "values", "type": "uint256[]", "internalType": "uint256[]" },
      { "name": "calldatas", "type": "bytes[]", "internalType": "bytes[]" },
      { "name": "stateChange", "type": "bytes", "internalType": "bytes" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "stateVars",
    "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "supportsInterface",
    "inputs": [
      { "name": "interfaceId", "type": "bytes4", "internalType": "bytes4" }
    ],
    "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "Law__Initialized",
    "inputs": [
      {
        "name": "law",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "separatedPowers",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "name",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "description",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "allowedRole",
        "type": "uint48",
        "indexed": false,
        "internalType": "uint48"
      },
      {
        "name": "config",
        "type": "tuple",
        "indexed": false,
        "internalType": "struct ILaw.LawConfig",
        "components": [
          { "name": "quorum", "type": "uint8", "internalType": "uint8" },
          { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
          {
            "name": "votingPeriod",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "needCompleted",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "needNotCompleted",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "delayExecution",
            "type": "uint48",
            "internalType": "uint48"
          },
          {
            "name": "throttleExecution",
            "type": "uint48",
            "internalType": "uint48"
          }
        ]
      }
    ],
    "anonymous": false
  },
  { "type": "error", "name": "Law__DeadlineNotPassed", "inputs": [] },
  { "type": "error", "name": "Law__ExecutionGapTooSmall", "inputs": [] },
  { "type": "error", "name": "Law__ExecutionLimitReached", "inputs": [] },
  { "type": "error", "name": "Law__NoDeadlineSet", "inputs": [] },
  { "type": "error", "name": "Law__NoZeroAddress", "inputs": [] },
  { "type": "error", "name": "Law__OnlySeparatedPowers", "inputs": [] },
  { "type": "error", "name": "Law__ParentBlocksCompletion", "inputs": [] },
  { "type": "error", "name": "Law__ParentLawNotSet", "inputs": [] },
  { "type": "error", "name": "Law__ParentNotCompleted", "inputs": [] },
  { "type": "error", "name": "Law__ProposalNotSucceeded", "inputs": [] },
  {
    "type": "error",
    "name": "StringTooLong",
    "inputs": [{ "name": "str", "type": "string", "internalType": "string" }]
  }
]


// Note: these abis only have the functions that are used in the UI
export const erc20Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
]

export const erc721Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
]

export const erc1155Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "account", "type": "address", "internalType": "address" },
      { "name": "id", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
]
