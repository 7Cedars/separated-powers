"use client";

import React, { useState } from "react";
import { setLaw, useOrgStore } from "../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { ArrowPathIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";
import { parseRole } from "@/utils/parsers";


export function RoleList() {
  const organisation = useOrgStore();
  const router = useRouter();

  // need to fetch number of role holders for each role. 

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Roles
        </div>
        <button className="w-fit h-fit p-2 border border-opacity-0 hover:border-opacity-100 rounded-md border-slate-500 ">
            <ArrowPathIcon
              className="w-4 h-4 text-slate-600"
              />
        </button>
      </div>
      {/* table laws  */}
      <table className="w-full table-auto border border-t-0">
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Role </th>
                <th className="font-light"> Holders </th>
                <th className="font-light"> Laws </th>
                <th className="font-light"> Proposals </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200 border-t-0 border-slate-200 rounded-b-md">
          {
            organisation?.roles?.map((role: bigint) =>
              <tr
                key={role}
                className={`text-sm text-left text-slate-800 h-16 p-2`}
              >
                <td className="flex flex-col justify-center items-start text-left rounded-bl-md px-2 py-2 w-60">
                  <Button
                    showBorder={false}
                    role={parseRole(role)}
                    onClick={() => {
                      setLaw(law);
                      router.push("/roles/role");
                    }}
                    align={0}
                  >
                    {law.name}
                  </Button>
                </td>
                <td className="pe-4 text-slate-500">{law.description}</td>
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
  );
}
