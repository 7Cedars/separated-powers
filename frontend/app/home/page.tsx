"use client";
 
import React, { useEffect, useState } from "react";
import { useOrgStore, setLaw, useLawStore, deleteLaw  } from "../../context/store";
import Link from "next/link";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { LawList } from "@/app/laws/LawList";
// import { colourScheme } from "@/context/ThemeContext"; 


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
 
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        {/* hero banner  */}
        <section className={`w-full h-[30vh] flex flex-col justify-center items-center text-center text-slate-50 text-5xl bg-gradient-to-bl ${colourScheme[organisation.colourScheme] } rounded-md`}> 
          {organisation?.name}
        </section>
        {/**/}

        {/* main body  */}
        <section className="w-full flex flex-row">

          {/* left panel  */}
          <LawList /> 

          {/* right panel  */}
          <div className="w-96 flex flex-col gap-4 justify-start items-center ps-4">
            {/* My proposals  */}
            <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 mt-2 rounded-md"> 
              <Link
                href="/proposals"
                className="w-full border-b border-slate-300 p-2"
              >
              <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
                <div className="text-left text-sm text-slate-600 w-52">
                  My proposals
                </div> 
                  <ArrowUpRightIcon
                    className="w-5 h-5 text-slate-800"
                    />
                </div>
              </Link>
              <div className="w-full flex flex-col gap-3 justify-start items-center px-2 pb-4">
                <div className = "text-sm text-slate-600">
                  Here some dynamic text
                </div>
              </div>
            </div>

            {/* Roles  */}
            <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md"> 
            <Link
                href="/roles"
                className="w-full border-b border-slate-300 p-2"
              >
              <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
                <div className="text-left text-sm text-slate-600 w-52">
                  My roles
                </div> 
                  <ArrowUpRightIcon
                    className="w-5 h-5 text-slate-800"
                    />
                </div>
              </Link>
              <div className="w-full flex flex-col gap-3 justify-start items-center px-2 pb-4">
                <div className = "text-sm text-slate-600">
                  Here some dynamic text
                </div>
              </div>
            </div>
            

            {/* Notifications  */}
            <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md"> 
              <div className="w-full border-b border-slate-300 p-2">
                <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
                  <div className="text-left text-sm text-slate-600 w-52">
                    Notifications
                  </div>
                </div>
              </div>
              <div className="w-full flex flex-col gap-3 justify-start items-center px-2 pb-4">
                <div className = "text-sm text-slate-600">
                  Here some dynamic text
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
    )

}
