// This should become law page. Has the following 
// - an overview of laws. 
// - should have selection by role type at top. 
// - exact same as home page. (but larger as fits to the whole page.)
// - is a list of LawSmall components. 
// - see https://www.tally.xyz/gov/arbitrum/proposals for example. 
// - when a law is clicked, 
//   - should link to a LawLarge component / page. 
//   - this page should have an additional navigation line (see tally.xyz for example.)
//   - this page should have dynamic status bar on the right. 

"use client";

import React, { useState } from "react";
import {LawList} from "@/components/LawList";
import { usePathname } from 'next/navigation'

export default function Page() {     
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        <LawList />
      </main>
    )
}
