"use client";

import React, { useState } from "react";
import { setLaw, useOrgStore } from "../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";


export function LawList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const [selectedRoles, setSelectedRoles] = useState<number[]>([0, 4294967295]);
  const colourScheme = [
    "from-indigo-500 to-emerald-500",
    "from-blue-500 to-red-500",
    "from-indigo-300 to-emerald-900",
    "from-emerald-400 to-indigo-700 ",
    "from-red-200 to-blue-400",
    "from-red-800 to-blue-400",
  ];

  const handleRoleSelection = (role: number) => {
    const index = selectedRoles.indexOf(role);
    if (index == -1) {
      setSelectedRoles([...selectedRoles, role]);
    } else {
      const updatedRoles = selectedRoles.toSpliced(index, 1);
      setSelectedRoles(updatedRoles);
    }
  };

  console.log("selectedRoles", selectedRoles);

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Laws
        </div>
        <Button
          size={0}
          showBorder={false}
          role={0}
          onClick={() => handleRoleSelection(0)}
          selected={selectedRoles.includes(0)}
        >
          Admin
        </Button>
        {organisation?.roles.map((role) => {
          return role != 0n && role != 4294967295n ? (
            <Button
              size={0}
              showBorder={false}
              role={Number(role)}
              selected={selectedRoles.includes(Number(role))}
              onClick={() => handleRoleSelection(Number(role))}
            >
              Role {role}
            </Button>
          ) : null;
        })}
        <Button
          size={0}
          showBorder={false}
          role={6}
          onClick={() => handleRoleSelection(4294967295)}
          selected={selectedRoles.includes(4294967295)}
        >
          Public
        </Button>
        <Button size={0}>Create Law</Button>
      </div>
      {/* table laws  */}
      <table className="w-full table-auto border border-t-0">
        <tbody className="w-full text-sm text-right text-slate-600 bg-slate-50 p-2 rounded-b-md">
          {organisation?.laws?.map((law: Law, index: number) =>
            law.allowedRole != undefined &&
            selectedRoles.includes(Number(law.allowedRole)) ? (
              <tr
                key={law.name}
                className={`text-sm text-left text-slate-800 h-16 p-2`}
              >
                <div className={`flex flex-row items-center justify-start p-2`}>
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
                  >
                    <div
                      className={`w-full flex flex-row gap-6 items-center justify-between pe-2`}
                    >
                      <div className="text-left min-w-52">{law.name}</div>
                      <div className="grow text-left">{law.description}</div>
                      <div className="min-w-16 text-right">
                        {law.allowedRole == 0n
                          ? "Admin"
                          : law.allowedRole == 4294967295n
                          ? "Public"
                          : `Role ${law.allowedRole}`}
                      </div>
                    </div>
                  </Button>
                </div>
              </tr>
            ) : null
          )}
        </tbody>
      </table>
    </div>
  );
}
