"use client";

import React, { useState } from "react";
import { setLaw, useOrgStore, assignOrg} from "../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { ArrowPathIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";


export function LawList() {
  const organisation = useOrgStore();
  const router = useRouter();

  const handleRoleSelection = (role: bigint) => {
    const index = organisation?.deselectedRoles?.indexOf(role);
    console.log("@handleRoleSelection", {index, role, organisation});

    if (index == -1) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? [...organisation?.deselectedRoles, role as bigint] : [role as bigint]})
    } else if (index == 0) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? organisation?.deselectedRoles.slice(1) : []})
    } else if (index) {
      assignOrg({...organisation, deselectedRoles: organisation?.deselectedRoles ? organisation?.deselectedRoles.toSpliced(index) : []})
    }
  };

  console.log("deselectedRoles", organisation?.deselectedRoles);

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-2 px-4 rounded-t-md overflow-y-scroll">
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
        {/* <button className="w-fit h-fit p-2 border border-opacity-0 hover:border-opacity-100 rounded-md border-slate-500 ">
            <ArrowPathIcon
              className="w-4 h-4 text-slate-800"
              />
        </button> */}
      </div>
      {/* table laws  */}
      <div className="w-full border border-slate-200 border-t-0 rounded-b-md overflow-scroll">
      {/* border border-t-0 */}
      <table className="w-full table-auto"> 
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 ">
                <th className="ps-4 py-2 font-light rounded-tl-md"> Name </th>
                <th className="font-light"> Description </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
          {
            organisation?.laws?.map((law: Law) =>
              law.allowedRole != undefined && !organisation?.deselectedRoles?.includes(BigInt(`${law.allowedRole}`) ) ? 
              (
              <tr
                key={law.name}
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
