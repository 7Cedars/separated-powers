import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw, useActionStore, setProposal} from "@/context/store";
import { Law, Proposal, Status } from "@/context/types";
import { useProposal } from "@/hooks/useProposal";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { publicClient } from "@/context/clients";
import { separatedPowersAbi } from "@/context/abi";
import { supportedChains } from "@/context/chains";
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { useChainId } from "wagmi";
import { useRouter } from "next/navigation";

export function Transactions() {
  const organisation = useOrgStore();
  const {wallets} = useWallets();
  const {ready, authenticated, login, logout} = usePrivy();
  const [status, setStatus] = useState<Status>();
  const [error, setError] = useState<any | null>(null);
  const [transactions, setTransactions] = useState<Log[]>([]); // for now, adapt later. 
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id === chainId)
  const router = useRouter(); 

  console.log("@Transactions: ", {transactions})
  
  const fetchTransactions = useCallback(
    async () => {
      setError(null)
      setStatus("pending")

      if (publicClient) {
        try {
            if (organisation?.contractAddress) {
              const logs = await publicClient.getContractEvents({ 
                address: organisation.contractAddress as `0x${string}`,
                abi: separatedPowersAbi, 
                eventName: 'ProposalExecuted',
                fromBlock: supportedChain?.genesisBlock
              })
              const fetchedLogs = parseEventLogs({
                          abi: separatedPowersAbi,
                          eventName: 'ProposalExecuted',
                          logs
                        })
              const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType  
              const transactionsSorted = fetchedLogsTyped.sort((a: Log, b: Log) => (a.blockNumber ? Number(a.blockNumber) : 0) < (b.blockNumber == null ? 0 : Number(b.blockNumber)) ? 1 : -1)
              setTransactions(transactionsSorted)
            } 
        } catch (error) {
          setStatus("error") 
          setError(error)
        }
      }
      setStatus("success")
    }, [])
    
  useEffect(() => {
    fetchTransactions()
  }, [])

  return (
    <div className="w-full h-full grow flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
    {
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
      <div className="w-full border-b border-slate-300">
        <div className="w-full flex flex-row items-center justify-between p-2">
          <div className="text-left text-sm text-slate-600 w-52">
            Latest transactions
          </div> 
        </div>
      </div>
       {/* below should be a button */}
      <div className = "w-full h-full lg:h-48 flex flex-col gap-0 justify-start items-center overflow-y-scroll py-1 divide-y divide-slate-300">
      {
        transactions && transactions.length > 0 ? transactions.map((transaction: Log, i) =>
          <div className = {"w-full flex flex-col gap-1 justify-between items-center p-3"}>
            <div className ="w-full flex flex-row gap-1 text-sm text-slate-600 justify-between items-center">
              <div className = "w-full flex flex-row justify-start items-center text-right">
                Block:
              </div>
              <div className = "w-full flex flex-row justify-end items-center text-right">
                {/* here a number */}
                {Number(transaction.blockNumber)}
              </div>
            </div>
            <div className ="w-full flex flex-row gap-1 text-sm text-slate-600 justify-between items-center">
              <div className = "w-full flex flex-row justify-start items-center text-right">
                Hash: 
              </div>
              <div className = "w-full flex flex-row justify-end items-center text-right">
              <a href={`${supportedChain?.blockExplorerUrl}/tx/${transaction.transactionHash}`} target="_blank" rel="noopener noreferrer">
                <div className="w-full flex flex-row items-center justify-start gap-1">
                  <div className="text-left text-sm text-slate-600">
                    {transaction.transactionHash?.slice(0, 8)}...{transaction.transactionHash?.slice(-8)}
                  </div> 
                    <ArrowUpRightIcon
                      className="w-3 h-3 text-slate-800"
                      />
                </div>
              </a>              
              </div>
            </div>
          </div>
          )
          :
          <div className = "w-full flex flex-row gap-1 text-sm text-slate-600 justify-between items-center p-3">
            No transactions found
          </div>
        }
      </div>
    </div>
  }
  </div>
  )
}
