import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Checks, Status, LawSimulation } from "../context/types"
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useChainId, useWaitForTransactionReceipt } from "wagmi";
import { useActionStore, useLawStore, useOrgStore, setAction } from "@/context/store";
import { useWallets } from "@privy-io/react-auth";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { supportedChains } from "@/context/chains";

export const useChecks = () => {
  const organisation = useOrgStore()
  const law = useLawStore()
  const action = useActionStore();
  const blockNumber = useBlockNumber()
  const {wallets} = useWallets();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  const checkAccountAuthorised = useCallback(
    async () => {
      if (!wallets[0]) {
        return false 
      } else {      
        try {
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'canCallLaw', 
                  args: [wallets[0].address, law.law],
                })
          return result as boolean
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
      }
  }, [])

  const checkProposalExists = (description: string, calldata: `0x${string}`) => {
    const selectedProposal = organisation?.proposals?.find(proposal => 
      proposal.targetLaw == law.law && 
      proposal.executeCalldata == calldata && 
      proposal.description == description
    ) 
    console.log("@checkProposalExists: ", {selectedProposal})

    return selectedProposal
  }

  const checkProposalStatus = useCallback(
    async (description: string, calldata: `0x${string}`, stateToCheck: number[]) => {
      const selectedProposal = checkProposalExists(description, calldata)

      console.log("@checkProposalStatus: ", {selectedProposal})
    
      if (selectedProposal) {
        try {
          const state =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          const result = stateToCheck.includes(Number(state)) 
          return result 
        } catch (error) {
          setStatus("error")
          return false 
        }
      } else {
        return false 
      }
  }, []) 

  const checkLawCompleted = useCallback(
    async (description: string, calldata: `0x${string}`) => {
      const selectedProposal = organisation?.proposals?.find(proposal => 
        proposal.targetLaw === law.config.needCompleted && 
        proposal.executeCalldata === calldata && 
        proposal.description === description
      ) 

      console.log("@checkLawCompleted: ", {selectedProposal})
      
      try { 
        if (selectedProposal) {
          const state = await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("@checkLawCompleted: ", {state}) 
          const result = Number(state) == 4
          return result as boolean
        } else {
          return false
        }
      } catch (error) {
        setStatus("error")
        return false 
      }

  }, []) 

  const checkLawNotCompleted = useCallback(
    async (description: string, calldata: `0x${string}`) => {
      const selectedProposal = organisation?.proposals?.find(proposal => 
        proposal.targetLaw === law.config.needNotCompleted && 
        proposal.executeCalldata === calldata && 
        proposal.description === description
      ) 
  
      try { 
        if (selectedProposal) {
          const state =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("@checkLawNotCompleted: ", {state}) 
          const result = Number(state) != 4
          return result as boolean
        } else {
          return true 
        }
      } catch (error) {
        setStatus("error")
        setError( error )
        return true 
      }

  }, []) 

  const checkDelayedExecution = (description: string, calldata: `0x${string}`) => {
    const selectedProposal = organisation?.proposals?.find(proposal => 
      proposal.targetLaw === law.law && 
      proposal.executeCalldata === calldata && 
      proposal.description === description
    ) 

    const result = Number(selectedProposal?.voteEnd) + Number(law.config.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const fetchExecutions = async () => {
    if (publicClient) {
      try {
          if (organisation?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              address: organisation.contractAddress as `0x${string}`,
              abi: powersAbi, 
              eventName: 'ProposalCompleted',
              fromBlock: supportedChain?.genesisBlock,
              args: {targetLaw: law.law}
            })
            const fetchedLogs = parseEventLogs({
                        abi: powersAbi,
                        eventName: 'ProposalCompleted',
                        logs
                      })
            const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType  
            return (
              fetchedLogsTyped.sort((a: Log, b: Log) => (
                a.blockNumber ? Number(a.blockNumber) : 0
              ) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)) 
          } 
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const checkThrottledExecution = async () => {
    const fetchedExecutions = await fetchExecutions()

    if (fetchedExecutions && fetchedExecutions.length > 0) {
      const result = Number(fetchedExecutions[0].blockNumber) + Number(law.config.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }

  const fetchChecks = useCallback( 
    async () => {
        let results: Array<boolean | undefined> = new Array<boolean | undefined>(6);

        setError(null)
        setStatus("pending")

        console.log("law.config.quorum: ", law.config.quorum)
        
        // this can be written better. But ok for now. 
        results[0] = checkDelayedExecution(action.description, action.callData)
        results[1] = await checkThrottledExecution()
        results[2] = await checkAccountAuthorised()
        results[3] = await checkProposalStatus(action.description, action.callData, [3, 4])
        results[4] = await checkProposalStatus(action.description, action.callData, [4])
        results[5] = await checkLawCompleted(action.description, action.callData)
        results[6] = await checkLawNotCompleted(action.description, action.callData)

        const checks = !results.find(result => {result == undefined}) ? {
          delayPassed: law.config.delayExecution == 0n ? true : results[0],
          throttlePassed: law.config.throttleExecution == 0n ? true : results[1],
          authorised: results[2],
          proposalExists: law.config.quorum == 0n ? true : (checkProposalExists(action.description, action.callData) != undefined),
          proposalPassed: law.config.quorum == 0n ? true : results[3],
          proposalCompleted: law.config.quorum == 0n ? true : results[4],
          lawCompleted: law.config.needCompleted ==  `0x${'0'.repeat(40)}` ? true : results[5],
          lawNotCompleted: law.config.needNotCompleted == `0x${'0'.repeat(40)}` ? true : results[6]
        } : undefined 

        setChecks(checks)
 
        setStatus("idle") //NB note: after checking status, sets the status back to idle! 
  }, [ ])

  return {status, error, checks, fetchChecks, checkProposalExists}
}
