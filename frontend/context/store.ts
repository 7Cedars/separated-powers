import { create } from 'zustand';

type State = {
  organisation: string | null;
  logo: string | null;
  address: `0x${string}` | null;
}

type Action = {
  assign: (organisation: string, logo: string, address: `0x${string}`) => void;
  delete: () => void;
}

export const useOrgStore = create<State & Action>((set) => ({
  organisation: null,
  address: null,
  logo: null,
  assign: (organisation, logo, address) => set(() => ({ 
    organisation: organisation, 
    logo: logo,
    address: address })),
  delete: () => set(() => ({ 
    organisation: null, 
    logo: null,
    address: null 
  }))
}));