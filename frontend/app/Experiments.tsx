"use client";

import React, { useState, useEffect } from "react";
import { CalendarDaysIcon, QueueListIcon, UserGroupIcon } from "@heroicons/react/24/outline";

const roleColour = [  
  "blue-600", 
  "red-600", 
  "yellow-600", 
  "purple-600",
  "green-600", 
  "orange-600", 
  "slate-600",
]

const bgColour = [  
  "bg-blue-200", 
  "bg-red-200", 
  "bg-yellow-200", 
  "bg-purple-200",
  "bg-green-200", 
  "bg-orange-200", 
  "bg-slate-200",
]

const roleColourRightBorder = [  
  "border-r-red-600", 
  "border-r-yellow-600", 
  "border-r-purple-600",
  "border-r-green-600", 
  "border-r-orange-600", 
  "border-r-slate-600",
  "border-r-blue-600",
]

type LawProps = {
  title: string; 
  description: string; 
  vote?: boolean; 
  delay?: boolean; 
  throttle?: boolean; 
}

const dummyLaws: LawProps[] = [
  {
    title: "Propose an action", 
    description: "here some text...",
    vote: true, 
    delay: true, 
    throttle: true
  }, 
  {
    title: "Veto an action", 
    description: "here some text...", 
    delay: true, 
    throttle: true
  }, 
  {
    title: "Execute an action", 
    description: "here some text...", 
    vote: true, 
  }, 
]

export function GovernanceChain() {
  return (
    <section className = "relative w-full h-20 flex flex-row justify-stretch items-center">
      {
        dummyLaws.map((law, index) => 
          <div key = {index} className = {`w-full h-full border border-${roleColour[index]} ${bgColour[index]} rounded-md flex flex-col justify-center items-center gap-1`}>
            <div className = "text-sm font-bold">
              {law.title}
            </div>
            <div className = "flex flex-row gap-1"> 
              { law.delay && <CalendarDaysIcon className = "h-6 w-6"/> }
              { law.throttle &&<QueueListIcon className = "h-6 w-6"/> }
              { law.vote && <UserGroupIcon className = "h-6 w-6"/> }
            </div>
          </div>
        )
      }

      <Links /> 
      
    </section>
  )

}

export function Links( ) {
  return (
    <div className = "absolute inset-x-0 z-10 w-full h-24 flex flex-row justify-between items-center px-6">

      <div />

      {
        dummyLaws.map((law, index) => 
            index + 1 !=  dummyLaws.length &&
              <div className = " h-20 min-w-10 max-w-10 flex flex-col gap-0" key = {index}>
                <div className = {`grow border bg-slate-50 border-${roleColour[index]} ${roleColourRightBorder[index]} border-y-slate-50 border-t-2 skew-x-[-15rad]`} /> 
                <div className = {`grow border bg-slate-50 border-${roleColour[index]} ${roleColourRightBorder[index]} border-y-slate-50 border-b-2 skew-x-[15rad]`} /> 
              </div>
        )
      }
      
      <div />
    </div>
    
  )
}

export function Experiments() {

  return (
    <section className = "w-full min-h-[30vh] flex flex-col justify-center items-center snap-start px-4 pb-10"> 
      <div className = "w-full max-w-4xl h-full flex flex-col border border-slate-300 rounded-md bg-slate-50 p-3"> 
        A clean slate to experiment.. 
        
        <GovernanceChain /> 
    
      </div> 
    </section>
  )
}