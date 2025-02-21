import { supportedChains } from "@/context/chains";
import { ChainProps, Law, Organisation } from "@/context/types";
import { useChainId } from "wagmi";

const nameMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

export const toDateFormat = (timestamp: number): string => { 
  return new Date(timestamp * 1000).toISOString().split('T')[0]
}; 

export const toShortDateFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  const shortYear = date.getFullYear().toString() // .slice(2,4) 

  return `${nameMonths[date.getMonth()]} ${shortYear}`
}; 

export const toFullDateFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  return `${date.getDate()} ${nameMonths[date.getMonth()]} ${date.getFullYear()}`
}; 

export const toEurTimeFormat = (timestamp: number): string => {
  const date = new Date(timestamp * 1000) 
  let minutes = date.getMinutes().toString()
  minutes.length == 1 ? minutes = `0${minutes}` : minutes
  return `${date.getHours()}:${minutes}`
}; 

export const toTimestamp = (dateFormat: string): string => { 
  return String(Date.parse(dateFormat))
};

export const blocksToHoursAndMinutes = (blocks: number, supportedChain: ChainProps | undefined): string | undefined => { 
  const blockTime = supportedChain?.blockTimeInSeconds ? supportedChain?.blockTimeInSeconds : 0
  const minutes = (blocks * blockTime) / 60 

  const response = minutes < 60 ? ` ${Math.floor(minutes % 60)} minutes.` 
  : 
  ` ${Math.floor(minutes / 60)} hours and ${Math.floor(minutes % 60)} minutes.`

  return response 
};

export const orgToGovernanceTracks = (organisation: Organisation): {tracks: Law[][] | undefined , orphans: Law[] | undefined}  => {  

  console.log("@orgToGovernanceTracks: ", {organisation})

  const childLawAddresses = organisation.activeLaws?.map(law => law.config.needCompleted
      ).concat(organisation.activeLaws?.map(law => law.config.needNotCompleted)
      ).concat(organisation.activeLaws?.map(law => law.config.readStateFrom)
    )
  const childLaws = organisation.activeLaws?.filter(law => childLawAddresses?.includes(law.law))
  const parentLaws = organisation.activeLaws?.filter(law => law.config.needCompleted != `0x${'0'.repeat(40)}` || law.config.needNotCompleted != `0x${'0'.repeat(40)}` || law.config.readStateFrom != `0x${'0'.repeat(40)}` ) 

  const start: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == false)
  const middle: Law[] | undefined = childLaws?.filter(law => parentLaws?.includes(law) == true)
  const end: Law[] | undefined = parentLaws?.filter(law => childLaws?.includes(law) == false)
  const orphans = organisation.activeLaws?.filter(law => childLaws?.includes(law) == false && parentLaws?.includes(law) == false)

  console.log("@orgToGovernanceTracks: ", {start, middle, end, orphans})

  const tracks1 = end?.map(law => {
    const dependencies = [law.config.needCompleted, law.config.needNotCompleted, law.config.readStateFrom]
    const dependentLaws = middle?.filter(law1 => dependencies?.includes(law1.law)) 

    return dependentLaws ?  [law].concat(dependentLaws) : [law]
  })

  const tracks2 = tracks1?.map(lawList => {
    const dependencies = lawList.map(law => law.config.needCompleted).concat(lawList.map(law => law.config.needNotCompleted)).concat(lawList.map(law => law.config.readStateFrom))
    const dependentLaws = start?.filter(law1 => dependencies?.includes(law1.law)) 

    return dependentLaws ?  lawList.concat(dependentLaws).reverse() : lawList.reverse()
  })

  const result = {
    tracks: tracks2,
    orphans: orphans 
  }

  console.log("@orgToGovernanceTracks: ", {result})

  return result

};