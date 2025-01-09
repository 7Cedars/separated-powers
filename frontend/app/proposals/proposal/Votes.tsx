"use client";

import { setLaw, useActionStore, useLawStore, useOrgStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useProposal } from "@/hooks/useProposal";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect, useState } from "react";

export const Votes: React.FC = () => {
  const {status, error, checks, law: currentLaw, execute, fetchSimulation, checkProposalExists, fetchChecks} = useLaw(); 
  const {status: statusProposal, error: errorProposal, proposals: proposal, fetchProposalsState, propose, cancel, castVote} = useProposal();
  const action = useActionStore();
  const layout = `w-full flex flex-row justify-center items-center px-2 py-1 text-bold`

  useEffect(() => {
    const selectedProposal = checkProposalExists(action.description, action.callData)
    if (selectedProposal) {
      fetchProposalsState([selectedProposal])
    }
  }, [])

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Votes
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
            { 
              !proposal ? 
                <div className={`${layout} text-slate-500`}> No Proposal Found </div>
              :
              proposal && proposal[0].state == 0 ? 
                <div className={`${layout} text-blue-500`}> Active </div>
              :
              proposal && proposal[0].state == 1 ? 
                <div className={`${layout} text-orange-500`}> Cancelled </div>
              :
              proposal && proposal[0].state == 2 ? 
                <div className={`${layout} text-red-500`}> Defeated </div>
              :
              proposal && proposal[0].state == 3 ? 
                <div className={`${layout} text-green-500`}> Succeeded </div>
              :
              proposal && proposal[0].state == 4 ? 
                <div className={`${layout} text-slate-500`}> Executed </div>
              :
              null 
            }
        </div>
    </section>
  )
}