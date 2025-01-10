// This should become Roles page. Has the following 
// - an overview of roles, how many account hold a role, etc.
// - note: NO selection by role type 
// - is a list of RoleSmall components. 
// - see https://www.tally.xyz/gov/arbitrum/proposals for example, but each item should be colour coded. 
// - when a role is clicked, 
//   - should link to a RoleLarge component / page. 
//   - this page should cards of accounts that hold the role. + additional info on that account. 
//   - if clicked on 'public' -> get cards with top accounts by vote token holdings.  
//   - see https://www.tally.xyz/gov/arbitrum/delegates for example 

"use client";

import React, { useState } from "react";
import { useWriteContract } from "wagmi";
import { agCoinsAbi } from "@/context/abi";
import Link from "next/link";

export default function Page() {
    const [value, setValue] = useState<string>('');  
    
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

        {/* <input
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
          </button> */}

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
