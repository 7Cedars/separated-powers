import { ConnectedWallet } from '@privy-io/react-auth';

export type Role = bigint;
export type Status = "idle" | "loading" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, for, abstain  

export type userActionsProps = { wallet: ConnectedWallet, isDisabled: boolean }
export type ProposalViewProps = { proposal: Proposal, isDisabled: boolean} 

export type Law = {
  address: `0x${string}`;
  name?: string;
  description?: string;
  allowedRole?: bigint;
  params?: string[];
  quorum?: bigint;
  succeedAt?: bigint;
  votingPeriod?: bigint;
  needCompleted?: `0x${string}`;
  needNotCompleted?: `0x${string}`;
  delayExecution?: bigint;
  throttleExecution?: bigint;
}

export type Organisation = {
  address: `0x${string}`;
  name?: string;
  colourScheme?: string;
  laws?: Law[];
  proposals?: Proposal[];
  holders: number;
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
}

export type ContractAddress = {
  contract: string; 
  address: `0x${string}`; 
}