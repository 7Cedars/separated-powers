"use client";

// This should become the header. Has the following (from left to right): 
// - logo -> click will bring to github page (or something about page like / documentation)
// - A button with the name of the currently selected Dao. -> click will bring to landing page.
// - NavigationBar buttons: home, laws, proposals, roles, treasury --> all correspond with their pages. 
// - address / login button -> links to privy.

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { PropsWithChildren } from "react";
import { useRouter } from 'next/navigation'
import { useEffect } from "react";
import { useOrgStore, deleteOrg } from "../context/store";
import Image from 'next/image'
import { Button } from "./Button";
import { 
  GiftIcon, 
  MagnifyingGlassIcon, 
  HomeIcon, 
  BookOpenIcon,
  IdentificationIcon,
  ChatBubbleBottomCenterIcon,
  BuildingLibraryIcon
} from '@heroicons/react/24/outline';
import { useConnectWallet, useLogout, usePrivy } from "@privy-io/react-auth";
import { useWallets } from "@privy-io/react-auth";

const layoutIconBox: string = 'flex flex-row md:gap-2 gap-0 align-middle items-center'
const layoutIcons: string = 'h-5 w-5'
const layoutText: string = 'lg:opacity-100 lg:text-sm text-[0px] lg:w-fit w-0 opacity-0'

const NavigationBar = () => {
  const router = useRouter();
  const path = usePathname()

  return (
    <div className="w-full flex flex-row gap-1 justify-center items-center px-2"> 
            <Button 
              size = {0} 
              onClick={() => router.push('/home')}
              selected={path == `/home`} 
              showBorder={false}
              >
                <div className={layoutIconBox}> 
                  <HomeIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Home </p>
                </div> 
            </Button>

            <Button 
              size = {0} 
              onClick={() => router.push('/laws')}
              selected={path == `/laws`} 
              showBorder={false}
              >
                <div className={layoutIconBox}> 
                  <BookOpenIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Laws </p>      
                </div> 
            </Button>

            <Button 
              size = {0} 
              onClick={() => router.push('/proposals')}
              selected={path == `/proposals`} 
              showBorder={false}
              >
                <div className={layoutIconBox}> 
                  <ChatBubbleBottomCenterIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Proposals </p>      
                </div> 
            </Button>

            <Button 
              size = {0} 
              onClick={() => router.push('/roles')}
              selected={path == `/roles`} 
              showBorder={false}
              >
                <div className={layoutIconBox}> 
                  <IdentificationIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Roles </p>
                </div> 
            </Button>

            <Button 
              size = {0} 
              onClick={() => router.push('/treasury')}
              selected={path == `/treasury`} 
              showBorder={false}
              >
                <div className={layoutIconBox}> 
                  <BuildingLibraryIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Treasury </p>
                </div> 
            </Button>
          </div>
  )
}

const Header = () => {
  const router = useRouter();
  const organisation = useOrgStore(); 
  const {wallets } = useWallets();
  const {ready, authenticated, login, logout} = usePrivy();

  return (
    <header className="absolute grow w-screen top-0 h-fit py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300">
    <section className="grow flex flex-row gap-1 justify-between px-2 max-w-screen-lg">
      <div className="flex flex-row gap-1 max-w-96 min-w-48"> 
        <Button size = {0} onClick={() => router.push('/')} showBorder={true}>  
          <Image 
            src='/logo.png' 
            width={30}
            height={30}
            alt="Logo Separated Powers"
            >
          </Image>
        </Button> 
        <div className="">
        {
            organisation.name != '' ? 
            <div className="flex flex-row w-32 text-center h-10">
              <Button 
                size = {0} 
                onClick={() => deleteOrg({}) }
                >
                  {organisation.name}
              </Button>
            </div>
            :
            <Button 
              size = {0} 
              onClick={() => deleteOrg({}) }
              >
                <div className={"flex flex-row gap-1 justify-center items-center"}> 
                  <MagnifyingGlassIcon
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
        <div className="flex flex-row w-0 md:w-full opacity-0 md:opacity-100">
          {organisation.name != '' ? NavigationBar() : null  }
        </div>
      }

      <div className="flex flex-row gap-2 min-w-40"> 
      { 
        wallets[0] && authenticated ? 
        <Button 
            size = {0} 
            onClick={() => logout()}
            >
              <div className={layoutIconBox}> 
                {wallets[0].address.slice(0, 6)}...{wallets[0].address.slice(-6)}   
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
  )
}

const Footer = () => {  
  return (
     <header className="absolute bottom-0 z-20 bg-slate-50 flex justify-between border-t border-slate-300 h-14 items-center md:opacity-0 opacity-100 w-full text-sm px-4 py-2">
        {NavigationBar()}  
    </header>
  )
}


export const NavBars = (props: PropsWithChildren<{}>) => {
  const organisation = useOrgStore();
  const router = useRouter();

  useEffect(() => {
    if (organisation.name == '') {
      router.push('/') 
    }
  }, [organisation]);


  return (
    <>
      <Header />
      <main className="grow max-w-screen-lg max-h-screen h-fit grid grid-cols-1 py-20 px-2 overflow-y-auto">
        {props.children}
      </main>
      <Footer />
    </>

  )


}

