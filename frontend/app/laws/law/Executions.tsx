import { useOrgStore } from "@/context/store";
import Link from "next/link";
import { supportedChains } from "@/context/chains";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChainId } from "wagmi";


export function Executions() {
  const organisation = useOrgStore();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        {
          organisation.proposals?.length != 0 ?
          <div className = "w-full flex flex-col max-h-36 lg:max-h-56 overflow-y-scroll divide-y divide-slate-300">
            {organisation?.proposals?.map((proposal => 
              <div className = "w-full flex flex-col justify-center items-center p-2"> 
                <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
                  <div>
                    {/* need to get the timestamp.. */}
                    block: {proposal.blockNumber}  
                  </div>
                  {/* <div>
                    13:45
                  </div> */}
                </div>
                <div className = "w-full flex flex-row px-2">
                  {/* This should link to block explorer */}
                  <Link href={`${supportedChain?.blockExplorerUrl}/tx/${proposal.blockHash}`}>
                  <div className = "w-full flex flex-row justify-between gap-1 items-center">
                    {`hash: ${proposal.blockHash?.slice(0, 8)}...${proposal.blockHash?.slice(-8)} `} 
                    {/* <div className="text-left text-sm text-slate-500 w-fit"> */}
                          <ArrowUpRightIcon
                            className="w-3 h-3 text-slate-500"
                            />
                      {/* </div>    */}
                    </div>
                  </Link>
                </div>
                </div>
                ))
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