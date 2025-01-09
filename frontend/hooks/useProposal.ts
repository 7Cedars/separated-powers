import { useCallback, useEffect, useRef, useState } from "react";
import { separatedPowersAbi } from "../context/abi";
import { Organisation, Proposal, Status } from "../context/types"
import { lawContracts } from "@/context/lawContracts";
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { readContract } from "wagmi/actions";
import { publicClient } from "@/context/clients";
import { useOrgStore } from "@/context/store";
import { parseEventLogs, ParseEventLogsReturnType } from "viem";

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
  const getProposals = async (organisation: Organisation) => {
      if (publicClient) {
        try {
            if (organisation?.contractAddress) {
              const logs = await publicClient.getContractEvents({ 
                address: organisation.contractAddress as `0x${string}`,
                abi: separatedPowersAbi, 
                eventName: 'ProposalCreated',
                fromBlock: 102000000n
              })
              const fetchedLogs = parseEventLogs({
                          abi: separatedPowersAbi,
                          eventName: 'ProposalCreated',
                          logs
                        })
              const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
              const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
              const fetchedProposalsWithBlockNumber: Proposal[] = fetchedProposals.map(
                (proposal, index) => ({ ...proposal, 
                  blockNumber: Number(fetchedLogsTyped[index].blockNumber), 
                  blockHash: fetchedLogsTyped[index].blockHash
                }))
              fetchedProposalsWithBlockNumber.sort((a: Proposal, b: Proposal) => a.blockNumber > b.blockNumber ? 1 : -1)
              return fetchedProposalsWithBlockNumber
            }
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
    }
  
  
  const getProposalsState = async (proposals: Proposal[]) => {
    let proposal: Proposal
    let state: number[] = []

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
              state.push(Number(fetchedState)) // = 5 is a non-existent state
          }
        } 
        return state
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const getProposalsVotes = async (proposals: Proposal[]) => {
    let proposal: Proposal
    let votes: bigint[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.proposalId) {
            const fetchedVotes = await readContract(wagmiConfig, {
              abi: separatedPowersAbi,
              address: organisation.contractAddress,
              functionName: 'getProposalVotes', 
              args: [proposal.proposalId]
            })
            console.log("@useProposal @fetchProposalsVote, return value: ", fetchedVotes)
          }
        } 
        // return votes
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchProposals = useCallback(
    async (organisation: Organisation) => {
      let proposals: Proposal[] | undefined;
      let states: number[] | undefined; 
      let votes: bigint[] | undefined;
      let proposalsFull: Proposal[] | undefined;

      setError(null)
      setStatus("pending")

      proposals = await getProposals(organisation)
      if (proposals) {
        states = await getProposalsState(proposals)
        // const votes = await getProposalsVotes(proposals) 
      } 
      if (states) { // + votes later.. 
        proposalsFull = proposals?.map((proposal, index) => {
          return ( 
            {...proposal, state: states[index]}
          )
        })
      }

      setProposals(proposalsFull)
      setStatus("success") //NB note: after checking status, sets the status back to idle! 
  }, [ ]) 

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

  return {status, error, law, proposals, fetchProposals, propose, cancel, castVote}
}
