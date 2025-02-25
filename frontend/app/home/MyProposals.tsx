`use client`

import { useOrgStore, setProposal, setAction, setLaw} from "@/context/store";
import { Proposal } from "@/context/types";
import { ArrowUpRightIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { toFullDateFormat } from "@/utils/toDates";

const roleColour = [  
  "border-blue-600", 
  "border-red-600", 
  "border-yellow-600", 
  "border-purple-600",
  "border-green-600", 
  "border-orange-600", 
  "border-slate-600"
]

type MyProposalProps = {
  hasRoles: {role: bigint, since: bigint}[]
  authenticated: boolean;
  proposals: Proposal[] | undefined; 
}

export function MyProposals({hasRoles, authenticated, proposals}: MyProposalProps ) {
  const organisation = useOrgStore();

  const router = useRouter();
  const myRoles = hasRoles.filter(hasRole => hasRole.role > 0).map(hasRole => hasRole.role)

  return (
    <div className="w-full grow flex flex-col justify-start items-center bg-slate-50 border slate-300 rounded-md max-w-80"> 
      <button
        onClick={() => 
          { 
             // here have to set deselectedRoles
            router.push('/proposals')
          }
        } 
        className="w-full border-b border-slate-300 p-2"
      >
      <div className="w-full flex flex-row gap-6 items-center justify-between px-2">
        <div className="text-left text-sm text-slate-600 w-52">
          My active proposals
        </div> 
          <ArrowUpRightIcon
            className="w-4 h-4 text-slate-800"
            />
        </div>
      </button>
       {/* below should be a button */}
       {
      authenticated ?
        proposals && proposals.length > 0 ? 

          <div className = "w-full h-fit lg:max-h-48 max-h-32 flex flex-col gap-2 justify-start items-center overflow-x-scroll p-2 px-1">
          {
          proposals?.map((proposal: Proposal, i) => {
              const law = organisation?.laws?.find(law => law.law == proposal.targetLaw)
              return (
              law && law.allowedRole != undefined && myRoles.includes(law.allowedRole) && proposal.state == 0 ? 
                <div className = "w-full px-2" key={i}>
                  <button 
                    className = {`w-full h-full disabled:opacity-50 rounded-md border ${roleColour[Number(law.allowedRole)]} text-sm p-1 px-2`} 
                    onClick={
                      () => {
                        setProposal(proposal)
                        setLaw(law)
                        setAction({
                          description: proposal.description,
                          callData: proposal.executeCalldata
                        })
                        router.push('/proposals/proposal')
                        }
                      }>
                      <div className ="w-full flex flex-col gap-1 text-sm text-slate-600 justify-center items-center">
                        <div className = "w-full flex flex-row justify-between items-center text-left">
                          <p> Date: </p> 
                          <p> {toFullDateFormat(Number(proposal.voteStartBlockData?.timestamp))}  </p>
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
      <div className = "w-full flex flex-row gap-1 text-sm text-slate-500 justify-center items-center text-center p-3">
        No proposals found
      </div>
      :   
    <div className="w-full h-full flex flex-col justify-center text-sm text-slate-500 items-center p-3">
      Connect your wallet to see your proposals. 
    </div>
    }
    </div>
  )
}