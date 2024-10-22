"use client"

import React, { useState } from 'react';
import { userActionsProps } from '@/context/types';
import { useActions } from '@/hooks/useActions';
import { lawContracts } from '@/context/lawContracts';
import { encodeAbiParameters, parseAbiParameters, stringToBytes, stringToHex } from 'viem'

const SeniorActions: React.FC<userActionsProps> = ({wallet, isDisabled}: userActionsProps ) => {
    const [addressLaw, setAddressLaw] = useState<`0x${string}`>();
    const [seniorAssign, setSeniorAssign] = useState<`0x${string}`>();
    const [seniorRevoke, setSeniorRevoke] = useState<`0x${string}`>();
    const [revokeId, setRevokeId] = useState<string>();
    const [descriptionA, setDescriptionA] = useState<string>();
    const [descriptionB, setDescriptionB] = useState<string>();
    const [descriptionC, setDescriptionC] = useState<string>();
    const [descriptionD, setDescriptionD] = useState<string>();
    const [toInclude, setToInclude] = useState<boolean>(true);
    const {status, error, law, propose, execute} = useActions(); 

    const handleAcceptProposeLaw = async () => {
        const lawCalldata: string =  encodeAbiParameters(parseAbiParameters("address, bool"), [addressLaw ? addressLaw : '0x0', toInclude]);
        propose(
            lawContracts.find((law: any) => law.contract === "Senior_acceptProposeLaw")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionA ? descriptionA : ''
        )
    };

    const handleAssignRole = async () => {
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("address"), [seniorAssign ? seniorAssign : '0x0']);
        propose(
            lawContracts.find((law: any) => law.contract === "Senior_assignRole")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionB ? descriptionB : ''
        )
    };

    const handleReinstateMember = async () => {
        // using revokeId, need to retrieve this data from the initial proposal! 
        const revokeDescriptionHash = '0x0'
        const revokeCalldata = '0x0'
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("bytes32, bytes"), [revokeDescriptionHash, revokeCalldata]);
        propose(
            lawContracts.find((law: any) => law.contract === "Senior_reinstateMember")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionC ? descriptionC : ''
        )
    };

    const handleRevokeRole = async () => {
        const lawCalldata: string = encodeAbiParameters(parseAbiParameters("address"), [seniorRevoke ? seniorRevoke : '0x0']);
        propose(
            lawContracts.find((law: any) => law.contract === "Senior_revokeRole")?.address as `0x${string}`,
            lawCalldata as `0x${string}`,
            descriptionD ? descriptionD : ''
        )
    };

    return (
        <>
        {/* AcceptProposeLaw */}
        <div 
            className="bg-gradient-to-r from-amber-300 to-amber-600 p-4 px-6 rounded-lg shadow-lg border-2 border-amber-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}
            >
            <h4 className='text-white text-lg font-semibold text-center'>
                Accept proposed law
            </h4>
            <p className='text-white text-center mb-4'>
                Following an accepted proposal by whales, Seniors can accept the proposed (in- or) exclusion of a law. 
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
                    value={descriptionA}
                    onChange={(e) => setDescriptionA(e.target.value)}
                    placeholder="Enter the original description of the proposal to add a new law." 
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
                        onClick={handleAcceptProposeLaw}
                        className="w-fit bg-white text-amber-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200  disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled} 
                        
                    >
                        {`Propose to ${toInclude ? 'activate' : 'deactivate'} law`}
                    </button>
                </div>
        </div>

        {/* AssignRole */}
        <div 
            className="bg-gradient-to-r from-amber-300 to-amber-600 p-4 px-6 rounded-lg shadow-lg border-2 border-amber-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}
        >
            <h4 className='text-white text-lg font-semibold text-center'>
                Assign a senior role to an account
            </h4>
            <p className='text-white text-center mb-4'>
                Seniors can assign a senior role to an account by majority vote. 
            </p>
                <input
                    type="text"
                    value={seniorAssign}
                    onChange={(e) => setSeniorAssign (e.target.value as `0x${string}`)}
                    placeholder="Enter the address of the account to be assign a senior role."
                    maxLength={100}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <input
                    type="text"
                    value={descriptionB}
                    onChange={(e) => setDescriptionB(e.target.value)}
                    placeholder="Enter supporting statement." 
                    maxLength={35}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <div className="flex flex-row justify-start mt-6">
                    <button
                        onClick={handleAssignRole}
                        className="w-fit bg-white text-amber-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled}
                    >
                        Propose to assign senior role 
                    </button>
                </div>
        </div>
        
        {/* ReinstateMember */}
        <div 
            className="bg-gradient-to-r from-amber-300 to-amber-600 p-4 px-6 rounded-lg shadow-lg border-2 border-amber-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}
        >
            <h4 className='text-white text-lg font-semibold text-center'>
                Reinstate member
            </h4>
            <p className='text-white text-center mb-4'>
                Seniors can reinstate an account to a member role, following a challenge by this member. 
            </p>
                <input
                    type="text"
                    value={revokeId}
                    onChange={(e) => setRevokeId(e.target.value)}
                    placeholder="Enter proposal ID through which whales revoked he member."
                    maxLength={100}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <input
                    type="text"
                    value={descriptionC}
                    onChange={(e) => setDescriptionC(e.target.value)}
                    placeholder="Enter the exact supporting statement from the member challenge." 
                    maxLength={35}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <div className="flex flex-row justify-start mt-6">
                    <button
                        onClick={handleReinstateMember}
                        className="w-fit bg-white text-amber-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled} 
                    >
                        Propose to reinstate member role 
                    </button>
                </div>
        </div>


        {/* RevokeRole */}
        <div 
            className="bg-gradient-to-r from-amber-300 to-amber-600 p-4 px-6 rounded-lg shadow-lg border-2 border-amber-600 opacity-30 aria-selected:opacity-100"
            aria-selected={!isDisabled}>
            
            <h4 className='text-white text-lg font-semibold text-center'>
                Revoke senior role
            </h4>
            <p className='text-white text-center mb-4'>
                By large majority vote, seniors can revoke an account their senior role. 
            </p>
                <input
                    type="text"
                    value={seniorRevoke}
                    onChange={(e) => setSeniorRevoke(e.target.value as `0x${string}`)}
                    placeholder="Enter the address of the account to be revoked a senior role."
                    maxLength={100}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <input
                    type="text"
                    value={descriptionD}
                    onChange={(e) => setDescriptionD(e.target.value)}
                    placeholder="Enter supporting statement." 
                    maxLength={35}
                    className="border border-white rounded-lg p-2 mb-4 w-full"
                />
                <div className="flex flex-row justify-start mt-6">
                    <button
                        onClick={handleRevokeRole}
                        className="w-fit bg-white text-amber-600 font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:hover:bg-white transition duration-100"
                        disabled = {isDisabled} 
                    >
                        Propose to revoke senior role 
                    </button>
                </div>
        </div>
        </>
    );
};

export default SeniorActions;
