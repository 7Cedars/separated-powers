"use client";

import { ChangeEvent, useEffect, useState } from "react";
import { parseInput } from "@/context/parsers";
import { DataType, InputType } from "@/context/types";
import { 
 MinusIcon,
 PlusIcon
} from '@heroicons/react/24/outline';
import {notUpToDate} from "@/context/store"

type InputProps = {
  dataType: DataType;
  values: InputType | InputType[]  
}

export function StaticInput({dataType, values}: InputProps) {
  const [error, setError] = useState<String>()
  const [test, setTest] = useState<Number>(0)

  console.log("@StaticInput", {error})
  console.log("@StaticInput", {values})

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
  const itemsArray = array ? values as Array<InputType> : [values] as Array<InputType>
  console.log({itemsArray})

  return (
    <div className="w-full flex flex-col justify-center items-center">
      {itemsArray.map((item) =>  
          <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6">
            <div className="text-sm/6 block min-w-16 font-medium text-slate-600">
              {`${dataType}`.replace(/\[\]/g, '')}
            </div>

            {
            // inputType == "number" || inputType == "string" || inputType == "hex" || inputType == "address" ? 
              <>
                <div className="w-full flex items-center rounded-md bg-slate-100 pl-3 outline outline-1 outline-gray-300">  
                  <input 
                    type={"string"}
                    name={`input${item}`} 
                    id={`input${item}`}
                    className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm/6" 
                    value={String(item)}
                    disabled={true}
                    />
                </div>
              </>
            // :
            // null
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
