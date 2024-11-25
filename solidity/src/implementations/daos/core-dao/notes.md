This should be a base implementation of a DAO that can be deployed as is, and gives an immediate functional and safe DAO infrastructure. 

It does not have any executive logic to start with, but has a governance flow for adding - severely restricted - governance actions. 

Governance roles (in addition to ADMIN_ROLE and PUBLIC_ROLE): 
A - MEMBER_ROLE
B - HOLDER_ROLE
C - SENIOR_ROLE

Electoral flow: 
- Assign MEMBER_ROLE
  -  PUBLIC_ROLE can nominate. (as in, anyone) 
  -  HOLDER_ROLE _and_ SENIOR_ROLE can accept nomination. - no vote needed. 
- Revoke + blacklist MEMBER_ROLE
   -  Through vote among HOLDER_ROLE _or_ SENIOR_ROLE. 
   -  No challenge possible. Needs to be done through adding a law, executing it - almost impossible. 
- Assign & revoke HOLDER_ROLE
  - Through token elections. 
  - SENIOR_ROLE calls elections, nut only once every x blocks. 
- Assign & revoke SENIOR_ROLE
  - By other SENIOR_ROLE holders, through vote. 

Governance flows:
- Add & remove, amend laws
  - MEMBER_ROLE: Propose {PresetAction}, 
  - HOLDER_ROLE: through weighted (& delegated?) vote: Accept & execute {setLaw}: {PresetAction} 
- Execute {PresetAction} law. 
  - SENIOR_ROLE, execute through simple majority vote.  
