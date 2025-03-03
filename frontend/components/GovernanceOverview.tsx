"use client";

import React, { useState, useEffect } from "react";
import { CalendarDaysIcon, QueueListIcon, UserGroupIcon } from "@heroicons/react/24/outline";
import { Law, Organisation } from "@/context/types";
import { orgToGovernanceTracks } from "@/utils/orgToGovOverview";
import { setLaw, useLawStore, useOrgStore } from "@/context/store";
import { usePathname, useRouter } from "next/navigation";

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

const adaptiveBg = [
  "bg-slate-100 border-y-slate-100",
  "bg-slate-50 border-y-slate-50"
]

type TrackProps = {
  track?: Law[];
  orphans?: Law[]; 
  roleIds?: number[];
  lawSelected: Law | undefined
  bgItem: number; 
};


const lawToColourCode = (law: Law) => {
  return (law.allowedRole == undefined || law.allowedRole == 4294967295n ? 6 : Number(law.allowedRole) % roleColour.length)
}

export function GovernanceOverview({law}: {law?: Law | undefined}) {
  const organisation = useOrgStore(); 
  const roleIdsParsed = organisation?.deselectedRoles?.map(id => Number(id))
  let governanceTracks = orgToGovernanceTracks(organisation) 
  const bgItem = usePathname() == '/laws/law' || usePathname() == '/proposals/proposal'  ? 0 : 1

  if (law != undefined ) {
    governanceTracks.orphans = governanceTracks.orphans ? governanceTracks.orphans.filter(law2 => law2.law == law.law) : []
    governanceTracks.tracks = governanceTracks.tracks ? governanceTracks.tracks.filter(track => track.find(law2 => law2.law == law.law)) : []
  }

  return (
    <section className = "w-full h-fit min-h-20 flex flex-col justify-start items-start overflow-x-scroll px-4">
      <div className = "w-full min-h-fit flex flex-col gap-4">  
        {
          governanceTracks.tracks && governanceTracks.tracks.length > 0 && governanceTracks.tracks.map((track, index) => 
            track && <GovernanceTrack track = {track} roleIds = {roleIdsParsed} lawSelected = {law} key = {index} bgItem = {bgItem} /> 
          )
        }
        {
          governanceTracks.orphans && governanceTracks.orphans.length > 0 && <GovernanceOrphans orphans = {governanceTracks.orphans} lawSelected = {law} roleIds = {roleIdsParsed} bgItem = {bgItem} /> 
        }
        
      </div> 
    </section>
  )
}

function GovernanceTrack({track, roleIds, lawSelected, bgItem}: TrackProps) {
  const router = useRouter();

  return (
    <> 
      {/* draws the laws */}
      <div className = "relative w-full h-20 flex justify-stretch items-center min-w-[520px]">
        {
          track && track.map((law, index) => 
            <div key = {index} className = {`w-full h-full flex flex-row justify-between items-center gap-1 border border-${roleColour[lawToColourCode(law)]} ${roleBgColour[lawToColourCode(law)]} rounded-md`}>
              { index == track.length - 1 &&  <div className = "w-8"/> }
              <div className = "flex flex-col w-full h-full ps-2 justify-center items-center gap-0">
                <div className = "text-sm text-pretty p-1 px-4 text-center text-slate-700 max-w-40">
                  {law.name}
                </div>
                <div className = "flex flex-row gap-1"> 
                  { law.config.delayExecution != 0n && <CalendarDaysIcon className = "h-6 w-6 text-slate-700"/> }
                  { law.config.throttleExecution != 0n && <QueueListIcon className = "h-6 w-6 text-slate-700"/> }
                  { law.config.quorum != 0n && <UserGroupIcon className = "h-6 w-6 text-slate-700"/> }
              </div>
              </div>
              { index == 0 &&  <div className = "w-12"/> }
            </div> 
          )
        }

        {/* draws the arrows in between the laws */}
        <div className = "absolute inset-x-0 z-10 w-full h-20 flex flex-row justify-between items-center px-6 min-w-[520px]">
        <div />
        {
          track && track.map((law, index) => 
          {
            if (index + 1 !=  track.length) {
              const lawAfter = track[index + 1]

              return (
                  <div className = " h-full min-w-10 max-w-10 flex flex-col gap-0" key = {index}>
                    <div className = {`grow border border-${roleColour[lawToColourCode(law)]} ${roleColourRightBorder[lawToColourCode(lawAfter)] } ${adaptiveBg[bgItem]} border-t-2 skew-x-[-15rad]`} /> 
                    <div className = {`grow border border-${roleColour[lawToColourCode(law)]} ${roleColourRightBorder[lawToColourCode(lawAfter)] } ${adaptiveBg[bgItem]}  border-b-2 skew-x-[15rad]`} /> 
                  </div>
              )
            }
          }  
        )
        
        }
        <div />
        </div>

        {/* draws the button / selections on top of the law arrows */}
        <div className = "absolute inset-x-0 z-20 w-full h-20 flex flex-row justify-between items-center min-w-[520px]">
        {
          track && track.map((law, index) => 
            <button 
                key = {index} 
                className = {`w-full h-full flex flex-row justify-center items-center gap-1 ${adaptiveBg[bgItem]}  opacity-50 aria-selected:opacity-0`} 
                aria-selected = {
                  lawSelected ? 
                  law.law == lawSelected.law
                  :
                  law.allowedRole != undefined ? !roleIds?.includes(Number(law.allowedRole)) : false
                }
                onClick = {() => {
                  setLaw(law)
                  router.push('/laws/law') 
                }}
                />
          )
        }
        </div>    
      </div>
    </>
  )
}

function GovernanceOrphans({orphans, roleIds, lawSelected, bgItem}: TrackProps) {
  const router = useRouter();
  const home = usePathname() == '/home'
 
  return (
    <>
      {/* draws the laws */}
      <div className = {`relative grow w-full h-20 flex flex-wrap gap-6 justify-stretch items-center ${home && "min-w-[520px]"}`}>
        {
          orphans && orphans.map((law, index) => 
            <button 
              key = {index} 
              className = {`min-w-32 max-w-full grow h-full aria-selected:opacity-100 opacity-50 border border-${roleColour[lawToColourCode(law)]} ${roleBgColour[lawToColourCode(law)]} rounded-md flex flex-row justify-center items-center gap-1`}
              aria-selected = {
                lawSelected ? 
                law.law == lawSelected.law
                :
                law.allowedRole != undefined ? !roleIds?.includes(Number(law.allowedRole)) : false
              }
              onClick = {() => {
                setLaw(law)
                router.push('/laws/law')
              }}
            >
              <div className = "flex flex-col w-full h-full justify-center items-center gap-1">
                <div className = "text-sm text-pretty p-1 px-4 text-center text-slate-700">
                  {law.name}
                </div>
                <div className = "flex flex-row gap-1"> 
                  { law.config.delayExecution != 0n && <CalendarDaysIcon className = "h-6 w-6 text-slate-700"/> }
                  { law.config.throttleExecution != 0n && <QueueListIcon className = "h-6 w-6 text-slate-700"/> }
                  { law.config.quorum != 0n && <UserGroupIcon className = "h-6 w-6 text-slate-700"/> }
              </div>
              </div>
            </button> 
          )
        }
        </div> 

    </>

  )
}