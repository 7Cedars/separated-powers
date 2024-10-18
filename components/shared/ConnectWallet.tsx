import { useState, useEffect } from 'react';
import Web3 from 'web3';

interface ConnectWalletProps {
    setAddress: (address: string) => void;
}

const ConnectWallet: React.FC<ConnectWalletProps> = ({ setAddress }) => {
    const [connected, setConnected] = useState<boolean>(false);

    useEffect(() => {
        const connectWallet = async () => {
            if ((window as any).ethereum) {
                const web3 = new Web3((window as any)?.ethereum);
                try {
                    const accounts = await (window as any)?.ethereum.request({ method: 'eth_requestAccounts' });
                    setAddress(accounts[0]);
                    setConnected(true);
                } catch (error) {
                    console.error('Failed to connect wallet:', error);
                }
            }
        };
        connectWallet();
    }, [setAddress]);

    return (
        <div>
            {connected ? <p>Wallet Connected</p> : <p>Please connect your wallet</p>}
        </div>
    );
};

export default ConnectWallet;
