"use client";

import { HeartIcon } from '@heroicons/react/24/outline';
import Image from 'next/image'

export function Footer() {

  return (
    <section className="w-full z-20 min-h-48 h-fit bg-slate-50 flex md:flex-row flex-col justify-between items-start text-slate-800 text-sm px-16 snap-end pt-12 pb-6 border-t border-slate-300 gap-16 snap-end">
      <div className="grid grid-cols-3 gap-28">
          <div className="flex flex-col gap-3 justify-start items-start">
          <div className="font-bold"> 
              DApp
          </div>
          <div className="text-slate-500"> 
              Docs
          </div>
          <div className="text-slate-500"> 
              Github repo 
          </div>
          </div>
          <div className="flex flex-col gap-3 justify-start items-start">
          <div className="font-bold"> 
              Protocol
          </div>
          <div className="text-slate-500"> 
              About
          </div>
          <div className="text-slate-500"> 
              Docs
          </div>
          <div className="text-slate-500"> 
              Github repo 
          </div>
          </div>
      </div>

      <div className="w-full flex flex-row gap-3 justify-end items-end snap-end">
          <div className="flex flex-col gap-3 justify-start md:items-end items-center pb-12">
          <Image 
          src='/logo.png' 
          width={48}
          height={48}
          alt="Logo Separated Powers"
          >
          </Image>
          <div className="text-md font-bold flex flex-row gap-1">
              <p>Made with</p> 
              <HeartIcon className="w-4 h-4 text-red-700" />
              <p>by 7Cedars</p>
          </div>
          <div className="flex flex-row gap-2">
              <div>
              discord
              </div>
              <div>
              mirror.xyz
              </div>
              <div>
              telegram
              </div>
              <div>
              twitter
              </div>
          </div>
          </div>
      </div>
  </section>

  )
}