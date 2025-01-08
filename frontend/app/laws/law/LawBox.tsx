"use client";

import React, { useEffect, useState } from "react";
import { setLaw, useActionStore, setAction, useLawStore, useOrgStore } from "../../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { Law } from "@/context/types";
import { TitleText, SectionText } from "@/components/StandardFonts";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { parseParams } from "../../../utils/parsers";
import { InputType } from "../../../context/types";
import { DynamicInput } from "@/components/DynamicInput";

export function LawBox() {
  const router = useRouter();
  const action = useActionStore();

  const {status, error, law, simulation, checks, execute, fetchSimulation, fetchChecks} = useLaw();
  const { data: params, isLoading, isError } = useReadContract({
    abi: lawAbi,
    address: law.law,
    functionName: 'getParams'
  })
  const dataTypes = params ? parseParams(params as string[]) : []
  console.log("@lawbox:", {error, status})

  const [inputValues, setInputValues] = useState<InputType[] | InputType[][]>(new Array<InputType>(dataTypes.length)); // NB! String has to be converted to hex using toHex before being able to use as input.  
  const [description, setDescription] = useState<string>("");
  const [jsxSimulation, setJsxSimulation] = useState<React.JSX.Element[]> ([]); 


  const roleColour = [ // this I should import from somewhere. 
    "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
    "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
  ]

  const role = law.allowedRole == 0n ? 0 
  : law.allowedRole == 4294967295n ? 6 
  : Number(law.allowedRole)

  const handleChange = (input: InputType | InputType[], index: number) => {
    console.log("@handleChange triggered")
    const currentInput = inputValues 
    currentInput[index] = input
    console.log("@handleChange", {currentInput})
    setInputValues(currentInput)
  }  
  
  const handleSimulate = async (event: React.MouseEvent<HTMLButtonElement>) => {
      event.preventDefault() 
      console.log("@handleSimulate Called")
      let lawCalldata: `0x${string}`
      if (dataTypes.length > 0 && inputValues) {
        lawCalldata = encodeAbiParameters(parseAbiParameters(dataTypes.toString()), inputValues);
      } else {
        lawCalldata = '0x0'
      }
        // resetting rendering output
        setJsxSimulation([])
        // resetting store 
        setAction({
          dataTypes: dataTypes,
          inputValues: inputValues,
          description: description,
          callData: lawCalldata,
          upToDate: true
        })
        // simulating law. 
        fetchSimulation(
          law.law as `0x${string}`,
          lawCalldata as `0x${string}`,
          keccak256(toHex(description))
        )
  };

  const handleExecute = async () => {
      execute(
          law.law as `0x${string}`,
          action.callData as `0x${string}`,
          action.description
      )
  };

  // NB! need to check if Action from store is same as Action in current form. If not -> disable Execute! + disable links in check boxes. -> do not let user go to other law. 
  useEffect(() => {
    if (simulation && simulation[0].length > 0) {
      console.log("@useEffect, jsxSimulate triggered")
      let jsxElements: React.JSX.Element[] = []; 
      for (let i = 0; i < simulation[0].length; i++) {
        console.log("@useEffect building..", i)
        jsxElements = [ 
          ... jsxElements, 
          <tr
            key={i}
            className={`text-sm text-left text-slate-800 h-16 p-2`}
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

  return (
    <main className="w-full flex flex-col justify-start items-center">
      <section className={`w-full flex flex-col justify-start items-center bg-slate-50 border ${roleColour[role]} mt-2 rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={law?.name}
          subtext={law?.description}
          size = {0}
        /> 
      </div>

      {/* dynamic form */}
      <form action="" method="get" className="w-full">
        {
          dataTypes.map((dataType, index) => 
            <DynamicInput dataType = {dataType} onChange = {(input)=> {handleChange(input, index)}}/>)
        }
        <div className="w-full mt-4 flex flex-row justify-center items-start gap-y-4 px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 -outline-offset-1 outline-gray-300 focus-within:outline focus-within:outline-2 focus-within:-outline-offset-2 focus-within:outline-indigo-600">
              <textarea 
                name="reason" 
                id="reason" 
                rows={3} 
                cols ={25} 
                className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder="Describe reason for action here. This description needs to be unique for action to be valid."
                onChange={(event) => {setDescription(event.target.value)}} />
            </div>
        </div>
        <div className="w-full flex flex-row justify-center items-center px-6 pb-4">
          <Button 
            size={1} 
            showBorder={true} 
            onClick={(event) => handleSimulate(event)} 
            statusButton={
              !action.upToDate && description.length > 0 ? status : 'disabled'
              }> 
            Check 
          </Button>
        </div>
      </form>


      {/* fetchSimulation output */}
      <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 pt-2 px-6">
        <div className="w-full text-xs text-center text-slate-500 border rounded-t-md border-b-0 border-slate-300 p-2">
          Simulated output 
        </div>
        <div className="w-full h-fit border border-slate-300 rounded-b-md overflow-hidden">
          <table className="w-full table-auto">
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
          <Button 
            size={1} 
            onClick={handleExecute} 
            statusButton={
              checks && 
              checks.authorised && 
              checks.delayPassed && 
              checks.lawCompleted && 
              checks.lawNotCompleted && 
              checks.proposalPassed && 
              checks.throttlePassed ? 
              status : 'disabled'
              }> 
            Execute
          </Button>
        </div>
      </section>
    </main>
  );
}
