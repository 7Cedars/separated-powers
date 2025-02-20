"use client";

import React, { useEffect, useState } from "react";
import {LawBox} from "./LawBox";
import { ChecksBox } from "./ChecksBox";
import { Children } from "./Children";
import { Executions } from "./Executions";
import { setAction, useActionStore, useLawStore } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";

const Page: React.FC = () => {
  const {status, error, fetchExecutions} = useLaw();
  const action = useActionStore();
  const law = useLawStore(); 

  // resetting lawBox and fetching executions when switching laws:
  // note, as of now executions are not saved in memory & fetched every time. To do for later..  
  useEffect(() => {
    setAction({
      ...action, 
      upToDate: false
    })
    fetchExecutions() 
  }, [law])

  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      {/* main body  */}
      <section className="w-full lg:max-w-full h-full flex max-w-2xl lg:flex-row flex-col-reverse justify-start items-start">

        {/* left panel: writing, fetching data is done here  */}
        <div className="lg:w-5/6 w-full flex my-4"> 
         <LawBox /> 
        </div>

        {/* right panel: info boxes should only reads from zustand.  */}
        <div className="flex flex-col flex-wrap lg:flex-nowrap max-h-48 lg:max-h-full lg:w-96 lg:my-4 my-0 lg:flex-col lg:overflow-hidden lg:ps-4 w-full flex-row gap-4 justify-center items-center overflow-x-hidden overflow-y-scroll scroll-snap-x">
          <div className="w-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
            <ChecksBox /> 
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
