"use client"

import { ProposalViewProps } from '@/context/types';
import { useActions } from '@/hooks/useActions';
import React, { useState } from 'react';
import { contractAddresses } from '@/context/contractAddresses';
import { encodeAbiParameters, parseAbiParameters, stringToBytes, stringToHex } from 'viem'

const ProposalView:  React.FC<ProposalViewProps> = ({proposal, isDisabled}: ProposalViewProps) => {
    const [addressLaw, setAddressLaw] = useState<`0x${string}`>('0x0');
    const [descriptionHash, setDescriptionHash] = useState<`0x${string}`>('0x0');
    const [toInclude, setToInclude] = useState<boolean>(true);
    const {status, error, law, execute} = useActions(); 
    
    const handleAction = async () => {
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("address, bool"), [addressLaw, toInclude]);
    
        execute(
            contractAddresses.find((address) => address.contract === "Admin_setLaw")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionHash as `0x${string}`
        )
    };

    return (
        <>
        <div className="bg-gradient-to-r from-red-300 to-red-600 p-4 px-6 rounded-lg shadow-lg border-2 border-red-600  opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}>
            <h4 className='text-white text-lg font-semibold text-center'>
                Implement Law
            </h4>
            <p className='text-white text-center mb-4'>
                This decision will only pass if Seniors have accepted Whale's proposal. 
            </p>
                <input
                    type="text"
                    value={addressLaw}
                    onChange={(e) => setAddressLaw(e.target.value as `0x${string}`)}
                    placeholder="Enter the address of the law."
                    maxLength={100}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <input
                    type="text"
                    value={descriptionHash}
                    onChange={(e) => setDescriptionHash(e.target.value as `0x${string}`)}
                    placeholder="Enter the description hash of the proposal." 
                    maxLength={35}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <div className="flex flex-row justify-center mb-4">
                    <button
                        onClick={() => setToInclude(!toInclude)}
                        className="w-fit bg-white text-slate-700 px-4 py-2 rounded-lg hover:bg-blue-200 transition duration-100"
                    >
                        {
                            toInclude ? 'This is a new law that needs to be activated' : 'This is an existing law that needs to be deactivated'
                        }
                    </button>
                </div>
                <div className="flex flex-row justify-start mt-6">
                    <button
                        onClick={handleAction}
                        className="w-fit bg-white text-red-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100"
                        disabled = {isDisabled} 
                    >
                        Accept and implement proposed decision
                    </button>
                </div>
    
        </div>
    </>
    );
};

export default AdminActions;
