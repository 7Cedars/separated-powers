import { create } from 'zustand';
import { Config, Proposal, Law, Organisation } from '../context/types'


// type Law = {
//   name: string | null;
//   description: string | null;
//   law: `0x${string}` | null;
//   allowedRole: bigint | null;
//   config?: Config;
//   params?: string[];
// }

type OrgStore = Organisation; 

const initialState: OrgStore = {
  name: '',
  contractAddress: `0x0`,
  colourScheme: 0,
  laws: [],
  proposals: [],
  roles: []
}

export const useOrgStore = create<OrgStore>()(() => initialState); 

// export default function updateOrg() {
//   const organisation = useOrgStore()
//   const assignOrg: typeof useOrgStore.setState = (organisation) => {
//     useOrgStore.setState(organisation)
//   }
export const assignOrg: typeof useOrgStore.setState = (organisation) => {
      useOrgStore.setState(organisation)
    }
export const deleteOrg: typeof useOrgStore.setState = () => {
      useOrgStore.setState(initialState)
    }


// {
//   name: null,
//   description: null,
//   address: null, 
//   assignOrg: (name, description, address) => set(() => ({
//       name: name,
//       description: description,
//       address: address
//   })),
//   deleteOrg: () => set(() => ({ 
//     name: null,
//     description: null,
//     address: null, 
//   }))
// }));

// export const useLawStore = create<LawsState & LawAction>((set) => ({
//   laws: [], 
//   saveLaw: (name, description, law, allowedRole) => set(() => ({
//     laws: [...state.laws]
//   })),
//   deleteLaw: () => set(() => ({ 
//     laws: laws.slice(index, 1)
//   }))
// }));