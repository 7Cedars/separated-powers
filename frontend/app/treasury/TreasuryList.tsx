"use client";

import React, { useCallback, useEffect, useState } from "react";
import { setLaw, useOrgStore } from "../../context/store";
import { ArrowPathIcon, ArrowUpRightIcon, GiftIcon } from "@heroicons/react/24/outline";
import { useRouter } from "next/navigation";
import { supportedChains } from "@/context/chains";
import { useChainId, useReadContracts } from "wagmi";
import { erc1155Abi, erc20Abi } from "@/context/abi";
import Link from "next/link";

export function TreasuryList() {
  const organisation = useOrgStore();
  const router = useRouter();
  const chainId = useChainId();
  const supportedChain = supportedChains.find(chain => chain.id == chainId)
  let balances: number[] = []; 

  const mockErc20Contract  = {
    address: supportedChain?.mockErc20?.address,
    abi: erc20Abi,
  } as const
  const mockErc1155Contract = {
    address: supportedChain?.mockErc1155?.address,
    abi: erc1155Abi,
  } as const
  
  const {isSuccess, status, data, refetch} = useReadContracts({
    contracts: [
      {
        ...mockErc20Contract,
        functionName: 'balanceOf', 
        args: [organisation.contractAddress],
      },
      {
        ...mockErc1155Contract,
        functionName: 'balanceOf', 
        args: [organisation.contractAddress, 0],
      }
    ]
  })
  if (isSuccess) {
    balances = data.map((item: any) => Number(item.result))
  }

  console.log("@TreasuryList: ", {data})

  return (
    <div className="w-full flex flex-col justify-start items-center">
      {/* table banner  */}
      <div className="w-full flex flex-row gap-3 justify-between items-center bg-slate-50 border slate-300 mt-2 py-4 px-6 rounded-t-md">
        <div className="text-slate-900 text-center font-bold text-lg">
          Treasury
        </div>
        <button 
          className="w-fit h-fit p-2 border border-opacity-0 hover:border-opacity-100 rounded-md border-slate-500"
          onClick = {() => refetch()}
          >
            <ArrowPathIcon
              className="w-4 h-4 text-slate-800"
              />
        </button>
      </div>
      {/* table laws  */}
      <div className="w-full h-full border border-slate-200 border-t-0 rounded-b-md overflow-x-scroll overflow-y-hidden">
      <table className="w-full table-auto border border-t-0">
      <thead className="w-full">
            <tr className="w-96 bg-slate-50 text-xs font-light text-left text-slate-500 rounded-md border-b border-slate-200">
                <th className="ps-6 py-2 font-light rounded-tl-md"> Token </th>
                <th className="font-light"> Type </th>
                <th className="font-light text-center"> Holdings </th>
                <th className="font-light text-right ps-2 pe-8"> Address </th>
            </tr>
        </thead>
        <tbody className="w-full h-full text-sm text-right text-slate-500 bg-slate-50 divide-y divide-slate-200 border-t-0 border-slate-200 rounded-b-md">
            <tr className={`text-sm text-left text-slate-500 h-16 overflow-x-scroll`}>
              <td className="text-left rounded-bl-md ps-6 px-2 min-w-48"> Mock Erc20 Vote Coin </td>
              <td className="text-left text-slate-500 min-w-24">ERC 20</td>
              <td className="text-center pe-8 text-slate-500">{balances.length > 0 ?  balances[0] : 0}</td>
              <td className="pe-4 text-left pe-8 text-slate-500">
                  <Link
                    href={`${supportedChain?.blockExplorerUrl}/address/${supportedChain?.mockErc20?.address}#code`}
                    className="w-full p-2"
                  >
                  <div className="flex flex-row gap-1 items-center justify-end px-2">
                    <div className="text-left text-sm text-slate-500 w-fit">
                    { supportedChain?.mockErc20?.address }
                    </div> 
                      <ArrowUpRightIcon
                        className="w-4 h-4 text-slate-500"
                        />
                    </div>
                  </Link>
                </td>
            </tr> 
            <tr className={`text-sm text-left text-slate-500 h-16 p-2 overflow-x-scroll`}>
              <td className="text-left rounded-bl-md ps-6 px-2 py-4 min-w-48"> Mock Erc1155 Coin </td>
              <td className="text-left text-slate-500 min-w-24">ERC 1155</td>
              <td className="text-center pe-8 text-slate-500">{balances.length > 1 ?  balances[1] : 0}</td>
              <td className="pe-4 text-left pe-8 text-slate-500">
                  <a
                    href={`${supportedChain?.blockExplorerUrl}/address/${supportedChain?.mockErc1155?.address}#code`} target="_blank" rel="noopener noreferrer"
                    className="w-full p-2"
                  >
                  <div className="flex flex-row gap-1 items-center justify-end px-2">
                    <div className="text-left text-sm text-slate-500 w-fit">
                    { supportedChain?.mockErc1155?.address }
                    </div> 
                      <ArrowUpRightIcon
                        className="w-4 h-4 text-slate-500"
                        />
                    </div>
                  </a>
              </td>
            </tr> 
        </tbody>
      </table>
      </div>
    </div>
  );
}
