"use client";

import React, { useState } from "react";
import { setLaw, useLawStore, useOrgStore } from "../../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";
import { TitleText, SectionText } from "@/components/StandardFonts";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";

export function LawBox() {
  const law = useLawStore();
  const router = useRouter();
  const { data: params, isLoading, isError } = useReadContract({
    abi: lawAbi,
    address: law.law,
    functionName: 'getParams'
  })

  console.log({params, isLoading, isError})

  const roleColour = [
    "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
    "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
  ]

  const role = law.allowedRole == 0n ? 0 
    : law.allowedRole == 4294967295n ? 6 
    : Number(law.allowedRole)

    // need to check this here, to adapt the input params
            // {
        //   ...currentLaw,
        //   functionName: 'getParams', // NB need to deploy new DAO to get this to work. 
        // },
  
  console.log("law:", law)

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[role]} mt-2 rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={law?.name}
          subtext={law?.description} 
          size = {0}
        /> 
      </div>

      {/* dynamic form */}
      <form action="" method="get" className="w-full">
        
        {/* Below needs to be a dynamic list */}
        <div className="w-full mt-6 flex flex-row justify-center items-center gap-y-4 px-6">
          <label htmlFor="username" className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">Input 1 (text) </label>
            <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
              <input type="text" name="username" id="username" className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" placeholder="janesmith" />
            </div>
        </div>
        <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
          <label htmlFor="username" className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">Input 1 (text) </label>
            <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
              <input type="text" name="username" id="username" className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" placeholder="janesmith" />
            </div>
        </div>

         {/* Above needs to be a dynamic list */}

         <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="username" className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea name="reason" id="reason" rows={3} cols ={25} className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" placeholder="janesmith"/>
            </div>
        </div>
      </form>

      {/* simulate output */}
      <div className="w-full flex flex-col gap-2 justify-start items-center bg-slate-50 py-2 px-6">
        {/* Horizontal divider line  */}
        {/* <div className="w-1/3 border-b border-slate-200 mt-2 mb-6"/>  */}

        <div className="w-full h-fit border border-slate-300 rounded-md overflow-hidden">
          <table className="w-full table-auto">
            <thead className="w-full">
              <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                  <th className="ps-6 py-2 font-light"> Target contracts </th>
                  <th className="font-light"> Value </th>
                  <th className="font-light"> Calldata </th>
              </tr>
            </thead>
              <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y border-b border-slate-200 divide-slate-200">
                {/* This has to become dynamic */}
                <tr
                  key={law.name}
                  className={`text-sm text-left text-slate-800 h-16 p-2`}
                >
                  <td className="ps-6 text-slate-500"> Address here + link to explorer? </td>
                  <td className="text-slate-500"> Value here </td>
                  <td className="pe-4 text-slate-500"> Summary calldata here </td>
                </tr>
              </tbody>
            </table>
            <div className="w-full h-fit p-2">
              <Button size={0} showBorder={false}> 
                Simulate output
              </Button>
            </div>
          </div>
        
        {/* Horizontal divider line  */}
        {/* <div className="w-1/3 border-b border-slate-200 mt-6"/>  */}
          
      </div>

      {/* execute button */}
        <div className="w-full h-fit p-6">
          <Button size={2}> 
            Execute
          </Button>
        </div>
      </section>
    </main>
  );
}
