---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 💪 Welcome to Powers Protocol

🚧 **Documentation is under construction** 🚧

## What is it

The Powers Protocol is a role restricted governance protocol.

This means, simply, that all governance actions are restricted along pre-assigned roles: Only accounts with role 2 can vote for role 2 proposals, execute actions designated for role 2, and so on.

It allows for the creation of checks and balances between roles, guard-railing specific (AI agentic) accounts and creating hybrid on- and off-chain organizations, among many other use cases.

The challenge with creating role restricted governance protocols is that actions need to be _restricted_ before they can be _role_ restricted. These type of protocols only work with external contracts that pre-define which actions a specific role can do under what conditions. They become very complex, very quickly.

The Powers Protocol provides a minimalistic, but very powerful, proof of concept of a role restricted governance protocol.

It consists of two elements: Powers and Laws.

### Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It has the following core functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning and revoking roles.
* Adopting and revoking laws.

In addition there is a `constitute` functionality that allows adopting multiple laws at once. It can only be called be the admin, and only once.

Executing, proposing and voting can only be done in reference to a role restricted law. Roles and laws can only be assigned and revoked through the execute function of the protocol.

Important: this means that _no one_ has direct access to assets managed by the Powers protocol. All actions, may they be subject to a vote or not, need to be done via a law.

In any organization this engine should be a pure deployment of the `Powers.sol` contract.

For more information about Powers, see&#x20;



### Laws

Laws define under which conditions a role can execute what actions.

Example:

> Any account that has a role 2 can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of role 2 holders vote in favor.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`. Laws have the following functions:

* They are role restricted.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by a preset `Powers.sol` deployment.

Many elements of laws can be changed: what function call is returned, which checks need to pass, what state (if any) is saved. Laws are the meat on the bones provided by Powers.

What is not flexible, is how Powers interacts with laws. This is done through the `executeLaw` function. When this function is called:

* The checks are run.
* The function call is executed.
* Any state change is saved to the law.
* A return call is returned to the Powers protocol for execution.

### Role restricted governance flow

Together, Powers and Laws define which accounts can do what in what situations. Let us explore some examples.

> Example one ...

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
