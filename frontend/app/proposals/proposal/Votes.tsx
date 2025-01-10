"use client";

import { separatedPowersAbi } from "@/context/abi";
import { parseVoteData } from "@/context/parsers";
import { setLaw, useActionStore, useLawStore, useOrgStore, useProposalStore } from "@/context/store";
import { Proposal } from "@/context/types";
import { useLaw } from "@/hooks/useLaw";
import { useProposal } from "@/hooks/useProposal";
import { XCircleIcon, CheckIcon, XMarkIcon,ArrowPathIcon } from "@heroicons/react/24/outline";
import { useEffect, useState } from "react";
import { useReadContracts } from "wagmi";

export const Votes: React.FC = () => {
  const {law, checkProposalExists} = useLaw(); 
  const action = useActionStore();
  const organisation = useOrgStore()
  const [selectedProposal, setSelectedProposal] = useState<Proposal>()
  
  const separatedPowersContract = {
    address: organisation.contractAddress,
    abi: separatedPowersAbi,
  } as const
  const { isSuccess, status, data } = useReadContracts({
    contracts: [
      {
        ...separatedPowersContract,
        functionName: 'getProposalVotes',
        args: [selectedProposal?.proposalId]
      }, 
      {
        ...separatedPowersContract,
        functionName: 'getAmountRoleHolders', 
        args: [law.allowedRole]
      }, 
    ]
  })

  useEffect(() => {
    const proposal = checkProposalExists(action.description as string, action.callData as `0x${string}`)
    setSelectedProposal(proposal)
  }, [action])

  const votes = isSuccess ? parseVoteData(data).votes : [0, 0, 0]
  const init = 0
  const allVotes = votes.reduce((acc, current) => acc + current, init)
  const quorum = isSuccess ? Math.floor((parseVoteData(data).holders * 100) / Number(law.config.quorum)) : 0
  const threshold = isSuccess ? Math.floor((parseVoteData(data).holders * 100) / Number(law.config.succeedAt)) : 0

  console.log("@Votes:", {action, selectedProposal, data, law, status})

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
            { votes[1] + votes[2] >= quorum ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { votes[1] + votes[2] >= quorum ? "Quorum passed" : "Quorum not passed"}
            </div>
          </div>
          <div className={`relative w-full leading-none rounded-sm h-3 border border-slate-300 overflow-hidden`}>
            <div 
              className={`absolute bottom-0 leading-none h-3 bg-slate-400`}
              style={{width:`${((votes[1] + votes[2]) * 100) / quorum }%`}}> 
            </div>
          </div>
          <div className="w-full text-sm text-left text-slate-500"> 
           {isSuccess ? `${votes[1] + votes[2] } / ${quorum} votes` : ""}
          </div>
        </div>

        {/* Threshold block */}
        <div className = "w-full flex flex-col justify-center items-center gap-2 py-2 px-4"> 
          <div className = "w-full flex flex-row justify-between items-center">
            { votes[1] >= threshold ? <CheckIcon className="w-4 h-4 text-green-600"/> : <XMarkIcon className="w-4 h-4 text-red-600"/>}
            <div>
            { votes[1] >= threshold ? "Threshold passed" : "Threshold not passed"}
            </div>
          </div>
          <div className={`relative w-full flex flex-row justify-start leading-none rounded-sm h-3 border border-slate-300`}>
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-gray-400`} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-red-400`} style={{width:`${((votes[1] + votes[0]) / allVotes)*100}%`}} />
            <div className={`absolute bottom-0 w-full leading-none h-3 bg-green-400`} style={{width:`${((votes[1]) / allVotes)*100}%`}} />
            <div className={`absolute -top-2 w-full leading-none h-6 border-r-4 border-green-500`} style={{width:`${law.config.succeedAt}%`}} />
          </div>
          <div className="w-full flex flex-row justify-between items-center"> 
            <div className="w-fit text-sm text-center text-green-500">
              {isSuccess ? `${votes[1]} for` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-red-500">
              {isSuccess ? `${votes[0]} against` : "na"}
            </div>
            <div className="w-fit text-sm text-center text-gray-500">
            {isSuccess ? `${votes[2]} abstain` : "na"}
            </div>
          </div>
        </div>

    </section>
  )
}