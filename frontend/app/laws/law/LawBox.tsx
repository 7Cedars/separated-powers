"use client";

import React, { useEffect, useState } from "react";
import { setLaw, useActionStore, setAction, useLawStore, useOrgStore } from "../../../context/store";
import { Button } from "@/components/Button";
import Link from "next/link";
import { GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { DataType, Law } from "@/context/types";
import { TitleText, SectionText } from "@/components/StandardFonts";
import { useReadContract, useReadContracts } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { parseParams, parseRole } from "@/utils/parsers";
import { InputType } from "@/context/types";
import { DynamicInput } from "@/app/laws/law/DynamicInput";
import { notUpToDate } from "@/context/store"
import { SimulationBox } from "@/components/SimulationBox";
import { useWallets } from "@privy-io/react-auth";

const roleColour = [  
  "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
  "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
]

export function LawBox() {
  const router = useRouter();
  const action = useActionStore();
  const {status, error, law, simulation, checks, resetStatus, execute, fetchSimulation, fetchChecks} = useLaw();
  const { data, isLoading, isError } = useReadContract({
        abi: lawAbi,
        address: law.law,
        functionName: 'getInputParams'
      })
  const dataTypes = data ? parseParams(data as string[]) : []
  const {wallets} = useWallets();
  console.log("@lawbox:", {error, action, status, checks, dataTypes, wallets, simulation})

  const [paramValues, setParamValues] = useState<InputType[] | InputType[][]>(new Array<InputType>(dataTypes.length)); // NB! String has to be converted to hex using toHex before being able to use as input.  
  const [description, setDescription] = useState<string>("");

  const handleChange = (input: InputType | InputType[], index: number) => {
    console.log("@handleChange called:", {input, index, paramValues})
    const currentInput = paramValues 
    currentInput[index] = input
    setParamValues(currentInput)
    // reset useLaw hook  
    resetStatus()
  }  
  
  const handleSimulate = async (event: React.MouseEvent<HTMLButtonElement>) => {
      event.preventDefault() 
      console.log("@handleSimulate Called")
      let lawCalldata: `0x${string}`
      if (paramValues.length > 0 && paramValues) {
        lawCalldata = encodeAbiParameters(parseAbiParameters(dataTypes.toString()), paramValues);
      } else {
        lawCalldata = '0x0'
      }
        // resetting store 
        setAction({
          dataTypes: dataTypes,
          paramValues: paramValues,
          description: description,
          callData: lawCalldata,
          upToDate: true
        })
        // simulating law. 
        fetchSimulation(
          wallets[0] ? wallets[0].address as `0x${string}` : '0x0', // needs to be wallet! 
          lawCalldata as `0x${string}`,
          keccak256(toHex(description))
        )
        fetchChecks(description, lawCalldata) 
  };

  const handleExecute = async () => {
      execute(
          law.law as `0x${string}`,
          action.callData as `0x${string}`,
          action.description
      )
  };

  // resetting lawBox when switching laws: 
  useEffect(() => {
    notUpToDate({})
    resetStatus()
  }, [law])

  return (
    <main className="w-full h-full">
      <section className={`w-full h-full bg-slate-50 border ${roleColour[parseRole(law.allowedRole)]} rounded-md overflow-hidden`} >
      {/* title  */}
      <div className="w-full flex flex-row justify-between items-center border-b border-slate-300 py-4 ps-6 pe-2">
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
            <DynamicInput dataType = {dataType} values = {paramValues[index]} onChange = {(input)=> {handleChange(input, index)}}/>)
        }
        <div className="w-full mt-4 flex flex-row justify-center items-start px-6 pb-4 min-h-24">
          <label htmlFor="reason" className="block min-w-20 text-sm/6 font-medium text-slate-600 pb-1">Reason</label>
          <div className="grow flex items-center rounded-md bg-white pl-3 outline outline-1 outline-slate-300">
              <textarea 
                name="reason" 
                id="reason" 
                rows={3} 
                cols ={25} 
                className="min-w-0 p-1 text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0" 
                placeholder="Describe reason for action here."
                onChange={(event) => {{
                  setDescription(event.target.value); 
                  resetStatus(); 
                  }}} />
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
      <SimulationBox simulation = {simulation} />

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
