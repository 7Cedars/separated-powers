"use client";
 
import React, { useCallback, useEffect, useState } from "react";
import { useOrgStore, setLaw, useLawStore, deleteLaw  } from "../../context/store";
import Link from "next/link";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { LawList } from "@/app/laws/LawList";
import { MyProposals } from "./MyProposals";
import { Status } from "@/context/types";
import { publicClient } from "@/context/clients";
import { wagmiConfig } from "@/context/wagmiConfig";
import { readContract } from "@wagmi/core";
import { separatedPowersAbi } from "@/context/abi";
import { useWallets } from "@privy-io/react-auth";
import { MyRoles } from "./MyRoles";
import { Transactions } from "./Transactions";

const colourScheme = [
  "from-indigo-500 to-emerald-500", 
  "from-blue-500 to-red-500", 
  "from-indigo-300 to-emerald-900",
  "from-emerald-400 to-indigo-700 ",
  "from-red-200 to-blue-400",
  "from-red-800 to-blue-400"
]

export default function Page() {
    const organisation = useOrgStore()
    const {wallets} = useWallets()
    const [status, setStatus] = useState<Status>()
    const [error, setError] = useState<any | null>(null)
    const [hasRoles, setHasRoles] = useState<{role: bigint; since: bigint}[]>([])

    console.log("@Page", {status, error, hasRoles})

    const fetchMyRoles = useCallback(
      async (account: `0x${string}`, roles: bigint[]) => {
        let role: bigint; 
        let fetchedHasRole: {role: bigint; since: bigint}[] = []; 

        if (publicClient) {
          try {
            for await (role of roles) {
              const fetchedSince = await readContract(wagmiConfig, {
                abi: separatedPowersAbi,
                address: organisation.contractAddress,
                functionName: 'hasRoleSince', 
                args: [account, role]
                })
              console.log("@getRoleSince:" , {fetchedSince})
              fetchedHasRole.push({role, since: fetchedSince as bigint})
              }
              setHasRoles(fetchedHasRole)
          } catch (error) {
            setStatus("error") 
            setError(error)
          }
        }
    }, [])

    useEffect(() => {
      if (wallets && wallets[0]) {
        fetchMyRoles(wallets[0].address as `0x${string}`, organisation.roles)
      }
    }, [wallets?.[0]?.address, fetchMyRoles, organisation.roles])
 
    return (
      <main className="w-full h-full flex flex-col justify-center items-center gap-3">
        {/* hero banner  */}
        <section className={`w-full h-[30vh] flex flex-col justify-center items-center text-center text-slate-50 text-5xl bg-gradient-to-bl ${colourScheme[organisation.colourScheme] } rounded-md`}> 
          {organisation?.name}
        </section>
        
        {/* Description + link to powers protocol deployment */}
        
        <section className="w-full h-fit flex flex-col justify-left items-center border border-slate-200 rounded-md bg-slate-50 lg:max-w-full max-w-2xl p-2">
          <div className="w-full text-sm text-slate-500 text-left">
          Optional description here. 
          </div>
        </section>
        
        {/* main body  */}
        <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start -mt-2">
          {/* left / bottom panel  */}
          <LawList /> 

          {/* right / top panel  */}
          <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 lg:max-h-full lg:w-96 lg:my-2 my-0 lg:flex-col lg:overflow-hidden lg:ps-2 w-full flex-row gap-3 justify-center items-center overflow-y-hidden overflow-x-scroll scroll-snap-x">
            <MyProposals hasRoles = {hasRoles}/> 

            <MyRoles hasRoles = {hasRoles}/>

            <Transactions /> 
          </div>
        </section>
      </main>
    )

}
