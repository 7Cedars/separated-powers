"use client";

import { Button } from "@/components/Button";
import { useLawStore } from "@/context/store";
import { userActionsProps } from "@/context/types";
import { useLaw } from "@/hooks/useLaw";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";


export const Checks: React.FC = () => {
  const {status, error, checks, law: currentLaw, execute, simulate, checkStatus} = useLaw(); 
  const law = useLawStore();
  const roleColour = [
    "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
    "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
  ]
  const role = law.allowedRole == 0n ? 0 
    : law.allowedRole == 4294967295n ? 6 
    : Number(law.allowedRole)

    console.log("checks", checks)
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Checks
          </div> 
          <button onClick={() => checkStatus("description", "0x0")}>
            <ArrowPathIcon
              className="w-4 h-4 text-slate-600"
              />
          </button>
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            <XMarkIcon className="w-4 h-4 text-red-600"/>
            <div>
              Account authorised
            </div>
          </div>
        </div>

        {/* from here on elements need to be conditional  */}
        {/* Proposal Vote */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            <CheckIcon className="w-4 h-4 text-green-600"/>
            <div>
              Proposal passed
            </div>
          </div>
          <div className = "w-full flex flex-row px-2 py-1">
            <button className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[role]}`}>
              <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1  px-2 py-1`}>
                View / Create Proposal
              </div>
            </button>
          </div>
        </div>

        {/* Executed */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            <CheckIcon className="w-4 h-4 text-green-600"/>
            <div>
              Law executed
            </div>
          </div>
          <div className = "w-full flex flex-row px-2 py-1">
            <button className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[1]}`}>
              <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                Here a law name
              </div>
            </button>
          </div>
        </div>

        {/* Not executed */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            <XMarkIcon className="w-4 h-4 text-red-600"/>
            <div>
              Law not executed
            </div>
          </div>
          <div className = "w-full flex flex-row px-2 py-1">
            <button className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[1]}`}>
              <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                Here a law name
              </div>
            </button>
          </div>
        </div>

        {/* Delay */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            <XMarkIcon className="w-4 h-4 text-red-600"/>
            <div>
              Delayed execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              X blocks left until execution allowed
            </div>
          </div>
        </div>

        {/* Delay */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 justify-between items-center">
            <XMarkIcon className="w-4 h-4 text-red-600"/>
            <div>
              Throttled execution
            </div>
          </div>
          <div className = "w-full flex flex-row pt-2">
            <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 px-3`}>
              X blocks left until next execution allowed
            </div>
          </div>
        </div>
    </section>
  )
}