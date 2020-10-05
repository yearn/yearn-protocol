## Contributing to Yearn

This is a living guide that defines a development process for yearn.finance protocol.

We want to make contributing to this project as easy and transparent as possible, whether it's:

-   Bug report.
-   Current state of the code discussion.
-   Fix submission.
-   Feature proposal.
-   Maintainer application.

### We Develop with Github

We use Github to host code, to track issues and feature requests, as well as accept pull requests.

Pull requests are the best way to propose changes to the codebase (we use Github [flow](https://guides.github.com/introduction/flow/index.html)). We welcome your pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests or ensure it doesn't break current tests.
3. If you've changed something impacting current docs, please update the documentation.
4. Ensure the test suite passes (if applicable).
5. Ensure your code follows formatting rules.
6. Issue that pull request!

### Release Process

The `master` branch has the up to date changes of the codebase with working code. Releases should be tracked via git tags to link a specific commit to a deployment for history and documentation purposes.

### Github Actions

Repository uses GH actions to setup CI for [test](https://github.com/iearn-finance/yearn-protocol/blob/master/.github/workflows/test.yaml) harness. Be sure to setup any secret or env variable needed for your GH actions to work.

### Bug Reports

We use GitHub issues to track public bugs. Report a bug by opening a new [issue](https://github.com/iearn-finance/yearn-protocol/issues/new); it's that easy!

Before adding a new issue, please check that your issue is not already identified or hasn't been handled by searching the active/closed issues.

**Great Bug Reports** tend to have:

-   A clear and concise summary of an issue.
-   Steps to reproduce a bug.
-   What is expected to happen.
-   What actually happens.
-   Notes.

### Consistent Coding Style

-   Setup [prettier](https://github.com/prettier/prettier) and [solium](https://github.com/duaraghav8/Ethlint) linters into your local coding environment.
-   Check that your changes adhere to the linting rules before pushing by running `yarn lint:check` and `yarn lint:fix`.
-   Merging may be blocked if a PR does not follow the coding style guidelines.

### License

By contributing, you agree that your contributions will be licensed under its [APGL License](https://choosealicense.com/licenses/agpl-3.0/).

### References

TBD
