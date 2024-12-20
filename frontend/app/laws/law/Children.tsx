import { Button } from "@/components/Button";

export function Children() {
  const roleColour = [
    "border-blue-600", "border-red-600", "border-yellow-600", "border-purple-600",
    "green-slate-600", "border-orange-600", "border-stone-600", "border-slate-600"
  ]

  return (
    <section className="w-full flex flex-col text-sm text-slate-600" > 
      <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900 border-b border-slate-300">
        <div className="text-left w-52">
          Children
        </div> 
      </div>

      {/* Law -- this should be dynamic. btw. will very rarely be more than 2*/}
      <div className = "w-full flex flex-row p-2 px-3">
        <button className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[1]}`}>
          <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
            Here law name 
          </div>
        </button>
      </div>

      <div className = "w-full flex flex-row p-2 px-3">
        <button className={`w-full h-full flex flex-row items-center justify-center rounded-md border ${roleColour[2]}`}>
          <div className={`w-full h-full flex flex-row items-center justify-center text-slate-600 gap-1 px-2 py-1`}>
          Here law name 
          </div>
        </button>
      </div>

  </section>
  )
}