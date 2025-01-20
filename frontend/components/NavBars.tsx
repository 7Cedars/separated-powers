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
  HeartIcon, 
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
const layoutButton: string = `w-full h-full flex flex-row justify-center items-center rounded-md border aria-selected:bg-slate-200 md:hover:border-slate-600 text-sm aria-selected:text-slate-700 text-slate-500 border-transparent`

const NavigationBar = () => {
  const router = useRouter();
  const path = usePathname()

  return (
    <div className="w-full h-full flex flex-row gap-1 justify-center items-center px-2 py-1 md:py-0"> 
            <button 
              onClick={() => router.push('/home')}
              aria-selected={path == `/home`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <HomeIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Home </p>
                </div> 
            </button>

            <button 
              onClick={() => router.push('/laws')}
              aria-selected={path == `/laws`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <BookOpenIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Laws </p>      
                </div> 
            </button>

            <button 
              onClick={() => router.push('/proposals')}
              aria-selected={path == `/proposals`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <ChatBubbleBottomCenterIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Proposals </p>      
                </div> 
            </button>

            <button 
              onClick={() => router.push('/roles')}
              aria-selected={path == `/roles`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <IdentificationIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Roles </p>
                </div> 
            </button>

            <button 
              onClick={() => router.push('/treasury')}
              aria-selected={path == `/treasury`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <BuildingLibraryIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Treasury </p>
                </div> 
            </button>
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
        <Button size = {0} onClick={
            () => {
              router.push('/')
              deleteOrg({})
            }
            
            } showBorder={true}>  
          <Image 
            src='/logo.png' 
            width={28}
            height={28}
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
                onClick={() =>router.push('/home') }
                >
                  {organisation.name}
              </Button>
            </div>
            :
            <Button 
              size = {0} 
              onClick={() => router.push('/') }
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
          {organisation.name != '' ? NavigationBar() : null }
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

const NavigationSmallScreen = () => {  
  return (
     <header className="absolute bottom-0 z-20 bg-slate-50 flex justify-between border-t border-slate-300 h-14 items-center md:opacity-0 opacity-100 w-full text-sm px-4">
        {NavigationBar()}  
    </header>
  )
}

export const Footer = () => { 
  // Need to include some legal stuff here as well?  
  return (
     <div className="w-full z-20 min-h-60 h-fit bg-slate-50 flex md:flex-row flex-col justify-between items-start text-slate-800 text-sm px-24 snap-end pt-12 border-t border-slate-300 gap-16 snap-end">
      <div className="grid grid-cols-3 gap-28">
        <div className="flex flex-col gap-3 justify-start items-start">
          <div className="font-bold"> 
            DApp
          </div>
          <div className="text-slate-500"> 
            Docs
          </div>
          <div className="text-slate-500"> 
            Github repo 
          </div>
        </div>
        <div className="flex flex-col gap-3 justify-start items-start">
          <div className="font-bold"> 
            Protocol
          </div>
          <div className="text-slate-500"> 
            About
          </div>
          <div className="text-slate-500"> 
            Docs
          </div>
          <div className="text-slate-500"> 
            Github repo 
          </div>
        </div>
      </div>

      <div className="w-full flex flex-row gap-3 justify-end items-end snap-end">
        <div className="flex flex-col gap-3 justify-start md:items-end items-center pb-20">
          <Image 
          src='/logo.png' 
          width={48}
          height={48}
          alt="Logo Separated Powers"
          >
          </Image>
          <div className="text-md font-bold flex flex-row gap-1">
            <p>Made with</p> 
            <HeartIcon className="w-4 h-4 text-red-700" />
            <p>by 7Cedars</p>
          </div>
          <div className="flex flex-row gap-2">
            <div>
              discord
            </div>
            <div>
              mirror.xyz
            </div>
            <div>
              telegram
            </div>
            <div>
              twitter
            </div>
          </div>
        
        
        </div>
      </div>
    
    </div>
  )
}


export const NavBars = (props: PropsWithChildren<{}>) => {
  const organisation = useOrgStore();
  const router = useRouter();
  const path = usePathname()

  useEffect(() => {
    if (organisation.name == '') {
      router.push('/') 
    }
  }, [organisation]);

  return (
    <>
      {
      path == '/' ? 
      <div className="w-full h-full grid grid-cols-1 overflow-y-scroll">
        <main className="w-full h-full grid grid-cols-1 overflow-y-scroll">
          {props.children}
        </main>
        {/* <Footer /> */}
      </div>
      : 
        <div className="w-full h-full grid grid-cols-1 overflow-y-scroll">
          <Header /> 
          <main className="grow max-w-screen-lg max-h-screen h-fit grid grid-cols-1 py-16 px-2 justify-items-center overflow-y-auto border border-red-500">
            {props.children}
          </main>
          <NavigationSmallScreen /> 
        </div>
      }
    </>
  )
}

