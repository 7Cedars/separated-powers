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
import { ArrowPathIcon, HeartIcon } from '@heroicons/react/24/outline';

const useCases = [
    {
        value: "",
        image: "",
        imageNarrow: "", 
        detail: "",
        examples: [] 
    }, 
    {
        value: "Increase efficiency by delegating tasks",
        image: "/lawList.png",
        imageNarrow: "/lawListNarrow.png", 
        detail: "Define tasks in external programmable contracts, called laws, and assign them to specific roles.",
        examples: ["example 1", "example 2", "example 3"] 
    }, 
    {
        value: "Cut the noise, while remaining transparent",
        image: "/home.png", 
        imageNarrow: "/homeNarrow.png", 
        detail: "Each roles submits proposals, votes and executes within their role defined group, but open for all to see.",
        examples: ["example 1", "example 2", "example 3"]
    },
    {
        value: "Decentralise power by designating roles to diverse groups",
        image: "/roles.png", 
        imageNarrow: "/rolesNarrow.png", 
        detail: "Create roles for builders, community leaders, token holders, and more.",
        examples: ["example 1", "example 2", "example 3"]
    },
    {
        value: "Fully composable to integrate with your favorite tools",
        image: "/home.png", 
        imageNarrow: "/homeNarrow.png", 
        detail: "Separated Powers can be used in combination with existing governance tools like OpenZeppelin's Governor or Safe multiSig Wallets, laws integrate seamlessly with oracles and other (on or off-)chain tools.",
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
        value: "Further integrations coming soon",
        image: "/home.png", 
        imageNarrow: "/homeNarrow.png", 
        detail: "Modules to integrate separated powers directly with OpenZeppelin's Governor.sol, Hats protocol and Safe wallets are coming soon.",
        examples: ["example 1", "example 2", "example 3"]
    },
    // .... more can be added
]

