"use client";

import React, { useEffect, useState } from "react";
import { setLaw, useOrgStore } from "@/context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { ArrowPathIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law, Proposal } from "@/context/types";
import { parseRole } from "@/utils/parsers";
import { useProposal } from "@/hooks/useProposal";
import { setProposal } from "@/context/store"

// NB: need to delete action from store? Just in case? 


export function ProposalList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const [deselectedRoles, setDeselectedRoles] = useState<number[]>([]);
  const {status, error, law, proposals: proposalsWithState, fetchProposals, propose, cancel, castVote} = useProposal();

  const handleRoleSelection = (role: number) => {
    const index = deselectedRoles.indexOf(role);
    if (index == -1) {
      setDeselectedRoles([...deselectedRoles, role]);
    } else {
      const updatedRoles = deselectedRoles.toSpliced(index, 1);
      setDeselectedRoles(updatedRoles);
    }
  };

  useEffect(() => {
    if (organisation) {
      fetchProposals(organisation);
    }
  }, []);

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 rounded-t-md overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Proposals
        </div>
        <Button
          size={0}
          showBorder={false}
          role={0}
          onClick={() => handleRoleSelection(0)}
          selected={!deselectedRoles.includes(0)}
        >
          Admin
        </Button>
        {organisation?.roles.map((role) => {
          return role != 0n && role != 4294967295n ? (
            <div className="flex flex-row w-full min-w-16 h-10">
            <Button
              size={0}
              showBorder={false}
              role={Number(role)}
              selected={!deselectedRoles.includes(Number(role))}
              onClick={() => handleRoleSelection(Number(role))}
            >
              Role {role}
            </Button>
            </div>
          ) : null;
        })}
        <Button
          size={0}
          showBorder={false}
          role={6}
          onClick={() => handleRoleSelection(4294967295)}
          selected={!deselectedRoles.includes(4294967295)}
        >
          Public
        </Button>
        <button className="w-fit h-fit p-2 border border-opacity-0 hover:border-opacity-100 rounded-md border-slate-500 ">
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800"
              />
        </button>
      </div>
      {/* table laws  */}
      <div className="w-full border border-slate-200 border-t-0 rounded-b-md overflow-scroll">
      <table className="w-full table-auto">
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Block </th>
                <th className="font-light"> Law name </th>
                <th className="font-light"> Reason </th>
                <th className="font-light"> Status </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
          {
            proposalsWithState?.map((proposal: Proposal, i) => {
              const law = organisation?.laws?.find(law => law.law == proposal.targetLaw)
              return (
                law && law.allowedRole != undefined && !deselectedRoles.includes(Number(law.allowedRole)) ? 
             
                <tr
                  key={i}
                  className={`text-sm text-left text-slate-800 h-16 p-2 overflow-x-scroll`}
                >
                  <td className="flex flex-col justify-center items-start text-left rounded-bl-md px-2 py-2 w-fit">
                    <Button
                      showBorder={false}
                      role={parseRole(law.allowedRole)}
                      onClick={() => {
                        setLaw(law);
                        setProposal(proposal)
                        router.push("/proposals/proposal");
                      }}
                      align={0}
                    >
                      {proposal.blockNumber}
                    </Button>
                  </td>
                  <td className="pe-4 text-slate-500 min-w-60">{law.name}</td>
                  <td className="pe-4 text-slate-500 min-w-48">{proposal.description}</td>
                  <td className="pe-4 text-slate-500 text-center">{proposal.state}</td>
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
                : 
                null
              )
            }
          )}
        </tbody>
      </table>
      </div>
    </div>
  );
}
