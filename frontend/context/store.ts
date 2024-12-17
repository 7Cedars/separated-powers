import { create } from 'zustand';

type State = {
  organisation: string | null;
  logo: string | null;
  address: `0x${string}` | null;
}

type Action = {
  assignOrg: (organisation: string, logo: string, address: `0x${string}`) => void;
  deleteOrg: () => void;
  
}

export const useOrgStore = create<State & Action>((set) => ({
  organisation: null,
  address: null,
  logo: null,
  assignOrg: (organisation, logo, address) => set(() => ({ 
    organisation: organisation, 
    logo: logo,
    address: address })),
  deleteOrg: () => set(() => ({ 
    organisation: null, 
    logo: null,
    address: null 
  }))
}));