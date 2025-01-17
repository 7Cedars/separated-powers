// This should become landing page: 
// searchers for deployed Separated Powers Protocols.
// Has search bar.
// also has template DAOs to deploy.  
// Loads names,# laws, # proposals, # roles, # members, chain. 
// see example: https://www.tally.xyz/explore

"use client";

import React, { useState, useEffect } from "react";
import { useOrgStore, assignOrg } from "@/context/store";
import { useRouter } from "next/navigation";
import { Button } from "../components/Button";
import { useOrganisations } from "@/hooks/useOrganisations";
import { colourScheme } from "@/context/Theme"
import Image from 'next/image'

const useCases = [
    {
        value: "Increase efficiency by delegating tasks",
        image: "/lawList.png",
        imageNarrow: "/lawListNarrow.png", 
        detail: "Define tasks in external programmable contracts, called laws, and assign them to specific roles.",
        examples: ["example 1", "example 2", "example 3"]
    }, 
    {
        value: "Use oracles to automate tasks seamlessly",
        image: "/proposal.png", 
        imageNarrow: "/proposalNarrow.png", 
        detail: "Seamlessly integrate with time based oracles to execute laws automatically.",
        examples: ["example 1", "example 2", "example 3"]
    },
    {
        value: "Increase security through checks and balances",
        image: "/law.png", 
        imageNarrow: "/lawListNarrow.png", 
        detail: "Only allow tasks to be executed if certain conditions have been met. For example, if other roles have (not) passed like-for-like proposals.",
        examples: ["example 1", "example 2", "example 3"]
    }, 
    {
        value: "Distribute power by designating roles to diverse groups",
        image: "/roles.png", 
        imageNarrow: "/rolesNarrow.png", 
        detail: "Create roles for builders, community leaders, token holders, and more.",
        examples: ["example 1", "example 2", "example 3"]
    },
    {
        value: "Cut the noise, while remaining transparent",
        image: "/home.png", 
        imageNarrow: "/homeNarrow.png", 
        detail: "Each roles submits proposals, votes and executes within their role defined group, but open for all to see.",
        examples: ["example 1", "example 2", "example 3"]
    },
    // .... more can be added
]

