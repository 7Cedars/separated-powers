"use client";

import React, { useState, useEffect } from "react";
// import MemberActions from "@/components/MemberActions";
// import WhaleActions from "@/components/WhaleActions";
// import SeniorActions from "@/components/SeniorActions";
// import GuestActions from "@/components/GuestActions";
// import AdminActions from "@/components/AdminActions";
// import { usePrivy, useWallets } from "@privy-io/react-auth";
// import { useRoles } from "@/hooks/useRoles";
// import { useProposals } from "@/hooks/useProposals";
// import ProposalView from "@/components/ProposalView";
// import { Proposal } from "@/context/types";
// import ValuesView from "@/components/ValuesView";
// import { lawContracts } from "@/context/lawContracts";
// import { useReadContract } from "wagmi";
// import { agCoinsAbi } from "@/context/abi";
// import Link from "next/link";
import { Battery50Icon } from "@heroicons/react/24/outline";


const DashboardPage: React.FC = () => {

    return (
        <section className="w-full h-screen bg-slate-200 dark:bg-slate-800 flex flex-col justify-center items-center p-4">
            <div className="flex flex-col items-center justify-center w-full h-full text-lg text-center border-4 border-yellow-400 rounded-lg">
                <div className="flex justify-center items-center"> 
                    <Battery50Icon className="w-16 h-16" />
                </div>
                <div className="text-bold dark:text-slate-200 text-slate-800">
                This site is currently under construction. Check back later.
                </div>
            </div>
        </section>
    )
}
// const DashboardPage: React.FC = () => {
//     const [admin, setAdmin] = useState<boolean>(false);  
//     const [senior, setSenior] = useState<boolean>(false);  ;  
//     const [whale, setWhale] = useState<boolean>(false);  
//     const [member, setMember] = useState<boolean>(false);  
//     const [guest, setGuest] = useState<boolean>(true);  
//     const [mode, setMode] = useState<"Values"|"Actions"|"Proposals">("Actions");  

//     const {wallets } = useWallets();
//     const wallet = wallets[0];
//     const {status, error, roles, fetchRoles} = useRoles();
//     const {proposals, status: proposalStatus, error: proposalError, fetchProposals} = useProposals();
//     const {ready, authenticated, login, logout} = usePrivy();

//     const agCoinsContract = lawContracts.find((law: any) => law.contract === "AgCoins")
//     const {data: userBalance, error: userBalanceError, status: userBalanceStatus}  = useReadContract({
//         abi: agCoinsAbi,
//         address: agCoinsContract?.address as `0x${string}`,
//         functionName: 'balanceOf',
//         args: [wallet && wallet.address ? wallet.address as `0x${string}` : `0x0`]
//       })
    
//     // console.log("@DashboardPage", {authenticated, roles, wallet})

//     useEffect(() => {
//         if (ready && wallet && status == "idle") fetchRoles(wallet)
//     }, [status, ready, wallet])

//     useEffect(() => {
//         if (mode == "Proposals") fetchProposals()
//     }, [mode])

//     return (
//         <main className="min-h-screen flex flex-col">
//         {
//         ready == true  ?

//         <div className="p-6 min-h-screen w-full bg-gray-100  flex flex-col items-center">
//             <h1 className="w-full text-3xl font-bold text-center mt-20 mb-2 text-gray-800">Welcome to AgDAO</h1>
//             <h2 className="w-full text-lg mb-2 text-center text-gray-800">A decentralised system of checks and balances for funding aligned accounts</h2>
//             <div className="flex flex-col mb-8 w-full items-center">
//             <Link href="/about" className="underline mb-4 text-gray-800">
//                 About   
//             </Link>
                
//                 <div className="flex flex-col max-w-xl w-full items-center h-full bg-gray-500 py-2 px-8 rounded-lg hover:from-blue-500 hover:to-blue-700 shadow-lg z-10 cursor-pointer transition duration-200 mb-12">
//                     {ready && wallet && authenticated ? (
//                         <>
//                             <button 
//                                 className="text-white"
//                                 onClick={() => logout()}
//                             >
//                                 Wallet Connected @{wallet.address.slice(0, 5)}...{wallet.address.slice(-4)}
//                             </button>
//                             <div className="flex flex-row justify-center items-center gap-2">
//                             <p className="text-white">
//                              {userBalance != undefined ? `You own ${Number(userBalance)} agCoins` : "Fetching balance..."}
//                             </p>
//                             <Link href="/cheat" className="text-white text-xs underline">
//                                 Want to cheat?
//                             </Link>
//                             </div>
//                         </>
//                     ) : (
//                         <button className="text-white text-lg font-semibold"
//                             onClick={() => login()}
//                         >
//                             Please connect your wallet
//                         </button>
//                     )}
//                 </div>

               
//             </div>
            
