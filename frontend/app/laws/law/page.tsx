"use client";

import React, { useState } from "react";
import {LawBox} from "./LawBox";
import { Checks } from "./Checks";
import { Children } from "./Children";
import { Executions } from "./Executions";

const Page: React.FC = () => {
  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      {/* main body  */}
      <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-start items-start">

        {/* left panel  */}
        <div className="lg:w-5/6 w-full flex my-4"> 
         <LawBox />
        </div>

        {/* right panel  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 lg:max-h-full lg:w-96 lg:my-4 my-0 lg:flex-col lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-y-scroll scroll-snap-x">
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
            <Checks /> 
          </div>
            <Children /> 
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
            <Executions /> 
          </div>
        </div>
        
      </section>
    </main>
  )

}

export default Page 
