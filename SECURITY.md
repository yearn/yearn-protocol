## Yearn's Security Process

This document describes the Security Process for Yearn Finance, including vulnerability disclosures and its [Bug Bounty program](#bug-bounty-program). We are committed to conduct our Security Process in a professional and civil manner. Public shaming, under-reporting, or misrepresentation of vulnerabilities will not be tolerated.

To submit a finding, please follow the steps outlined in receiving disclosures [section](#receiving-disclosures).

## Responsible Disclosure Standard

Yearn follows a community [standard](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#the-standard) for responsible disclosure in cryptocurrency and related software. This document is a public commitment to
following the standard.

This standard provides detailed information for:

-   [Initial Contact](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#initial-contact): how to establish initial contact with Yearn's security team.
-   [Giving Details](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#giving-details): what details to include with your vulnerability disclosure after having received a response to your initial contact.
-   [Setting Dates](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#setting-dates): how to agree on timelines for releasing updates and making details of the issue public.

Any expected deviations and necessary clarifications around the standard are explained in the following sections.

## Receiving Disclosures

Yearn is committed to working with researchers who submit security vulnerability notifications to us, to resolve those issues on an appropriate timeline, and to perform a coordinated release, giving credit to the reporter if they would so like.

Please submit issues to **all** of the following main points of contact for
security related issues according to the
[initial contact](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#initial-contact)
and [giving details](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#giving-details)
guidelines.

For all security related issues, Yearn has 3 main points of contact:

| Contact                | Public key                                                                                                   | Email                             | Keybase                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------- | ----------------------------------------------- |
| milkyklim              | [PGP](https://github.com/iearn-finance/yearn-security/blob/master/keys/milkyklim.asc)                        | y at milkyklim.com                | [@milkyklim](https://keybase.io/milkyklim/chat) |
| Doggie Boy / fubuloubu | [PGP](https://github.com/iearn-finance/yearn-security/blob/master/keys/publickey.yearn-security%40pm.me.asc) | yearn-security at pm.me           | N/A                                             |
| Daniel Lehnberg        | [PGP](https://github.com/iearn-finance/yearn-security/blob/master/keys/lehnberg.asc)                         | daniel.lehnberg at protonmail.com | [@lehnberg](https://keybase.io/lehnberg/chat)   |

Include all contacts in your communication, PGP encrypted to all parties.

You can also reach out informally over keybase encrypted chat to one or more of the contacts as per the details above.

## Sending Disclosures

In the case where we become aware of security issues affecting other projects that has never affected Yearn, our intention is to inform those projects of security issues on a best effort basis.

In the case where we fix a security issue in Yearn that also affects the following neighboring projects, our intention is to engage in responsible disclosures with them as described in the adopted [standard](https://github.com/RD-Crypto-Spec/Responsible-Disclosure), subject to the deviations described in the deviations [section](#deviations-from-the-standard) of this document.

## Bilateral Responsible Disclosure Agreements

_Yearn does not currently have any established bilateral disclosure agreements._

## Bug Bounty Program

Yearn has a Bug Bounty program to encourage security researchers to spend time studying the protocol in order to uncover vulnerabilities. We believe these researchers should get fairly compensated for their time and effort, and acknowledged for their valuable contributions.

### Rules

1. Bug has not been publicly disclosed.
2. Vulnerabilities that have been previously submitted by another contributor or already known by the Yearn development team are not eligible for rewards.
3. The size of the bounty payout depends on the assessment of the severity of the exploit. Please refer to the rewards [section](#rewards) below for additional details.
4. Bugs must be reproducible in order for us to verify the vulnerability.
5. Rewards and the validity of bugs are determined by the Yearn security team and any payouts are made at their sole discretion.
6. Terms and conditions of the Bug Bounty program can be changed at any time at the discretion of Yearn.
7. Details of any valid bugs may be shared with complementary protocols utilized in the Yearn ecosystem in order to promote ecosystem cohesion and safety.

### Classifications

-   **Severe:** Highly likely to have a material impact on availability, integrity, and/or loss of funds.
-   **High:** Likely to have impact on availability, integrity, and/or loss of funds.
-   **Medium:** Possible to have an impact on availability, integrity, and/or loss of funds.
-   **Low:** Unlikely to have a meaningful impact on availability, integrity, and/or loss of funds.

### Rewards

-   **Severe:** 20,000-50,000 yUSD
-   **High:** 5,000-20,000 yUSD
-   **Medium:** 1,000-5,000 yUSD
-   **Low:** 100-1,000 yUSD

Actual payouts are determined by classifying the vulnerability based on its impact and likelihood to be exploited successfully, as well as the process working with the disclosing security researcher. The rewards represent the _maximum_ that will be paid out for a disclosure.

Rewards are paid out in [yUSD](https://etherscan.io/token/0x5dbcf33d8c2e976c6b560249878e6f1491bca25c).

### Scope

The scope of the Bug Bounty program spans smart contracts utilized in the Yearn ecosystem – the Solidity and/or Vyper smart contracts in the `contracts` folder of the `master` branch of the yearn-protocol [repo](https://github.com/iearn-finance/yearn-protocol), including historical deployments that still see active use on Ethereum Mainnet associated with YFI, and excluding any contracts used in a test-only capacity (including test-only deployments).

Note: Other contracts, outside of the ones mentioned above, might be considered on a case by case basis, please, reach out to the Yearn development team for clarification.

### Bug Bounty FAQ

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

## Deviations from the Standard

The standard describes reporters of vulnerabilities including full details of an issue, in order to reproduce it. This is necessary for instance in the case of an external researcher both demonstrating and proving that there really is a security issue, and that security issue really has the impact that they say it
has - allowing the development team to accurately prioritize and resolve the issue.

In the case of a counterfeiting or fund-stealing bug affecting Yearn, however, we might decide not to include those details with our reports to partners ahead of coordinated release, as long as we are sure that they are not vulnerable.

## More Information

Additional security-related information about the Yearn project including disclosures, signatures and PGP public keys can be found in the [yearn-security](https://github.com/iearn-finance/yearn-security) repository.

## Credits

Parts of this document were inspired by [Grin's security policy](https://github.com/mimblewimble/grin/blob/master/SECURITY.md).
