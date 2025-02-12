"use client"

import { useConnectWallet, useLogout, usePrivy } from "@privy-io/react-auth";
import { useWallets } from "@privy-io/react-auth";
import { 
  PowerIcon,
} from '@heroicons/react/24/outline';
import BlockiesSvg from 'blockies-react-svg'

export const ConnectButton = () => {
  const {wallets } = useWallets();
  const {ready, authenticated, login, logout} = usePrivy();

  return (
    <> 
    {
      wallets[0] && authenticated ?  
      <button
        className={`w-fit h-full flex flex-row items-center justify-center text-center rounded-md bg-slate-100 border-opacity-0 md:border-opacity-100 border border-slate-600`}  
        onClick={() => logout() }
      >
        <div className={`flex flex-row items-center text-center text-slate-600 md:gap-2 gap-0 w-full h-full w-full md:py-1 px-1 py-0`}>
        {/* here should also be an icon. Address should disappear when screen = small. */}
          <BlockiesSvg 
            address={wallets[0].address}
            className='md:h-6 md:w-6 h-9 w-fit rounded-md border border-slate-800'
            />
          <div className="md:w-fit w-0 opacity-0 md:opacity-100">
            {wallets[0].address.slice(0, 6)}...{wallets[0].address.slice(-6)}
          </div>
        </div>
      </button>
      :
      <button 
        className={`w-fit h-full`}  
        onClick={() => login() }
        >
          <div className={`w-fit h-full flex flex-row items-center justify-center text-center rounded-md bg-slate-600 hover:bg-slate-800 text-slate-100 px-4 py-0`}>
            <PowerIcon
              className="h-4 w-4 text-bold md:w-0 md:opacity-0 opacity-100" 
            />
            <div
              className="md:w-fit w-0 opacity-0 md:opacity-100" 
             >
              Connect wallet
            </div>
        </div>
      </button>
    }    
    </>
  );
};
