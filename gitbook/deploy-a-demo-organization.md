---
description: Learn how to deploy your own role restricted governance protocol.
---

# Deploy a demo organization

## Deployment sequence&#x20;

Deploying an organization unfolds in four steps.&#x20;

1. Deploy
2. Deploy any additional protocols that will be controlled by the organization.&#x20;
3. Deploy multiple instances of `Law.sol`.
4. Run the `Powers::constitute` function to adopt laws deployed at step 2.&#x20;

That's the short version.&#x20;

## Deployment scripts (Foundry)&#x20;

In reality, the sequence is a bit more complex because we always need to decide if we need to deploy additional protocols (for instance ERC20 tokens that will be controlled by laws), choose what laws to deploy and how to configure them.&#x20;

The good news for Foundry users is that it is relatively straightforward to deploy a fully fledged organization through a single script. See the following examples:

* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployBasicDao.s.sol](../solidity/script/DeployBasicDao.s.sol)
* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployAlignedDao.s.sol](../solidity/script/DeployAlignedDao.s.sol)
* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployGovernYourTax.s.sol](../solidity/script/DeployGovernYourTax.s.sol)

These scripts automate the following four steps. &#x20;

## Step 1: Deploy `Powers.sol`

## Step 2: Deploy any additional protocols

## Step 3: Deploy multiple instances of `Law.sol`.&#x20;

text here&#x20;

{% content-ref url="example-laws/" %}
[example-laws](example-laws/)
{% endcontent-ref %}



## Step 4: Run the SeparatedPower::constitute





