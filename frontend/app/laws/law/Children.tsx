import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw} from "@/context/store";
import { Law } from "@/context/types";

export function Children() {
  const organisation = useOrgStore();
  const currentLaw = useLawStore();

  const roleColour = [
    "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
    "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
  ]

  const childLaws: Law[] | undefined = organisation?.laws?.filter(law => 
    law.config.needCompleted == currentLaw.law || law.config.needNotCompleted == currentLaw.law
  ) 

  return (
    <section className="w-full flex flex-col text-sm text-slate-600" > 
      <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 border-b border-slate-300">
        <div className="text-left w-52">
          Child laws
        </div> 
      </div>

      {/* Law -- this should be dynamic. btw. will very rarely be more than 2*/}

      { 
        childLaws?.length != 0 ?
          childLaws?.map(law =>
            <> 
              <div className = "w-full flex flex-row p-2 px-3">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[1]}`}
                  onClick = {() => {setLaw(law)}}
                >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                      {law.name}
                  </div>
                </button>
              </div>
            </>
          )
        : 
        <> 
          <div className = "w-full flex flex-col justify-center items-center p-2 px-3 italic text-slate-400">
            No dependencies found. 
          </div>
        </>
      }
  </section>
  )
}