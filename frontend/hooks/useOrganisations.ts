import { Status, Proposal, Organisation, Law } from "../context/types"
import { readContracts } from '@wagmi/core'
import { wagmiConfig } from '../context/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "@/context/abi";
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { publicClient } from "@/context/clients"; 
import { readContract } from "wagmi/actions";
import { supportedChains } from "@/context/chains";
import { useChainId } from 'wagmi'
import { assignOrg } from "@/context/store";

export const useOrganisations = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [organisations, setOrganisations] = useState<Organisation[] | undefined>() 
  const chainId = useChainId()
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const fetchNames = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let orgsWithNames: Organisation[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
              const name = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: organisation.contractAddress,
                functionName: 'name'
              })
              const nameParsed = name as string
              console.log({name, nameParsed}) 
              orgsWithNames.push({...organisation, name: nameParsed})
            }
          return orgsWithNames
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
  }

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
              fromBlock: supportedChain?.genesisBlock,
              args: {
                powers: organisation.contractAddress as `0x${string}`
              }
            })
            const fetchedLogs = parseEventLogs({
              abi: lawAbi,
              eventName: 'Law__Initialized',
              logs
            })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            const fetchedLaws: Law[] = fetchedLogsTyped.map(log => log.args as Law)

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

  const fetchActiveLaws = async (organisations: Organisation[]) => {
    let organisation: Organisation
    let law: Law
    let activeLaws: Law[] = []
    let orgsWithActiveLaws: Organisation[] = []

    if (publicClient) {
      try {
        for await (organisation of organisations) {
          if (organisation?.contractAddress && organisation?.laws) {
            for await (law of organisation.laws) {
              const activeLaw = await readContract(wagmiConfig, {
                abi: powersAbi,
                address: organisation.contractAddress,
                functionName: 'getActiveLaw', 
                args: [law.law]
              })
              const active = activeLaw as boolean
              console.log({law, active})
              if (active) activeLaws.push(law) 
            }
          } 
          const orgActiveLaws: Law[] = activeLaws.filter(law => law.powers == organisation.contractAddress) 
          orgsWithActiveLaws.push({...organisation, activeLaws: orgActiveLaws})
        } 
        return orgsWithActiveLaws
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
              abi: powersAbi, 
              eventName: 'ProposalCreated',
              fromBlock: supportedChain?.genesisBlock
            })
            const fetchedLogs = parseEventLogs({
              abi: powersAbi,
              eventName: 'ProposalCreated',
              logs
            })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
            const fetchedProposals: Proposal[] = fetchedLogsTyped.map(log => log.args as Proposal)
            fetchedProposals.sort((a: Proposal, b: Proposal) => a.voteStart  > b.voteStart ? 1 : -1)
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

  const fetch = useCallback(
    async () => {
      // this should be refactored at some point. Does not all have to be sequential.. 
      // £ todo 

      setStatus("pending")
      console.log("waypoint 3: fetch called")
      
      let orgsWithNames: Organisation[] | undefined
      let orgsWithLaws: Organisation[] | undefined
      let orgsWithActiveLaws: Organisation[] | undefined
      let orgsWithProposals: Organisation[] | undefined 

      const defaultOrganisations = supportedChain?.organisations?.map(org => { return ({
        contractAddress: org
        }) as Organisation }
      )
      if (defaultOrganisations) {
        console.log("waypoint 4")
        orgsWithNames = await fetchNames(defaultOrganisations)
      }
      if (orgsWithNames) {
        console.log("waypoint 4")
        orgsWithLaws = await fetchLaws(orgsWithNames)
      }
      if (orgsWithLaws) {
        console.log("waypoint 5")
        orgsWithActiveLaws = await fetchActiveLaws(orgsWithLaws)
      }
      if (orgsWithActiveLaws) {
        console.log("waypoint 6")
        orgsWithProposals = await fetchProposals(orgsWithActiveLaws)
      }
      if (orgsWithProposals) {
        console.log("waypoint 7")
        setOrganisations(orgsWithProposals)
        localStorage.setItem("powersProtocol_savedOrgs", JSON.stringify(orgsWithProposals, (key, value) =>
          typeof value === "bigint" ? Number(value) : value,
        ));
        console.log("waypoint 8")
        setStatus("success")
      }
    }, [ ]
  )

  const initialise = () => {
      console.log("waypoint 1: initialise called")
      setStatus("pending")
      let localStore = localStorage.getItem("powersProtocol_savedOrgs")
      const saved: Organisation[] = localStore ? JSON.parse(localStore) : []
      console.log("waypoint 2: local storage queried:", {saved})

      saved.length == 0 ? fetch() : setOrganisations(saved)
      setStatus("success")  
    } 

    
  const update = useCallback(
    async (organisation: Organisation) => {
      setStatus("pending")

      let localStore = localStorage.getItem("powersProtocol_savedOrgs")
      const saved: Organisation[] = localStore ? JSON.parse(localStore) : []

      let orgWithLaws: Organisation[] | undefined
      let orgWithActiveLaws: Organisation[] | undefined
      let orgWithProposals: Organisation[] | undefined 

      orgWithLaws = await fetchLaws([organisation])
      if (orgWithLaws) {
        orgWithActiveLaws = await fetchActiveLaws(orgWithLaws)
      }
      if (orgWithActiveLaws) {
        orgWithProposals = await fetchProposals(orgWithActiveLaws)
      }
      if (orgWithProposals && saved.length > 0) {
        const updatedOrgs: Organisation[] = saved.map(org => 
          organisation.contractAddress == org.contractAddress ? 
          orgWithProposals[0] : org)
        
          setOrganisations(updatedOrgs)
          localStorage.setItem("powersProtocol_savedOrgs", JSON.stringify(updatedOrgs, (key, value) =>
            typeof value === "bigint" ? Number(value) : value,
          ));
      
        setStatus("success")
      }
  }, [])

  const run = useCallback(
    async (protocol: `0x${string}`) => {
      setStatus("pending")

      const requestedOrg =  {
        contractAddress: protocol
        } as Organisation 

      let orgWithName: Organisation[] | undefined
      let orgWithLaws: Organisation[] | undefined
      let orgWithActiveLaws: Organisation[] | undefined
      let orgWithProposals: Organisation[] | undefined 
      
      if (requestedOrg) {
        console.log("waypoint 4")
        orgWithName = await fetchNames([requestedOrg])
      }
      if (orgWithName) {
        orgWithLaws = await fetchLaws(orgWithName)
      }
      if (orgWithLaws) {
        orgWithActiveLaws = await fetchActiveLaws(orgWithLaws)
      }
      if (orgWithActiveLaws) {
        orgWithProposals = await fetchProposals(orgWithActiveLaws)
      }
      if (orgWithProposals) {
        assignOrg(orgWithProposals[0])
        setStatus("success")
      }
  }, [])

  return {status, error, organisations, initialise, fetch, update, run}
}