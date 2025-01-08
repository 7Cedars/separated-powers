import { create } from 'zustand';
import { Config, Proposal, Law, Organisation, Action } from '../context/types'

type OrgStore = Organisation; 
const initialStateOrg: OrgStore = {
  name: '',
  contractAddress: `0x0`,
  colourScheme: 0,
  laws: [],
  proposals: [],
  roles: []
}

type LawStore = Law;
const initialStateLaw: LawStore = {
  name: '',
  description: '',
  config: {
    delayExecution: 0n, 
    needCompleted: `0x0`,
    needNotCompleted: `0x0`,
    quorum: 0n, 
    succeedAt: 0n, 
    throttleExecution: 0n,
    votingPeriod: 0n
  },
  law: `0x0`,
  params: [],
  allowedRole: 0n
}

type ActionStore = Action;
const initialStateAction: ActionStore = {
  dataTypes: [],
  inputValues: [],
  description: '',
  callData: `0x0`, 
  upToDate: false
}

// Organisation Store
export const useOrgStore = create<OrgStore>()(() => initialStateOrg); 

export const assignOrg: typeof useOrgStore.setState = (organisation) => {
      useOrgStore.setState(organisation)
    }
export const deleteOrg: typeof useOrgStore.setState = () => {
      useOrgStore.setState(initialStateOrg)
    }

// Law Store 
export const useLawStore = create<LawStore>()(() => initialStateLaw); 

export const setLaw: typeof useLawStore.setState = (law) => {
  useLawStore.setState(law)
    }
export const deleteLaw: typeof useOrgStore.setState = () => {
      useLawStore.setState(initialStateLaw)
    }

// Action Store
export const useActionStore = create<ActionStore>()(() => initialStateAction);

export const setAction: typeof useActionStore.setState = (action) => {
  useActionStore.setState(action)
    }
export const deleteAction: typeof useActionStore.setState = () => {
      useActionStore.setState(initialStateAction)
    }

export const notUpToDate: typeof useActionStore.setState = () => {
  useActionStore.setState({...initialStateAction, upToDate: false})
}

