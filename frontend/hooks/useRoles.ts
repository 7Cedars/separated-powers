import { useCallback, useEffect, useRef, useState } from "react";
import { agDaoAbi } from "../context/abi";
import { Status } from "../context/types"
import { ConnectedWallet } from "@privy-io/react-auth";
import { lawContracts } from "@/context/lawContracts";
import { readContract } from "@wagmi/core";
import { wagmiConfig } from "@/context/wagmiConfig";

export const useRoles = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [roles, setRoles] = useState<bigint[]>([]) 
  const agDaoAddress: `0x${string}` = lawContracts.find((law: any) => law.contract === "AgDao")?.address as `0x${string}`

  const fetchRoles = useCallback( 
    async (wallet: ConnectedWallet | undefined) => {
        setStatus("pending")
        if (wallet) {
          try {

            let role: bigint; 
            let allRoles: bigint[] = [0n, 1n, 2n, 3n]
            let hasRoles: bigint[] = [4n]

            for await (role of allRoles) {
              const response = await readContract(wagmiConfig, {
                abi: agDaoAbi,
                address: agDaoAddress,
                functionName: 'hasRoleSince', 
                args: [wallet.address, role]
              })
              if (response != 0n) hasRoles.push(role)
            }
            setRoles(hasRoles)
            setStatus("success")
          } catch (error) {
              setStatus("error") 
              setError(error)
          }
        } else {
          return []
        }
  }, [ ])

  return {status, error, roles, fetchRoles }
}