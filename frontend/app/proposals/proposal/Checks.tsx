"use client";

import { setLaw, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect } from "react";

export const Checks: React.FC = () => {
  const {checks, fetchChecks} = useLaw(); 

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
            <div>
            {checks?.authorised ? "Account authorised" : "Account not authorised"  } 
            </div>
          </div>
        </div>

    </section>
  )
}