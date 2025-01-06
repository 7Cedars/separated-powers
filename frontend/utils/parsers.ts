import {InputType, DataType} from "../context/types"


export const parseParam = (param: string) => {
  let inputType: InputType; 
  let dataType: DataType; 
  let array: boolean = false

  switch (param) {
    case "0x7bcdc9c6": inputType = "number"; dataType = "uint8"; break;
    case "0x267213ef": inputType = "number"; dataType = "uint16"; break;
    case "0xaab7cacf": inputType = "number"; dataType = "uint32"; break;
    case "0xf1b7aa7b": inputType = "number"; dataType = "uint64"; break;
    case "0x26255fcf": inputType = "number"; dataType = "uint128"; break;
    case "0xec13d6d1": inputType = "number"; dataType = "uint256"; break;
    case "0x79b36d0f": inputType = "number"; dataType = "uint8[]"; array = true; break;
    case "0x176bfc5e": inputType = "number"; dataType = "uint16[]"; array = true; break;
    case "0x78cd6b36": inputType = "number"; dataType = "uint32[]"; array = true; break;
    case "0x9dc4a28a": inputType = "number"; dataType = "uint64[]"; array = true; break;
    case "0x3d05ac75": inputType = "number"; dataType = "uint128[]"; array = true; break;
    case "0xc1b76e99": inputType = "number"; dataType = "uint256[]"; array = true; break;
    case "0x421683f8": inputType = "address"; dataType = "address"; break;
    case "0x23d8ff3d": inputType = "address"; dataType = "address"; break;
    case "0x084b42f8": inputType = "hex"; dataType = "bytes"; break;
    case "0xb963e9b4": inputType = "hex"; dataType = "bytes"; break;
    case "0xc0427979": inputType = "hex"; dataType = "bytes"; break;
    case "0x9878dbb4": inputType = "hex"; dataType = "bytes32"; break;
    case "0x97fc4627": inputType = "string"; dataType = "string"; break;
    case "0xa227fd7a": inputType = "string"; dataType = "string"; array = true; break; 
    case "0xc1053bda": inputType = "bool"; dataType = "bool"; break;
    case "0x8761250c": inputType = "bool"; dataType = "bool"; array = true; break; 
  }

  return { dataType, inputType, array }
}



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

