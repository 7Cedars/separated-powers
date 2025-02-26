"use client";

import React, { useEffect, useState } from "react";
import {ProposalBox} from "./ProposalBox";
import {ChecksBox} from "./ChecksBox"; 
import {Status} from "./Status"; 
import {Votes} from "./Votes"; 
import {Law} from "./Law";
import { useChecks } from "@/hooks/useChecks";
import { useActionStore, useLawStore } from "@/context/store";
import { Proposal } from "@/context/types";
import { GovernanceOverview } from "@/components/GovernanceOverview";

const Page = () => {
  const {checkProposalExists, checks, fetchChecks} = useChecks(); 
  const [selectedProposal, setSelectedProposal] = useState<Proposal>()
  const action = useActionStore();
  const law = useLawStore(); 

  useEffect(() => {
    const proposal = checkProposalExists(action.description as string, action.callData as `0x${string}`, law)
    setSelectedProposal(proposal)
  }, [action])

  useEffect(() => {
    fetchChecks(law, action.callData, action.description)
  }, [])

  return (
    <main className="w-full h-full flex flex-col justify-start items-center gap-3 px-4 pt-16 overflow-x-scroll">
      <GovernanceOverview law = {law} /> 
      {/* main body  */}
      <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start">

        {/* left panel  */}
        <div className="lg:w-5/6 w-full flex my-4 pb-16 min-h-fit"> 
         <ProposalBox />
        </div>

        {/* right panel  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap lg:max-h-full max-h-48 min-h-48  lg:w-96 lg:my-6 my-0 lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-scroll scroll-snap-x overflow-y-hidden"> 
      
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72">
            <Law /> 
          </div>
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72">
            { <Status proposal = {selectedProposal} /> }
          </div>
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border border-slate-300 rounded-md max-w-72"> 
            { checks && <ChecksBox checks = {checks} /> }  
          </div>
            { selectedProposal && <Votes proposal = {selectedProposal} /> }
        </div>
      </section>
    </main>
  )

}

export default Page 
