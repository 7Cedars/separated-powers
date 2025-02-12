"use client";

import { DataType, InputType } from "@/context/types";

type InputProps = {
  dataType: DataType;
  values: InputType | InputType[]  
}

export function StaticInput({dataType, values}: InputProps) {
  const array = 
    dataType.indexOf('[]') > -1 ? true : false
  const itemsArray = array ? values as Array<InputType> : [values] as Array<InputType>

  return (
    <div className="w-full flex flex-col justify-center items-center">
      {itemsArray.map((item) =>  
          <section className="w-full mt-4 flex flex-row justify-center items-center gap-4 px-6">
            <div className="text-sm/6 block min-w-16 font-medium text-slate-600">
              {`${dataType}`.replace(/\[\]/g, '')}
            </div>

            {
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
            }
          </section>

      )
      }
    </div>
  )
}
