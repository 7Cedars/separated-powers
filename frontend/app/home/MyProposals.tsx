import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw, useActionStore, setProposal} from "@/context/store";
import { Law, Proposal } from "@/context/types";
import { useProposal } from "@/hooks/useProposal";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useEffect } from "react";
import Link from "next/link";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";

const roleColour = [  
  "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
  "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
]

type MyProposalProps = {
  hasRoles: {role: bigint, since: bigint}[]
}

export function MyProposals({hasRoles}: MyProposalProps ) {
  const organisation = useOrgStore();
  const {status, error, law, proposals: proposalsWithState, fetchProposals, propose, cancel, castVote} = useProposal();
  const {wallets} = useWallets();
  const {ready, authenticated, login, logout} = usePrivy();
  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.role > 0).map(hasRole => hasRole.role)

  console.log("@myProposal: ", {myRoles})

  useEffect(() => {
    if (organisation) {
      fetchProposals(organisation);
    }
  }, []);

  return (
    <div className="w-full h-full grow flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80"> 
      <button
        onClick={() => 
          { 
            console.log("clicked") // here have to set deselectedRoles
            router.push('/proposals')
          }
        } 
        className="w-full border-b border-slate-300 p-2"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
        <div className="text-left text-sm text-slate-600 w-52">
          My proposals
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {/* below should be a button */}
       {
      authenticated ? 
      <div className = "w-full h-full lg:h-48 flex flex-col gap-2 justify-start items-center overflow-y-scroll p-2 px-1">
        {
        proposalsWithState?.map((proposal: Proposal, i) => {
            const law = organisation?.laws?.find(law => law.law == proposal.targetLaw)
            return (
            law && law.allowedRole != undefined && myRoles.includes(law.allowedRole) ? 
              <div className = "w-full px-2" key={i}>
                <button 
                  className = {`w-full h-full disabled:opacity-50 rounded-md border ${roleColour[Number(law.allowedRole)]} text-sm p-1 px-2`} 
                  onClick={
                    () => {
                      setProposal(proposal)
                      router.push('/proposals/proposal')
                      }
                    }>
                    <div className ="w-full flex flex-col gap-1 text-sm text-slate-600 justify-center items-center">
                      <div className = "w-full flex flex-row justify-between items-center text-left">
                        {/* need to get the timestamp.. */}
                        <p> Block: </p> 
                        <p> {proposal.blockNumber}  </p>
                      </div>

                      <div className = "w-full flex flex-row justify-between items-center text-left">
                        <p> Law: </p> 
                        <p> {law.name}  </p>
                      </div>
                    </div>
                </button>
                </div>
                :
                null
            )
        })
        }
      </div>
    : 
    <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
      Connect your wallet to see your proposals. 
    </div>
    }
    </div>
  )
}