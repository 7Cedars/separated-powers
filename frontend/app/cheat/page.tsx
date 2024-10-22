"use client";

import React, { useState } from "react";
import { lawContracts } from "@/context/lawContracts";
import { useWriteContract } from "wagmi";
import { agCoinsAbi } from "@/context/abi";
import Link from "next/link";

export default function Page() {
    const [value, setValue] = useState<number>(20);  
    
    const agCoinsContract = lawContracts.find((law: any) => law.contract === "AgCoins")
    const { writeContract } = useWriteContract()
 
    return (
      <section className="w-full flex flex-col justify-center items-center m-4 text-center mt-20">
        How many agCoins do you want?

        <input
            type="number"
            value={value}
            onChange={(e) => setValue(Number(e.target.value))}
            placeholder="How many agCoins do you want?"
            className="border border-gray-800 rounded-lg p-2 m-8 w-1/2"
        />

          <button
            onClick={() => 
              writeContract({ 
                abi: agCoinsAbi,
                  address: agCoinsContract?.address as `0x${string}`,
                  functionName: 'mintCoins',
                  args: [value ? BigInt(value) : 0n],
              })
              }
              className="w-fit bg-white border px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100"
            >
            Gimme the coins! 
          </button>

          <Link href="/" className="text-gray-800 m-6 underline">
              Back to dashboard
          </Link>
      </section>
    )
}
