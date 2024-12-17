"use client";

import React, { useState } from "react";
import { useOrgStore } from "../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";

type Law = {
  name: string;
  description: string;
  address: `0x${string}`;
  roleId: number;
}

export default function LawList() {
 const organisation = useOrgStore((state) => state.organisation)
    const [selectedRoles, setSelectedRoles] = useState<number[]>([])

    // Have
    // 
    const dummyData: Law[] = [
        {
          name: 'This is nearly thirty characters', 
          description: 'This is some kind of long description of a law that can keep on going for a while.', 
          address: '0x123',
          roleId: 1
        },
        {
          name: 'Short description', 
          description: 'Very short.', 
          address: '0x123',
          roleId: 2
        },
        {
          name: 'A bit longer description', 
          description: 'This would be a normal description. yadi ya.', 
          address: '0x123',
          roleId: 3
        }
    ]

    const roles = dummyData.map((law) => law.roleId); 

    const handleRoleSelection = (role: number) => {
      console.log("handle role selection triggered")
      const index = selectedRoles.indexOf(role) 
      if (index > -1) {
        selectedRoles.splice(index, 1);
      } else {
        setSelectedRoles([...selectedRoles, role])
      }  
    }

    console.log("selectedRoles:", selectedRoles)
 
    return (
      <main className="w-full min-h-full flex flex-col justify-center items-center">
        {/* hero banner  */}
        <section className="grow flex w-full flex-row gap-3 h-[30vh] flex flex-col justify-center items-center text-center text-slate-50 text-5xl bg-gradient-to-bl from-indigo-500 from-10% via-sky-500 via-30% to-emerald-500 to-90% rounded-md">
          {organisation}
        </section>

        {/* main body  */}
        <section className="w-full h-fit flex flex-row">

          {/* left panel  */}
          <div className="w-full flex flex-col justify-start items-center ">
            {/* table banner  */}
            <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border border-b-0 slate-300 mt-4 p-2 rounded-t-md">
              <div className="text-slate-900 text-center font-bold text-xl min-w-20">
                Laws  
              </div> 
              <Button size = {0} showBorder={false}>
                Admin
              </Button>
              {
                roles.map(role => {
                  return (
                    <Button 
                      size = {0} 
                      showBorder={false} 
                      role={role}
                      selected={selectedRoles.includes(role)}
                      onClick={() => handleRoleSelection(role)}
                    >
                      Role {role}
                    </Button>
                  )
                })
              }
              <Button size = {0} showBorder={false}>
                Public
              </Button>
              <Button size = {0}>
                Create Law  
              </Button>
            </div>
            {/* table laws  */}
            <table className="w-full table-auto border">
                <tbody className="w-full text-sm text-right text-slate-600 bg-slate-50 p-2 rounded-b-md">
                    {
                        dummyData.map((law: Law, index) => (
                            <tr key={law.name} className={`text-sm text-left text-slate-800 h-16 p-2`}>
                                <div className={`flex flex-row items-center justify-start p-2`}>
                                {/* <td className="text-left ps-4 my-2">  */}
                                  <Button showBorder={false} role={index}>
                                    <div className={`w-full flex flex-row gap-6 items-center justify-between`}>
                                      <div className="text-left min-w-52">
                                        {law.name} 
                                      </div> 
                                      <div className="grow text-left">
                                        {law.description}
                                      </div>
                                      <div className="min-w-16 text-right">
                                        Role {law.roleId}
                                      </div>
                                    </div>
                                  </Button>
                                </div>
                            </tr>
                        ))
                    }
                </tbody>
            </table>   
         </div>

     </section>
  </main>
  )
}