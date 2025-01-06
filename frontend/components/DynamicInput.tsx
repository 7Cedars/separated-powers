import { useOrgStore } from "@/context/store";
import Link from "next/link";
import { useState } from "react";
import { InputType } from "../context/types";
import { parseParam } from "@/utils/parsers";

export function DynamicInput(param: `0x${string}`) {
  const [input, setInput] = useState<Number | Boolean | String | `0x${string}` | Number[] | Boolean[] | String[] | `0x${string}`[] | undefined >(undefined)
  const [arrayLength, setArrayLength] = useState<number>(1)
  const {inputType, array}  = parseParam(param)

  for (let items = 0; items < arrayLength; items++) {
    return (
      <>
      {
        inputType == "number" || inputType == "string" || inputType == "hex" || inputType == "address" ? 
        <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
          <label htmlFor="username" className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">Input 1 (text) </label>
            <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
              <input 
                type={
                  inputType == "string" || inputType == "hex" || inputType == "address" ? "text" : "number" 
                } // £todo this I can make more specific later on...   
                name="username" id="username" className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" placeholder="janesmith" />
            </div>
        </div>  
      :
      <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
         Input type not supported. 
      </div> 
      }
      </>
    )
  }
}
