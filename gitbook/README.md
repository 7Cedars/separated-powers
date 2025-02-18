---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 😎 Welcome to the Powers Protocol

🚧 **Documentation is under construction** 🚧

## What is it

The Powers Protocol is a role restricted governance protocol. All governance actions in the Power Protocol are restricted along roles that are assigned to accounts. The protocol consists of two elements: Powers and Laws.

### Powers

The engine of the protocol that manages governance flows. It has the following functionalities:   
* Proposing an action. 
* Voting on a proposal. 
* Executing an action. 
* Assigning and revoking roles. 
* Adopting and revoking laws.  

In addition there is a `constitute` functionality that can be used once, and can only by called by the admin, that allows to adopt multiple laws.  

### Laws

Laws define specific actions that a particular role can execute under certain conditions.

> Any account that has a role 2 can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of role 2 holders vote in favor.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`. Laws have the following functions:

* It returns a function call.
* It can save a state.
* It has multiple checks
* It has a function `executeLaw` that can only be called by the SeparatePowers protocol. It runs all checks, executes

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

## Use cases
