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
import { colourScheme } from "@/context/ThemeContext"

export default function Page() {
    const router = useRouter();
    const organisation = useOrgStore()
    const { fetchOrganisations, organisations } = useOrganisations()
    
    console.log("organisations", organisations)
    console.log("organisation", organisation)
    useEffect(() => {
        if (organisation.name != '') router.push('/home') 
    }, [organisation])

    useEffect(() => {
        if (!organisations) fetchOrganisations()
    }, [, organisation])

    return (
        <main className="w-full flex flex-col justify-center items-center border border-slate-300 rounded-md">
            <table className="w-full table-auto">
            <thead className="w-full">
                <tr className="w-96 bg-slate-50 text-xs font-light text-slate-600 rounded-md border-b border-slate-300">
                    <th className=""></th>
                    <th className="text-left  ps-4 py-2 font-light rounded-tl-md">Name</th>
                    <th className="text-right font-light">Laws</th>
                    <th className="text-right font-light">Proposals</th>
                    <th className="text-right font-light">Roles</th> 
                    <th className="text-right font-light pe-2 rounded-tr-md">Chain</th>
                </tr>
            </thead>
            <tbody className="w-full text-sm text-right text-slate-600 bg-slate-50 divide-y divide-slate-300">
                {
                    organisations?.map((org, index) => (
                        <tr key={org.name} className="text-sm text-right text-slate-900 h-16">
                            <td className="w-6">
                                <div className={`ms-4 h-6 w-6 rounded-md bg-gradient-to-bl ${colourScheme[index]}`}/>
                            </td>
                            <td className="text-left rounded-bl-md">
                                <Button 
                                    size={1} align={0} showBorder={false} onClick={() => assignOrg(org)}>
                                    {org.name}
                                </Button>
                            </td>
                            <td>{org.laws?.length}</td>
                            <td>{org.proposals?.length}</td>
                            <td>{org.roles?.length}</td>
                            <td className="pe-4 rounded-br-md"> Arbitrum </td>
                        </tr>
                    ))
                }
            </tbody>
            </table> 
        </main>
    )
}
