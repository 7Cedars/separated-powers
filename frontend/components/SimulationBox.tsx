"use client";

import React, { useEffect, useState } from "react";
import { useReadContract } from 'wagmi'
import { lawAbi } from "@/context/abi";
import { useLaw } from "@/hooks/useLaw";
import { parseParams } from "@/utils/parsers";

export const SimulationBox = () => {
  const {status, error, law, simulation, checks, resetStatus, execute, fetchSimulation, fetchChecks} = useLaw();
  const [jsxSimulation, setJsxSimulation] = useState<React.JSX.Element[][]> ([]); 
  const { data, isLoading, isError } = useReadContract({
        abi: lawAbi,
        address: law.law,
        functionName: 'getStateVars'
      })
  const dataTypes = parseParams(data as string[])
    
  useEffect(() => {
    if (simulation && simulation[0].length > 0) {
      console.log("@useEffect, jsxSimulate 0 triggered")
      let jsxElements: React.JSX.Element[] = []; 
      for (let i = 0; i < simulation[0].length; i++) {
        console.log("@useEffect building..", i)
        jsxElements = [ 
          ... jsxElements, 
          <tr
            key={i}
            className={`text-sm text-slate-800 h-16 p-2 overflow-x-scroll`}
          >
            {/*  */}
            <td className="ps-6 text-left text-slate-500"> {simulation[0][i]} </td> 
            <td className="text-center text-slate-500"> {String(simulation[1][i])} </td>
            <td className="pe-4 text-left text-slate-500"> {simulation[2][i]} </td>
          </tr>
        ];
      }
      setJsxSimulation([jsxElements])
    }  
  
    if (simulation && simulation[1].length > 0) {
      console.log("@useEffect, jsxSimulate 1 triggered")
      let jsxElements: React.JSX.Element[] = []; 
      for (let i = 0; i < simulation[1].length; i++) {
        console.log("@useEffect building..", i)
        jsxElements = [ 
          ... jsxElements, 
          <tr
            key={i}
            className={`text-sm text-slate-800 h-16 p-2 overflow-x-scroll`}
          >
            {/*  */}
            <td className="ps-6 text-left text-slate-500"> {dataTypes[1][i]} </td> 
            <td className="text-center text-slate-500"> {String(simulation[0][i])} </td>
            </tr>
        ];
      }
      const sim = [...jsxSimulation, jsxElements]
      setJsxSimulation(sim)
    }  
  }, [simulation])

  // try to do without this. Don't know if it is actually necessary.. 
  useEffect(() => {
    setJsxSimulation([])
  }, [])

  return (
    <>
    <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 pt-2 px-6">
        <div className="w-full text-xs text-center text-slate-500 border rounded-t-md border-b-0 border-slate-300 p-2">
          State variables to be saved in law 
        </div>
        <div className="w-full h-fit border border-slate-300 overflow-scroll rounded-b-md">
          <table className="table-auto w-full ">
            <thead className="w-full">
              <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                  <th className="ps-6 py-2 font-light"> Data type </th>
                  <th className="font-light"> Value </th>
              </tr>
            </thead>
              <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                { jsxSimulation[1].map(row => {return (row)} ) } 
              </tbody>
            </table>
          </div>
      </div>

      <div className="w-full flex flex-col gap-0 justify-start items-center bg-slate-50 pt-2 px-6">
        <div className="w-full text-xs text-center text-slate-500 border rounded-t-md border-b-0 border-slate-300 p-2">
          Data to be send to protocol 
        </div>
        <div className="w-full h-fit border border-slate-300 overflow-scroll rounded-b-md">
          <table className="table-auto w-full ">
            <thead className="w-full">
              <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                  <th className="ps-6 py-2 font-light"> Target contracts </th>
                  <th className="font-light"> Value </th>
                  <th className="font-light"> Calldata </th>
              </tr>
            </thead>
              <tbody className="w-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200">
                { jsxSimulation[0].map(row => {return (row)} ) } 
              </tbody>
            </table>
          </div>
          
      </div>
    </>
  )
}