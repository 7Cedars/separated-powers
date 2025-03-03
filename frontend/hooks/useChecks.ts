import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Checks, Status, LawSimulation, Execution, LogExtended } from "../context/types"
import { wagmiConfig } from "@/context/wagmiConfig";
import { useChainId, useWaitForTransactionReceipt } from "wagmi";
import { useActionStore, useLawStore, useOrgStore, setAction } from "@/context/store";
import { useWallets } from "@privy-io/react-auth";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { supportedChains } from "@/context/chains";
import { sepolia } from "@wagmi/core/chains";

export const useChecks = () => {
  const organisation = useOrgStore(); 
  const action = useActionStore();
  // note: I had a problem that zustand's lawStore did not update for some reason. Hence laws are handled as props.  
  const {data: blockNumber, error: errorBlockNumber} = useBlockNumber({ // this needs to be dynamic, for use in different chains! £todo
    chainId: sepolia.id, // NB: reading blocks from sepolia, because arbitrum One & sepolia reference these block numbers, not their own. 
  })
  const {ready, wallets} = useWallets();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  // console.log("@fetchChecks useChecks called: ", {action, blockNumberError, blockNumber})

  const checkAccountAuthorised = useCallback(
    async (law: Law) => {
      if (ready && wallets[0]) {
        try {
          const result =  await readContract(wagmiConfig, {
                  abi: powersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'canCallLaw', 
                  args: [wallets[0].address, law.law],
                })
          return result ? result as boolean : false
        } catch (error) {
            setStatus("error") 
            setError(error)
            return false
        } 
      } else { 
        return false 
      }         
  }, [])

  const checkProposalExists = (description: string, calldata: `0x${string}`, law: Law) => {
    const selectedProposal = organisation?.proposals?.find(proposal => 
      proposal.targetLaw == law.law && 
      proposal.executeCalldata == calldata && 
      proposal.description == description
    ) 
    // console.log("@checkProposalExists: ", {selectedProposal})

    return selectedProposal
  }

  const checkProposalStatus = useCallback(
    async (description: string, calldata: `0x${string}`, stateToCheck: number[], law: Law) => {
      const selectedProposal = checkProposalExists(description, calldata, law)

      // console.log("@checkProposalStatus: ", {selectedProposal})
    
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
          setError(error)
          return false 
        }
      } else {
        return false 
      }
  }, []) 


  const checkDelayedExecution = (description: string, calldata: `0x${string}`, law: Law) => {
    // console.log("CheckDelayedExecution triggered")
    const selectedProposal = organisation?.proposals?.find(proposal => 
      proposal.targetLaw === law.law && 
      proposal.executeCalldata === calldata && 
      proposal.description === description
    ) 
    // console.log("waypoint 1, CheckDelayedExecution: ", {selectedProposal, blockNumber})
    const result = Number(selectedProposal?.voteEnd) + Number(law.config.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const fetchExecutions = async (lawAddress: `0x${string}`) => {
    if (publicClient) {
      try {
          if (organisation?.contractAddress) {
            const logs = await publicClient.getContractEvents({ 
              address: organisation.contractAddress as `0x${string}`,
              abi: powersAbi, 
              eventName: 'ProposalCompleted',
              fromBlock: supportedChain?.genesisBlock,
              args: {targetLaw: lawAddress}
            })
            const fetchedLogs = parseEventLogs({
                        abi: powersAbi,
                        eventName: 'ProposalCompleted',
                        logs
                      })
            const fetchedLogsTyped = fetchedLogs as unknown[] as LogExtended[]  
            // console.log({fetchedLogsTyped})
            return (
              fetchedLogsTyped.sort((a: LogExtended, b: LogExtended) => (
                a.blockNumber ? Number(a.blockNumber) : 0
              ) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)) as LogExtended[]
          } 
      } catch (error) {
        setStatus("error") 
        setError(error)
      }
    }
  }

  const checkThrottledExecution = useCallback( async (law: Law) => {
    const fetchedExecutions = await fetchExecutions(law.law)

    if (fetchedExecutions && fetchedExecutions.length > 0) {
      const result = Number(fetchedExecutions[0].blockNumber) + Number(law.config.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const checkNotCompleted = useCallback( 
    async (description: string, calldata: `0x${string}`, lawAddress: `0x${string}`) => {
      
      const fetchedExecutions = await fetchExecutions(lawAddress)
      const selectedExecution = fetchedExecutions && fetchedExecutions.find(execution => execution.args?.description == description && execution.args?.lawCalldata == calldata)

      return selectedExecution == undefined; 
  }, [] ) 

  const fetchChecks = useCallback( 
    async (law: Law, callData: `0x${string}`, description: string) => {
      // console.log("fetchChecks triggered")
        let results: boolean[] = new Array<boolean>(8)
        setError(null)
        setStatus("pending")
        
        results[0] = checkDelayedExecution(description, callData, law)
        results[1] = await checkThrottledExecution(law)
        results[2] = await checkAccountAuthorised(law)
        results[3] = await checkProposalStatus(description, callData, [3, 4], law)
        results[4] = await checkNotCompleted(description, callData, law.law)
        results[5] = await checkNotCompleted(description, callData, law.config.needCompleted)
        results[6] = await checkNotCompleted(description, callData, law.config.needNotCompleted)
        results[7] = checkProposalExists(description, callData, law) != undefined

        // console.log("@fetchChecks: ", {results})

        if (!results.find(result => !result) && law.config) {// check if all results have come through 
          let newChecks: Checks =  {
            delayPassed: law.config.delayExecution == 0n ? true : results[0],
            throttlePassed: law.config.throttleExecution == 0n ? true : results[1],
            authorised: results[2],
            proposalExists: law.config.quorum == 0n ? true : results[7],
            proposalPassed: law.config.quorum == 0n ? true : results[3],
            proposalNotCompleted: results[4],
            lawCompleted: law.config.needCompleted == `0x${'0'.repeat(40)}` ? true : results[5] == false, 
            lawNotCompleted: law.config.needNotCompleted == `0x${'0'.repeat(40)}` ? true : results[6]
          } 
          newChecks.allPassed =  
            newChecks.delayPassed && 
            newChecks.throttlePassed && 
            newChecks.authorised && 
            newChecks.proposalExists && 
            newChecks.proposalPassed && 
            newChecks.proposalNotCompleted && 
            newChecks.lawCompleted &&
            newChecks.lawNotCompleted ? true : false, 
          
            setChecks(newChecks)
        }
 
        setStatus("success") //NB note: after checking status, sets the status back to idle! 
  }, [ ])

  return {status, error, checks, fetchChecks, checkProposalExists}
}
