"use client"

import { ProposalViewProps, Vote } from '@/context/types';
import { useActions } from '@/hooks/useActions';
import React, { useState } from 'react';
import { lawContracts } from '@/context/lawContracts';
import { encodeAbiParameters, keccak256, parseAbiParameters, stringToBytes, stringToHex, toHex } from 'viem'
import { useReadContract } from "wagmi";
import { agDaoAbi } from '@/context/abi';
import { useWallets } from '@privy-io/react-auth';

const proposalColour = [
    "from-red-300 to-red-600 border-red-600",
    "from-amber-300 to-yellow-600 border-amber-600",
    "from-emerald-300 to-emerald-600 border-emerald-600",
    "from-blue-300 to-blue-600 border-blue-600",
    "from-purple-300 to-purple-600 border-purple-600"
  ]

const textColour = [
    "text-red-600",
    "text-amber-600",
    "text-emerald-600",
    "text-blue-600",
    "text-purple-600"
]

const ProposalView:  React.FC<ProposalViewProps> = ({proposal, isDisabled}: ProposalViewProps) => {
    const {status, error, law, execute, castVote} = useActions(); 
    const lawTitle: `0x${string}` = lawContracts.find((law: any) => law.address === proposal.targetLaw)?.description as `0x${string}`
    const roleId: number = Number(lawContracts.find((law: any) => law.address === proposal.targetLaw)?.accessRoleId) 
    const {wallets } = useWallets();
    const wallet = wallets[0];
    const agDaoContract = lawContracts.find((law: any) => law.contract === "AgDao")
    
    const {data: hasVoted, error: errorHasVoted, status: statusHasVoted, refetch}  = useReadContract({
        abi: agDaoAbi,
        address: agDaoContract?.address as `0x${string}`,
        functionName: 'hasVoted',
        args: [BigInt(proposal.proposalId), wallet && wallet.address ? wallet.address as `0x${string}` : `0x0`]
      })

    console.log({ hasVoted, errorHasVoted, statusHasVoted})

    const handleCastVote = async (vote: Vote) => {    
        castVote(
            BigInt(proposal.proposalId),
            vote
        ) 
    };

    const handleExecute = async () => {
        const descriptionHash = keccak256(toHex(proposal.description));
    
        execute(
            lawContracts.find((law: any) => law.contract === "Admin_setLaw")?.address as `0x${string}`,
            proposal.executeCalldata as `0x${string}`,
            descriptionHash as `0x${string}`
        )
    };

    return (
        <>
        <div 
            className={`p-4 px-6 rounded-lg shadow-lg border-2 bg-gradient-to-r ${proposalColour[roleId]} opacity-30 aria-selected:opacity-100`} 
            aria-selected={!isDisabled}
            >
                <section className='grid grid-cols-2'>
                    <div className='flex flex-col items-start gap-1'>
                        <h4 className='text-white text-lg font-semibold text-left'>
                            Proposal: {lawTitle}
                        </h4>
                        <p className='text-white text-left'>
                            Proposal Id: {`${String(proposal.proposalId).slice(0, 6)}...${String(proposal.proposalId).slice(-6)}`}
                        </p>
                        <p className='text-white text-left'>
                            Proposer: {`${String(proposal.initiator).slice(0, 6)}...${String(proposal.initiator).slice(-6)}`}
                        </p>
                    </div>
                    <div className='flex flex-col items-end gap-1'>
                        <h4 className='text-white text-lg font-semibold text-right'>
                            {
                            proposal.state === 0 ? "Active" 
                            : 
                            proposal.state === 1 ? "Cancelled" 
                            : 
                            proposal.state === 2 ? "Defeated" 
                            : 
                            proposal.state === 3 ? "Succeeded" 
                            : 
                            proposal.state === 4 ? "Completed" 
                            :
                            "Expired"
                            } 
                        </h4>
                        <p className='text-white text-right'>
                            Start vote: L1 block {Number(proposal.voteStart)}
                        </p>
                        <p className='text-white text-right'>
                            end vote: L1 block {Number(proposal.voteEnd)}
                        </p>
                    </div>
                </section>

                <section className='flex flex-col text-white text-center m-6'>
                    <p className='text-lg font-semibold'>
                    Supporting Statement: {proposal.description}
                    </p>
                    <p className='text-sm'>
                        calldata: {String(proposal.executeCalldata)}
                    </p>
               
                </section>

                <section className='flex flex-row justify-between overflow-y-auto'>
                    { hasVoted ? 
                    <div className='flex flex-row max-w-96 text-white justify-center font-semibold'>
                        You already voted
                    </div>
                    :
                    <div className='flex flex-row max-w-96 gap-4'>
                        <button
                            onClick={() => handleCastVote(0n)}
                            className={`grow bg-white ${textColour[roleId]} font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100`}
                            disabled = {isDisabled} 
                        >
                            Against
                        </button>
                        <button
                            onClick={() => handleCastVote(1n)}
                            className={`grow bg-white ${textColour[roleId]} font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100`}
                            disabled = {isDisabled} 
                        >
                            For
                        </button>
                        <button
                            onClick={() => handleCastVote(2n)}
                            className={`grow bg-white ${textColour[roleId]} font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white transition duration-100`}
                            disabled = {isDisabled} 
                        >
                            Abstain
                        </button>
                    </div>
                    }

                    <button
                            onClick={() => handleExecute()}
                            className={`max-w-36 bg-white ${textColour[roleId]} font-semibold px-4 py-2 rounded-lg hover:bg-blue-200 disabled:bg-white disabled:opacity-50 transition duration-100 mx-4`}
                            disabled = {isDisabled || proposal.state !== 3} 
                        >
                            Execute
                    </button>
                </section>
        </div>
    </>
    );
};

export default ProposalView;
