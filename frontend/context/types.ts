import { ConnectedWallet } from '@privy-io/react-auth';

export type Status = "idle" | "pending" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, for, abstain  
// 'string | number | bigint | boolean | ByteArray 
export type InputType = number | boolean | string | `0x${string}` | undefined 
export type DataType = "uint8" | "uint16" | "uint32" | "uint64" | "uint128" | "uint256" | "address" | "bytes" | "string" | "bytes32" | "bool" |
                       "uint8[]" | "uint16[]" | "uint32[]" | "uint64[]" | "uint128[]" | "uint256[]" | "address[]" | "bytes[]" | "string[]" | "bytes32[]" | "bool[]" | "unsupported" | "empty" 
export type LawSimulation = [
      `0x${string}`[], 
      bigint[], 
      `0x${string}`[], 
      `0x${string}`
    ]

export type ChainProps = {
  name: string;
  network: string; 
  id: number;
  genesisBlock: bigint; // block at which the first SeparatedPowers Protocol was deployed. 
  rpc?: string;
  nativeCurrency?: {
    name: string;
    symbol: string;
    decimals: number;
  };
  blockExplorerUrl?: string;
  iconUrl?: string;
  mockErc20?: `0x${string}`;
  mockErc721?: `0x${string}`;
  mockErc1155?: `0x${string}`;
  erc20s?: 
    { name: string; 
      symbol: string; 
      decimals: number; 
      address: `0x${string}`
    }[];
  erc721s?: `0x${string}`[];
  erc1155s?: `0x${string}`[];
}
                      

export type Config = {
  delayExecution: bigint; 
  needNotCompleted: `0x${string}`;
  needCompleted: `0x${string}`;
  quorum: bigint; 
  succeedAt: bigint; 
  throttleExecution: bigint;
  votingPeriod: bigint;
}

export type Law = {
  law: `0x${string}`;
  name?: string;
  description?: string;
  allowedRole?: bigint;
  separatedPowers?: `0x${string}`;
  config: Config;
  params?: string[];
}

export type Organisation = {
  contractAddress: `0x${string}`;
  name: string;
  colourScheme: number;
  laws?: Law[];
  proposals?: Proposal[];
  roles: bigint[];
}

export type Role = {
  access: boolean,
  account: `0x${string}`,
  roleId: number,
  since?: number
}

export type Roles = {
  roleId: number, 
  holders?: number,
  laws?: Law[],
  proposals?: Proposal[],
  roles?: Role[]
};

export type Action = {
  dataTypes: DataType[] | undefined;
  paramValues: (InputType | InputType[])[] | undefined;
  description: string;
  callData: `0x${string}`;
  upToDate: boolean;
}

export type Proposal = {
  proposalId: number;
  targetLaw: `0x${string}`;
  voteStart: bigint;
  voteDuration: bigint;
  voteEnd: bigint;
  cancelled: boolean;
  completed: boolean;
  initiator: `0x${string}`;
  againstVotes?: bigint;
  forVotes?: bigint;
  abstainVotes?: bigint;
  description?: string;
  executeCalldata?: `0x${string}`;
  state?: number;
  blockNumber: number;
  blockHash?: `0x${string}`;
}

export type ProtocolEvent = {
  address: `0x${string}`;
  blockHash: `0x${string}`;
  blockNumber: bigint;
  args: any; 
  data: `0x${string}`;
  eventName: string;
  logIndex: number;
  transactionHash: `0x${string}`;
  transactionIndex: number;
}

export type ContractAddress = {
  contract: string; 
  address: `0x${string}`; 
}

export type CompletedProposal = {
  initiator: `0x${string}`;
  address: `0x${string}`;
  lawCalldata: `0x${string}`;
  descriptionHash: `0x${string}`;
  blockNumber: bigint;
} 