"use client";

import React from "react";
import Link from "next/link";

export default function Page() { 
    return (
      <section className="w-full flex flex-col justify-center items-center m-4 text-center mt-20">
          <div className="max-w-3xl bg-gray-200 text-center border border-gray-200 px-4 rounded-lg shadow-lg z-10 mb-6">
                    <h2 className="text-lg font-bold mx-4"> What is this dashboard about? </h2>
                    <p className="mb-2"> AgDAO is a very simple example implementation of the Separated Powers Protocol.</p>
                    <p> It showcases different rules that can be created to assign accounts to roles, and how checks and balances between roles can be implemented.</p>
                    <div className="h-fit mt-0" >

                        <h2 className="text-lg font-bold mt-4"> What is AgDao? </h2>
                        <h2 className="font-semibold">
                            Aligned Grants DAO aims to fund projects that are ‘aligned’ with the core values of the agDAO. </h2>
                        <h2 className="font-semibold mt-2"> It functions along the following mechanisms: </h2>
                        <ul 
                            className="list-decimal list-inside"
                            > 
                            <li>Anyone can become a community member of AgDao.</li>
                            <li>Community members are paid in agCoins for governance participation.</li>
                            <li>Community members can transfer agCoins to any address they want.</li> 
                            <li>Whales can revoke and blacklist member roles of accounts that fund non-aligned addresses.</li>
                            <li>Members can challenge a decision to revoke their membership.</li>
                            <li>Seniors can uphold a challenge and reinstate a member.</li>
                            <li>Whales can propose new laws, senior can accept them, and the admin implements them.</li>
                        </ul>

                        <h2 className="font-bold my-4"> See the actions tab in the dashboard for concrete implementation of protocol laws. </h2>
                    </div>
                </div>

                <Link href="/" className="underline ">
                    Back to dashboard
                </Link>
      </section>
    )

    // return (
    //     <section className="w-full h-screen bg-white flex flex-col justify-center items-center text-center">
    //       ...      
    //     </section>
    //   )
}
