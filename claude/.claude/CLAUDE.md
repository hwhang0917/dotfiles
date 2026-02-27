## Guidelines

### General Coding Conventions

- Use minimal comment and make function/variable name descriptive and clean.
- Follow the idioms and best practices of the programming language being used.
- Ensure code is modular and reusable where applicable.
- Avoid hardcoding values; use configuration files or environment variables instead.

### Verification

Do NOT build and run to verify, let the user do that.
Only provide guides to build and run the project, and let the user provide logs if there are any issues.

### Version Specification

Before specifying package version, verify they exists by checking the appropriate package registries such as npm, PyPI, Maven Central, etc.
Do NOT guess arbitrary version numbers. When uncertain use 'latest' or omit version constraints and ask for clarification.

- Before adding any NPM packages, first run `npm view <package-name> versions` to confirm the version exists.
- Before adding any PyPI packages, first run `pip index versions <package-name>` to confirm the version exists.
- Before adding any Maven packages, first check [Maven Central Repository](https://search.maven.org/) to confirm the version exists.
- Before adding any Go packages, first check [pkg.go.dev](https://pkg.go.dev/) to confirm the version exists.

### Alternate CLI tools

If available, prefer using the following CLI tools over their more common counterparts for better performance and usability:

- `curl` over `wget` for downloading files.
- `jq` for JSON processing over manual parsing with tools like `grep`
- `fd` over `find` for file searching tasks.
- `rg` over `grep` for text searching tasks.
- `uv` or `uvx` over `pip` or `pip3` for Python package management.

### Version Control

If it is a git repository, try to make meaningful and atomic commits with clear messages.
