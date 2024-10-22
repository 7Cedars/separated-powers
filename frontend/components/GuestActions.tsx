"use client"

import React, { useState } from 'react';
import { userActionsProps } from '@/context/types';
import { useActions } from '@/hooks/useActions';
import { lawContracts } from '@/context/lawContracts';
import { encodeAbiParameters, keccak256, parseAbiParameters, stringToBytes, stringToHex, toHex } from 'viem'

const GuestActions: React.FC<userActionsProps> = ({wallet, isDisabled}: userActionsProps ) => {
    const [addressSenior, setAddressSenior] = useState<`0x${string}`>();
    const [revokeId, setRevokeId] = useState<string>('');
    const [description, setDescription] = useState<string>('');
    const {status, error, law, propose, execute} = useActions(); 

    console.log({status, error, law})

    const handleAssignRole = async () => {
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("address"), [wallet.address as `0x${string}`]);
        const descriptionHash = keccak256(toHex("I request membership to agDAO."));
        execute(
            lawContracts.find((law: any) => law.contract === "Public_assignRole")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionHash as `0x${string}`
        )
    };

    const handleChallengeRevoke = async () => {
        const descriptionHash = keccak256(toHex(description));
        // using revokeId, need to retrieve this data from the initial proposal! 
        const revokeDescriptionHash = '0x0'
        const revokeCalldata = '0x0'
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("bytes32, bytes"), [revokeDescriptionHash, revokeCalldata]);
        propose(
            lawContracts.find((law: any) => law.contract === "Public_challengeRevoke")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            description
        )
    };

    return (
        <>
        {/* AssignRole */}
        <div 
            className="bg-gradient-to-r from-purple-300 to-purple-600 p-4 px-6 rounded-lg shadow-lg border-2 border-purple-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}
        >
            <h4 className='text-white text-lg font-semibold text-center'>
                Claim Member Role
            </h4>
            <p className='text-white text-center mb-4'>
                Anyone can claim a member role. 
            </p>
                <div className="flex flex-row justify-left mt-6">
                    <button
                        onClick={handleAssignRole}
                        className="w-fit bg-white text-purple-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled}
                    >
                        Claim member role
                    </button>
                </div>
        </div>
        
        {/* ChallengeRevoke */}
        <div 
            className="bg-gradient-to-r from-purple-300 to-purple-600 p-4 px-6 rounded-lg shadow-lg border-2 border-purple-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}
        >
            <h4 className='text-white text-lg font-semibold text-center'>
                Challenge Revoke Member Role
            </h4>
            <p className='text-white text-center mb-4'>
                If your member role has been revoked, you can create a challenge which allows seniors to vote on your reinstatement. 
            </p>
                <input
                    type="text"
                    value={addressSenior}
                    onChange={(e) => setRevokeId(e.target.value)}
                    placeholder="Enter proposal ID through which whales revoked your member role."
                    maxLength={100}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <input
                    type="text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Enter supporting statement." 
                    maxLength={35}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <div className="flex flex-row justify-start mt-6">
                    <button
                        onClick={handleChallengeRevoke}
                        className="w-fit bg-white text-purple-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled} 
                    >
                        Challenge revoke (NB: this creates a proposal you need to accept) 
                    </button>
                </div>
        </div>
        </>
    );
};

export default GuestActions;
