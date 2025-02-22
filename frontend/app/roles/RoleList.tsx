"use client";

import React, { useCallback, useEffect, useState } from "react";
import {  useOrgStore } from "../../context/store";
import { Button } from "@/components/Button";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Roles, Status } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { separatedPowersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { setRole } from "@/context/store"
import { useOrganisations } from "@/hooks/useOrganisations";

export function RoleList() {
  const organisation = useOrgStore();
  const { organisations, status: statusUpdate, initialise, fetch, update } = useOrganisations()
  const router = useRouter();

  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roles, setRoles ] = useState<Roles[]>([])

  const fetchRoleHolders = useCallback(
    async (roleIds: bigint[]) => {
      let roleId: number; 
      let rolesFetched: Roles[] = []; 
      let lawsFetched: number[]; 

      const roleIdsParsed = roleIds.map(roleId => Number(roleId))

      setError(null)
      setStatus("pending")

      if (publicClient) {
        try {
          for await (roleId of roleIdsParsed) {
            const fetchedRoleHolders = await readContract(wagmiConfig, {
              abi: separatedPowersAbi,
              address: organisation.contractAddress,
              functionName: 'getAmountRoleHolders', 
              args: [roleId]
            })
            const laws = organisation.laws?.filter(law => law.allowedRole == BigInt(roleId))
            rolesFetched.push({roleId, holders: Number(fetchedRoleHolders), laws})
            }
          } catch (error) {
            setStatus("error") 
            setError(error)
          }
      }
      const rolesSorted = rolesFetched.sort((a: Roles, b: Roles) => a.roleId > b.roleId ? 1 : -1)
      setRoles(rolesSorted)
      setStatus("success")
  }, [ ]) 

  useEffect(() => {
    fetchRoleHolders(organisation.roles)
  }, [])

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Roles
        </div>
        <button 
          className="w-fit h-fit p-1 rounded-md border-slate-500"
          onClick = {() => update(organisation)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={statusUpdate == 'pending'}
              />
        </button>
      </div>
      {/* table laws  */}
      <table className="w-full table-auto border border-t-0">
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Role </th>
                <th className="font-light text-center"> Holders </th>
                <th className="font-light text-right pe-8"> Laws </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200 border-t-0 border-slate-200 rounded-b-md">
          {
            roles?.map((role: Roles) =>
              <tr>
                <td className="flex flex-col justify-center items-start text-left rounded-bl-md px-2 py-2 w-fit">
                 <Button
                    showBorder={false}
                    role={parseRole(BigInt(role.roleId))}
                    onClick={() => {
                      setRole(role);
                      router.push("/roles/role");
                    }}
                    align={0}
                  >
                  { 
                    role.roleId == 0 ? "Admin"
                    : role.roleId == 4294967295 ? "Public"
                    : `Role ${role.roleId}` 
                  }
                  </Button>
                </td>
                <td className="pe-4 text-left text-slate-500 text-center">{role.roleId == 4294967295 ? 'n/a' : role.holders}</td>
                <td className="pe-4 text-right pe-8 text-slate-500">{role.laws?.length} </td>
              </tr> 
            )
          }
        </tbody>
      </table>
    </div>
  );
}
