# CLAUDE.md

## Dependencies
- Before adding or bumping ANY dependency, verify the package and the exact version actually exist in its registry (npm, Go modules, PyPI, Maven Central, NuGet, crates.io, …). Never guess names or versions.
- Default to the latest stable release unless a constraint says otherwise. Match the manifest/lockfile's version syntax for the ecosystem.

## Code style
- Write code that reads like the surrounding code: match its comment density, naming, and idiom.
- Clear names over clever ones. Comment the *why* when it can't live in the code (non-obvious workaround, external gotcha, business rule), not the *what*.

## No hardcoding
- No magic values, secrets, URLs, hosts, paths, ports, or timeouts inline.
- Source config from env vars, config files, or named constants. Fail loudly when required config is missing.

## Commit convention
- Follow Conventional Commits: `type(scope): message` (e.g. `feat(scripts): add ec2ls`, `chore(claude): enable plugin`). Common types: feat, fix, chore, docs, refactor, test, style, perf.
- Do not include the `Claude-Session:` URL trailer in commit messages.
