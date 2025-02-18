import { useLawStore, useOrgStore } from "@/context/store";
import Link from "next/link";
import { supportedChains } from "@/context/chains";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChainId } from "wagmi";
import { useCallback, useEffect, useState } from "react";
import { Status } from "@/context/types";
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { powersAbi } from "@/context/abi";
import { publicClient } from "@/context/clients";


export function Executions() {
  const organisation = useOrgStore();
  const law = useLawStore();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  const [status, setStatus] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [executions, setExecutions] = useState<Log[]>([]) 

  const fetchExecutions = useCallback(
    async () => {
      setError(null)
      setStatus("pending")

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
              const executionsSorted = fetchedLogsTyped.sort((a: Log, b: Log) => (a.blockNumber ? Number(a.blockNumber) : 0) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)
              setExecutions(executionsSorted)
            } 
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
      setStatus("success")
    }, [])
    
  useEffect(() => {
    fetchExecutions()
  }, [])
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {
          executions?.length != 0 ?
          <div className = "w-full flex flex-col max-h-36 lg:max-h-56 overflow-y-scroll divide-y divide-slate-300">
            {executions?.map((execution: Log, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2"> 
                <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
                  <div>
                    {/* need to get the timestamp.. */}
                    block: {Number(execution.blockNumber)}  
                  </div>
                  {/* <div>
                    13:45
                  </div> */}
                </div>
                <div className = "w-full flex flex-row px-2">
                  {/* This should link to block explorer */}
                  <a href={`${supportedChain?.blockExplorerUrl}/tx/${execution.transactionHash}`} target="_blank" rel="noopener noreferrer">
                  <div className = "w-full flex flex-row justify-between gap-1 items-center">
                    {`hash: ${execution.transactionHash?.slice(0, 8)}...${execution.transactionHash?.slice(-8)} `} 
                          <ArrowUpRightIcon
                            className="w-3 h-3 text-slate-500"
                            />
                    </div>
                  </a>
                </div>
                </div>
                )
            }
            </div>
            :
            <div className = "w-full flex flex-col justify-center items-center italic text-slate-400 p-2">
                No executions found. 
            </div> 
          }
        

    </section>
  )
}