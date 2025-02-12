"use client";

import React from "react";
import { setLaw, useOrgStore, assignOrg} from "../../context/store";
import { Button } from "@/components/Button";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useOrganisations } from "@/hooks/useOrganisations";

export function LawList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const { organisations, status, initialise, fetch, update } = useOrganisations()
  console.log({status})

  const handleRoleSelection = (role: bigint) => {
    const index = organisation?.deselectedRoles?.indexOf(role);

    if (index == -1) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? [...organisation?.deselectedRoles, role as bigint] : [role as bigint]})
    } else if (index == 0) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? organisation?.deselectedRoles.slice(1) : []})
    } else if (index) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? organisation?.deselectedRoles.toSpliced(index) : []})
    }
  };

  return (
    <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-hidden">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center py-2 px-4 overflow-y-scroll border-b slate-300">
        <div className="text-slate-900 text-center font-bold text-lg">
          Laws
        </div>
        <div className="flex flex-row w-full min-w-16 h-8">
          <Button
            size={0}
            showBorder={false}
            role={0}
            onClick={() => handleRoleSelection(0n)}
            selected={!organisation?.deselectedRoles?.includes(0n)}
          >
            Admin
          </Button>
        </div>
        {organisation?.roles.map((role) => {
          return role != 0n && role != 4294967295n ? (
            <div className="flex flex-row w-full min-w-16 h-8">
            <Button
              size={0}
              showBorder={false}
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
            showBorder={false}
            role={6}
            onClick={() => handleRoleSelection(4294967295n)}
            selected={!organisation?.deselectedRoles?.includes(4294967295n)}
          >
            Public
          </Button>
        </div>
        <button 
          className="w-fit h-fit p-1 rounded-md border-slate-500"
          onClick = {() => update(organisation)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={status == 'pending'}
              />
        </button>
      </div>
      {/* table laws  */}
      <div className="w-full overflow-scroll">
      {/* border border-t-0 */}
      <table className="w-full table-auto"> 
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500 ">
                <th className="ps-4 py-2 font-light rounded-tl-md"> Name </th>
                <th className="font-light"> Description </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {
            organisation?.laws?.map((law: Law, i) =>
              law.allowedRole != undefined && !organisation?.deselectedRoles?.includes(BigInt(`${law.allowedRole}`) ) ? 
              (
              <tr
                key={i}
                className={`text-sm text-left text-slate-800 h-16 p-2 overflow-x-scroll`}
              >
                <td className="flex flex-col justify-center items-start text-left rounded-bl-md px-2 py-2 w-60">
                  <Button
                    showBorder={false}
                    role={
                      law.allowedRole == 4294967295n
                        ? 6
                        : law.allowedRole == 0n
                        ? 0
                        : Number(law.allowedRole)
                    }
                    onClick={() => {
                      setLaw(law);
                      router.push("/laws/law");
                    }}
                    align={0}
                  >
                    {law.name}
                  </Button>
                </td>
                <td className="pe-4 text-slate-500 min-w-96">{law.description}</td>
                <td className="pe-4 min-w-20 text-slate-500"> { 
                  law.allowedRole == 0n ? 
                    "Admin"
                  : law.allowedRole == 4294967295n ? 
                      "Public"
                    : 
                      `Role ${law.allowedRole}`
                    }
                </td>
              </tr>
            ) : null
          )}
        </tbody>
      </table>
      </div>
    </div>
  );
}
