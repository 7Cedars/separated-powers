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
  const organisation = useOrgStore(); 
  const action = useActionStore();
  // note: I had a problem that zustand's lawStore did not update for some reason. Hence laws are handled as props.  
  const {data: blockNumber, error: blockNumberError} = useBlockNumber()
  const {ready, wallets} = useWallets();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null) 
  const [checks, setChecks ] = useState<Checks>()

  console.log("@fetchChecks useChecks called: ", {action, blockNumberError, blockNumber})

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
    console.log("@checkProposalExists: ", {selectedProposal})

    return selectedProposal
  }

  const checkProposalStatus = useCallback(
    async (description: string, calldata: `0x${string}`, stateToCheck: number[], law: Law) => {
      const selectedProposal = checkProposalExists(description, calldata, law)

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
          setError(error)
          return false 
        }
      } else {
        return false 
      }
  }, []) 

  const checkLawCompleted = useCallback(
    async (description: string, calldata: `0x${string}`, law: Law) => {
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
        setError(error)
        return false 
      }

  }, []) 

  const checkLawNotCompleted = useCallback(
    async (description: string, calldata: `0x${string}`, law: Law) => {
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

  const checkDelayedExecution = (description: string, calldata: `0x${string}`, law: Law) => {
    const selectedProposal = organisation?.proposals?.find(proposal => 
      proposal.targetLaw === law.law && 
      proposal.executeCalldata === calldata && 
      proposal.description === description
    ) 

    const result = Number(selectedProposal?.voteEnd) + Number(law.config.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const fetchExecutions = async (law: Law) => {
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

  const checkThrottledExecution = useCallback( async (law: Law) => {
    const fetchedExecutions = await fetchExecutions(law)

    console.log({fetchedExecutions, blockNumber})

    if (fetchedExecutions && fetchedExecutions.length > 0) {
      const result = Number(fetchedExecutions[0].blockNumber) + Number(law.config.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }, [])

  const fetchChecks = useCallback( 
    async (law: Law) => {
        let results: boolean[] = new Array<boolean>(8)
        setError(null)
        setStatus("pending")
        
        // this can be written better. But ok for now. 
        results[0] = checkDelayedExecution(action.description, action.callData, law)
        results[1] = await checkThrottledExecution(law)
        results[2] = await checkAccountAuthorised(law)
        results[3] = await checkProposalStatus(action.description, action.callData, [3, 4], law)
        results[4] = await checkProposalStatus(action.description, action.callData, [4], law) == false
        results[5] = await checkLawCompleted(action.description, action.callData, law)
        results[6] = await checkLawNotCompleted(action.description, action.callData, law)
        results[7] = checkProposalExists(action.description, action.callData, law) != undefined

        console.log("@fetchChecks: ", {results})

        if (!results.find(result => !result) && law.config) {// check if all results have come through 
          let newChecks: Checks =  {
            delayPassed: law.config.delayExecution == 0n ? true : results[0],
            throttlePassed: law.config.throttleExecution == 0n ? true : results[1],
            authorised: results[2],
            proposalExists: law.config.quorum == 0n ? true : results[7],
            proposalPassed: law.config.quorum == 0n ? true : results[3],
            proposalNotCompleted: results[4],
            lawCompleted: law.config.needCompleted == `0x${'0'.repeat(40)}` ? true : results[5], 
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
