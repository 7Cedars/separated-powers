import { Status, Proposal, Organisation } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { separatedPowersAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients";
import { lawContracts } from "@/context/lawContracts";
import { readContract } from "wagmi/actions";

export const useSeparatedPowers = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [organisations, setOrganisations] = useState<Organisation[] | undefined>() 

  // console.log("@useProposal:", {proposals, status, error})

  const getOrganisations = useCallback( 
    async () => {
      if (publicClient) {
        try {
          const logs = await publicClient.getContractEvents({ 
            abi: separatedPowersAbi, 
            eventName: 'SeparatedPowers__Initialized',
            fromBlock: 102000000n
          })
          const fetchedLogs = parseEventLogs({
            abi: separatedPowersAbi,
            eventName: 'SeparatedPowers__Initialized',
            logs
          })
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
          console.log("@fetchedLogsTyped", fetchedLogsTyped)
          const fetchedOrganisations: Organisation[] = fetchedLogsTyped.map(log => log.args as Organisation)
          return fetchedOrganisations
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
      } 
  }, [ ])

  const getOrganisationData = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let orgsWithProposals: Organisation[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          if (organisation?.address) {
            const separatedPowersContract = {
              address: organisation.address,
              abi: separatedPowersAbi,
            } as const

            const fetchedState = await readContracts(wagmiConfig, {
              contracts: [
                {
                ...separatedPowersContract,
                functionName: 'name'
                }

              ]
            }
          
          )


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

  const fetchProposals = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let orgsWithProposals: Organisation[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          if (organisation?.address) {
            const logs = await publicClient.getContractEvents({ 
              address: organisation.address,
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
            if (fetchedProposals) {
              orgsWithProposals.push({...organisation, proposals: fetchedProposals})
            }
          }
        } 
        return orgsWithProposals
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const fetchOrganisations = useCallback(
    async () => {
      setStatus("loading")

      const fetchedOrganisations = await getProposals()
      if (fetchedOrganisations) {
        // const proposalsWithState = await getProposalState(proposalsWithoutState)
        setOrganisations(fetchedOrganisations)
      }

      setStatus("success")
    }, [ ])

  return {status, error, organisations, fetchOrganisations}
}