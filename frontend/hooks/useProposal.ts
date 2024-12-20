import { useCallback, useEffect, useRef, useState } from "react";
import { agDaoAbi } from "../context/abi";
import { Status } from "../context/types"
import { lawContracts } from "@/context/lawContracts";
import { writeContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { useWaitForTransactionReceipt } from "wagmi";

export const useProposal = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const [law, setLaw ] = useState<`0x${string}` | undefined>()
  const [error, setError] = useState<any | null>(null)
  const agDaoAddress: `0x${string}` = lawContracts.find((law: any) => law.contract === "AgDao")?.address as `0x${string}`

  const {error: errorReceipt, status: statusReceipt} = useWaitForTransactionReceipt({
    confirmations: 2, 
    hash: transactionHash,
  })

  useEffect(() => {
    if (statusReceipt === "success") setStatus("success")
    if (statusReceipt === "error") setStatus("error")
  }, [statusReceipt])


  // Status //
  // NB! see useProposals for checking status.. 


  // Actions // 
  const propose = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      description: string
    ) => {
        setStatus("loading")
        setLaw(targetLaw)
        try {
            const result = await writeContract(wagmiConfig, {
              abi: agDaoAbi,
              address: agDaoAddress,
              functionName: 'propose', 
              args: [targetLaw, lawCalldata, description]
            })
            setTransactionHash(result)
        } catch (error) {
            setStatus("error") 
            setError(error)
        }
  }, [ ])

  const cancel = useCallback( 
    async (
      targetLaw: `0x${string}`,
      lawCalldata: `0x${string}`,
      descriptionHash: `0x${string}`
    ) => {
        setStatus("loading")
        setLaw(targetLaw)
        try {
          const result = await writeContract(wagmiConfig, {
            abi: agDaoAbi,
            address: agDaoAddress,
            functionName: 'cancel', 
            args: [targetLaw, lawCalldata, descriptionHash]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  // note: I did not implement castVoteWithReason -- to much work for now. 
  const castVote = useCallback( 
    async (
      proposalId: bigint,
      support: bigint 
    ) => {
        setStatus("loading")
        setLaw("0x01") // note: a dummy value to signify cast vote 
        try {
          const result = await writeContract(wagmiConfig, {
            abi: agDaoAbi,
            address: agDaoAddress,
            functionName: 'castVote', 
            args: [proposalId, support]
          })
          setTransactionHash(result)
      } catch (error) {
          setStatus("error") 
          setError(error)
      }
  }, [ ])

  return {status, error, law, propose, cancel, castVote}
}
