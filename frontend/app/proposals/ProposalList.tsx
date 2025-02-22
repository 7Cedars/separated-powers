"use client";

import React, { useEffect, useState } from "react";
import { assignOrg, setAction, setLaw, useOrgStore } from "@/context/store";
import { Button } from "@/components/Button";
import { useRouter } from "next/navigation";
import { Proposal } from "@/context/types";
import { parseProposalStatus, parseRole } from "@/utils/parsers";
import { useProposal } from "@/hooks/useProposal";
import { setProposal } from "@/context/store"
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { useOrganisations } from "@/hooks/useOrganisations";


// NB: need to delete action from store? Just in case? 
export function ProposalList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const [deselectedStatus, setDeselectedStatus] = useState<number[]>([1, 2, 3, 4])
  const { organisations, status: statusUpdate, initialise, fetch, update } = useOrganisations()
  const {status, error, law, proposals: proposalsWithState, fetchProposals, propose, cancel, castVote} = useProposal();
  const possibleStatus: number[] = [0, 1, 2, 3, 4]; 

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

  const handleStatusSelection = (proposalStatus: number) => {
    let newDeselection: number[] = []
    if (deselectedStatus.includes(proposalStatus)) {
      newDeselection = deselectedStatus.filter(option => option != proposalStatus)
    } else {
      newDeselection = [...deselectedStatus, proposalStatus]
    }
    setDeselectedStatus(newDeselection)
  };

  useEffect(() => {
    if (organisation) {
      fetchProposals(organisation);
    }
  }, []);

  return (
    <div className="w-full min-w-96 flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md overflow-hidden">
      {/* table banner:roles  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center pt-3 px-6 overflow-y-scroll">
        <div className="text-slate-900 text-center font-bold text-lg">
          Proposals
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
              onClick={() => handleRoleSelection((BigInt(role)))}
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
          className="w-fit h-fit p-1"
          onClick = {() => update(organisation)}
          >
            <ArrowPathIcon
              className="w-5 h-5 text-slate-800 aria-selected:animate-spin"
              aria-selected={statusUpdate == 'pending'}
              />
        </button>
      </div>

      {/* table banner:status  */}
      <div className="w-full flex flex-row gap-3 justify-between items-between py-2 overflow-y-scroll border-b border-slate-200 px-6">
      {
        possibleStatus.map(option => {
          return (
            <button 
            key = {option}
            onClick={() => handleStatusSelection(option)}
            className="w-fit h-full hover:text-slate-400 text-sm aria-selected:text-slate-800 text-slate-300"
            aria-selected = {!deselectedStatus?.includes(option)}
            >  
              <p className="text-sm text-left"> {parseProposalStatus(option)} </p>
          </button>
          )
        })
      }
      </div>

      {/* table laws  */}
      <div className="w-full overflow-scroll">
      <table className="w-full table-auto">
      <thead className="w-full border-b border-slate-200">
            <tr className="w-96 text-xs font-light text-left text-slate-500">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Block </th>
                <th className="font-light"> Law name </th>
                <th className="font-light"> Reason </th>
                <th className="font-light"> Status </th>
                <th className="font-light"> Role </th>
            </tr>
        </thead>
        <tbody className="w-full text-sm text-right text-slate-500 divide-y divide-slate-200">
          {
            proposalsWithState?.map((proposal: Proposal, i) => {
              const law = organisation?.laws?.find(law => law.law == proposal.targetLaw)
              return (
                law && 
                law.allowedRole != undefined && 
                !organisation?.deselectedRoles?.includes(BigInt(`${law.allowedRole}`)) && 
                !deselectedStatus.includes(proposal.state ? proposal.state : 9) 
                ? 
                <tr
                  key={i}
                  className={`text-sm text-left text-slate-800 h-full p-2 overflow-x-scroll`}
                >
                  <td className="h-full flex flex-col justify-center items-center text-left w-fit p-2">
                    <Button
                      showBorder={false}
                      role={parseRole(law.allowedRole)}
                      onClick={() => {
                        setLaw(law);
                        setProposal(proposal)
                        setAction({
                          description: proposal.description,
                          callData: proposal.executeCalldata,
                          upToDate: true
                        })
                        router.push("/proposals/proposal");
                      }}
                      align={0}
                    >
                      {proposal.blockNumber}
                    </Button>
                  </td>
                  <td className="pe-4 text-slate-500 min-w-60">{law.name}</td>
                  <td className="pe-4 text-slate-500 min-w-48">{proposal.description}</td>
                  <td className="pe-4 text-slate-500">{parseProposalStatus(proposal.state)}</td>
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
