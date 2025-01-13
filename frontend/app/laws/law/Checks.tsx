"use client";

import { Button } from "@/components/Button";
import { setLaw, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect } from "react";
import { roleColour } from "@/context/Theme"
import { parseRole } from "@/utils/parsers";
import { useRouter } from "next/navigation";

export const Checks: React.FC = () => {
  const {status, error, checks, law: currentLaw, execute, fetchSimulation, fetchChecks} = useLaw(); 
  const law = useLawStore();
  const router = useRouter();
  const organisation = useOrgStore();
  const action = useActionStore();
  const needCompletedLaw = organisation?.laws?.find(law => law.law == currentLaw.config.needCompleted); 
  const needNotCompletedLaw = organisation?.laws?.find(law => law.law == currentLaw.config.needNotCompleted); 

  useEffect(() => {
    fetchChecks("dummy string", "0x0")
  }, [])

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            { checks?.authorised ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            {/* <XMarkIcon className="w-4 h-4 text-red-600"/> */}
            <div>
            {checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

        {law.config.quorum != 0n ?
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
              { checks?.proposalPassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
              <div>
                Proposal passed
              </div>
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[parseRole(law.allowedRole)]} disabled:opacity-50`}
                onClick = {() => router.push('/proposals/proposal')}
                disabled = { !action.upToDate }
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1  px-2 py-1`}>
                { checks?.proposalExists ? "View Proposal" : "Create proposal" }
                </div>
              </button>
            </div>
          </div>
          : null
        }

        {/* Executed */}
        {law.config.needCompleted != `0x${'0'.repeat(42)}`  ?  
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
              <div>
                Law executed
              </div>
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[parseRole(needCompletedLaw?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {setLaw(needCompletedLaw ? needCompletedLaw : law)}}
                disabled = { !action.upToDate }
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                {needCompletedLaw?.name}
                </div>
              </button>
            </div>
          </div>
          :
          null
        }

        {/* Not executed */}
        {law.config.needNotCompleted != `0x${'0'.repeat(42)}` ? 
          <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.lawNotCompleted ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
              <div>
                Law not executed
              </div>
            </div>
            <div className = "w-full flex flex-row px-2 py-1">
              <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[parseRole(needNotCompletedLaw?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {setLaw(needNotCompletedLaw ? needNotCompletedLaw : law)}}
                disabled = { !action.upToDate }
                >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                 {needNotCompletedLaw?.name}
                </div>
              </button>
            </div>
          </div>
          : null
          }

        {/* Delay */}
        {law.config.delayExecution != 0n?
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.delayPassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
              Delayed execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              {`This law can only be executed ${law.config.delayExecution } blocks after a vote passed.`}
            </div>
          </div>
        </div>
        : null  
        }

        {/* Delay */}
        {law.config.throttleExecution != 0n ? 
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            { checks?.throttlePassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
              Throttled execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              {`This law can only be executed once every ${law.config.throttleExecution} blocks.`}
            </div>
          </div>
        </div>
        : null
        }
    </section>
  )
}