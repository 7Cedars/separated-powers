"use client";

import { setLaw, useActionStore, useLawStore, useOrgStore, useProposalStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useProposal } from "@/hooks/useProposal";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect, useState } from "react";
import { useReadContract } from 'wagmi'
import { separatedPowersAbi } from "@/context/abi";
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
    abi: separatedPowersAbi,  
    functionName: 'state',
    args: [selectedProposal?.proposalId],
  })
  // I should set Action @proposalBox, and read action here. Then the lines below can go. 
  const description =  proposal?.description && proposal.description.length > 0 ? proposal.description 
  : action.description && action.description.length > 0 ? action.description
  : undefined  
  const calldata =  proposal?.executeCalldata && proposal.executeCalldata.length > 0 ? proposal.executeCalldata 
    : action.callData && action.callData.length > 0 ? action.callData
    : undefined  

  useEffect(() => {
    const proposal = checkProposalExists(description as string, calldata as `0x${string}`)
    setSelectedProposal(proposal)
  }, [])

console.log({readContractStatus, proposalState})

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