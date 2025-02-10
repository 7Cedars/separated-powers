// £todo 
// needs to take in: address + type of token (simple drop down menu).

import { Button } from "@/components/Button";
import { DropDownButton } from "@/components/DropDownButton";


export function AddAsset() {
  return (
    <div className="w-full flex flex-col justify-start items-center bg-slate-50 border border-slate-200 rounded-md overflow-hidden">
      <div className="w-full flex flex-row gap-3 min-w-6xl justify-between items-center py-4 px-6 overflow-x-scroll overflow-y-hidden">
        <div className="text-slate-900 text-center font-bold text-md min-w-24">
          Add Token
        </div>
        {/* address input */}
        <div className="grow min-w-28 flex items-center rounded-md bg-white pl-3 outline outline-1 outline-gray-300">  
          <input 
            type= "text" 
            name={`input`} 
            id={`input`}
            className="w-full h-8 pe-2 text-base text-slate-600 placeholder:text-gray-400 focus:outline focus:outline-0 sm:text-sm" 
            placeholder={`Enter token address here.`}
            onChange={() => {}}
            />
        </div>
        {/* dropdown button: type of token */}
        <div className="h-8 flex flex-row w-32 min-w-24 text-center text-slate-200">
          <DropDownButton 
            size = {0} 
            role={8}
            onClick={() => {}}
            > 
              <div className = "text-slate-800">
                Token type
              </div>
          </DropDownButton>
        </div>

        {/* button: add */}
        <div className="h-8 flex flex-row w-20 min-w-12 text-center">
          <Button 
            size = {0} 
            role = {8} 
            onClick={() => {}}
            > 
            <div className = "text-slate-800">
              Add
            </div>
          </Button>
        </div>
      </div>
    </div>
  ) 

} 