import { Button } from "@/components/Button";

import {useLawStore, useOrgStore, setLaw, useActionStore} from "@/context/store";
import { Law } from "@/context/types";
import { roleColour } from "@/context/Theme"

export function Children() {
  const organisation = useOrgStore();
  const currentLaw = useLawStore();
  const action = useActionStore();

  const childLaws: Law[] | undefined = organisation?.laws?.filter(law => 
    law.config.needCompleted == currentLaw.law || law.config.needNotCompleted == currentLaw.law
  ) 

  return (
    childLaws?.length != 0 ? 
    <div className="w-full flex flex-col gap-3 justify-start items-center bg-slate-50 border slate-300 rounded-md"> 
    <section className="w-full flex flex-col text-sm text-slate-600" > 
      <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 border-b border-slate-300">
        <div className="text-left w-52">
          Child laws
        </div>
      </div>
        {    
          childLaws?.map(law =>
            <> 
              <div className = "w-full flex flex-row p-2 px-3">
                <button 
                  className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[1]} disabled:opacity-50`}
                  onClick = {() => {setLaw(law)}}
                  disabled = { !action.upToDate }
                >
                  <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                      {law.name}
                  </div>
                </button>
              </div>
            </>
          )
      }
  </section>
  </div>
  : null
  )
}