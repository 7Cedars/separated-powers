import { Status, ExecutiveAction } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { agDaoAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients";
import { lawContracts } from "@/context/lawContracts";
import { readContract } from "wagmi/actions";

export const useExecutiveActions = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [proposals, setExecutiveActions] = useState<ExecutiveAction[] | undefined>() 
  const agDaoAddress: `0x${string}` = lawContracts.find((law: any) => law.contract === "AgDao")?.address as `0x${string}`

  // console.log("@useExecutiveAction:", {proposals, status, error})

  const getExecutiveActions = useCallback( 
    async () => {
      if (publicClient) {
        try {
          const logs = await publicClient.getContractEvents({ 
            address: agDaoAddress,
            abi: agDaoAbi, 
            eventName: 'ExecutiveActionCreated',
            fromBlock: 90000000n
          })
          const fetchedLogs = parseEventLogs({
            abi: agDaoAbi,
            eventName: 'ExecutiveActionCreated',
            logs
          })
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
          const fetchedExecutiveActions: ExecutiveAction[] = fetchedLogsTyped.map(log => log.args as ExecutiveAction)
          
          return fetchedExecutiveActions
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
      } 
  }, [ ])

  const getActionState = async (proposals: ExecutiveAction[]) => {
    let proposal: ExecutiveAction
    let proposalWithState: ExecutiveAction[] = []

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

  const fetchExecutiveActions = useCallback(
    async () => {
      setStatus("loading")

      const proposalsWithoutState = await getExecutiveActions()
      if (proposalsWithoutState) {
        const proposalsWithState = await getActionState(proposalsWithoutState)
        setExecutiveActions(proposalsWithState)
      }

      setStatus("success")
    }, [ ])

  return {status, error, proposals, fetchExecutiveActions}
}