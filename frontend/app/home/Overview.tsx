"use client"

import { usePrivy } from "@privy-io/react-auth";
import { ArrowPathIcon, ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { assignOrg, useOrgStore } from "@/context/store";
import { Button } from "@/components/Button";
import { Organisation } from "@/context/types";
import { useOrganisations } from "@/hooks/useOrganisations";
import { GovernanceOverview } from "@/components/GovernanceOverview";
import { useEffect } from "react";

export function Overview( ) {
  const organisation = useOrgStore(); 
  const { status, updateOrg } = useOrganisations() 

  const handleRoleSelection = (role: bigint) => {
    let newDeselection: bigint[] = []

    if (organisation?.deselectedRoles?.includes(role)) {
      newDeselection = organisation?.deselectedRoles?.filter(oldRole => oldRole != role)
    } else if (organisation?.deselectedRoles != undefined) {
      newDeselection = [...organisation?.deselectedRoles, role]
    } else {
      newDeselection = [role]
    }
    assignOrg({...organisation, deselectedRoles: newDeselection})
  };
  
  return (
    <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-hidden">
    {/* table banner  */}
    <div className="w-full flex flex-row gap-3 justify-between items-center py-2 px-4 overflow-y-scroll border-b slate-300">
      {/* <div className="text-slate-900 text-center font-bold text-lg">
        Laws
      </div> */}
      <div className="flex flex-row w-full min-w-16 h-8">
        <Button
          size={0}
          showBorder={true}
          role={0}
          onClick={() => handleRoleSelection(0n)}
          selected={!organisation?.deselectedRoles?.includes(0n)} 
        >
          Admin
        </Button>
      </div>
      {organisation?.roles.map((role, i) => {
        return role != 0n && role != 4294967295n ? (
          <div className="flex flex-row w-full min-w-16 h-8" key={i}>
          <Button
            size={0}
            showBorder={true}
            role={Number(role)}
            selected={!organisation?.deselectedRoles?.includes(BigInt(role))}
            onClick={() => handleRoleSelection(BigInt(role))}
          >
            Role {role}
          </Button>
          </div>
        ) : null;
      })}
      <div className="flex flex-row w-full min-w-16 h-8">
        <Button
          size={0}
          showBorder={true}
          role={6}
          onClick={() => handleRoleSelection(4294967295n)}
          selected={!organisation?.deselectedRoles?.includes(4294967295n)}
        >
          Public
        </Button>
      </div>
      <button 
        className="w-fit h-fit p-1 rounded-md border-slate-500"
        onClick = {() => updateOrg(organisation)}
        >
          <ArrowPathIcon
            className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
            aria-selected={status == 'pending'}
            />
      </button>
    </div>

    {/* Overview here  */}
    <div className = "p-4"> 
      <GovernanceOverview /> 
    </div> 
  </div>
  )
}
