"use client";

import { ChangeEvent, useState } from "react";
import { parseInput } from "@/utils/parsers";
import { DataType, InputType } from "@/context/types";
import { 
 MinusIcon,
 PlusIcon
} from '@heroicons/react/24/outline';
import {notUpToDate} from "@/context/store"

type InputProps = {
  dataType: DataType;
  varName: string;
  values: InputType | InputType[]
  onChange: (input: InputType | InputType[]) => void;
}

export function DynamicInput({dataType, varName, onChange}: InputProps) {
  const [inputArray, setInputArray] = useState<InputType[]>(new Array<InputType>(1))
  const [itemsArray, setItemsArray] = useState<number[]>([0])
  const [error, setError] = useState<String>()
  console.log({varName})

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
    if (currentInput == 'Incorrect input data') {
      setError(currentInput) 
    } else if(typeof onChange === 'function'){
      let currentArray = inputArray
      if (array) {  
        currentArray[item] = currentInput
        setInputArray(currentArray)
        onChange(inputArray)
      } else {
        currentArray[0] =  currentInput
        setInputArray(currentArray)
        onChange(inputArray[0])
      }  
      notUpToDate({}) 
    }    
  }

  const handleResizeArray = (event: React.MouseEvent<HTMLButtonElement>, expand: boolean, index?: number) => {
    event.preventDefault() 

    if (expand) {
      const newItemsArray = [...Array(itemsArray.length + 1).keys()]
      let newInputArray = new Array<InputType>(newItemsArray.length) 
      // currentInput = [...inputArray] 
      // currentInput.push() // lets see if this works.. 
      setItemsArray(newItemsArray) 
      setInputArray(newInputArray)
    } else {
      const newItemsArray = [...Array(itemsArray.length - 1).keys()]
      const newInputArray = inputArray.slice(0, index)
      setItemsArray(newItemsArray) 
      setInputArray(newInputArray)
    }
  }

  return (
    <div className="w-full flex flex-col justify-center items-center">
      {itemsArray.map((item) =>  
          <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6">
            <div className="text-sm block min-w-20 font-medium text-slate-600">
              {varName}
            </div>

            {
            inputType == "number" || inputType == "string" || inputType == "hex" || inputType == "address" ? 
              <>
                <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
                  <input 
                    type={
                      inputType == "string" || inputType == "hex" || inputType == "address" ? "text" : "number" 
                    } 
                    name={`input${item}`} 
                    id={`input${item}`}
                    className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                    placeholder={`Enter ${dataType.replace(/\[\]/g, '')} value here.`}
                    onChange={(event) => handleChange({event, item})}
                    />
                </div>
              </>
            :
            inputType == "boolean" ? 
              <>
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
                        value={'true'} 
                        className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                        onChange={(event) => handleChange({event, item})}
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
                        value={'false'} 
                        className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
                        onChange={(event) => handleChange({event, item})}
                      />
                  </div>
                </div>
              </>
            :
            null
            }
            {
              array && item == itemsArray.length - 1 ?
                <div className = "flex flex-row gap-2">
                  <button 
                    className = "h-8 w-8 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
                    onClick = {(event) => handleResizeArray(event, true)}
                    > 
                    <PlusIcon className = "h-4 w-4"/> 
                  </button>
                  {
                  item > 0 ? 
                    <button className = "h-8 w-8 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
                    onClick = {(event) => handleResizeArray(event, false, item)}
                    > 
                      <MinusIcon className = "h-4 w-4"/> 
                    </button>
                  : null 
                  }
                </div>
              :
              null
            } 

          </section>

      )
      }
    </div>
  )

  // £CONTINUE HERE: fix that loop stops after doing the first return... 

  // for (let item = 0; item <= inputArray.length; item++) {
  //   if (dataType != 'empty' && dataType != "unsupported") {
  //     return (
  //       <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6">
  //         <div className="text-sm/6 block min-w-16 font-medium text-slate-600 pb-1">
  //           {`${dataType}`}
  //         </div>
  //       {
  //       inputType == "number" || inputType == "string" || inputType == "hex" || inputType == "address" ? 
  //         <>
  //           <div className="w-full flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
  //             <input 
  //               type={
  //                 inputType == "string" || inputType == "hex" || inputType == "address" ? "text" : "number" 
  //               } 
  //               name={`input${item}`} 
  //               id={`input${item}`}
  //               className="block h-8 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
  //               placeholder={`Enter ${dataType} value here.`}
  //               onChange={(event) => handleChange({event, item})}
  //               />
  //           </div>
  //         </>
  //       :
  //       inputType == "boolean" ? 
  //         <>
  //           <div className = {"w-full h-8 ps-4 flex flex-row gap-4  items-center rounded-md bg-white outline outline-1 outline-gray-300" }>
  //           {/* radio button true  */}
  //             <div className = {"flex flex-row gap-1 "}>
  //               <label 
  //                 htmlFor={`input${item}true`} 
  //                 className="block text-sm/6 font-medium text-slate-600 pe-2">
  //                   {`true`}
  //               </label>
  //                 <input 
  //                   type="radio" 
  //                   name={`input${item}`} 
  //                   id={`input${item}true`} 
  //                   value={`true`} 
  //                   className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
  //                 />
  //             </div>
  //             {/* radio button false  */}
  //             <div className = {"flex flex-row gap-1"}>
  //               <label 
  //                 htmlFor={`input${item}false`} 
  //                 className="block text-sm/6 font-medium text-slate-600 pe-2">
  //                   {`false`}
  //               </label>
  //                 <input 
  //                   type="radio" 
  //                   name={`input${item}`} 
  //                   id={`input${item}false`} 
  //                   value={`false`} 
  //                   className="min-w-0 text-base text-slate-600 placeholder:text-gray-400" 
  //                 />
  //             </div>
  //           </div>
  //         </>
  //       :
  //       null
  //       }
  //       {
  //         array ?
  //           <>
  //             <button 
  //               className = "h-8 w-10 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
  //               onClick = {(event) => handleResizeArray(event, true)}
  //               > 
  //               <PlusIcon className = "h-4 w-4"/> 
  //             </button>
  //             {
  //             item > 0 ? 
  //               <button className = "h-8 w-10 grow py-2 flex flex-row items-center justify-center  rounded-md bg-white outline outline-1 outline-gray-300"
  //               onClick = {(event) => handleResizeArray(event, false, item)}
  //               > 
  //                 <MinusIcon className = "h-4 w-4"/> 
  //               </button>
  //             : null 
  //             }
  //           </>
  //         :
  //         null
  //       } 

  //       </section>
  //     )
  //   }
  // }
}
