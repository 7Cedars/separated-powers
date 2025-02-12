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

