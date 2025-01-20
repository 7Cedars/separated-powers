"use client";

import React from "react";
import {LawList} from "@/app/laws/LawList";

export default function Page() {     
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        <LawList />
      </main>
    )
}
