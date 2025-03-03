---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 💪 Welcome to Powers Protocol

🚧 **Documentation is under construction** 🚧

## What is it

The Powers Protocol is a role restricted governance protocol.

This means, simply, that all governance actions are restricted by roles that are assigned to accounts. Only accounts with a 'Senior' role can vote for senior proposals, execute actions designated for seniors, and so on.

It allows for the creation of checks and balances between roles, guard-railing specific (AI agentic) accounts and creating hybrid on- and off-chain organizations, among many other use cases.

The challenge with creating role restricted governance protocols is that actions need to be _restricted_ before they can be _role_ restricted. These type of protocols only work with external contracts that pre-define which actions a specific role can do under what conditions. They become very complex, very quickly.

The Powers Protocol provides a minimalistic, but very powerful, proof of concept of a role restricted governance protocol.

It consists of two elements: Powers and Laws.

### Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It should be deployed as is and has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labelling roles.
* Adopting and revoking laws.

In addition there is a `constitute` functionality that allows adopting multiple laws at once. It can only be called be the admin, and only once.

The governance flow is defined by the following restrictions:

* Executing, proposing and voting can only be done in reference to a role restricted law. 
* Roles and laws can only be labelled, assigned and revoked through the execute function of the protocol itself.
* All actions, may they be subject to a vote or not, are executed via Powers' execute function in reference to a law.

{% content-ref url="for-developers/powers.sol.md" %}
[powers.sol.md](for-developers/powers.sol.md)
{% endcontent-ref %}

### Laws

Laws define under which conditions a role can execute what actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favor.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`. Laws have the following functionalities:

* They are role restricted by a single roleId.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.

Many elements of laws can be changed: the input parameters, the function call that is returned, which checks need to pass, what state (if any) is saved. Pretty much anything is possible. Laws are the meat on the bones provided by Powers engine.

What is not flexible, is how Powers interacts with a law. This is done through the `executeLaw` function. When this function is called:

* The checks are run.
* The function call is executed.
* Any state change is saved to the law.
* A return call is returned to the Powers protocol for execution.

{% content-ref url="for-developers/law.sol.md" %}
[law.sol.md](for-developers/law.sol.md)
{% endcontent-ref %}

### Role restricted governance flow

Together, Powers and Laws define which accounts can do what in what situations. Let us explore several examples.

Example A: Allow the adoption of a new law, but have a second role check actions, so this power cannot be abused.   
> **Law 1** allows accounts with role 1 to propose an address of a new law. The law is subject to a vote, and the proposal will only be accepted if more than half of role 1 account holders votes in favour.
> 
> Alice, who has been assigned a role 1, proposes to transfer ether from the protocol to X. Bob and Charlotte, other role 1 holders, vote in favour and the proposal passes. 
> 
> Now *nothing* happens. Only a proposal has been formalised, no executable call is send to Power protocol. 
>
> **Law 2** allows accounts with role 2 to execute any actions. The law is subject to a vote and, crucially, needs the exact same proposal to have passed with Law 1. 
> 
> David, who has role 2, notices that a proposal has passed at Law 1. He puts the proposal up for a vote among role 2 holders. Eve and Helen, both role 2 holders, vote in favour. 
> 
> Following the vote, David calls the execute function and the Power protocol implements the action.   

Example B: Assign roles through Liquid Democracy and Peer Selection 
> Example two ...


## Characteristics

Role restricted governance protocols divide community governance into multiple tracks. Each track consists of several laws through which role holders can initiate, approve, stop or revert executive actions.

Each action can be conditional on votes, delays, throttling or any other check to pass.

### Composability

text

### Upgradability

text

### Safety

text

### Flexibility

text

### Efficiency

text

### Engagement

text
