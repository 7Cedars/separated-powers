"use client";

import React, { useCallback, useEffect, useState } from "react";
import { setLaw, useOrgStore, useRoleStore } from "@/context/store";
import { Button } from "@/components/Button";
import { ArrowPathIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law, Role, Status } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { publicClient } from "@/context/clients";
import { separatedPowersAbi } from "@/context/abi";
import { readContract } from "wagmi/actions";
import { wagmiConfig } from "@/context/wagmiConfig";
import { setRole } from "@/context/store"
import { roleColour } from "@/context/Theme"
import { Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { useChainId } from 'wagmi'
import { supportedChains } from "@/context/chains";

export default function Page() {
  const organisation = useOrgStore();
  const role = useRoleStore();
  const router = useRouter();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState<any | null>(null)
  const [roleInfo, setRoleInfo ] = useState<Role[]>()

  console.log("@role", {status, error, roleInfo})

  const getRolesSet = async () => {
      if (publicClient) {
        try {
          const logs = await publicClient.getContractEvents({ 
            address: organisation.contractAddress,
            abi: separatedPowersAbi, 
            eventName: 'RoleSet',
            fromBlock: supportedChain?.genesisBlock,
            args: {
              roleId: role.roleId,
              access: true
            },
          })
          console.log("@role:", {logs})
          const fetchedLogs = parseEventLogs({
            abi: separatedPowersAbi,
            eventName: 'RoleSet',
            logs
          })
          const fetchedLogsTyped = fetchedLogs as ParseEventLogsReturnType
          console.log("@role", {fetchedLogsTyped})
          const rolesSet: Role[] = fetchedLogsTyped.map(log => log.args as Role)
          console.log("@role", {rolesSet})
          return rolesSet
        } catch (error) {
            setStatus("error") 
            setError(error)
        } 
      }
    }

    const getRoleSince = async (roles: Role[]) => {
        let role: Role; 
        let rolesWithSince: Role[] = []; 
  
        if (publicClient) {
          try {
            for await (role of roles) {
              const fetchedSince = await readContract(wagmiConfig, {
                abi: separatedPowersAbi,
                address: organisation.contractAddress,
                functionName: 'hasRoleSince', 
                args: [role.account, role.roleId]
              })
              console.log("@getRoleSince:" , {fetchedSince})
              rolesWithSince.push({...role, since: fetchedSince as number})
              }
              return rolesWithSince
            } catch (error) {
              setStatus("error") 
              setError(error)
            }
        }
    } 

    const fetchRoleInfo = useCallback(
      async () => {
        setError(null)
        setStatus("pending")

        const rolesSet = await getRolesSet() 
        const roles = rolesSet ? await getRoleSince(rolesSet) : []

        setRoleInfo(roles) 
        setStatus("success")
      }, [])
  
    useEffect(() => {
      fetchRoleInfo()
    }, [])

  // step 4: parse data
  // step 5: render. 

  return (
    <div className={`w-full flex flex-col justify-start items-center ${roleColour[parseRole(BigInt(role.roleId))]} rounded-md`}>
      {/* table banner  */}
      <div className={`w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 ${roleColour[parseRole(BigInt(role.roleId))]} border-b-slate-300 rounded-t-md`}>
        <div className="text-slate-900 text-center font-bold text-lg">
        { 
          role.roleId == 0 ? "Admin"
          : role.roleId == 4294967295 ? "Public"
          : `Role ${role.roleId}` 
        }
        </div>
      </div>
      {/* table laws  */}
      <table className={`w-full table-auto border border-t-0 ${roleColour[parseRole(BigInt(role.roleId))]}`}>
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Address / ENS </th>
                <th className="font-light text-right pe-8"> Has Role Since </th>
                {/* <th className="font-light text-right pe-8"> Actions </th>
                <th className="font-light text-right pe-8"> Proposals </th> */}
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200 border-t-0 border-slate-200 rounded-b-md">
          {
            roleInfo?.map((role: Role) =>
              <tr>
                <td className="flex flex-col justify-center items-start text-left rounded-bl-md px-6 py-2 w-60">{role.account}</td>
                <td className="pe-8 text-right text-slate-500">{role.since}</td>
              </tr> 
            )
          }
        </tbody>
      </table>
    </div>
  );
}


