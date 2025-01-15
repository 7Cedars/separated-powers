import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw, useActionStore, setProposal} from "@/context/store";
import { Law, Proposal } from "@/context/types";
import { useProposal } from "@/hooks/useProposal";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useEffect } from "react";
import Link from "next/link";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";

type MyRolesProps = {
  hasRoles: {role: bigint, since: bigint}[]
}

export function MyRoles({hasRoles}: MyRolesProps ) {
  const organisation = useOrgStore();
  const {wallets} = useWallets();
  const {ready, authenticated, login, logout} = usePrivy();
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.since != 0n)

  return (
    <div className="w-full h-full grow flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80">
    {
    authenticated ? 
    <div className="w-full h-full flex flex-col gap-0 justify-start items-center"> 
      <button
        onClick={() => 
          { 
            console.log("clicked") // here have to set deselectedRoles
            router.push('/roles')
          }
        } 
        className="w-full border-b border-slate-300"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between p-2 ps-3">
        <div className="text-left text-sm text-slate-600 w-52">
          My roles
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {/* below should be a button */}
      <div className = "w-full flex flex-col justify-center items-center max-h-48 overflow-y-scroll divider-slate-300 divide-y">
          <div className ="w-full flex flex-row text-sm text-slate-600 justify-center items-center p-3">
            <div className = "w-full flex flex-row justify-start items-center text-left">
              Public
            </div>
            <div className = "w-full flex flex-row justify-end items-center text-right">
              {/* Since: n/a */}
            </div>
          </div>
        {
        myRoles?.map((role: {role: bigint, since: bigint}, i) =>
          role.role == 4294967295n ? null :
          <div className ="w-full flex flex-row gap-1 text-sm text-slate-600 justify-center items-center p-3">
            <div className = "w-full flex flex-row justify-start items-center text-left">
              {/* need to get the timestamp.. */}
              {
                role.role == 0n ? "Admin" : `Role ${role.role}`
              }
            </div>
            <div className = "w-full flex flex-row justify-end items-center text-right">
              Since: {role.since} 
            </div>
          </div>
          )
        }
      </div>
    </div>
  : 
  <div>


  </div>

  }
  </div>
  )
}
