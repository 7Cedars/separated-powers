"use client";

import { ChangeEvent, useState } from "react";
import { parseParam, parseInput } from "@/utils/parsers";
import { DataType, InputType } from "@/context/types";

type InputProps = {
  dataType: DataType;
  onChange: (input: InputType | InputType[]) => void;
}

export function DynamicInput({dataType, onChange}: InputProps) {
  const [inputArray, setInputArray] = useState<InputType[]>([])
  const [error, setError] = useState<String>()

  const inputType = 
    dataType.indexOf('uint') > -1 ? "number"
    : dataType.indexOf('bool') > -1 ? "boolean"
    : dataType.indexOf('string') > -1 ? "string"
    : dataType.indexOf('address') > -1 ? "address"
    : dataType.indexOf('bytes') > -1 ? "hex"
    : dataType.indexOf('empty') > -1 ? "empty"
    : "unsupported"
  
  const array = 
    dataType.indexOf('[]') > -1 ? true : false

  const handleChange=({event, item}: {event:ChangeEvent<HTMLInputElement>, item: number}) => {
    const currentInput = parseInput(event, dataType)
    if (typeof currentInput == 'string') {
      setError(currentInput)
    } else if(typeof onChange === 'function'){
      if (array) {
        let currentArray = inputArray
        currentArray[item] = parseInput(event, dataType)
        setInputArray(currentArray)
        onChange(inputArray)
      } else {
        onChange(currentInput)
      }  
    }    
  }

  const handleResizeArray= (expand: boolean, index?: number) => {
    if (expand) {
      const currentInput = inputArray
      currentInput.push() // lets see if this works.. 
      setInputArray(currentInput)
    } else {
      const currentInput = inputArray.slice(0, index)
      setInputArray(currentInput)
    }
  }

  for (let item = 0; item <= inputArray.length; item++) {
    return (
      <>
      {
        inputType == "number" || inputType == "string" || inputType == "hex" || inputType == "address" ? 
        <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
          <label htmlFor={`input${item}`} className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">
          {`${dataType}`}
          </label>
            <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
              <input 
                type={
                  inputType == "string" || inputType == "hex" || inputType == "address" ? "text" : "number" 
                } // £todo this I can make more specific later on...   
                name={`input${item}`} 
                id={`input${item}`}
                className="block min-w-0 grow py-1.5 pl-1 pr-3 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                placeholder={`Enter ${dataType} value here.`}  
                onChange={(event) => handleChange({event, item})}
                />
            </div>
        </div>  
      :
      inputType == "boolean" ? 
        <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
          <div className="block min-w-28 text-sm/6 font-medium text-slate-600 pb-1">
            {`${dataType}`}
          </div>
          <div className = {"w-full h-8 ps-4 flex flex-row gap-4  items-center rounded-md bg-white outline outline-1 outline-gray-300" }>
          {/* radio button true  */}
            <div className = {"flex flex-row gap-1 "}>
              <label 
                htmlFor={`input${item}true`} 
                className="block text-sm/6 font-medium text-slate-600 pe-2">
                  {`true`}
              </label>
                <input 
                  type="radio" 
                  name={`input${item}`} 
                  id={`input${item}true`} 
                  value={`true`} 
                  className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                />
            </div>
            {/* radio button false  */}
            <div className = {"flex flex-row gap-1"}>
              <label 
                htmlFor={`input${item}false`} 
                className="block text-sm/6 font-medium text-slate-600 pe-2">
                  {`false`}
              </label>
                <input 
                  type="radio" 
                  name={`input${item}`} 
                  id={`input${item}false`} 
                  value={`false`} 
                  className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                />
            </div>
          </div>
        </div>  
      :
      inputType == "empty" ? null 
      : 
      // here add a block for boolean. 
      <div className="w-full mt-4 flex flex-row justify-center items-center gap-y-4 px-6">
         Input type not supported. 
      </div> 
      }
      </>
    )
  }
}
