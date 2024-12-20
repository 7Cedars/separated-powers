// This should become a single law page. Has the following 
//   - should link to a LawLarge component / page. 
//   - this page should have an additional navigation line (see tally.xyz for example.)
//   - this page should have dynamic status bar on the right: showing checks. 
//   - should have dynamic bar on right showing dependent laws.     

"use client";

import React, { useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import {LawBox} from "./LawBox";
import Link from "next/link";
import { Checks } from "./Checks";
import { Children } from "./Children";
import { Executions } from "./Executions";
import { useLaw } from "@/hooks/useLaw";
import { Button } from "@/components/Button";

const Page: React.FC = () => {
  const {status, error, law: currentLaw, execute, simulate, checkStatus} = useLaw(); 
  
  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      {/* main body  */}
      <section className="w-full flex flex-row">

        {/* left panel  */}
         <LawBox />

        {/* right panel  */}
        <div className="w-96 flex flex-col gap-4 justify-start items-center ps-4">
          <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 mt-2 rounded-md">
            <Checks /> 
          </div>
          <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md"> 
            <Children /> 
          </div>
          <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md">
            <Executions /> 
          </div>
        </div>
        
      </section>
    </main>
  )

}

export default Page 
