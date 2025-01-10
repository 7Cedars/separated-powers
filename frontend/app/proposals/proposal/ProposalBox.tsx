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
import { roleColour } from "@/context/ThemeContext"
import { notUpToDate } from "@/context/store"
import { useProposal } from "@/hooks/useProposal";

// NB! the proposalBox can be requested using a proposal with only calldata (and without the original inputValues) -> coming from proposalList. 
// or using only the original inputValues -> coming from law. NB: action DOES have calldata. 
// so have to  

export function ProposalBox() {
  const router = useRouter();
  const proposal = useProposalStore();
  const action = useActionStore();

  const {simulation, law, checks, resetStatus, execute, checkProposalExists, fetchSimulation, fetchChecks} = useLaw();
  const {status, error, propose, castVote} = useProposal();
  const [jsxSimulation, setJsxSimulation] = useState<React.JSX.Element[]> ([]); 
  const [inputValues, setInputValues] = useState<(InputType | InputType[])[]>([])
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
        setInputValues(valuesParsed)

        // resetting rendering output
        setJsxSimulation([])
        
        // simulating law. 
        fetchSimulation(
          law.law as `0x${string}`,
          calldata,
          keccak256(toHex(description))
        )

        fetchChecks(description, calldata)

        setAction({
          dataTypes: dataTypes,
          inputValues: inputValues,
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

  useEffect(() => {
    if (simulation && simulation[0].length > 0) {
      console.log("@useEffect, jsxSimulate triggered: ", simulation)
      let jsxElements: React.JSX.Element[] = []; 
      for (let i = 0; i < simulation[0].length; i++) {
        console.log("@useEffect building..", i)
        jsxElements = [ 
          ... jsxElements, 
          <tr
            key={i}
            className={`text-sm text-left text-slate-800 h-16 p-2 overflow-x-scroll`}
          >
            {/*  */}
            <td className="ps-6 text-slate-500"> {simulation[0][i]} </td> 
            <td className="text-slate-500"> {String(simulation[1][i])} </td>
            <td className="pe-4 text-slate-500"> {simulation[2][i]} </td>
          </tr>
        ];
      }
      setJsxSimulation(jsxElements)
    }  
  }, [simulation])

  // resetting lawBox when switching laws: 
  useEffect(() => {
    console.log("startup set @proposalBox triggered:", {calldata, description})
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

      {/* dynamic form */}
      <form action="" method="get" className="w-full">
        {
          dataTypes ? dataTypes.map((dataType, index) => 
            <StaticInput dataType = {dataType} values = {inputValues && inputValues[index] ? inputValues[index] : []} />)
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

      {/* fetchSimulation output */}
      <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 pt-2 px-6">
        <div className="w-full text-xs text-center text-slate-500 border rounded-t-md border-b-0 border-slate-300 p-2">
          Simulated output 
        </div>
        <div className="w-full h-fit border border-slate-300 overflow-scroll rounded-b-md">
          <table className="table-auto w-full ">
            <thead className="w-full">
              <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                  <th className="ps-6 py-2 font-light"> Target contracts </th>
                  <th className="font-light"> Value </th>
                  <th className="font-light"> Calldata </th>
              </tr>
            </thead>
              <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                { jsxSimulation.map(row => {return (row)} ) } 
              </tbody>
            </table>
          </div>
        
        {/* Horizontal divider line  */}
        {/* <div className="w-1/3 border-b border-slate-200 mt-6"/>  */}
          
      </div>

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
