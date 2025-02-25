import { useActionStore, useLawStore, useOrgStore } from "@/context/store";
import Link from "next/link";
import { supportedChains } from "@/context/chains";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChainId } from "wagmi";
import { useCallback, useEffect, useState } from "react";
import { Execution, Status } from "@/context/types";
import { Log, parseEventLogs, ParseEventLogsReturnType } from "viem";
import { powersAbi } from "@/context/abi";
import { publicClient } from "@/context/clients";
import { getBlock, GetBlockReturnType } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/transformData";
 
 
export const Executions = ({executions}: {executions: Execution[] | undefined}) => {
  const law = useLawStore();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  // console.log("@executions: ", {executions})

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {
          executions && executions?.length != 0 ?
          <div className = "w-full flex flex-col max-h-36 lg:max-h-56 overflow-y-scroll divide-y divide-slate-300">
            {executions.map((execution: Execution, index: number) => 
              <div className = "w-full flex flex-col justify-center items-center p-2" key = {index}> 
                <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
                    {`${toFullDateFormat(Number(execution.blocksData?.timestamp))}: ${toEurTimeFormat(Number(execution.blocksData?.timestamp))}`}
                </div>
                <div className = "w-full flex flex-row px-2">
                  {/* This should link to block explorer */}
                  <a href={`${supportedChain?.blockExplorerUrl}/tx/${execution.log.transactionHash}`} target="_blank" rel="noopener noreferrer">
                  <div className = "w-full flex flex-row justify-between gap-1 items-center">
                    {`${execution.log.transactionHash?.slice(0, 12)}...${execution.log.transactionHash?.slice(-12)} `} 
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