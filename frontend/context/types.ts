import { ConnectedWallet } from '@privy-io/react-auth';

export type Role = "Admin" | "Member" | "Whale" | "Senior" | "Guest";
export type Status = "idle" | "loading" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, for, abstain  

export type userActionsProps = { wallet: ConnectedWallet, isDisabled: boolean }
export type ExecutiveActionViewProps = { proposal: ExecutiveAction, isDisabled: boolean} 

export type ExecutiveAction = {
  targetLaw: `0x${string}`;
  proposalId: number;
  initiator: `0x${string}`;
  executeCalldata: `0x${string}`;
  voteStart: bigint;
  voteEnd: bigint;
  description: string;
  signature?: string;
  state?: number;
}

export type ContractAddress = {
  contract: string; 
  address: `0x${string}`; 
}