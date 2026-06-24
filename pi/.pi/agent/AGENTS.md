# Developer Guidelines

## Dependency Management
- Before adding or upgrading any dependency, you must verify the package name and exact version exist in the registry (npm, Go modules, PyPI, etc.). Never guess.
- Default to the latest stable release. Exact syntax must match the project's existing manifest or lockfile like package.json or go.mod.
- Do not introduce heavy dependencies for trivial tasks. Prefer native standard libraries where reasonable.

## Go Specifics
- When adding packages, use go get via terminal tools rather than manually editing go.mod unless necessary. Run go mod tidy immediately after adding or removing code.
- Handle all errors explicitly. Do not ignore errors with the blank identifier. Wrap errors with context using fmt.Errorf when bubbling them up.
- Follow standard golangci-lint rules and idiomatic Go formatting via gofmt.

## Code Style and Documentation
- Write clean, self-documenting code. Prioritize explicit, clear naming over clever or ultra-terse optimizations.
- Do not write comments that explain what the code does.
- Only use comments to document the why, such as obscure business logic, non-obvious workarounds, or external API quirks.

## Configuration and Security
- Zero magic values, secrets, URLs, hosts, paths, ports, or timeouts inline.
- Use environment variables, structured config files, or properly scoped constants.
- The application must fail loudly and immediately at startup if a required configuration value is missing.

## Agent Execution Behavior
- Read relevant existing files before modifying or creating new ones to maintain architectural consistency.
- Avoid massive rewrite blocks if a targeted refactor achieves the same goal. Keep diffs reviewable.
- If a terminal command, lint check, or test fails, stop and fix the underlying issue immediately before writing more code.
