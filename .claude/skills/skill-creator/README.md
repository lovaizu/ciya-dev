# skill-creator

## Background

Anthropic provides a skill called `skill-creator` that helps build, test, and improve Claude Code skills. There are two versions available from different sources:

- **GitHub version** ([anthropics/skills](https://github.com/anthropics/skills)) — Skill creation guidance, static validation, and packaging.
- **Claude.ai version** — Significantly expanded. Adds eval mode (execute a skill and grade against expectations), benchmark mode (compare with/without a skill), and four specialized agents (executor, grader, comparator, analyzer).

As of February 2025, the Claude.ai version is not available through Claude Code's skill install feature or on the public GitHub repository. It can only be obtained by asking Claude to provide the files directly.

## Why this copy exists

We obtained the Claude.ai version and placed it here so that skill developers in this repository can use eval and benchmark modes without manual setup each time.

## When to replace

When the same version is published on GitHub (likely at [anthropics/skills](https://github.com/anthropics/skills)), replace this directory with the official release. The official version will receive updates and bug fixes that this snapshot will not.

## License

Apache License 2.0 — see [LICENSE.txt](LICENSE.txt).
