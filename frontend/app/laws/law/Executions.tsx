import Link from "next/link";


export function Executions() {
  
  return (
    <section className="w-full flex flex-col divide-y divide-slate-300 text-sm text-slate-600" > 
        <div className="w-full flex flex-row items-center justify-between px-4 py-2 text-slate-900">
          <div className="text-left w-52">
            Latest executions
          </div>
        </div>

        {/* execution logs block 1 */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            <div>
              12 Dec 2024
            </div>
            <div>
              13:45
            </div>
          </div>
          <div className = "w-full flex flex-row px-2">
            {/* This should link to block explorer */}
            <Link href="/laws/law">
              0x74ea8...439bc89
            </Link>
          </div>
        </div>

        {/* execution logs block 1 */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            <div>
              12 Dec 2024
            </div>
            <div>
              13:45
            </div>
          </div>
          <div className = "w-full flex flex-row px-2">
            {/* This should link to block explorer */}
            <Link href="/laws/law">
              0x74ea8...439bc89
            </Link>
          </div>
        </div>

        {/* execution logs block 1 */}
        <div className = "w-full flex flex-col justify-center items-center p-2"> 
          <div className = "w-full flex flex-row px-2 py-1 justify-between items-center">
            <div>
              12 Dec 2024
            </div>
            <div>
              13:45
            </div>
          </div>
          <div className = "w-full flex flex-row px-2">
            {/* This should link to block explorer */}
            <Link href="/laws/law">
              0x74ea8...439bc89
            </Link>
          </div>
        </div>

    </section>
  )
}