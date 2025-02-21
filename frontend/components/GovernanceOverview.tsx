"use client";

import React, { useState, useEffect } from "react";
import { CalendarDaysIcon, QueueListIcon, UserGroupIcon } from "@heroicons/react/24/outline";
import { Law, Organisation } from "@/context/types";
import { orgToGovernanceTracks } from "@/utils/transformData";

const roleColour = [  
  "blue-600", 
  "red-600", 
  "yellow-600", 
  "purple-600",
  "green-600", 
  "orange-600", 
  "slate-600",
]

const roleBgColour = [  
  "bg-blue-100", 
  "bg-red-100", 
  "bg-yellow-100", 
  "bg-purple-100",
  "bg-green-100", 
  "bg-orange-100", 
  "bg-slate-100",
]

const roleColourRightBorder = [  
  "border-r-blue-600",
  "border-r-red-600", 
  "border-r-yellow-600", 
  "border-r-purple-600",
  "border-r-green-600", 
  "border-r-orange-600", 
  "border-r-slate-600",
]
 
type OverviewProps = {
  organisation: Organisation;
  law?: Law;
  roleIds?: bigint[];
  onClick?: (arg0: Law) => void;
};

type TrackProps = {
  track?: Law[];
  orphans?: Law[]; 
  law?: Law;
  roleIds?: number[];
  onClick?: (arg0: Law) => void;
};


export function GovernanceOverview({organisation, roleIds, law, onClick}: OverviewProps) {
  const roleIdsParsed = roleIds?.map(id => Number(id))
  let governanceTracks = orgToGovernanceTracks(organisation)

  if (law) {
    governanceTracks.orphans = governanceTracks.orphans ? governanceTracks.orphans.filter(law2 => law2 == law) : []
    governanceTracks.tracks = governanceTracks.tracks ? governanceTracks.tracks.filter(track => track.includes(law)) : []
  }

  console.log("@GovernanceOverview: ",  {governanceTracks})

  return (
    <section className = "w-full h-fit flex flex-col justify-center items-center"> 
      <div className = "w-full max-w-4xl h-full flex flex-wrap gap-4 justify-start items-start bg-slate-50"> 
      {
        governanceTracks.tracks && governanceTracks.tracks.length > 0 && governanceTracks.tracks.map((track, index) => 
          track && <GovernanceTrack track = {track} roleIds = {roleIdsParsed} law = {law} onClick = {onClick} key = {index}/> 
        )
      }
      {
        governanceTracks.orphans && governanceTracks.orphans.length > 0 && <GovernanceOrphans orphans = {governanceTracks.orphans} roleIds = {roleIdsParsed} law = {law} onClick = {onClick} /> 
      }
      </div> 
    </section> 
  )
}

