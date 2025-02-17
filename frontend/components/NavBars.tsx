"use client";

// This should become the header. Has the following (from left to right): 
// - logo -> click will bring to github page (or something about page like / documentation)
// - A button with the name of the currently selected Dao. -> click will bring to landing page.
// - NavigationBar buttons: home, laws, proposals, roles, treasury --> all correspond with their pages. 
// - address / login button -> links to privy.

import { usePathname } from 'next/navigation';
import type { PropsWithChildren } from "react";
import { useRouter } from 'next/navigation'
import { useEffect } from "react";
import { useOrgStore, deleteOrg } from "../context/store";
import Image from 'next/image'
import { Button } from "./Button";
import { 
  MagnifyingGlassIcon, 
  HomeIcon, 
  BookOpenIcon,
  IdentificationIcon,
  ChatBubbleBottomCenterIcon,
  BuildingLibraryIcon
} from '@heroicons/react/24/outline';
import { ConnectButton } from './ConnectButton';

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
  const path = usePathname()
 
  return (
    <header className="absolute grow w-screen top-0 h-fit py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300">
    <section className="grow flex flex-row gap-1 justify-between px-2 max-w-screen-xl">
      <div className="flex flex-row gap-1 min-w-48"> 
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
        <div className="flex flex-row grow gap-2 md:max-w-2xl opacity-0 md:opacity-100 max-w-0">
          {organisation.name != '' ? NavigationBar() : null }
        </div>
      }
        {path == `/` ? null : <ConnectButton /> }
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
        <div className="absolute h-dvh w-screen flex flex-col justify-center items-center">
          <Header /> 
          <main className="max-w-screen-lg w-full h-full grid grid-cols-1 justify-items-start content-start overflow-y-scroll px-2 pt-20 pb-20">
            {props.children}   
          </main>
          <NavigationSmallScreen /> 
        </div>
      }
    </>
  )
}

