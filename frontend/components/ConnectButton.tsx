"use client"

import { LinkedAccountWithMetadata, useConnectWallet, useLogout, usePrivy } from "@privy-io/react-auth";
import { useWallets } from "@privy-io/react-auth";
import { 
  PowerIcon,
} from '@heroicons/react/24/outline';
import BlockiesSvg from 'blockies-react-svg'
import { useSetActiveWallet } from "@privy-io/wagmi";

export const ConnectButton = () => {
  const {ready: walletsReady, wallets} = useWallets();
  const {ready, user, authenticated, login, logout, connectWallet, linkWallet} = usePrivy();
 
  // console.log({walletsReady, wallets, authenticated, user, ready})

  //NB see: 
  // https://github.com/privy-io/wagmi-demo/blob/main/app/page.tsx
  // and 
  //https://demo.privy.io/
  // watch out, if you try anything original. You'll suffer. 

  return (
    <> 
    {ready && !authenticated &&  
      <button
        className={`w-fit h-full flex flex-row items-center justify-center text-center rounded-md bg-slate-100 border-opacity-0 md:border-opacity-100 border border-slate-400 hover:border-slate-600`}  
        onClick={ login }
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

    {ready && authenticated && walletsReady && !wallets[0] &&
      <button
        className={`w-fit h-full flex flex-row items-center justify-center text-center rounded-md bg-slate-100 border-opacity-0 md:border-opacity-100 border border-slate-400 hover:border-slate-600`}  
        onClick={ connectWallet }
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

    {ready && authenticated && walletsReady && wallets[0] && 
        <button
          className={`w-fit h-full flex flex-row items-center justify-center text-center rounded-md bg-slate-100 border-opacity-0 md:border-opacity-100 border border-slate-400 hover:border-slate-600`}  
          onClick={ logout }
        >
          <div className={`flex flex-row items-center text-center text-slate-600 md:gap-2 gap-0 w-full h-full w-full md:py-1 px-2 py-0`}>
            <BlockiesSvg 
              address={wallets[0].address}
              className='md:h-6 md:w-6 h-9 w-fit rounded-md border border-slate-800'
              />
            <div className="md:w-fit w-0 opacity-0 md:opacity-100">
              {`${wallets[0].address.slice(0, 6)}...${wallets[0].address.slice(-6)}`}
            </div>
          </div>
        </button> 
    }


    </>
  )
}
