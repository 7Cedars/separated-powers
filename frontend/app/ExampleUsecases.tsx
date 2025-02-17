"use client";

import { useEffect, useRef } from "react";
import { exampleUseCases } from  "../public/exampleUseCases";
import Image from 'next/image'
import { ArrowUpRightIcon, ChevronDownIcon } from "@heroicons/react/24/outline";
  

export function ExampleUseCases() { 

  return (    
    <section className="w-full min-h-[100vh] flex flex-col justify-between items-center bg-gradient-to-b from-blue-600 to-blue-400 snap-start snap-always pt-6 px-6">
        {/* title  */}
          <section className="w-full min-h-64 flex flex-col justify-center items-center">
              <div className = "w-full flex flex-col gap-1 justify-center items-center md:text-4xl text-3xl font-bold text-slate-100 max-w-4xl text-center text-pretty">
                  The next generation of on-chain governance
              </div>
              <div className = "w-full flex justify-center items-center md:text-2xl text-lg text-slate-300 max-w-2xl text-center">
                  Separated Powers is a proof of concept of a role restricted governance protocol. These type of protocols have several potential high-impact use cases. 
              </div>
          </section>

          <section className = "h-full w-full flex flex-col justify-center items-center" style = {{position: 'relative', width: '100%', height: '100%'}}> 
            <Image 
                src={"/home.png"} 
                className = "p-4 rounded-md" 
                style={{objectFit: "contain", objectPosition: "center"}}
                fill={true}
                alt="Screenshot Separated Powers"
                >
            </Image>
          </section>


        {/* use cases  */}
        <section 
          className="w-screen min-h-fit h-full flex flex-row gap-10 justify-start items-center overflow-x-scroll" 
          >
            <div className = "h-20" />
            {   
              exampleUseCases.map((useCase, index) => (
                <div className="min-w-96 max-h-[25vh] h-full flex flex-col justify-center items-center border border-slate-300 rounded-md bg-slate-50 overflow-hidden" key={index}>  
                  <div className="w-full h-fit font-bold text-slate-700 p-3 ps-5 border-b border-slate-300 bg-slate-100">
                      {useCase.title}
                  </div> 
                  <div className = "w-full grow flex flex-col justify-start items-start ps-5 pe-4 p-3 gap-2">
                    <div className="w-full text-left">
                        {useCase.challenge}
                    </div>
                    <div className="w-full text-left">
                        {useCase.solution}
                    </div>
                  </div>
                </div>
              ))
            }
      </section>  

      {/* arrow down */}
      <div className = "flex flex-col align-center justify-end"> 
        <ChevronDownIcon
            className = "w-16 h-16 text-slate-700" 
        /> 
      </div>

    </section>
  )

}