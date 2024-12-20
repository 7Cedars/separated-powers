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
  authorised?: boolean | 'checked';
  proposalPassed?: boolean | 'checked';
  lawCompleted?: boolean | 'checked';
  lawNotCompleted?: boolean | 'checked';
  delayPassed?: boolean | 'checked';
  throttlePassed?: boolean | 'checked';
}

export const useLaw = () => {
  const organisation = useOrgStore()
  const law = useLawStore()
  const blockNumber = useBlockNumber()
  const {wallets} = useWallets();
  const wallet = wallets[0];

  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
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

  // Status //
  const checkAccountAuthorised = useCallback(
    async () => {
      console.log({
        org: organisation.contractAddress,
        wallet: wallet.address,
        law: law.law
      })
      try {
        const result =  await readContract(wagmiConfig, {
                abi: separatedPowersAbi,
                address: organisation.contractAddress as `0x${string}`,
                functionName: 'canCallLaw', 
                args: [wallet.address, law.law],
              })
        setChecks({...checks, authorised: result as boolean})
    } catch (error) {
        setStatus("error") 
        setError(error)
    }
  }, []) 

  const checkProposalStatus = useCallback(
    async (description: string, calldata: `0x${string}`) => {
      const selectedProposal = organisation?.proposals?.find(proposal => 
        proposal.targetLaw === law.law && 
        proposal.executeCalldata === calldata && 
        proposal.description === description
      ) 
      console.log("selectedProposal @checkProposalStatus", selectedProposal)
    
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
          setChecks({...checks, proposalPassed: result as boolean})
        } catch (error) {
          setStatus("error")
          setChecks({...checks, proposalPassed: false})
        }
      } else {
        setChecks({...checks, proposalPassed: false})
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
          const state =  await readContract(wagmiConfig, {
                  abi: separatedPowersAbi,
                  address: organisation.contractAddress as `0x${string}`,
                  functionName: 'state', 
                  args: [selectedProposal.proposalId],
                })
          console.log("state @checkLawCompleted", state)
          const result = Number(state) == 4
          setChecks({...checks, lawCompleted: result as boolean})
        } else {
          setChecks({...checks, lawCompleted: false})
        }
      } catch (error) {
        setStatus("error")
        setChecks({...checks, lawCompleted: false})
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
          setChecks({...checks, lawNotCompleted: result as boolean})
        } else {
          setChecks({...checks, lawNotCompleted: true})
        }
      } catch {
        setStatus("error")
        setChecks({...checks, lawNotCompleted: true})
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
    setChecks({...checks, delayPassed: result as boolean})
  }

  const checkThrottledExecution = () => {
    const selectedProposals = organisation?.proposals?.filter(proposal => 
      proposal.targetLaw === law.law && 
      proposal.state === 4
    )
    if (selectedProposals) {
      const result = selectedProposals[0].blockNumber + Number(law.config.throttleExecution) < Number(blockNumber)
      setChecks({...checks, throttlePassed: result})
    } else {
      setChecks({...checks, throttlePassed: true})
    } 
  }

  const checkStatus = useCallback( 
    async (description: string, calldata: `0x${string}`) => {
        setStatus("loading")
        
        // this can be written better. But ok for now. 
        await checkAccountAuthorised()
        if (law.config.quorum != 0n) await checkProposalStatus(description, calldata)
        if (law.config.needCompleted != '0x0000000000000000000000000000000000000000') await checkLawCompleted(description, calldata)
        if (law.config.needNotCompleted != '0x0000000000000000000000000000000000000000') await checkLawNotCompleted(description, calldata)
        if (law.config.delayExecution != 0n) checkDelayedExecution(description, calldata)
        // if (law.config.throttleExecution == 0n) checkThrottledExecution()

        setStatus("success")
  }, [ ])
  

  // Actions // 
  // £todo:  need to retrieve the data that is returned from this call. 
  const simulate = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      description: string
    ) => {
        setStatus("loading")
        try {
          // NB! This needs to be READcontract. 
          const result = await writeContract(wagmiConfig, {
            abi: lawAbi,
            address: law.law,
            functionName: 'simulateLaw', 
            args: [targetLaw, lawCalldata, description]
          })
          setTransactionHash(result)
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
        setStatus("loading")
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

  return {status, error, law, checks, execute, simulate, checkStatus}
}
