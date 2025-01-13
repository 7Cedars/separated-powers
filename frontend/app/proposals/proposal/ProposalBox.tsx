"use client";

import React, { useEffect, useState } from "react";
import { setLaw, useActionStore, setAction, useLawStore, useOrgStore, useProposalStore } from "@/context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law, Proposal } from "@/context/types";
import { TitleText, SectionText } from "@/components/StandardFonts";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { decodeAbiParameters, encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { parseInputValues, parseParams, parseRole } from "@/utils/parsers";
import { InputType } from "@/context/types";
import { StaticInput } from "./StaticInput";
import { roleColour } from "@/context/Theme"
import { notUpToDate } from "@/context/store"
import { useProposal } from "@/hooks/useProposal";
import { SimulationBox } from "@/components/SimulationBox";

// NB! the proposalBox can be requested using a proposal with only calldata (and without the original paramValues) -> coming from proposalList. 
// or using only the original paramValues -> coming from law. NB: action DOES have calldata. 
// so have to  

export function ProposalBox() {
  const router = useRouter();
  const proposal = useProposalStore();
  const action = useActionStore();

  const {simulation, law, checks, resetStatus, execute, checkProposalExists, fetchSimulation, fetchChecks} = useLaw();
  const {status, error, propose, castVote} = useProposal();
  const [paramValues, setParamValues] = useState<(InputType | InputType[])[]>([])
  const description =  proposal?.description && proposal.description.length > 0 ? proposal.description 
                    : action.description && action.description.length > 0 ? action.description
                    : undefined  
  const calldata =  proposal?.executeCalldata && proposal.executeCalldata.length > 0 ? proposal.executeCalldata 
                    : action.callData && action.callData.length > 0 ? action.callData
                    : undefined  
  const { data: params, isLoading, isError } = useReadContract({
    abi: lawAbi,
    address: law.law,
    functionName: 'getParams'
  })
  const dataTypes = params ? parseParams(params as string[]) : []

  console.log("@ProposalBox:", {proposal, action, status, checks, dataTypes})

  const handleSimulate = async () => { 
      if (dataTypes && dataTypes.length > 0 && calldata && description) {
        const values = decodeAbiParameters(parseAbiParameters(dataTypes.toString()), calldata);
        const valuesParsed = parseInputValues(values)
        setParamValues(valuesParsed)
        
        // simulating law. 
        fetchSimulation(
          law.law as `0x${string}`,
          calldata,
          keccak256(toHex(description))
        )

        fetchChecks(description, calldata)

        setAction({
          dataTypes: dataTypes,
          paramValues: paramValues,
          description: description,
          callData: calldata, 
          upToDate: true
        })
      }
  };

  const handlePropose = async () => {
    propose(
          law.law as `0x${string}`,
          proposal.executeCalldata as `0x${string}`,
          proposal.description as string
      )
  };

  const handleCastVote = async (support: bigint) => { 
    const selectedProposal = description && calldata ? checkProposalExists(description, calldata) : undefined
    if (selectedProposal)
    castVote(
        BigInt(selectedProposal.proposalId),
        support
      )
  };

  // resetting lawBox when switching laws: 
  useEffect(() => {
    handleSimulate()
  }, [, law, proposal ])

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[parseRole(law.allowedRole)]} mt-2 rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={`Proposal: ${law?.name}`}
          subtext={law?.description}
          size = {0}
        /> 
      </div>

      {/* static form */}
      <form action="" method="get" className="w-full">
        {
          dataTypes ? dataTypes.map((dataType, index) => 
            <StaticInput dataType = {dataType} values = {paramValues && paramValues[index] ? paramValues[index] : []} />)
          :
          null
        }
        <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md bg-slate-100 pl-3 outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea 
                name="reason" 
                id="reason" 
                rows={3} 
                cols ={25} 
                value={description}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here. This description needs to be unique for action to be valid."
                disabled={true} 
                />
            </div>
        </div>
      </form>

      <SimulationBox /> 

      {/* execute button */}
        <div className="w-full h-fit p-6">
          {
            checks?.proposalExists ? 
            <div className = "w-full flex flex-row gap-2"> 
              <Button 
                size={1} 
                onClick={() => handleCastVote(1n)} 
                statusButton={
                  checks && 
                  checks.authorised ? 
                  status : 'disabled'
                  }> 
                  For
              </Button>
              <Button 
                size={1} 
                onClick={() => handleCastVote(0n)} 
                statusButton={
                  checks && 
                  checks.authorised ? 
                  status : 'disabled'
                  }> 
                  Against
              </Button>
              <Button 
                size={1} 
                onClick={() => handleCastVote(2n)} 
                statusButton={
                  checks && 
                  checks.authorised ? 
                  status : 'disabled'
                  }> 
                  Abstain
              </Button>
            </div>
            :
            <Button 
            size={1} 
            onClick={handlePropose} 

            statusButton={ 
              checks && 
              checks.authorised ? 
              status : 'disabled'
              }> 
            Propose
          </Button>
          }
        </div>
      </section>
    </main>
  );
}
