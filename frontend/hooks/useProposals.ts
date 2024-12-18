import { Status, Proposal } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { agDaoAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients";
import { lawContracts } from "@/context/lawContracts";
import { readContract } from "wagmi/actions";

export const useProposals = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [proposals, setProposals] = useState<Proposal[] | undefined>() 
  const agDaoAddress: `0x${string}` = lawContracts.find((law: any) => law.contract === "AgDao")?.address as `0x${string}`

  // console.log("@useProposal:", {proposals, status, error})

  const getProposals = useCallback( 
    async () => {
      if (publicClient) {
        try {
          const logs = await publicClient.getContractEvents({ 
            address: agDaoAddress,
            abi: agDaoAbi, 
            eventName: 'ProposalCreated',
            fromBlock: 90000000n
          })
          const fetchedLogs = parseEventLogs({
            abi: agDaoAbi,
            eventName: 'ProposalCreated',
            logs
          })
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
          const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
          
          return fetchedProposals
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
      } 
  }, [ ])


  const getProposalState = async (proposals: Proposal[]) => {
    let proposal: Proposal
    let proposalWithState: Proposal[] = []

    if (publicClient) {
      try {
        for await (proposal of proposals) {
          if (proposal?.proposalId) {
            const fetchedState = await readContract(wagmiConfig, {
              abi: agDaoAbi,
              address: agDaoAddress,
              functionName: 'state', 
              args: [proposal.proposalId]
            })
            if (Number(fetchedState) < 5) 
              proposalWithState.push({...proposal, state: Number(fetchedState)}) // = 5 is a non-existent state
          }
        } 
        return proposalWithState
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchProposals = useCallback(
    async () => {
      setStatus("loading")

      const proposalsWithoutState = await getProposals()
      if (proposalsWithoutState) {
        const proposalsWithState = await getProposalState(proposalsWithoutState)
        setProposals(proposalsWithState)
      }

      setStatus("success")
    }, [ ])

  return {status, error, proposals, fetchProposals}
}