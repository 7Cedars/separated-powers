import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, separatedPowersAbi } from "../context/abi";
import { CompletedProposal, Law, ProtocolEvent, Status, LawSimulation } from "../context/types"
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useChainId, useWaitForTransactionReceipt } from "wagmi";
import { useLawStore, useOrgStore } from "@/context/store";
import { useWallets } from "@privy-io/react-auth";
import { publicClient } from "@/context/clients";
import { readContract } from "wagmi/actions";
import { useBlockNumber } from 'wagmi'
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { supportedChains } from "@/context/chains";

type Checks = {
  authorised?: boolean | undefined;
  proposalExists?: boolean | undefined;
  proposalPassed?: boolean | undefined;
  lawCompleted?: boolean | undefined;
  lawNotCompleted?: boolean | undefined;
  delayPassed?: boolean | undefined;
  throttlePassed?: boolean | undefined;
}

export const useLaw = () => {
  const organisation = useOrgStore()
  const law = useLawStore()
  const blockNumber = useBlockNumber()
  const {wallets} = useWallets();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  // const wallet = wallets[0];

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [simulation, setSimulation ] = useState<LawSimulation>()
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
      
      try { 
        if (selectedProposal) {
          const state = await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
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
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
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
              abi: separatedPowersAbi, 
              eventName: 'ProposalCompleted',
              fromBlock: supportedChain?.genesisBlock,
              args: {targetLaw: law.law}
            })
            const fetchedLogs = parseEventLogs({
                        abi: separatedPowersAbi,
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
    async (description: string, calldata: `0x${string}`) => {
        let results: Array<boolean | undefined> = new Array<boolean | undefined>(6);

        setError(null)
        setStatus("pending")
        
        // this can be written better. But ok for now. 
        results[0] = checkDelayedExecution(description, calldata)
        results[1] = await checkThrottledExecution()
        results[2] = await checkAccountAuthorised()
        results[3] = checkProposalExists(description, calldata) != undefined
        results[4] = await checkProposalStatus(description, calldata)
        results[5] = await checkLawCompleted(description, calldata)
        results[6] = await checkLawNotCompleted(description, calldata)

        if (!results.find(result => {result == undefined})) setChecks({
          delayPassed: law.config.delayExecution == 0n ? true : results[0],
          throttlePassed: law.config.throttleExecution == 0n ? true : results[1],
          authorised: results[2],
          proposalExists: law.config.quorum == 0n ? true : results[3],
          proposalPassed: law.config.quorum == 0n ? true : results[4],
          lawCompleted: law.config.needCompleted == '0x0000000000000000000000000000000000000000' ? true : results[5],
          lawNotCompleted: law.config.needNotCompleted == '0x0000000000000000000000000000000000000000' ? true : results[6]
        })
        
        setStatus("idle") //NB note: after checking status, sets the status back to idle! 
  }, [ ])
  
  // Actions // 
  const fetchSimulation = useCallback( 
    async (initiator: `0x${string}`, lawCalldata: `0x${string}`, description: string) => {
      setError(null)
      setStatus("pending")
      try {
        const result = await readContract(wagmiConfig, {
          abi: lawAbi,
          address: law.law,
          functionName: 'simulateLaw', 
          args: [initiator, lawCalldata, description]
        })
          setSimulation(result as LawSimulation)
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

  return {status, error, law, simulation, checks, checkProposalExists, resetStatus, fetchSimulation, fetchChecks, execute}
}
