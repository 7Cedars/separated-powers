"use client";

import { separatedPowersAbi } from "@/context/abi";
import { setLaw, useActionStore, useLawStore, useOrgStore, useProposalStore } from "@/context/store";
import { Proposal } from "@/context/types";
import { useLaw } from "@/hooks/useLaw";
import { useProposal } from "@/hooks/useProposal";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect, useState } from "react";
import { useReadContract } from "wagmi";

export const Votes: React.FC = () => {
  const {law, checkProposalExists} = useLaw(); 
  const action = useActionStore();
  const organisation = useOrgStore()
  const [quorumPassed, setQuorumPassed] = useState<boolean>()
  const [thresholdPassed, setThresholdPassed] = useState<boolean>()
  const [selectedProposal, setSelectedProposal] = useState<Proposal>()
  const { status: readContractStatus, data: proposalVotes } = useReadContract({
    address: organisation.contractAddress,
    abi: separatedPowersAbi,  
    functionName: 'getProposalVotes',
    args: [selectedProposal?.proposalId],
  })

  useEffect(() => {
    const proposal = checkProposalExists(action.description as string, action.callData as `0x${string}`)
    setSelectedProposal(proposal)
  }, [action])

  console.log("@Votes:", {action, selectedProposal, proposalVotes, law})

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Votes
          </div> 
        </div>

        {/* Quorum block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { quorumPassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { quorumPassed ? "Quorum passed" : "Quorum not passed"}
            </div>
          </div>
          <div className={`relative w-full leading-none rounded-sm h-3 border border-slate-300 overflow-hidden`}>
            <div 
              className={`absolute bottom-0 leading-none h-3 bg-slate-400`}
              style={{width:`60%`}}> 
            </div>
          </div>
          <div className="w-full text-sm text-left text-slate-500"> 
            12 / 40 votes
          </div>
        </div>

        {/* Threshold block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { thresholdPassed ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { thresholdPassed ? "Threshold passed" : "Threshold not passed"}
            </div>
          </div>
          <div className={`relative w-full flex flex-row justify-start leading-none rounded-sm h-3 border border-slate-300`}>
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-gray-400`} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-red-400`} style={{width:`60%`}} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-green-400`} style={{width:`20%`}} />
            <div className={`absolute -top-2 w-full leading-none h-6 border-r-4 border-green-500`} style={{width:`60%`}} />
          </div>
          <div className="w-full flex flex-row justify-between items-center"> 
            <div className="w-fit text-sm text-center text-green-500">
              12 for
            </div>
            <div className="w-fit text-sm text-center text-red-500">
              2 against
            </div>
            <div className="w-fit text-sm text-center text-gray-500">
              4 abstain
            </div>
          </div>
        </div>

    </section>
  )
}