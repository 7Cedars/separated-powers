// This should become a single law page. Has the following 
//   - should link to a LawLarge component / page. 
//   - this page should have an additional navigation line (see tally.xyz for example.)
//   - this page should have dynamic status bar on the right: showing checks. 
//   - should have dynamic bar on right showing dependent laws.     

"use client";

import React, { useState } from "react";
import { lawContracts } from "@/context/lawContracts";
import { useWriteContract } from "wagmi";
import { agCoinsAbi } from "@/context/abi";
import Link from "next/link";

export default function Page() {
    const [value, setValue] = useState<string>('');  
    
    const agCoinsContract = lawContracts.find((law: any) => law.contract === "AgCoins")
    const { writeContract, status, error } = useWriteContract()

    console.log("@cheat:", {status, error})

    const handleValueSet = (input: string) => {
      if (Number(input) != 0) {
        setValue(input) 
      }
    }
 
    return (
      <section className="w-full h-screen bg-white flex flex-col justify-center items-center text-center">
        How many agCoins do you want?

        <input
            type="number"
            value={Number(value)}
            onChange={(e) => handleValueSet(e.target.value)}
            placeholder="How many agCoins do you want?"
            className="border border-gray-800 rounded-lg p-2 m-8 w-1/2"
        />

          <button
            onClick={() => 
              writeContract({ 
                abi: agCoinsAbi,
                  address: agCoinsContract?.address as `0x${string}`,
                  functionName: 'mintCoins',
                  args: [value ? BigInt(Number(value)) : 0n],
              })
              }
              className="w-fit bg-white text-gray-800 border px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100"
            >
            {status === "success" ? "Success!" : "Gimme the coins!" }  
          </button>

          <Link href="/" className="text-gray-800 m-6 underline">
              Back to dashboard
          </Link>
      </section>
    )

    // return (
    //   <section className="w-full h-screen bg-white flex flex-col justify-center items-center text-center">
    //     ...      
    //   </section>
    // )
}
