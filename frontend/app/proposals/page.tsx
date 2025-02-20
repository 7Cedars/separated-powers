"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";
import { useProposal } from "@/hooks/useProposal";
import { useOrgStore } from "@/context/store";

export default function Page() {
  const { status, error, law, proposals: proposalsWithState, fetchProposals, propose, cancel, castVote} = useProposal();
  const organisation = useOrgStore();

  useEffect(() => {
    if (organisation) {
      fetchProposals(organisation);
    }
  }, []);

  
  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      <ProposalList />
    </main>
  )
}