//             <div className="flex flex-row mb-6 w-full text-gray-800">
//                 <button 
//                     className="w-full font-bold font-xl text-center aria-selected:opacity-100 opacity-25 py-2 px-4"
//                     onClick={() => setMode("Values")}
//                     aria-selected={(mode == "Values")}
//                 > 
//                     Values
//                 </button>
//                 <button
//                     className="w-full font-bold font-xl text-center aria-selected:opacity-100 opacity-25 py-2 px-4"
//                     onClick={() => setMode("Actions")}
//                     aria-selected={(mode == "Actions")}
//                 >  
//                     Actions
//                 </button>
//                 <button 
//                     className="w-full font-bold font-xl text-center aria-selected:opacity-100 opacity-25 py-2 px-4"
//                     onClick={() => setMode("Proposals")}
//                     aria-selected={(mode == "Proposals")}
//                 > 
//                     Proposals
//                 </button>
//             </div> 

//             <div className="flex flex-row gap-4 overflow-x-auto w-full p-2">
//                 <button 
//                     className="w-full bg-red-400 border-2 aria-pressed:border-red-700 hover:bg-red-500 text-white font-bold py-2 px-4 aria-selected:opacity-100 opacity-30 rounded-lg "
//                     onClick={() => setAdmin(!admin)}
//                     aria-selected={roles.includes(0n)}
//                     aria-pressed={admin}
//                     >
//                     Admin
//                 </button>
//                 <button className="w-full bg-amber-400 border-2 aria-pressed:border-amber-700 hover:bg-amber-500 text-white font-bold py-2 px-4 aria-selected:opacity-100 opacity-30 rounded-lg "
//                     onClick={() => setSenior(!senior)}
//                     aria-selected={roles.includes(1n)}
//                     aria-pressed={senior}
//                     >
//                     Senior
//                 </button>
//                 <button className="w-full bg-emerald-400 border-2 aria-pressed:border-emerald-700 hover:bg-emerald-500 text-white font-bold py-2 px-4 aria-selected:opacity-100 opacity-30 rounded-lg "
//                     onClick={() => setWhale(!whale)}
//                     aria-selected={roles.includes(2n)}
//                     aria-pressed={whale}
//                     >
//                     Whale
//                 </button>
//                 <button className="w-full bg-blue-400 border-2 aria-pressed:border-blue-700 hover:bg-blue-500 text-white font-bold py-2 px-4 aria-selected:opacity-100 opacity-30 rounded-lg "
//                     onClick={() => setMember(!member)}
//                     aria-selected={roles.includes(3n)}
//                     aria-pressed={member}
//                     >
//                     Member
//                 </button>
//                 <button className="w-full bg-purple-400 border-2 aria-pressed:border-purple-700 hover:bg-purple-500 text-white font-bold py-2 px-4 aria-selected:opacity-100 opacity-30 rounded-lg "
//                     onClick={() => setGuest(!guest)}
//                     aria-selected={roles.includes(4n)}
//                     aria-pressed={guest}
//                     >
//                     Guest
//                 </button>
//             </div>

//             {
//             mode == "Values" ? 
//                 <div className="bg-white shadow-lg rounded-lg p-6 w-full">
//                     <ValuesView />
//                 </div>
//             :
//             mode == "Actions" ?
//             // This is super clunky, but for now will do 
//                 <div className="flex flex-col overflow-y-auto gap-4 bg-white shadow-lg rounded-lg p-6 m-1 w-full">
//                     {admin === true ? <AdminActions wallet={wallet} isDisabled={!roles.includes(0n) ? true : false}/> : null}
//                     {senior === true ? <SeniorActions wallet={wallet} isDisabled={!roles.includes(1n) ? true : false}/> : null}
//                     {whale === true ? <WhaleActions wallet={wallet} isDisabled={!roles.includes(2n) ? true : false} /> : null}
//                     {member === true ? <MemberActions wallet={wallet} isDisabled={!roles.includes(3n) ? true : false} /> : null}
//                     {guest === true ? <GuestActions  wallet={wallet} isDisabled={!roles.includes(4n) ? true : false} /> : null} 
//                     {admin === false && senior === false && whale === false && member === false && guest === false ? 
//                         <p className="text-gray-600 text-center italic">Please select a role.</p> : null
//                     }
//                 </div>
//             :
//             mode == "Proposals" ?
//             <div className="flex flex-col overflow-y-auto gap-4 bg-white shadow-lg rounded-lg p-6 w-full">
//                 {
//                 proposals && proposals.length > 0 ? 
//                     <>
//                         {
//                         // This is super clunky, but for now will do 
//                         proposals.map((proposal: Proposal) => (
//                             lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint == 0n && admin || 
//                             lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint == 1n && senior ||
//                             lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint == 2n && whale ||
//                             lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint == 3n && member ||
//                             lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint == 4n && guest ?
//                                 <ProposalView key={proposal.proposalId} proposal={proposal} isDisabled={
//                                     !roles.includes(
//                                         lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId as bigint 
//                                     ) 
//                                 }/>
//                                 : 
//                                 null
//                         ))
//                         }
//                     </>
//                     :
//                     <>
//                         <p className="text-gray-800 text-center italic">No proposals found.</p>
//                     </>
//                 }
//             </div>
//             :
//             <div className="flex justify-center items-center h-screen">
//                 <div className="text-lg text-green-900">...</div>
//             </div>
//             }
//         </div>
//         :
//         null
//         }       
//     </main>
//     )
// }

export default DashboardPage;
