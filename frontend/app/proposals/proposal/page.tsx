"use client";

import React from "react";
import {ProposalBox} from "./ProposalBox";
import {Checks} from "./Checks"; 
import {Status} from "./Status"; 
import {Votes} from "./Votes"; 
import {Law} from "./Law";

const Page: React.FC = () => {
  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      {/* main body  */}
      <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-start items-start">

        {/* left panel  */}
        <div className="lg:w-5/6 w-full flex my-4"> 
         <ProposalBox />
        </div>

        {/* right panel  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap lg:max-h-full max-h-52 lg:w-96 lg:my-6 my-0 lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-scroll scroll-snap-x"> 
      
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-72">
            <Law /> 
          </div>
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-72">
            <Status /> 
          </div>
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-72">
            <Checks /> 
          </div>
          <Votes />  
        </div>
      </section>
    </main>
  )

}

export default Page 
