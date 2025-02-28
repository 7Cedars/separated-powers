import { setAction, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import Link from "next/link";
import { supportedChains } from "@/context/chains";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useChainId } from "wagmi";
import { Execution, Status } from "@/context/types";
import { toEurTimeFormat, toFullDateFormat } from "@/utils/toDates";
import { Button } from "@/components/Button";
import { parseRole } from "@/utils/parsers";
import { useRouter } from "next/navigation";
 
 
export const Executions = ({executions}: {executions: Execution[] | undefined}) => {
  const law = useLawStore()

  console.log("@executions: ", {executions})

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
                  <Button
                      showBorder={true}
                      role={parseRole(law.allowedRole)}
                      onClick={() => {
                        setAction({
                          description: execution.log.args?.description,
                          callData: execution.log.args?.lawCalldata,
                          upToDate: false
                        })
                      }}
                      align={0}
                      selected={false}
                      >  
                      <div className = "flex flex-col w-full"> 
                        <div className = "w-full flex flex-row gap-1 justify-between items-center">
                            {`${toFullDateFormat(Number(execution.blocksData?.timestamp))}: ${toEurTimeFormat(Number(execution.blocksData?.timestamp))}`}
                        </div>
                        {/* <div className = "w-full flex flex-row justify-between items-center">
                          {`Tx:  ${execution.log.transactionHash?.slice(0, 12)}...${execution.log.transactionHash?.slice(-12)} `} 
                        </div> */}
                      </div>
                    </Button>
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