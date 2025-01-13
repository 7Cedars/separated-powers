"use client";

import { setLaw } from "@/context/store";
import { useLaw } from "@/hooks/useLaw";
import { useRouter } from 'next/navigation'
import { roleColour } from "@/context/Theme"

export const Law: React.FC = () => {
  const {law} = useLaw(); 
  const router = useRouter();

  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Law
          </div> 
        </div>

        {/* authorised block */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
            <button 
                className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[Number(law?.allowedRole)]} disabled:opacity-50`}
                onClick = {() => {
                  setLaw(law)
                  router.push('/laws/law') 
                }}
              >
                <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
                    {law.name}
                </div>
            </button>
        </div>
    </section>
  )
}