export default function Page() {
    const router = useRouter();
    const organisation = useOrgStore()
    const { organisations, status, initialise, fetch, update } = useOrganisations()
 
    useEffect(() => {
        if (organisation.name != '') router.push('/home') 
    }, [organisation])

    useEffect(() => {
        if (status == 'idle' && !organisations) initialise()
    }, [, status, organisations])

    console.log({organisations})

    return (
        <main className="w-full grid grid-cols-1 gap-0 overflow-y-scroll snap-y snap-mandatory overflow-x-hidden">
            
            {/* section 1 */}
            <section className="w-full h-[80vh] flex flex-col justify-center items-center bg-gradient-to-b from-indigo-900 to-blue-500 snap-start snap-always border-b-0 -m-1"> 
            
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

            <section className="w-full h-[80vh] flex flex-col justify-center items-center bg-gradient-to-b from-blue-500 to-slate-100 snap-start snap-always p-12">    
                {/* use cases  */}
                <section className="w-screen h-fit flex flex-row gap-12 justify-center items-center overflow-x-scroll snap-x snap-mandatory">
                    <div className="min-w-[60vw] h-full flex flex-col justify-center items-center snap-center snap-always gap-2" />
                    {
                        useCases.map((useCase, index) => (
                            <div className="min-w-[60vw] w-full h-fit flex flex-col justify-center items-center text-slate-50 snap-center snap-always" key={index}> 
                                <div className="w-full h-full text-center text-pretty text-lg sm:text-2xl text-slate-200 py-4">
                                    {useCase.value}
                                </div> 
                                <div className="flex flex-col justify-center items-center w-0 max-h-0 md:grow md:min-h-96 md:w-full md:max-h-[60vw]" style = {{position: 'relative', width: '100%', height: '100%'}}>
                                    <Image 
                                        src={useCase.image} 
                                        className = "rounded-md" 
                                        style={{objectFit: "contain", objectPosition: "center"}}
                                        fill={true}
                                        alt="Screenshot Separated Powers"
                                        >
                                    </Image>
                                 </div>
                                 <div className="md:max-w-0 md:max-h-0 md:min-h-0 w-full min-h-80 flex flex-col justify-center items-center" style = {{position: 'relative', width: '100%', height: '100%'}}>
                                        <Image 
                                            src={useCase.imageNarrow} 
                                            className = "max-h-80 max-w-80 rounded-full overflow-hidden justify-self-center content-center" 
                                            style={{objectFit: "cover", objectPosition: "center"}}
                                            fill={true}
                                            alt="Screenshot Separated Powers"
                                            >
                                        </Image>
                                 </div>
                                <div className = "py-4 max-w-xl h-fit flex flex-row justify-between items-center text-md sm:text-lg text-slate-500 text-center text-pretty">
                                    {useCase.detail}
                                </div> 
                            </div> 
                        ))
                    }
                    <div className="min-w-[20vw] h-full flex flex-col snap-center snap-always gap-2" />
                </section>
            </section> 

            {/* section 2 */}
            <section className = "w-full min-w-[60vw] grow flex flex-col justify-start items-center snap-start px-4 pb-20"> 
                <div className = "w-full flex flex-row justify-center items-center text-3xl text-slate-600 text-center text-pretty font-bold pt-16 px-4">
                    Want to play around with a live demo?
                </div>
                <div className = "w-full flex flex-row justify-center items-center text-xl text-slate-400 text-center text-pretty py-2 pb-16 px-4">
                    The protocol and examples are proof of concepts. The are meant for testing purposes only. Do not use in production.
                </div>
                {/* table with example orgs  */}
                <section className="w-full max-w-5xl h-fit flex flex-col  justify-start items-center border border-slate-200 rounded-md overflow-hidden bg-slate-50" >
                    <div className="w-full flex flex-col justify-start items-center overflow-scroll">
                        <div className="w-full flex flex-col overflow-scroll">
                          <table className="w-full table-auto ">
                          <thead className="w-full border-b border-slate-200">
                                <tr className="w-96 text-xs font-light text-left text-slate-500">
                                <th className=""></th>
                                <th className="ps-3 py-2 font-light">Name</th>
                                <th className="font-light text-center ">Laws</th>
                                <th className="font-light text-center ">Proposals</th>
                                <th className="font-light text-center ">Roles</th> 
                                <th className="flex flex-row gap-1 justify-between items-between font-light text-left">
                                    <div className="py-2 w-full h-full flex gap-1 justify-start items-center text-center">
                                        Chain
                                    </div> 
                                    <button 
                                        className="py-2 w-12 h-full flex justify-center items-center text-center aria-selected:animate-spin"
                                        onClick = {() => fetch()}
                                        >
                                            <ArrowPathIcon
                                            className="w-4 h-4 text-slate-500 aria-selected:animate-spin"
                                            aria-selected={status == 'pending'}
                                            />
                                    </button>
                                </th>
                                </tr>
                            </thead>
                            <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                              {
                                organisations?.map((org, index) => {
                                  return (
                                    <tr
                                      key={index}
                                      className={`text-sm text-left text-slate-800 h-16 overflow-x-scroll`}
                                    >
                                        <td className="min-w-12">
                                            <div className={`ms-4 h-6 w-6 bg-gradient-to-bl ${colourScheme[index % colourScheme.length]} rounded-full`}/>
                                        </td>
                                        <td className="pe-4 text-slate-500 min-w-40">
                                            <Button 
                                                size={1} align={0} showBorder={false} onClick={() => assignOrg({...org, colourScheme: index % colourScheme.length})}>
                                                {org.name}
                                            </Button>
                                        </td>
                                        <td className="pe-4 text-slate-500 text-center min-w-12">{org.laws?.length}</td>
                                        <td className="pe-4 text-slate-500 text-center min-w-12">{org.proposals?.length}</td>
                                        <td className="pe-4 text-slate-500 text-center min-w-12">{org.roles?.length}</td>
                                        <td className="ps-1 text-slate-500 text-left max-w-12"> Arbitrum Sepolia </td>
                                    </tr>
                                  )
                                }
                              )}
                            </tbody>
                          </table>
                          </div>
                    </div> 
                </section>
            </section>

            {/* section 3: Footer */}
            <section className="w-full z-20 min-h-48 h-fit bg-slate-50 flex md:flex-row flex-col justify-between items-start text-slate-800 text-sm px-16 snap-end pt-12 pb-6 border-t border-slate-300 gap-16 snap-end">
                <div className="grid grid-cols-3 gap-28">
                    <div className="flex flex-col gap-3 justify-start items-start">
                    <div className="font-bold"> 
                        DApp
                    </div>
                    <div className="text-slate-500"> 
                        Docs
                    </div>
                    <div className="text-slate-500"> 
                        Github repo 
                    </div>
                    </div>
                    <div className="flex flex-col gap-3 justify-start items-start">
                    <div className="font-bold"> 
                        Protocol
                    </div>
                    <div className="text-slate-500"> 
                        About
                    </div>
                    <div className="text-slate-500"> 
                        Docs
                    </div>
                    <div className="text-slate-500"> 
                        Github repo 
                    </div>
                    </div>
                </div>

                <div className="w-full flex flex-row gap-3 justify-end items-end snap-end">
                    <div className="flex flex-col gap-3 justify-start md:items-end items-center pb-12">
                    <Image 
                    src='/logo.png' 
                    width={48}
                    height={48}
                    alt="Logo Separated Powers"
                    >
                    </Image>
                    <div className="text-md font-bold flex flex-row gap-1">
                        <p>Made with</p> 
                        <HeartIcon className="w-4 h-4 text-red-700" />
                        <p>by 7Cedars</p>
                    </div>
                    <div className="flex flex-row gap-2">
                        <div>
                        discord
                        </div>
                        <div>
                        mirror.xyz
                        </div>
                        <div>
                        telegram
                        </div>
                        <div>
                        twitter
                        </div>
                    </div>
                    </div>
                </div>
            </section>
        </main>
    )
}
