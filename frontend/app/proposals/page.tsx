"use client";

import React, { useEffect, useState } from "react";
import {ProposalList} from "./ProposalList";

export default function Page() {  
  return (
    <main className="w-full h-full flex flex-col justify-center items-center">
      <ProposalList />
    </main>
  )
}

