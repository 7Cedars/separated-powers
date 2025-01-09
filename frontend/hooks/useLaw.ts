import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, separatedPowersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Status } from "../context/types"
import { lawContracts } from "@/context/lawContracts";
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";
import { useLawStore, useOrgStore } from "@/context/store";
import { useReadContracts } from "wagmi";
import { useWallets } from "@privy-io/react-auth";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { parseEventLogs, ParseEventLogsReturnType } from "viem";

type Checks = {
  authorised?: boolean | undefined;
  proposalExists?: boolean | undefined;
  proposalPassed?: boolean | undefined;
  lawCompleted?: boolean | undefined;
  lawNotCompleted?: boolean | undefined;
  delayPassed?: boolean | undefined;
  throttlePassed?: boolean | undefined;
}

type LawSimulation = [
  `0x${string}`[], 
  bigint[], 
  `0x${string}`[] 
]

export const useLaw = () => {
  const organisation = useOrgStore()
  const law = useLawStore()
  const blockNumber = useBlockNumber()
  const {wallets} = useWallets();
  // const wallet = wallets[0];

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setLawSimulation ] = useState<LawSimulation>()
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })
  const [checks, setChecks ] = useState<Checks>()

  useEffect(() => {
    if (statusReceipt === "success") setStatus("success")
    if (statusReceipt === "error") setStatus("error")
  }, [statusReceipt])

  // reset // 
  const resetStatus = () => {
    setStatus("idle")
    setError(null)
    setTransactionHash(undefined)
  }

  // Status //
  const checkAccountAuthorised = useCallback(
    async () => {
      if (!wallets[0]) {
        return false 
      } else {      
        try {
          const result =  await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
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
      proposal.targetLaw === law.law && 
      proposal.executeCalldata === calldata && 
      proposal.description === description
    ) 
    return selectedProposal
  }

  const checkProposalStatus = useCallback(
    async (description: string, calldata: `0x${string}`) => {
      const selectedProposal = checkProposalExists(description, calldata)
    
      if (selectedProposal) {
        try {
          const state =  await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("state @checkProposalStatus", state)
          const result = Number(state) == 3
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
      console.log("selectedProposal @checkLawCompleted", selectedProposal)
      
      try { 
        if (selectedProposal) {
          const state = await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("state @checkLawCompleted", state)
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
      console.log("selectedProposal @checkLawNotCompleted", selectedProposal)
  
      try { 
        if (selectedProposal) {
          const state =  await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("state @checkLawNotCompleted", state)
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
    console.log("selectedProposal @checkDelayedExecution", selectedProposal)

    const result = Number(selectedProposal?.voteEnd) + Number(law.config.delayExecution) < Number(blockNumber)
    return result as boolean
  }

  const checkThrottledExecution = () => {
    const selectedProposals = organisation?.proposals?.filter(proposal => 
      proposal.targetLaw === law.law && 
      proposal.state === 4
    )
    if (selectedProposals && selectedProposals.length > 0) {
      const result = selectedProposals[0].blockNumber + Number(law.config.throttleExecution) < Number(blockNumber)
      return result as boolean
    } else {
      return true
    } 
  }

  const fetchChecks = useCallback( 
    async (description: string, calldata: `0x${string}`) => {
        let results: Array<boolean | undefined> = new Array<boolean | undefined>(6);

        setError(null)
        setStatus("pending")
        
        // this can be written better. But ok for now. 
        results[0] = checkDelayedExecution(description, calldata)
        results[1] = checkThrottledExecution()
        results[2] = await checkAccountAuthorised()
        results[3] = checkProposalExists(description, calldata) != undefined
        results[4] = await checkProposalStatus(description, calldata)
        results[5] = await checkLawCompleted(description, calldata)
        results[6] = await checkLawNotCompleted(description, calldata)

        if (!results.find(result => {result == undefined})) setChecks({
          delayPassed: results[0],
          throttlePassed: results[1],
          authorised: results[2],
          proposalExists: results[3],
          proposalPassed: results[4],
          lawCompleted: results[5],
          lawNotCompleted: results[6]
        })
        
        setStatus("idle") //NB note: after checking status, sets the status back to idle! 
  }, [ ])
  
  // Actions // 
  const fetchSimulation = useCallback( 
    async (targetLaw: `0x${string}`, lawCalldata: `0x${string}`, description: string) => {
      setError(null)
      setStatus("pending")
      try {
        const result = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.law,
          functionName: 'simulateLaw', 
          args: [targetLaw, lawCalldata, description]
        })
          setLawSimulation(result as LawSimulation)
          setStatus("success")
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
  }, [ ])

  const execute = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      description: string
    ) => {
        setError(null)
        setStatus("pending")
        try {
          const result = await writeContract(wagmiConfig, {
            abi: separatedPowersAbi,
            address: organisation.contractAddress,
            functionName: 'execute', 
            args: [targetLaw, lawCalldata, description]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  return {status, error, law, simulation, checks, resetStatus, fetchSimulation, fetchChecks, execute}
}
