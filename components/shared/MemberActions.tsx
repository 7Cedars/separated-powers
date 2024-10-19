import React, { useState } from 'react';
import { proposeNewValue } from '../../utils/blockchainUtils';

const MemberActions: React.FC = () => {
    const [newValue, setNewValue] = useState<string>('');
    const [message, setMessage] = useState<string>('');

    const handleProposeNewValue = async () => {
        try {
            const result = await proposeNewValue(newValue);
            setMessage(`New value proposed successfully: ${result}`);
            setNewValue('');
        } catch (error) {
            console.error('Error proposing new value:', error);
            if (message) {
                const parsedErrorMessage = message?.reason?.slice("execution reverted: " + .length).slice(0, -1)
                setMessage(parsedErrorMessage);
            }
        }
    };

    return (
        <div>
            <h3>Member Actions</h3>
            <div>
                <h4>Propose New Value</h4>
                <input
                    type="text"
                    value={newValue}
                    onChange={(e) => setNewValue(e.target.value)}
                    placeholder="Enter new value"
                />
                <button onClick={handleProposeNewValue}>Propose Value</button>
            </div>
            {message && <p>{message}</p>}
        </div>
    );
};

export default MemberActions;
