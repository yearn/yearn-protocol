# Contributing to Yearn
This is a living guide that defines a development process for The Yearn.finance Core Protocol. 

We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github
We use github to host code, to track issues and feature requests, as well as accept pull requests.

## We Use [Github Flow](https://guides.github.com/introduction/flow/index.html), So All Code Changes Happen Through Pull Requests
Pull requests are the best way to propose changes to the codebase (we use [Github Flow](https://guides.github.com/introduction/flow/index.html)). We actively welcome your pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests or ensure it doesn't break current tests.
3. If you've changed something impacting current docs, please update the documentation.
4. Ensure the test suite passes if applicable.
5. Make sure your code lints.
6. Issue that pull request!

## Release Process
The `master` branch has the up to date changes of the codebase with working code. Releases should be tracked via git tags to link a specific commit to a deployment for history and documentation purposes.

## Tests

Requirements for running tests locally: 
* Python 3.8 local development environment and NodeJs 10.x development environment for Ganache
* Brownie local environment setup. See here for instructions: [ETH Brownie](https://github.com/eth-brownie/brownie) 
* Local env variables for [Etherscan API](https://etherscan.io/apis) and [Infura](https://infura.io/). ETHERSCAN_TOKEN, WEB3_INFURA_PROJECT_ID
* Local Ganache environment installed with `npm install -g ganache-cli@6.10.1`


Running tests:
`brownie test -s`

Running tests with coverage:
`brownie test -s --coverage`

## Github Actions
Repository uses GH actions to setup CI for test harness.
You can see an example [here](https://github.com/iearn-finance/yearn-protocol/blob/master/.github/workflows/test.yaml)

Be sure to setup in the repository any secret or env variable needed for your GH actions to work.


## Any contributions you make will be under the APGL Software License
In short, when you submit code changes, your submissions are understood to be under the same [APGL License](https://choosealicense.com/licenses/agpl-3.0/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using Github's [issues](https://github.com/iearn-finance/yearn-protocol/issues)
We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/iearn-finance/yearn-protocol/issues/new); it's that easy!

Before adding a new issue, please check that your issue is not already identified or hasn't been handled by searching the active/closed issues.

## Write bug reports with detail, background, and sample code
[This is an example](http://stackoverflow.com/q/12488905/180626) of a bug report I wrote, and I think it's not a bad model. Here's [another example from Craig Hockenberry](http://www.openradar.me/11905408), an app developer whom I greatly respect.

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can. 
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Use a Consistent Coding Style

* Setup prettier and solium linters into your local coding environment.
* Check that your changes adhere to the linting rules before pushing.
* Merging may be blocked if a PR does not follow the coding style guidelines.

## License
By contributing, you agree that your contributions will be licensed under its APGL License.

## References
TBD
