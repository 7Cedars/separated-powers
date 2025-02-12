"use client";

import { useEffect, useRef } from "react";
import { exampleUseCases } from  "../public/exampleUseCases";
import Image from 'next/image'

function useHorizontalScroll<T extends HTMLElement>() {
    const elRef = useRef<T>(null);
    useEffect(() => {
      const el = elRef.current;
      if (el) {
        const onWheel = (e: WheelEvent) => {
          if (e.deltaY == 0) return;
          e.preventDefault();
          el.scrollTo({
            left: el.scrollLeft + (e.deltaY > 0 ? 300 : -300),
            behavior: 'smooth',
          });
        };
        el.addEventListener('wheel', onWheel);
        return () => el.removeEventListener('wheel', onWheel);
      }
    }, []);
    return elRef;
  }

  

export function ExampleUseCases() {
  const scrollRef = useHorizontalScroll();

  return (
   <section className="w-full h-[80vh] flex flex-col justify-center items-center bg-gradient-to-b from-blue-500 to-slate-100 snap-start snap-always p-12">    
                  {/* use cases  */}
                  <section 
                    className="w-screen h-fit flex flex-row gap-12 justify-center items-center"
                    style={{ overflow: "scroll" }}
                    ref={scrollRef}  
                    >
                        {/* An empty slot to help out with outlining */}
                        <div className="min-w-[50vw] h-full flex flex-col justify-center items-center snap-center snap-always gap-12" />
                        {   
                          exampleUseCases.map((useCase, index) => (
                              <div className="min-w-[60vw] min-h-[60vh] h-full flex flex-col justify-center items-center text-slate-50 snap-center snap-always" key={index}> 
                                  <div className="h-full flex flex-col justify-end text-center text-pretty text-lg sm:text-2xl text-slate-200 py-4">
                                      {useCase.value}
                                  </div> 
                                  <div className="lg:min-w-[40vw] lg:min-h-[40vh] lg:max-w-[60vw] lg:max-h-[60vh] min-w-[40vw] flex flex-col justify-center items-center" style = {{position: 'relative', width: '100%', height: '100%'}}>
                                      <Image 
                                          src={useCase.image} 
                                          className = "rounded-md" 
                                          style={{objectFit: "contain", objectPosition: "center"}}
                                          fill={true}
                                          alt="Screenshot Separated Powers"
                                          >
                                      </Image>
                                   </div>
                                  <div className = "h-full flex flex-col justify-start py-4 max-w-xl h-fit text-md sm:text-lg text-slate-500 text-center text-pretty">
                                      {useCase.detail}
                                  </div> 
                              </div> 
                          ))
                      }
                      <div className="min-w-[20vw] h-full flex flex-col snap-center snap-always gap-2" />
                      
                  </section>
              </section> 
  )

}