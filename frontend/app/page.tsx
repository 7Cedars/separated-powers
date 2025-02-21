// This should become landing page: 
// searchers for deployed Separated Powers Protocols.
// Has search bar.
// also has template DAOs to deploy.  
// Loads names,# laws, # proposals, # roles, # members, chain. 
// see example: https://www.tally.xyz/explore

"use client";

import React, { useState, useEffect } from "react";
import { useOrgStore } from "@/context/store";
import { useRouter } from "next/navigation";
import { useOrganisations } from "@/hooks/useOrganisations";
import { ExampleUseCases } from "./ExampleUsecases";
import { ExampleDemos } from "./ExampleDemos";
import { RunNewDemo } from "./RunNewDemo";
import { Footer } from "./Footer";
import { AdvantagesRRG } from "./AdvantagesRRG";
import { 
    ChevronDownIcon
  } from '@heroicons/react/24/outline';
import { GovernanceOverview } from "./Experiments";

export default function Page() {
    const router = useRouter();
    const organisation = useOrgStore()
    const { organisations, status, initialise } = useOrganisations()
 
    useEffect(() => {
        if (organisation.name != '') router.push('/home') 
    }, [organisation])

    useEffect(() => {
        initialise() 
    }, [ ])

    return (
        <main className="w-full flex flex-col gap-0 overflow-y-scroll snap-y snap-mandatory overflow-x-hidden">
            <section className="w-full min-h-[100vh] h-fit flex flex-col justify-center items-center bg-gradient-to-b from-indigo-900 to-blue-600 snap-start snap-always border-b-0 -m-1"> 
            
                {/* Title and subtitle */}
                <section className="w-full h-fit flex flex-col justify-center items-center p-4 pt-20 pb-20">
                    <div className = "w-full flex flex-col gap-1 justify-center items-center text-3xl sm:text-6xl font-bold text-slate-100 max-w-3xl text-center">
                        Communities thrive with Powers Protocol  
                    </div>
                    <div className = "w-full flex justify-center items-center text-xl sm:text-2xl py-4 text-slate-300 max-w-xl text-center p-4">
                        Distribute power, increase security, transparency and efficiency with role restricted governance
                    </div>
                </section> 

                {/* arrow down */}
                <div className = "flex flex-col align-center justify-end"> 
                <ChevronDownIcon
                    className = "w-16 h-16 text-slate-100" 
                /> 
                </div>
            </section>

            < ExampleUseCases /> 
            < AdvantagesRRG /> 
            {status == "success" && organisations &&  < ExampleDemos organisations = {organisations}  /> } 
            < RunNewDemo />
            {status == "success" && organisations && < GovernanceOverview organisation = {organisations[1]}  /> } 
            <div className = "min-h-48"/>  
            < Footer /> 
           
        </main>
    )
}
