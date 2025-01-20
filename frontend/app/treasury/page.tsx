"use client";

import React, { useState } from "react";
import { TreasuryList } from "./TreasuryList";

export default function Page() {     
    return (
      <main className="w-full h-full flex flex-col justify-center items-center">
        <TreasuryList />
      </main>
    )
}