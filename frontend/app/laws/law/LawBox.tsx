"use client";

import React, { useEffect, useState } from "react";
import { useActionStore, setAction } from "../../../context/store";
import { Button } from "@/components/Button";
import { ArrowUpRightIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { SectionText } from "@/components/StandardFonts";
import { useChainId, useReadContract, useReadContracts } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { encodeAbiParameters, keccak256, parseAbiParameters, toHex } from "viem";
import { bytesToParams, parseParams, parseRole } from "@/utils/parsers";
import { InputType, DataType } from "@/context/types";
import { DynamicInput } from "@/app/laws/law/DynamicInput";
import { notUpToDate } from "@/context/store"
import { SimulationBox } from "@/components/SimulationBox";
import { useWallets } from "@privy-io/react-auth";
import { supportedChains } from "@/context/chains";

// CONTINUE HERE 
/// NB! inputParams bytecode: (bytecode.length - 3) / 192 = number of params. And all params are strings.... 
// use abi.decode to get to params!

const roleColour = [  
  "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
  "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
] 
export function LawBox() {
  const router = useRouter();
  const action = useActionStore();
  const {status, error, law, simulation, checks, resetStatus, execute, fetchSimulation, fetchChecks} = useLaw();
  const { data, isLoading, isError, error: errorInputParams } = useReadContract({
        abi: lawAbi,
        address: law.law,
        functionName: 'inputParams'
      })

  console.log({data, isLoading, isError, errorInputParams})
  const params =  bytesToParams(data as `0x${string}`)  
  const dataTypes = params.map(param => param.dataType) 
  const {wallets} = useWallets();

  const [paramValues, setParamValues] = useState<InputType[] | InputType[][]>(new Array<InputType>(params.length)); // NB! String has to be converted to hex using toHex before being able to use as input.  
  const [description, setDescription] = useState<string>("");
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)

  const handleChange = (input: InputType | InputType[], index: number) => {
    const currentInput = paramValues 
    currentInput[index] = input
    setParamValues(currentInput)
    // reset useLaw hook  
    resetStatus()
  }  
  
  const handleSimulate = async (event: React.MouseEvent<HTMLButtonElement>) => {
      event.preventDefault() 
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
      <div className="w-full flex flex-col gap-2 justify-start items-start border-b border-slate-300 py-4 ps-6 pe-2">
        <SectionText
          text={law?.name}
          subtext={law?.description}
          size = {0}
        /> 
         <a
            href={`${supportedChain?.blockExplorerUrl}/address/${law.law}#code`} target="_blank" rel="noopener noreferrer"
            className="w-full"
          >
          <div className="flex flex-row gap-1 items-center justify-start">
            <div className="text-left text-sm text-slate-500 break-all w-fit">
              {law.law }
            </div> 
              <ArrowUpRightIcon
                className="w-4 h-4 text-slate-500"
                />
            </div>
          </a>
      </div>

      {/* dynamic form */}
      <form action="" method="get" className="w-full">
        {
          params.map((param, index) => 
            <DynamicInput dataType = {param.dataType} varName = {param.varName} values = {paramValues[index]} onChange = {(input)=> {handleChange(input, index)}}/>)
        }
        <div className="w-full mt-4 flex flex-row justify-center items-start ps-3 pe-6 pb-4 min-h-24">
          <label htmlFor="reason" className="text-sm text-slate-600 pb-1 pe-12 ps-3">Reason</label>
          <div className="w-full h-fit flex items-center text-md justify-start rounded-md bg-white pl-3 outline outline-1 outline-slate-300">
              <textarea 
                name="reason" 
                id="reason" 
                rows={5} 
                cols ={60} 
                className="min-w-0 p-1 w-full text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0" 
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
