## Yearn Bug Bounty

This document specifies the Bug Bounty program for Yearn Finance, including the rules of the program, descriptions of eligible bugs, and the reward amount for each bug. Follow the steps in the “Submission” section at the bottom of this page and our technical developer team will contact you shortly to discuss your submission.

### Rules

1. Bug has not been publicly disclosed.
2. Vulnerabilities that have been previously submitted by another contributor or already known by the Yearn developer team are not eligible for rewards.
3. The value of rewards are paid out depending on **Impact** and **Likelihood** of an exploit, using the [OWSAP](https://owasp.org/www-project-risk-assessment-framework) risk-rating model. Please refer to the reward [chart](#rewards) below for additional details.
4. Bugs must be reproducible in order for us to verify the vulnerability. A _secret Gist_ or _git patch_ of a test case is a good way to provide this to us.
5. Rewards and the validity of bugs are determined by the Yearn developer team and any payouts are made at the sole discretion of Yearn.
6. Terms and conditions of the Bug Bounty program can be changed at any time at the discretion of Yearn.
7. The Yearn Bug Bounty program adheres to the [Responsible Disclosure Standard](https://github.com/RD-Crypto-Spec/Responsible-Disclosure). Please refer to that document for additional details on how to handle your disclosure.
8. Details of any valid bugs may be shared with complementary protocols utilized in the Yearn ecosystem in order to promote ecosystem cohesion and safety.

### Vulnerability Classifications

**Severe** - an issue that may result in a loss of greater than \$10m of funds locked in Yearn, or may result in permanent impairment of the ecosystem.

**High** - an issue that may result in a loss of greater than \$1m but less than \$10m of funds locked in Yearn, or may result in severe damage to the ecosystem.

**Medium** - an issue that may result in a loss of greater than \$10k but less than \$1m of funds locked in Yearn, or cause either extreme user dissatisfaction or damage to the ecosystem.

**Low** - an issue that may result in user dissatisfaction but less than \$10k loss of funds locked in Yearn.

**Note** - an issue that may result in minimal user dissatisfaction and no financial loss, but could be rectified to improve the Yearn ecosystem.

### Likelihood Classifications

**Certain** - exploitable by anyone, with no preconditions required for success.

**Likely** - exploitable by anyone, under certain conditions (e.g., user with x amount of funds locked, or exploitable only over a longer period of time).

**Possible** - exploitable with 1 external fault required to access vulnerability, or direct access by single privileged key (e.g., Yearn strategist, bot, etc).

**Unlikely** - exploitable with 2 or more external faults required to access, or
direct access by a compromised Yearn multi-sig or Governance system).

**Maximum payouts per vulnerability:**

-   Severe - 40000 yUSD
-   High - 10000 yUSD
-   Medium - 4000 yUSD
-   Low - 1600 yUSD
-   Note - 100 yUSD

### <a name="rewards"></a> Rewards

Reward payouts are determined by a combination of the vulnerability and likelihood classifications identified above. The rewards represent the _maximum_ that will be paid out for a disclosure.

|          | Low  | Medium | High  | Severe |
| -------: | :--: | :----: | :---: | :----: |
|  Certain | 1600 |  4000  | 10000 | 40000  |
|   Likely | 800  |  2000  | 5000  | 20000  |
| Possible | 400  |  1000  | 2500  | 10000  |
| Unlikely | 200  |  500   | 1250  |  5000  |

Rewards are paid out in [yUSD](https://etherscan.io/token/0x5dbcf33d8c2e976c6b560249878e6f1491bca25c).

### Scope

The scope of the Bug Bounty program spans smart contracts utilized in the Yearn ecosystem – the Solidity and/or Vyper smart contracts in the `contracts` folder of the `master` branch of the yearn-protocol [repo](https://github.com/iearn-finance/yearn-protocol), including historical deployments that still see active use on Ethereum Mainnet associated with YFI, and excluding any contracts used in a test-only capacity (including test-only deployments).

Note: Other contracts, outside of the ones mentioned above, might be considered on a case by case basis, please, reach out to the technical developer team for clarification.

### Submission

Please, send a detailed description of vulnerability to [y@milkyklim.com](mailto:y@milkyklim.com?subject=Yearn%20Vulnerability) and [yearn-security@pm.me](mailto:yearn-security@pm.me?subject=Yearn%20Vulnerability), PGP keys can be found in yearn-security [repo](https://github.com/iearn-finance/yearn-security/tree/master/keys).

In your letter include:

1. Title: "Yearn Vulnerability".
2. A clear, concise description.
3. Steps to reproduce vulnerability.
4. Areas/smart contracts affected.
5. Code to reproduce the vulnerability, if available.
6. Potential solutions, if available.

For faster communication reach out to [@milkyklim](https://t.me/milkyklim).

### FAQs

**Q:** Is there a time limit for the Bug Bounty program?\
**A:** No. The Bug Bounty program currently has no end date, but this can be changed at any time at the discretion of Yearn.

**Q:** How big is the Bug Bounty program?\
**A:** There is currently a rolling \$500,000 bounty for bugs. This amount may be changed by a Yearn governance vote.

**Q:** How are bounties paid out?\
**A:** Rewards are paid out in yUSD.

**Q:** Can I submit bugs anonymously and still receive payment?\
**A:** Yes. If you wish to remain anonymous you can do so and still be eligible for rewards as long as they are for valid bugs. Rewards will be sent to the valid Ethereum address that you provide.

**Q:** Can I donate my reward to charity?\
**A:** Yes. You may donate your reward to a charity of your choosing, or to a gitcoin grant.
