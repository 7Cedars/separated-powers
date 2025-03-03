---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 💪 Welcome to Powers Protocol

🚧 **Documentation is under construction** 🚧

## What it is.&#x20;

The Powers protocol is a role restricted governance protocol.

This means, simply, that all governance actions are restricted by roles that are assigned to accounts. Only accounts with a 'Senior' role can vote for senior proposals, execute actions designated for seniors, and so on.

It allows for the creation of checks and balances between roles, guard-railing specific (AI agentic) accounts and creating hybrid on- and off-chain organizations, among many other use cases.

The challenge is that actions need to be _restricted_ before they can be _role_ restricted. Role restricted governance protocols only work with external contracts that define which actions a specific role can do under what conditions. These type of protocols become very complex, very quickly.

The Powers protocol provides a minimalist, but very powerful, proof of concept of a role restricted governance protocol.

It consists of two elements: Powers and Laws.

### Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It should be deployed as is and has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labeling roles.
* Adopting and revoking laws.

In addition there is a `constitute` function that allows adopting multiple laws at once. This function can only be called by the admin, and only once.

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

* They are role restricted by a single role.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.

Many elements of laws can be changed: the input parameters, the function call that is returned, which checks need to pass, what state (if any) is saved. Pretty much anything is possible. Laws are the meat on the bones provided by Powers engine.

What is not flexible, is how Powers interacts with a law. This is done through the `executeLaw` function. When this function is called, the function:&#x20;

1. Runs the checks&#x20;
2. Decodes input calldata.&#x20;
3. Computes return function calls and state change. This can include running additional checks.&#x20;
4. Saves any state change to the law.&#x20;
5. Returns the computed function call to Powers for execution.

{% content-ref url="for-developers/law.sol.md" %}
[law.sol.md](for-developers/law.sol.md)
{% endcontent-ref %}

### Powers + Laws = Governance

Together, Powers and Laws allow communities to build any governance structure that fit their needs. It is possible to define the mechanisms through which a role is assigned, the power it has, how roles check and balance each other, and under what conditions this can change. Let us explore two examples.

Example A: Assign governor roles through Liquid Democracy&#x20;

> **Law 1** allows 'members' of a community to nominate themselves for a 'governor' role in their community.&#x20;
>
> Alice, Bob and Charlotte each call the law through powers `execute` function and save their nomination in the law.
>
> **Law 2** assigns governor roles to accounts saved in Law 1. It does this on the basis of delegated tokens held by accounts. Any account can call the law, triggering (and paying gas costs for) an election.&#x20;
>
> In January, David obtains a large amount of tokens and delegates them to Bob. He calls law 2 and triggers an election. Alice and Bob are elected and assigned as governors. In the following weeks, he notices that bob is not responding to messages and not voting in elections.&#x20;
>
> In February, he re-delegates his tokens Charlotte and in the next block calls an election. Alice and Charlotte win the election and are assigned as governors. Bob per immediate effect loses his governor role and all of its privileges.

This is an example of what can be called Liquid Democracy. But roles can also be assigned directly, through votes among peers, a council vote or through a minimal threshold of token holdings. Pretty much anything is possible.  &#x20;

Example B: Allow the adoption of a new law, but have a second role check actions, so this power cannot be abused.

> **Law 1** allows 'members' of a community to propose adopting a new law that allows community members to mint tokens. Law 1 is subject to a vote, and the proposal will only be accepted if more than half of the community votes in favor.
>
> Alice, as a community member, proposes to transfer ether from the protocol to an account X  Bob and Charlotte, the other community members, vote in favor. The proposal passes.
>
> Alice calls the execute function. Now _nothing_ happens. Only a proposal has been formalized, no executable call is send to the Powers of the community.&#x20;
>
> **Law 2** allows governors in the community to accept and implement new laws. Law 2 is also subject to a vote and, crucially, needs the exact same proposal to have passed with Law 1.
>
> David, who is a senior, notices that a proposal has passed at Law 1. He puts the proposal up for a vote among other seniors. Eve and Helen, the other seniors, vote in favor.
>
> Following the vote, David calls the execute function and the Power protocol implements the action: the new law is adopted and community members will be able to mint tokens. &#x20;

This is a basic example of a governance chain: Multiple laws that are linked together through a child-parent relation where a proposal needs to pass a child law before it can executed by a parent law. Note that the nominate -> elect logic of example A is also a governance chain.   &#x20;

More examples can be found in the example organizations. &#x20;

{% content-ref url="example-communities/" %}
[example-communities](example-communities/)
{% endcontent-ref %}

## Differences &#x20;

In comparison to existing governance solutions, role restricted governance protocols are simpler, while being more efficient, modular and flexible. They are also different. It is important to be aware of some of the main implications of these differences before exploring them in more detail.&#x20;

### Assigning roles

Todo: Always need mechanism to assign roles. &#x20;

### Voting power

Todo: Explain severance relation token holdings and voting power.&#x20;

### Governance chains

Todo: Here explanation of gov chains.  &#x20;

### Upgradability

Todo: Modular and governed.&#x20;
