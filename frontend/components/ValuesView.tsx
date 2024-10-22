"use client"

import React, { useState } from 'react';
import { lawContracts } from '@/context/lawContracts';
import { encodeAbiParameters, keccak256, parseAbiParameters, stringToBytes, stringToHex, toHex } from 'viem'
import { useReadContract } from 'wagmi'
import { agDaoAbi } from '@/context/abi';

const ValuesView:  React.FC = () => {
  const agDaoContract = lawContracts.find((law: any) => law.contract === "AgDao")

  const {data, error, status}  = useReadContract({
    abi: agDaoAbi,
    address: agDaoContract?.address as `0x${string}`,
    functionName: 'getCoreValues'
  })

  const coreValues = data as string[]

  const {data: coreRequirementsData, error: coreRequirementsError, status: coreRequirementsStatus}  = useReadContract({
    abi: agDaoAbi,
    address: agDaoContract?.address as `0x${string}`,
    functionName: 'coreRequirements',
    args: [0n]
  })

  console.log("@ValuesView", {data, error, status})
  console.log("@ValuesView", {coreRequirementsData, coreRequirementsError, coreRequirementsStatus})

  return (
      <>
        <div className='text-center text-gray-800 text-xl font-semibold'>
          These are the current values of AgDao
        </div>
        <div className='text-center text-gray-800 mb-6'>
          Only accounts that align with these values will receive our precious agCoins. 
        </div>

        {
          coreValues.length > 0 ?
            coreValues.map((value: string, index: number) => (
              <div key={index} className='text-center text-gray-800'>
                <span className='text-lg font-semibold m-3'>{value}</span>
              </div>
            ))
            :
            <div className='text-center text-gray-800'>
              <span className='italic m-3'>No core values found.</span>
            </div>
        }
      </>
  );
};

export default ValuesView;
