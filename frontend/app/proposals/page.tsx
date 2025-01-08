// This should become Proposals page. Has the following 
// - an overview of proposals. 
// - should have selection by role type at top. 
// - as well as button: 'create proposal'. 
// - is a list of ProposalSmall components. 
// - see https://www.tally.xyz/gov/arbitrum/proposals for example. 
// - when a proposal is clicked, 
//   - should link to a ProposalLarge component / page. 
//   - this page should have an additional navigation line (see tally.xyz for example.)
//   - this page should have dynamic current votes on the right. 
// - if 'create proposal' is clicked, goes to ProposalCreate component / page.

"use client";
"use client";

import React, { useState } from "react";
import {ProposalList} from "./ProposalList";
import { usePathname } from 'next/navigation'

export default function Page() {     
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        <ProposalList />
      </main>
    )
}