function GovernanceTrack({track, roleIds, law, onClick}: TrackProps) {

  const handleClick= (selectedLaw: Law) => {
    if(typeof onClick === 'function'){
      onClick(selectedLaw)
   }    
  }
 
  return (
    <>
      {/* draws the laws */}
      <div className = "relative w-full h-20 flex justify-stretch items-center">
        {
          track && track.map((law, index) => 
            <div key = {index} className = {`w-full h-full flex flex-row justify-between items-center gap-1 border border-${roleColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length: 0]} ${roleBgColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length: 0]} rounded-md`}>
              { index == track.length - 1 &&  <div className = "w-12"/> }
              <div className = "flex flex-col w-full h-full justify-center items-center gap-1">
                <div className = "text-sm font-bold text-pretty p-1 px-4 text-center">
                  {law.name}
                </div>
                <div className = "flex flex-row gap-1"> 
                  { law.config.votingPeriod != 0n && <CalendarDaysIcon className = "h-6 w-6"/> }
                  { law.config.throttleExecution != 0n && <QueueListIcon className = "h-6 w-6"/> }
                  { law.config.quorum != 0n && <UserGroupIcon className = "h-6 w-6"/> }
              </div>
              </div>
              { index == 0 &&  <div className = "w-12"/> }
            </div> 
          )
        }

        {/* draws the arrows in between the laws */}
        <div className = "absolute inset-x-0 z-10 w-full h-20 flex flex-row justify-between items-center px-6">
        <div />
        {
          track && track.map((law, index) => 
          {
            if (index + 1 !=  track.length) {
              const lawAfter = track[index + 1]

              return (
                  <div className = " h-full min-w-10 max-w-10 flex flex-col gap-0" key = {index}>
                    <div className = {`grow border border-${roleColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length : 0]} ${roleColourRightBorder[lawAfter.allowedRole ? Number(lawAfter.allowedRole) % roleColour.length : 0] } bg-slate-50 border-y-slate-50 border-t-2 skew-x-[-15rad]`} /> 
                    <div className = {`grow border border-${roleColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length : 0]} ${roleColourRightBorder[lawAfter.allowedRole ? Number(lawAfter.allowedRole) % roleColour.length : 0] } bg-slate-50 border-y-slate-50 border-b-2 skew-x-[15rad]`} /> 
                  </div>
              )
            }
          }  
        )
        
        }
        <div />
        </div>

        {/* draws the button / selections on top of the law arrows */}
        <div className = "absolute inset-x-0 z-20 w-full h-20 flex flex-row justify-between items-center">
        {
          track && track.map((law, index) => 
            <button 
                key = {index} 
                className = {`w-full h-full flex flex-row justify-center items-center gap-1 bg-slate-50 opacity-50 aria-selected:opacity-0`} 
                aria-selected = {law.allowedRole != undefined ? roleIds?.includes(Number(law.allowedRole)) : true}
                onClick = {() => handleClick(law)}
                />
          )
        }
        </div>    
      </div>
  
 </>

  )
}

function GovernanceOrphans({orphans, roleIds, law, onClick}: TrackProps) {

  const handleClick= (selectedLaw: Law) => {
    if(typeof onClick === 'function'){
      onClick(selectedLaw)
   }    
  }
 
  return (
    <>
      {/* draws the laws */}
      <div className = "relative w-full h-20 flex flex-wrap justify-stretch items-center">
        {
          orphans && orphans.map((law, index) => 
            <div 
              key = {index} 
              className = {`min-w-32 max-w-full grow h-full border border-${roleColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length: 0]} ${roleBgColour[law.allowedRole ? Number(law.allowedRole) % roleColour.length: 0]} rounded-md flex flex-row justify-center items-center gap-1`}>
              { index == orphans.length - 1 &&  <div className = "w-12"/> }
              <div className = "flex flex-col w-full h-full justify-center items-center gap-1">
                <div className = "text-sm font-bold text-pretty p-1 px-4 text-center">
                  {law.name}
                </div>
                <div className = "flex flex-row gap-1"> 
                  { law.config.votingPeriod != 0n && <CalendarDaysIcon className = "h-6 w-6"/> }
                  { law.config.throttleExecution != 0n && <QueueListIcon className = "h-6 w-6"/> }
                  { law.config.quorum != 0n && <UserGroupIcon className = "h-6 w-6"/> }
              </div>
              </div>
              { index == 0 &&  <div className = "w-12"/> }
            </div> 
          )
        }

      {/* draws the button / selections on top of the laws */}
      <div className = "absolute inset-x-0 z-20 w-full h-20 flex flex-row justify-between items-center">
        {
          orphans && orphans.map((law, index) => {
            return (
              <button 
                  key = {index} 
                  className = {`min-w-32 max-w-full grow h-full justify-center items-center gap-1 bg-slate-50 aria-selected:opacity-0 opacity-50 `} 
                  aria-selected = {law.allowedRole != undefined ? roleIds?.includes(Number(law.allowedRole)) : true}
                  onClick = {() => handleClick(law)}
                  />
            )
          })
        }
        </div>
      </div>
    </>

  )
}