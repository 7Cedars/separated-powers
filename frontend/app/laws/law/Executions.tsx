import { useOrgStore } from "@/context/store";
import Link from "next/link";


export function Executions() {
  const organisation = useOrgStore();
  
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
          <>
            {organisation?.proposals?.map((proposal => 
              <div className = "w-full flex flex-col justify-center items-center p-2"> 
                <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
                  <div>
                    {/* need to get the timestamp.. */}
                    {proposal.blockNumber}  
                  </div>
                  {/* <div>
                    13:45
                  </div> */}
                </div>
                <div className = "w-full flex flex-row px-2">
                  {/* This should link to block explorer */}
                  <Link href="/laws/law">
                    {proposal.blockHash}
                  </Link>
                </div>
              </div>
              ))
            }
            </>
            :
              <div className = "w-full flex flex-col justify-center items-center italic p-2">
                No executions found. 
              </div> 
          }
        

    </section>
  )
}