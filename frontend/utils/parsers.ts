import { ChangeEvent } from "react";
import {InputType, DataType} from "../context/types"


export const parseParam = (param: string) => {
  let dataType: DataType;

  switch (param) {
    case "0x00000000": dataType = "empty"; break;

    case "0x7bcdc9c6": dataType = "uint8"; break;
    case "0x267213ef": dataType = "uint16"; break;
    case "0xaab7cacf": dataType = "uint32"; break;
    case "0xf1b7aa7b": dataType = "uint64"; break;
    case "0x26255fcf": dataType = "uint128"; break;
    case "0xec13d6d1": dataType = "uint256"; break;
    case "0x79b36d0f": dataType = "uint8[]"; break;
    case "0x176bfc5e": dataType = "uint16[]"; break;
    case "0x78cd6b36": dataType = "uint32[]"; break;
    case "0x9dc4a28a": dataType = "uint64[]"; break;
    case "0x3d05ac75": dataType = "uint128[]"; break;
    case "0xc1b76e99": dataType = "uint256[]"; break;

    case "0x421683f8": dataType = "address"; break;
    case "0x23d8ff3d": dataType = "address[]"; break;
    
    case "0xb963e9b4": dataType = "bytes"; break;
    case "0x084b42f8": dataType = "bytes[]"; break;
    
    case "0x9878dbb4": dataType = "bytes32"; break;
    case "0xc0427979": dataType = "bytes32[]"; break;
    
    case "0x97fc4627": dataType = "string"; break;
    case "0xa227fd7a": dataType = "string[]"; break; 
    
    case "0xc1053bda": dataType = "bool"; break;
    case "0x8761250c": dataType = "bool[]"; break; 

    default:
      dataType = "unsupported"; break
  } 

  return dataType
}

export const parseInput = (event: ChangeEvent<HTMLInputElement>, dataType: DataType): InputType | string => {
  // very basic parser. Here necessary input checks can be added later.  
  const errorMessage: string = 'Incorrect input data';
  if ( !event || typeof event !== 'string' || typeof event !== 'number' || typeof event !== 'boolean' ) {
     throw new Error('Incorrect or missing data.');
  }

  // Note that later on I can also check for maximum values by taking the power of uintxxx
  if (dataType.indexOf('uint') > -1) {
    try {
      return Number(event) 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bool') > -1) {
    try {
      return Boolean(event) 
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('string') > -1) { 
    try {
      return String(event) 
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('address') > -1) {
    try {
      return event as `0x${string}` 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bytes') > -1)  {
    try {
      return event as `0x${string}` 
    } catch {
      return errorMessage
    }
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