export default function Page() {
    const router = useRouter();
    const organisation = useOrgStore()
    const { fetchOrganisations, organisations, status } = useOrganisations()
    
    console.log("organisations", organisations)
    console.log("organisation", organisation)
    useEffect(() => {
        if (organisation.name != '') router.push('/home') 
    }, [organisation])

    useEffect(() => {
        if (status == 'idle') fetchOrganisations()
    }, [status])

    return (
        <main className="w-full grid grid-cols-1 gap-0 overflow-y-scroll snap-y snap-mandatory overflow-x-hidden">
            
            {/* section 1 */}
            <section className="w-full h-[80vh] flex flex-col justify-center items-center bg-gradient-to-b from-indigo-900 to-blue-500 snap-start snap-always"> 
            
                {/* Title and subtitle */}
                <section className="w-full h-fit flex flex-col justify-center items-center p-4 pt-20 pb-20">
                    <div className = "w-full flex justify-center items-center text-3xl sm:text-6xl text-slate-100 font-bold max-w-3xl text-center">
                        Communities thrive with Separated Powers
                    </div>
                    {/* <div className = "w-full flex justify-center items-center text-3xl text-slate-300">
                        R for onchain communities.
                    </div> */}
                    <div className = "w-full flex justify-center items-center text-xl sm:text-2xl py-4 text-slate-300 max-w-xl text-center p-4">
                        Distribute power, increase security, transparency and efficiency with role restricted governance
                    </div>
                </section> 
            </section>

            <section className="w-full h-[80vh] flex flex-col justify-center items-center bg-gradient-to-b from-blue-500 via-70% to-slate-100 snap-start snap-always p-12">    
                {/* scroll-snap-x overflow-y-hidden p-4 snap-always snap-center animate-loop-scroll */}
                {/* use cases  */}
                <section className="w-screen min-h-fit h-full h-full flex flex-row gap-12 justify-between items-start overflow-x-scroll snap-x snap-mandatory">
                    <div className="min-w-[20vw] h-full flex flex-col justify-center items-center snap-center snap-always gap-2" />
                    {
                        useCases.map((useCase, index) => (
                            <div className="min-w-[60vw] h-full flex flex-col justify-center items-center text-slate-50 snap-center snap-always" key={index}> 
                                <div className="w-full h-fit text-center text-pretty text-lg sm:text-2xl text-slate-200 py-4">
                                    {useCase.value}
                                </div> 
                                <div className="shrink w-0 max-h-0 md:grow md:w-full md:max-h-[60vw]" style = {{position: 'relative', width: '100%', height: '100%'}}>
                                    <Image 
                                        src={useCase.image} 
                                        className = "rounded-md" 
                                        style={{objectFit: "contain", objectPosition: "center"}}
                                        fill={true}
                                        alt="Screenshot Separated Powers"
                                        >
                                    </Image>
                                 </div>
                                 <div className="md:shrink md:w-0 md:max-h-0 grow w-full max-h-[60vw]" style = {{position: 'relative', width: '100%', height: '100%'}}>
                                    <Image 
                                        src={useCase.imageNarrow} 
                                        className = "rounded-md" 
                                        style={{objectFit: "contain", objectPosition: "center"}}
                                        fill={true}
                                        alt="Screenshot Separated Powers"
                                        >
                                    </Image>
                                 </div>
                                <div className = "py-4 max-w-xl h-fit flex flex-row justify-between items-center text-md sm:text-lg text-slate-500 text-center text-pretty">
                                    {useCase.detail}
                                </div> 
                                {/* <div className = "px-4 w-full h-full flex flex-row justify-center items-center text-center text-slate-600">
                                    See:
                                    {useCase.examples.map((example, index) => (
                                        <div className = "p-2" key={index}>
                                            {example}
                                        </div>
                                    ))}
                                </div> */}
                            </div> 
                        ))
                    }
                    <div className="min-w-[20vw] h-full flex flex-col snap-center snap-always gap-2" />
                </section>
            </section> 

            {/* section 2 */}
            <section className = "w-full min-w-[60vw] h-screen flex flex-col justify-start items-center snap-start px-4"> 
                <div className = "w-full flex flex-row justify-center items-center text-3xl text-slate-600 text-center text-pretty font-bold py-16 px-4">
                    Want to play around with a live demo?
                </div>
                {/* table with example orgs  */}
                <section className="w-full h-full flex flex-col justify-start items-center">
                    <div className="w-full flex flex-col justify-start items-center border border-slate-300 rounded-md overflow-hidden max-w-5xl">
                    <table className="w-full table-auto">
                    <thead className="w-full">
                        <tr className="min-w-96 bg-slate-50 text-xs font-light text-slate-600 border-b border-slate-300">
                            <th className=""></th>
                            <th className="text-left ps-4 py-2 font-light ">Name</th>
                            <th className="text-right font-light">Laws</th>
                            <th className="text-right font-light">Proposals</th>
                            <th className="text-right font-light">Roles</th> 
                            <th className="text-right font-light pe-2">Chain</th>
                        </tr>
                    </thead>
                    <tbody className="w-full text-sm text-right text-slate-600 bg-slate-50 divide-y divide-slate-300">
                        {
                            organisations?.map((org, index) => (
                                <tr key={index} className="text-sm text-right text-slate-900 h-16">
                                    <td className="w-6">
                                        <div className={`ms-4 h-6 w-6 bg-gradient-to-bl ${colourScheme[index % colourScheme.length]} rounded-full`}/>
                                    </td>
                                    <td className="text-left">
                                        <Button 
                                            size={1} align={0} showBorder={false} onClick={() => assignOrg({...org, colourScheme: index % colourScheme.length})}>
                                            {org.name}
                                        </Button>
                                    </td>
                                    <td>{org.laws?.length}</td>
                                    <td>{org.proposals?.length}</td>
                                    <td>{org.roles?.length}</td>
                                    <td className="pe-4"> Arbitrum </td>
                                </tr>
                            ))
                        }
                    </tbody>
                    </table>
                    </div> 
                </section>
            </section> 
        </main>
    )
}
