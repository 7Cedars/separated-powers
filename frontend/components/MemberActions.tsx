"use client"

import React, { useState } from 'react';
import { useActions } from '@/hooks/useActions';
import { userActionsProps } from '@/context/types';
import { lawContracts } from '@/context/lawContracts';
import { encodeAbiParameters, keccak256, parseAbiParameters, stringToBytes, stringToHex, toHex } from 'viem'
import { TwoSeventyRingWithBg } from "react-svg-spinners";

const MemberActions: React.FC<userActionsProps> = ({wallet, isDisabled}: userActionsProps ) => {
    const [newValue, setNewValue] = useState<string>('');
    const [whaleAddress, setWhaleAddress] = useState<`0x${string}`>();
    const [descriptionA, setDescriptionA] = useState<string>('');
    const [descriptionB, setDescriptionB] = useState<string>('');
    const {status, error, law, propose, execute} = useActions(); 

    console.log("@memberActions:", {status, error, law})

    const handleProposeCoreValue = async () => {
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("bytes"), [toHex(newValue)]);
        propose(
            lawContracts.find((law: any) => law.contract === "Member_proposeCoreValue")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionA
        )
    };

    const handleAssignWhale = async () => {
        const descriptionHash = keccak256(toHex(descriptionB));
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("address"), [whaleAddress as `0x${string}`]);
        execute(
            lawContracts.find((law: any) => law.contract === "Member_assignWhale")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionHash as `0x${string}`
        )
    };
    
    return (
        <>
            <div className="bg-gradient-to-r from-blue-300 to-blue-600 p-4 px-6 rounded-lg shadow-lg border-2 border-blue-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}>
                <h4 className='text-white text-lg font-semibold text-center mb-4'>
                    Propose New Core Value for the AgDao
                </h4>
                <p className='text-white text-center mb-4'>
                    This decision will only pass if Seniors have accepted Whale's proposal. 
                </p>
                    <input
                        type="text"
                        value={newValue}
                        onChange={(e) => setNewValue(e.target.value)}
                        placeholder="Enter new value (max 30 characters)"
                        maxLength={30}
                        className="border border-white rounded-lg p-2 mb-4 w-full"
                    />
                    <input
                        type="text"
                        value={descriptionA}
                        onChange={(e) => setDescriptionA(e.target.value)}
                        placeholder="Enter supporting message"
                        maxLength={100}
                        className="border border-white rounded-lg p-2 mb-4 w-full"
                    />
                    <div className="flex flex-row justify-start">
                        <button
                            onClick={handleProposeCoreValue}
                            className="flex flex-row justify-center items-center bg-white text-blue-600 min-w-60 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 transition duration-100"
                            disabled = {isDisabled}
                        >
                            {law === lawContracts.find((law: any) => law.contract === "Member_proposeCoreValue")?.address as `0x${string}` ?  
                                status === "loading" ? <TwoSeventyRingWithBg className='text-blue-600'/> :
                                status === "success" ? 'success' : 
                                status === "error" ? 'Error' :
                                "Idle"
                            : "Propose Value" 
                            }
                        </button>
                    </div>
        
            </div>

            <div className="bg-gradient-to-r from-blue-300 to-blue-600 p-4 px-6 rounded-lg shadow-lg border-2 border-blue-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}>
                <h4 className='text-white text-lg font-semibold text-center mb-4'>
                    Assess an Account and Assign a whale Role 
                </h4>
                <p className='text-white text-center mb-4'>
                    If the account has more than one million Ag coins, it will be assigned a whale role. If it already is a whale and has fewer than one million Ag coins, it will be removed from the whale role.
                </p>
                    <input
                        type="text"
                        value={whaleAddress}
                        onChange={(e) => setWhaleAddress(e.target.value as `0x${string}`)}
                        placeholder="Enter account address"
                        className="border border-white rounded-lg p-2 mb-4 w-full"
                    />
                    <input
                        type="text"
                        value={descriptionB}
                        onChange={(e) => setDescriptionB(e.target.value)}
                        placeholder="Enter supporting message"
                        maxLength={100}
                        className="border border-white rounded-lg p-2 mb-4 w-full"
                    />
                    <div className="flex flex-row justify-start">
                        <button
                            onClick={handleAssignWhale}
                            className="flex flex-row justify-center items-center bg-white text-blue-600 min-w-60 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                            disabled = {isDisabled}
                        >
                            {law === lawContracts.find((law: any) => law.contract === "Member_assignWhale")?.address as `0x${string}` ? 
                                status === "loading" ? <TwoSeventyRingWithBg className='text-blue-600'/> :
                                status === "success" ? 'success' : 
                                status === "error" ? 'Error' :
                                "idle"
                            : "Assess account"
                            }
                        </button>
                    </div>
        
            </div>

        </>
    );
};

export default MemberActions;
