"use client"

import React, { useEffect, useState } from 'react';
import { joinAsMember } from '../../utils/blockchainUtils';

const JoinAsMember = () => {
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState('');

    const handleJoin = async () => {
        setLoading(true);
        setMessage('');

        try {
            const txHash = await joinAsMember();
            setMessage(`Successfully joined as a member! Transaction Hash: ${txHash}`);
        } catch (error) {
            setMessage('Failed to join as a member. Please try again.');
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{ padding: '20px', textAlign: 'center' }}>
            <h2>Join as a Member</h2>
            <button onClick={handleJoin} disabled={loading}>
                {loading ? 'Joining...' : 'Join as Member'}
            </button>
            {message && <p>{message}</p>}
        </div>
    );
};

export default JoinAsMember;
