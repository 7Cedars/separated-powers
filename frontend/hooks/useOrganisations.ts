import { Status, Proposal, Organisation, Law } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, separatedPowersAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients";
import { lawContracts } from "@/context/lawContracts";
import { readContract } from "wagmi/actions";

export const useOrganisations = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [organisations, setOrganisations] = useState<Organisation[] | undefined>() 

  // const fromBlock = 102000000n // this should be taken from a config file. £todo 

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
          const fetchedOrganisations: Organisation[] = fetchedLogsTyped.map(log => log.args as Organisation)
          return fetchedOrganisations
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
      } 
  }, [ ])

  const fetchLaws = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let orgsWithLaws: Organisation[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          if (organisation?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              abi: lawAbi, 
              eventName: 'Law__Initialized',
              fromBlock: 102000000n,
              args: {
                separatedPowers: organisation.contractAddress as `0x${string}`
              }
            })
            const fetchedLogs = parseEventLogs({
              abi: lawAbi,
              eventName: 'Law__Initialized',
              logs
            })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            const fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)
            console.log("@fetchLaws", {fetchedLaws})

            const rolesAll = fetchedLaws.map((law: Law) => law.allowedRole)
            const roles = [... new Set(rolesAll)] as bigint[]
          
            if (fetchedLaws && roles) {
              orgsWithLaws.push({...organisation, laws: fetchedLaws, roles: roles, colourScheme: orgsWithLaws.length})
            }
          }
        } 
        return orgsWithLaws
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

      let orgsWithLaws: Organisation[] | undefined
      let orgsWithProposals: Organisation[] | undefined 

      const fetchedOrganisations = await getOrganisations()
      if (fetchedOrganisations) {
        orgsWithLaws = await fetchLaws(fetchedOrganisations)
      }
      if (orgsWithLaws) {
        orgsWithProposals = await fetchProposals(orgsWithLaws)
      }
      if (orgsWithProposals) {
        setOrganisations(orgsWithProposals)
      }
      setStatus("success")
    }, [ ])

  return {status, error, organisations, fetchOrganisations}
}