# Decentralized Crowdfunding Platform

A trustless, fully on-chain crowdfunding smart contract built with Solidity. This project emulates a Kickstarter-style funding mechanism where creators can launch campaigns, and backers can pledge ETH. It relies on mathematical guarantees rather than central authorities to manage refunds and payouts.

## Core Architecture & Security Patterns

This contract was built with a heavy emphasis on modern smart contract security and gas optimization:

* **Trustless Refunds (Lazy Evaluation):** The contract does not use background cron jobs or loops to process refunds. Instead, it uses lazy evaluation—backers pull their own refunds if a campaign fails to reach its target by the deadline.
* **Checks-Effects-Interactions (CEI):** Strictly enforced across all state-changing functions (`claim`, `withdraw`, `refund`) to completely neutralize Reentrancy attack vectors.
* **Pull-over-Push Payments:** The contract never forces ETH into external addresses during core logic execution, preventing Denial of Service (DoS) attacks caused by faulty receiving contracts.
* **O(1) Accounting Lookups:** Utilizes a nested mapping (`mapping(uint256 => mapping(address => uint256))`) to track pledges, ensuring constant time complexity and minimal gas costs regardless of how many backers a campaign has.
* **Custom Errors:** Implements Solidity custom errors (e.g., `error CampaignHasNotEnded(...)`) instead of `require` string reverts to significantly reduce deployment and execution gas costs.

## Features

* **Start Campaigns:** Anyone can launch a campaign by setting a funding target (in wei) and a duration (in days).
* **Pledge & Unpledge:** Backers can fund active campaigns. If they change their minds, they can withdraw their pledge anytime before the campaign deadline.
* **Claim (For Creators):** If the campaign reaches its target and the deadline has passed, the creator can securely claim the total raised funds.
* **Refund (For Backers):** If the campaign deadline passes and the target was *not* met, backers can securely withdraw their pledged ETH.

## Contract API

### Core Functions
* `startCampaign(uint256 _target, uint256 _durationDays)`: Initializes a new campaign.
* `createPledge(uint256 _campaign_id) payable`: Funds an active campaign.
* `withdraw(uint256 id, uint256 amount)`: Allows backers to reduce or remove their pledge while the campaign is active.
* `claim(uint256 id)`: Allows the creator to withdraw funds from a successful, completed campaign.
* `refund(uint256 _campaign_id)`: Allows backers to recover their funds from a failed, completed campaign.

## Getting Started

### Prerequisites
You can test and deploy this contract using [Remix IDE](https://remix.ethereum.org/), [Foundry](https://getfoundry.sh/), or [Hardhat](https://hardhat.org/).

### Quickstart (Remix)
1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new file named `Crowdfund.sol` and paste the contract code.
3. Compile using Solidity compiler version `0.8.26`.
4. Navigate to the **Deploy & Run Transactions** tab.
5. Select the `Remix VM` environment and click **Deploy**.
6. Use the provided UI to start a campaign, switch accounts to pledge ETH, and test the time-based claim/refund logic (you can adjust the duration to 0 days for immediate testing).

## License
This project is licensed under the GPL-3.0 License.
