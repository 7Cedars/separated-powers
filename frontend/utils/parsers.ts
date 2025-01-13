import { ChangeEvent } from "react";
import {InputType, DataType} from "../context/types"
import { type UseReadContractsReturnType } from 'wagmi'

const isArray = (array: unknown): array is Array<unknown> => {
  // array.find(item => !isString(item)) 
  return array instanceof Array;
};

export const parseParams = (params: string[]): DataType[]  => {
  if (!isArray(params)) {
    throw new Error('Incorrect or missing data.');
  }

  const filteredParams = params.filter(param => param != '0x00000000')
  let parsedParams; 

  if (filteredParams) {
    parsedParams = filteredParams.map(
      param => {
        switch (param) {
          case "0x7bcdc9c6": return "uint8";
          case "0x267213ef": return "uint16";
          case "0xaab7cacf": return "uint32";
          case "0xf1b7aa7b": return "uint64";
          case "0x26255fcf": return "uint128";
          case "0xec13d6d1": return "uint256";
          case "0x79b36d0f": return "uint8[]";
          case "0x176bfc5e": return "uint16[]";
          case "0x78cd6b36": return "uint32[]";
          case "0x9dc4a28a": return "uint64[]";
          case "0x3d05ac75": return "uint128[]";
          case "0xc1b76e99": return "uint256[]";
      
          case "0x421683f8": return "address";
          case "0x23d8ff3d": return "address[]";
          
          case "0xb963e9b4": return "bytes";
          case "0x084b42f8": return "bytes[]";
          
          case "0x9878dbb4": return "bytes32";
          case "0xc0427979": return "bytes32[]";
          
          case "0x97fc4627": return "string";
          case "0xa227fd7a": return "string[]"; 
          
          case "0xc1053bda": return "bool";
          case "0x8761250c": return "bool[]"; 
      
          default:
            return "unsupported";
        } 
      }
    )
  } else {
    throw new Error('Missing data.');
  }

  return parsedParams
}

export const parseInputValues = (inputs: unknown): Array<InputType | InputType[]> => {
  // very basic parser. Here necessary input checks can be added later.  
  if (!isArray(inputs)) {
    throw new Error('@parseInputValues: input not an array.');
  }

  const result = inputs.map(input => 
    isArray(input) ? input as InputType[] : input as InputType 
  )

  return result 
};

export const parseInput = (event: ChangeEvent<HTMLInputElement>, dataType: DataType): InputType => {
  // very basic parser. Here necessary input checks can be added later.  
  const errorMessage = 'Incorrect input data';
  console.log("value @parseInput:", event.target.value)
  if ( !event.target.value && typeof event.target.value !== 'string' && typeof event.target.value !== 'number' && typeof event.target.value !== 'boolean' ) {
     throw new Error('@parseInput: Incorrect or missing data.');
  }

  // Note that later on I can also check for maximum values by taking the power of uintxxx
  if (dataType.indexOf('uint') > -1) {
    try {
      return Number(event.target.value) 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bool') > -1) {
    console.log("@parser: ", event.target.value)
    try {
      return Boolean(event.target.value)
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('string') > -1) { 
    try {
      return event.target.value as string 
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('address') > -1) {
    try {
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bytes') > -1)  {
    try {
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }
};

export const parseRole = (role: bigint | undefined): number => {
  const returnValue = 
  role == undefined ? 0
  : role == 4294967295n ? 6
  : role == 0n ? 0
  : Number(role)

  return returnValue
}


export const parseVoteData = (data: unknown[]): {votes: number[], holders: number} => {
  if ( !data || !isArray(data)) {
    throw new Error('@parseVoteData: data not an array.');
  }
  if (data.length != 2) {
    throw new Error('@parseVoteData: data not correct length.');
  }
  const dataTypes = data.map(item => item as UseReadContractsReturnType) 
  let votes: number[]
  let holders: number 
  
  if (dataTypes[0] && 'result' in dataTypes[0]) {
    if (
      dataTypes[0].result == undefined || 
      !isArray(dataTypes[0].result)
    ) { 
      votes = [0, 0, 0] 
    } else {
      votes = dataTypes[0].result.map(item => Number(item))
    } 
  } else {
    votes = [0, 0, 0]
  }

  if ('result' in dataTypes[1]) {
    holders = Number(dataTypes[1].result)
  } else {
    holders = 0
  }

  return {votes, holders}
}
  
// direct copy for now from loyal-customer-engagement project. Adapt as needed. 
export const parseContractError = (rawReply: unknown): boolean | string  => {
  if (typeof rawReply == null) {
    return false
  }
  try {
    String(rawReply)
  } catch {
    throw new Error('Incorrect or missing data at rawReply');
  }

  if (typeof rawReply === 'boolean') {
    return rawReply
  }

  if (typeof rawReply !== 'boolean') {
    return String(rawReply).split("\n")[1]
  }

  else {
    return false 
  }
};




// Info: supported dataType Signatures: 
// uint8, = 0x7bcdc9c6
// uint16, = 0x267213ef
// uint32, = 0xaab7cacf
// uint64, = 0xf1b7aa7b
// uint128, = 0x26255fcf
// uint256, = 0xec13d6d1
// address, = 0x421683f8
// bytes, = 0xb963e9b4
// string, = 0x97fc4627
// bytes32, = 0x9878dbb4
// bool, = 0xc1053bda
// uint8[], = 0x79b36d0f
// uint16[], = 0x176bfc5e
// uint32[], = 0x78cd6b36
// uint64[], = 0x9dc4a28a
// uint128[], = 0x3d05ac75
// uint256[], = 0xc1b76e99
// address[], = 0x23d8ff3d
// bytes[], = 0x084b42f8
// string[], = 0xa227fd7a 
// bytes32[], = 0xc0427979
// bool[], = 0x8761250c

