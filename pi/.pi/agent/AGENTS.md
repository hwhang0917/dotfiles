# Guideline

## Dependencies
- Before adding or bumping ANY dependency, verify the package and the exact version actually exist in its registry (npm, Go modules, PyPI, Maven Central, NuGet, crates.io, …). Never guess names or versions.
- Default to the latest stable release unless a constraint says otherwise. Match the manifest/lockfile's version syntax for the ecosystem.

## Code style
- Write clean, readable, self-documenting code. Clear names over clever ones.
- Do not write comments. Only comment when the *why* genuinely can't live in the code itself (non-obvious workaround, external gotcha, business rule). Never narrate *what* the code does.

## No hardcoding
- No magic values, secrets, URLs, hosts, paths, ports, or timeouts inline.
- Source config from env vars, config files, or named constants. Fail loudly when required config is missing.
