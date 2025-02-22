"use client";
 
import React, { useCallback, useEffect, useState } from "react";
import { useOrgStore } from "../../context/store";
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
import { Assets } from "./Assets";
import { parseMetadata } from "@/utils/parsers";
import { useChainId } from "wagmi";
import { supportedChains } from "@/context/chains";

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
    const [description, setDescription] = useState<string>() 
    const chainId = useChainId();
    const supportedChain = supportedChains.find(chain => chain.id == chainId)

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


    const fetchMetaData = useCallback(
        async () => {
        setStatus("pending")

        if (organisation.contractAddress) {
          const uri = await readContract(wagmiConfig, {
            abi: separatedPowersAbi,
            address: organisation.contractAddress,
            functionName: 'uri'
          })

        if (uri) {
          try {
            const fetchedMetadata: unknown = await(
              await fetch(uri as string)
              ).json()
              const metadata = parseMetadata(fetchedMetadata)
              setDescription(metadata.description)
            } catch (error) {
            setStatus("error") 
            setError(error)
          }
        }
      }
    }, [])

    useEffect(() => {
      if (organisation) {
        fetchMetaData()
      }
    }, [, organisation ])
 
    return (
      <main className="w-full h-full flex flex-col justify-center items-center gap-6">
        {/* hero banner  */}
        <section className={`w-full min-h-[20vh] flex flex-col justify-center items-center text-center text-slate-50 text-5xl bg-gradient-to-bl ${colourScheme[organisation.colourScheme] } rounded-md`}> 
          {organisation?.name}
        </section>
        
        {/* Description + link to powers protocol deployment */}
        { !description ? null : 
        <section className="w-full h-fit flex flex-col gap-2 justify-left items-center border border-slate-200 rounded-md bg-slate-50 lg:max-w-full max-w-2xl p-4">
          <div className="w-full text-slate-800 text-left text-pretty">
            {description}
          </div>
          <a
            href={`${supportedChain?.blockExplorerUrl}/address/${organisation.contractAddress}#code`} target="_blank" rel="noopener noreferrer"
            className="w-full"
          >
          <div className="flex flex-row gap-1 items-center justify-start">
            <div className="text-left text-sm text-slate-500 break-all w-fit">
              {organisation.contractAddress }
            </div> 
              <ArrowUpRightIcon
                className="w-4 h-4 text-slate-500"
                />
            </div>
          </a>
        </section>
        }

        
        {/* main body  */}
        <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-end items-start">
          {/* left / bottom panel  */}
          <div className = {"w-full"}>
            <LawList /> 
          </div>
          {/* right / top panel  */} 
          <div className = {"w-full pb-2 flex flex-wrap flex-col lg:flex-nowrap max-h-48 lg:max-h-full lg:w-96 lg:flex-col lg:overflow-hidden lg:ps-2 gap-3 overflow-y-hidden overflow-x-scroll scroll-snap-x"}> 
            <Assets /> 
            
            <MyProposals hasRoles = {hasRoles}/> 

            <MyRoles hasRoles = {hasRoles}/>
          </div>
        </section>
      </main>
    )

}
