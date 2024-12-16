// This should become landing page: 
// searchers for deployed Separated Powers Protocols.
// Has search bar.
// also has template DAOs to deploy.  
// Loads names,# laws, # proposals, # roles, # members, chain. 
// see example: https://www.tally.xyz/explore

"use client";

import React, { useState, useEffect } from "react";
import MemberActions from "@/components/MemberActions";
import WhaleActions from "@/components/WhaleActions";
import SeniorActions from "@/components/SeniorActions";
import GuestActions from "@/components/GuestActions";
import AdminActions from "@/components/AdminActions";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useRoles } from "@/hooks/useRoles";
import { useProposals } from "@/hooks/useProposals";
import ProposalView from "@/components/ProposalView";
import { Proposal } from "@/context/types";
import ValuesView from "@/components/ValuesView";
import { lawContracts } from "@/context/lawContracts";
import { useReadContract } from "wagmi";
import { agCoinsAbi } from "@/context/abi";
import Link from "next/link";
import { Battery50Icon } from "@heroicons/react/24/outline";
import { useOrgStore } from "@/context/store";
import { useRouter } from "next/navigation";
import { Button } from "../components/Button";

type Org = {
    logo: string;
    name: string; 
    address: `0x${string}`;
    laws: number; 
    proposals: number;
    roles: number; 
    holders: number; 
}

export default function Page() {
    const router = useRouter();
    const organisation = useOrgStore((state) => state.organisation)
    const assign = useOrgStore((action) => action.assign)

    // Have to read for event 'SeparatedPowers__Initialized' - and get address from this. Get the most efficient way of doing this. 
    // See Consumer Card project? I think I have a nice useEvents hook there.. 
    const dummyData: Org[] = [
        {   
            logo: '/logo.png',
            name: 'Organisation A', 
            address: '0x123',
            laws: 5,
            proposals: 23,
            roles: 3,
            holders: 4000
        },
        {
            logo: '/logo.png',
            name: 'Organisation B', 
            address: '0x123',
            laws: 12,
            proposals: 256,
            roles: 3,
            holders: 76353
        }
    ]

    useEffect(() => {
        if (organisation) router.push('/home') 
    }, [organisation])

    return (
        <main className="w-full flex flex-col justify-center items-center border border-slate-300 rounded-md">
            <table className="w-full table-auto">
            <thead className="w-full">
                <tr className="w-96 bg-slate-50 text-xs font-light text-slate-600 rounded-md border-b border-slate-300">
                    <th className="text-left ps-6 py-2 font-light rounded-tl-md">Name</th>
                    <th className="text-right font-light">Laws</th>
                    <th className="text-right font-light">Proposals</th>
                    <th className="text-right font-light">Roles</th>
                    <th className="text-right font-light">Holders</th>
                    <th className="text-right font-light pe-2 rounded-tr-md">Chain</th>
                </tr>
            </thead>
            <tbody className="w-full text-sm text-right text-slate-600 bg-slate-50 divide-y divide-slate-300">
                {
                    dummyData.map((org) => (
                        <tr key={org.name} className="text-sm text-right text-slate-900 h-16">
                            <td className="text-left rounded-bl-md ps-2 py-2">
                                <Button 
                                    size={1} align={0} showBorder={false} onClick={() => assign(org.name, org.logo, org.address)}>
                                    {org.name}
                                </Button>
                            </td>
                            <td>{org.laws}</td>
                            <td>{org.proposals}</td>
                            <td>{org.roles}</td>
                            <td>{org.holders}</td>
                            <td className="pe-2 rounded-br-md"> Arbitrum </td>
                        </tr>
                    ))
                }
            </tbody>
            </table> 
        </main>
    )
}
