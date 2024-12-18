"use client";
 
import React, { useState } from "react";
import { useOrgStore, deleteOrg } from "../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { Law } from "@/context/types";
import { useOrganisations } from "@/hooks/useOrganisations";

export default function Page() {
    const organisation = useOrgStore()
    const [selectedRoles, setSelectedRoles] = useState<number[]>([])
    // const { colourScheme } = useOrganisations()
    const colourScheme = [
      "from-indigo-500 to-emerald-500", 
      "from-blue-500 to-red-500", 
      "from-indigo-300 to-emerald-900",
      "from-emerald-400 to-indigo-700 ",
      "from-red-200 to-blue-400",
      "from-red-800 to-blue-400"
    ]


    const handleRoleSelection = (role: number) => {
      const index = selectedRoles.indexOf(role)
      if (index == -1) {
        setSelectedRoles([...selectedRoles, role])
      } else {
        const updatedRoles = selectedRoles.toSpliced(index, 1); 
        setSelectedRoles(updatedRoles);
      }  
    }

    console.log("selectedRoles", selectedRoles)
 
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        {/* hero banner  */}
        <section className={`w-full h-[30vh] text-center text-slate-50 text-5xl bg-gradient-to-bl ${colourScheme[organisation.colourScheme] } rounded-md pt-24`}> 
          {organisation?.name}
        </section>
        {/**/}

        {/* main body  */}
        <section className="w-full flex flex-row">

          {/* left panel  */}
          <div className="w-full flex flex-col justify-start items-center">
            {/* table banner  */}
            <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border border-b-0 slate-300 mt-4 p-2 rounded-t-md">
              <div className="text-slate-900 text-center font-bold text-lg min-w-20">
                Laws  
              </div> 
              <Button 
                size = {0} 
                showBorder={false} 
                role = {0} 
                onClick={() => handleRoleSelection(0)}
                selected={selectedRoles.includes(0)}
                >
                Admin
              </Button>
              {
                organisation?.roles.map(role => {
                  return (
                    role != 0n && role != 4294967295n ? 
                      <Button 
                        size = {0} 
                        showBorder={false} 
                        role={Number(role)}
                        selected={selectedRoles.includes(Number(role))}
                        onClick={() => handleRoleSelection(Number(role))}
                      >
                        Role {role}
                      </Button>
                      : 
                      null 
                  )
                })
              }
              <Button 
                size = {0} 
                showBorder={false} 
                role = {6} 
                onClick={() => handleRoleSelection(4294967295)}
                selected={selectedRoles.includes(4294967295)}
                >
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
                        organisation?.laws?.map((law: Law, index: number) => (
                          law.allowedRole != undefined && selectedRoles.includes(Number(law.allowedRole)) ?
                            <tr key={law.name} className={`text-sm text-left text-slate-800 h-16 p-2`}>
                                <div className={`flex flex-row items-center justify-start p-2`}>
                                  <Button showBorder={false} role= {
                                    law.allowedRole == 4294967295n ? 
                                    6
                                    :
                                    law.allowedRole == 0n ? 
                                    0
                                    :
                                    Number(law.allowedRole)
                                    }>
                                    <div className={`w-full flex flex-row gap-6 items-center justify-between`}>
                                      <div className="text-left min-w-52">
                                        {law.name} 
                                      </div> 
                                      <div className="grow text-left">
                                        {law.description}
                                      </div>
                                      <div className="min-w-16 text-right">
                                        {
                                          law.allowedRole == 0n ? "Admin" 
                                          : 
                                          law.allowedRole == 4294967295n ? "Public"
                                          :
                                          `Role ${law.allowedRole}`
                                          }
                                      </div>
                                    </div>
                                  </Button>
                                </div>
                            </tr>
                            : null 
                        ))
                    }
                </tbody>
            </table>   
         </div>

          {/* right panel  */}
          <div className="w-96 flex flex-col gap-4 justify-start items-center ps-4">
            {/* My proposals  */}
            <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 mt-4 rounded-md"> 
              <Link
                href="/proposals"
                className="w-full border-b border-slate-300 p-2"
              >
              <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
                <div className="text-left text-sm text-slate-600 w-52">
                  My proposals
                </div> 
                  <GiftIcon
                    className="w-4 h-4 text-slate-600"
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
                  <GiftIcon
                    className="w-4 h-4 text-slate-600"
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
