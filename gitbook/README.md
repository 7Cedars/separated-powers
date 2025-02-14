---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 😎 Welcome to Separated Powers

🚧 **Documentation is under construction** 🚧

## What is it

Separated Powers is a proof of concept of a role restricted governance protocol. It consists of two elements: Separated Powers and Laws.

### Separated Powers

text here.

* item 1
* item 2

### Laws
Laws define specific actions that a particular role can execute under certain conditions. 

Example: 'Any account that has a role 2 can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of role 2 holders vote in favour'.  

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`. Laws have the following functions: 

* It returns a function call.
* It can save a state.
* It has multiple checks
* It has a function `executeLaw` that can only be called by the SeparatePowers protocol. It runs all checks, executes &#x20;

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
