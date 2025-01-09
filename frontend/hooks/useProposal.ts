import { useCallback, useEffect, useRef, useState } from "react";
import { separatedPowersAbi } from "../context/abi";
import { Proposal, Status } from "../context/types"
import { lawContracts } from "@/context/lawContracts";
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { readContract } from "wagmi/actions";
import { publicClient } from "@/context/clients";
import { useOrgStore } from "@/context/store";

export const useProposal = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const organisation = useOrgStore()
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const [proposals, setProposals] = useState<Proposal[] | undefined>()
  const [law, setLaw ] = useState<`0x${string}` | undefined>()
  const [error, setError] = useState<any | null>(null)

  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })

  useEffect(() => {
    if (statusReceipt === "success") setStatus("success")
    if (statusReceipt === "error") setStatus("error")
  }, [statusReceipt])


  // Status //
  const fetchProposalsState = async (proposals: Proposal[]) => {
    let proposal: Proposal
    let proposalsWithState: Proposal[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.proposalId) {
            const fetchedState = await readContract(wagmiConfig, {
              abi: separatedPowersAbi,
              address: organisation.contractAddress,
              functionName: 'state', 
              args: [proposal.proposalId]
            })
            if (Number(fetchedState) < 5) 
              proposalsWithState.push({...proposal, state: Number(fetchedState)}) // = 5 is a non-existent state
          }
        } 
        setProposals(proposalsWithState)
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  // Actions // 
  const propose = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      description: string
    ) => {
        setStatus("pending")
        setLaw(targetLaw)
        try {
            const result = await writeContract(wagmiConfig, {
              abi: separatedPowersAbi,
              address: organisation.contractAddress,
              functionName: 'propose', 
              args: [targetLaw, lawCalldata, description]
            })
            setTransactionHash(result)
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
  }, [ ])

  const cancel = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      descriptionHash: `0x${string}`
    ) => {
        setStatus("pending")
        setLaw(targetLaw)
        try {
          const result = await writeContract(wagmiConfig, {
            abi: separatedPowersAbi,
            address: organisation.contractAddress,
            functionName: 'cancel', 
            args: [targetLaw, lawCalldata, descriptionHash]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const castVote = useCallback( 
    async (
      proposalId: bigint,
      support: bigint 
    ) => {
        setStatus("pending")
        setLaw("0x01") // note: a dummy value to signify cast vote 
        try {
          const result = await writeContract(wagmiConfig, {
            abi: separatedPowersAbi,
            address: organisation.contractAddress,
            functionName: 'castVote', 
            args: [proposalId, support]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  return {status, error, law, proposals, fetchProposalsState, propose, cancel, castVote}
}
