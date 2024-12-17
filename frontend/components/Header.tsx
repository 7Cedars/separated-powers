"use client";

// This should become the header. Has the following (from left to right): 
// - logo -> click will bring to github page (or something about page like / documentation)
// - A button with the name of the currently selected Dao. -> click will bring to landing page.
// - Navigation buttons: home, laws, proposals, roles, treasury --> all correspond with their pages. 
// - address / login button -> links to privy.

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { PropsWithChildren } from "react";
import { useRouter } from 'next/navigation'
import { useEffect } from "react";
import { useOrgStore } from "../context/store";
import Image from 'next/image'
import { Button } from "./Button";
import { 
  GiftIcon, 
  HomeIcon, 
  Cog6ToothIcon, 
  ShoppingCartIcon
} from '@heroicons/react/24/outline';
import { usePrivy } from "@privy-io/react-auth";
import { useWallets } from "@privy-io/react-auth";

export const Header = () => {
  const router = useRouter();
  const organisation = useOrgStore((state) => state.organisation)
  const deleteOrg = useOrgStore((action) => action.deleteOrg)
  const path = usePathname()
  const {wallets } = useWallets();
  const wallet = wallets[0];
  const {ready, authenticated, login, logout} = usePrivy();
  const layoutIconBox: string = 'flex flex-row gap-2 align-middle items-center'
  const layoutIcons: string = 'h-4 w-4'

  useEffect(() => {
    if (!organisation) {
      router.push('/') 
    }
  }, [organisation]);

  return (
    <header className="absolute grow w-screen top-0 h-fit p-4 flex justify-around text-sm bg-slate-50 border-b border-slate-300">
      <section className="grow flex flex-row gap-3 justify-between max-w-screen-lg">
        <div className="flex flex-row gap-1 max-w-96"> 
          <Button size = {0} onClick={() => router.push('/')}> 
            <Image 
              src='/logo.png' 
              width={25}
              height={25}
              alt="Logo Separated Powers"
              >
            </Image>
          </Button> 
          <div className="">
          {
              organisation ? 
              <Button 
                size = {0} 
                onClick={() => deleteOrg() }
                >
                  <div className={"flex flex-row gap-1 justify-center items-center"}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    <div className="w-32">
                      {organisation}
                    </div>
                </div> 
              </Button>
              :
              <Button 
                size = {0} 
                onClick={() => deleteOrg() }
                >
                  <div className={"flex flex-row gap-1 justify-center items-center"}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    <div className="w-32">
                    Select organisation 
                    </div>
                </div> 
            </Button>
          }
          </div>
        </div>
        {
          organisation ? 
            <div className="flex flex-row gap-2"> 
              <Button 
                size = {0} 
                onClick={() => router.push('/home')}
                selected={path == `/home`} 
                showBorder={false}
                >
                  <div className={layoutIconBox}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    Home           
                  </div> 
              </Button>

              <Button 
                size = {0} 
                onClick={() => router.push('/laws')}
                selected={path == `/laws`} 
                showBorder={false}
                >
                  <div className={layoutIconBox}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    Laws           
                  </div> 
              </Button>

              <Button 
                size = {0} 
                onClick={() => router.push('/proposals')}
                selected={path == `/proposals`} 
                showBorder={false}
                >
                  <div className={layoutIconBox}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    Proposals           
                  </div> 
              </Button>

              <Button 
                size = {0} 
                onClick={() => router.push('/roles')}
                selected={path == `/roles`} 
                showBorder={false}
                >
                  <div className={layoutIconBox}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    Roles           
                  </div> 
              </Button>

              <Button 
                size = {0} 
                onClick={() => router.push('/treasury')}
                selected={path == `/treasury`} 
                showBorder={false}
                >
                  <div className={layoutIconBox}> 
                    <GiftIcon
                    className={layoutIcons} 
                    />
                    Treasury           
                  </div> 
              </Button>
            </div>
          : 
          <div/>
        }

        <div className="flex flex-row gap-2 min-w-40"> 
        { 
          ready && wallet && authenticated ? 
          <Button 
              size = {0} 
              onClick={() => logout()}
              >
                <div className={layoutIconBox}> 
                  {wallet.address.slice(0, 6)}...{wallet.address.slice(-6)}   
                </div> 
          </Button>
          : 
          <Button 
          size = {0} 
          onClick={() => login()}
          >
            <div className={layoutIconBox}> 
              <b> Connect Wallet </b>       
            </div> 
          </Button>
        }
        </div>
      </section>
    </header>
    );
}

