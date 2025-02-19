"use client";

import { useActionStore, useOrgStore, useProposalStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useEffect, useState } from "react";
import { useReadContract } from 'wagmi'
import { powersAbi } from "@/context/abi";
import { Proposal } from "@/context/types";

export const Status: React.FC = () => {
  const organisation = useOrgStore()
  const action = useActionStore();
  const proposal = useProposalStore(); 
  const { checkProposalExists, } = useLaw(); 
  const [selectedProposal, setSelectedProposal] = useState<Proposal>()
  const layout = `w-full flex flex-row justify-center items-center px-2 py-1 text-bold rounded-md`
  const { status: readContractStatus, data: proposalState } = useReadContract({
    address: organisation.contractAddress,
    abi: powersAbi,  
    functionName: 'state',
    args: [selectedProposal?.proposalId],
  })

  useEffect(() => {
    if (action.callData && action.description) {
      const proposal = checkProposalExists(action.description, action.callData)
      setSelectedProposal(proposal)
    }
  }, [action])

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Status
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
            { 
              !selectedProposal ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> No Proposal Found </div>
              :
              proposalState == 0 ? 
                <div className={`${layout} text-blue-500 bg-blue-100`}> Active </div>
              :
              proposalState == 1 ? 
                <div className={`${layout} text-orange-500 bg-orange-100`}> Cancelled </div>
              :
              proposalState ==  2 ? 
                <div className={`${layout} text-red-500 bg-red-100`}> Defeated </div>
              :
              proposalState ==  3 ? 
                <div className={`${layout} text-green-500 bg-green-100`}> Succeeded </div>
              :
              proposalState == 4 ? 
                <div className={`${layout} text-slate-500 bg-slate-100`}> Executed </div>
              :
              null 
            }
        </div>
    </section>
  )
}