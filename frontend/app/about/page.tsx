"use client";

import React, { useState } from "react";
import { lawContracts } from "@/context/lawContracts";
import { useWriteContract } from "wagmi";
import { agCoinsAbi } from "@/context/abi";
import Link from "next/link";

export default function Page() { 
    return (
      <section className="w-full flex flex-col justify-center items-center m-4 text-center mt-20">
          <div className="max-w-3xl bg-gray-200 text-center border border-gray-200 px-4 rounded-lg shadow-lg z-10 mb-6">
                    <h2 className="font-bold"> Goal: Fund projects that are ‘aligned’ with core values of the agDAO. </h2>        
                    <div 
                        className="h-fit mt-0" >
                        <ul 
                            className="list-decimal list-inside"
                            > 
                            <li>Anyone can become a community member of AgDao.</li>
                            <li>Community members are paid in agCoins for governance participation.</li>
                            <li>Community members can transfer agCoins to any address they want.</li> 
                            <li>Whales can revoke member roles of accounts that fund non-aligned addresses.</li>
                            <li>Members can challenge this decision and be reinstated.</li>
                            <li>Whales can propose new laws, senior can accept them, and the admin implements them.</li>
                        </ul>

                        <h2 className="font-bold mt-4"> See below for the concrete implementation of AgDAO </h2>
                    </div>
                </div>

                <Link href="/" className="underline ">
                    Back to dashboard
                </Link>
      </section>
    )
}
