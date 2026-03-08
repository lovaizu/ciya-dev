# CI/CD Expert Review

## Scope

| File | Description |
|------|-------------|
| `.github/workflows/test-shell.yml` | CI workflow for shell script tests with kcov coverage |

## Evaluation

| # | Finding | Severity | Improvement |
|---|---------|----------|-------------|
| 1 | Test discovery glob patterns miss `.claude/*_test.sh` — `statusline_test.sh` is not run in CI, so `statusline.sh` has no coverage enforcement | High | Add `.claude/*_test.sh` to the glob list in the "Run tests with coverage" step |
| 2 | kcov is cloned from HEAD of the default branch without a pinned version tag — a breaking upstream change could silently break CI | Medium | Pin to a release tag: `git clone --branch v44 --depth 1` |
| 3 | kcov is built from source on every CI run (~2-3 min) with no caching — this adds avoidable latency to every workflow execution | Medium | Cache the kcov installation using `actions/cache` keyed on the pinned version |
| 4 | First test failure stops the loop (GitHub Actions default `set -e`) — remaining tests are skipped, hiding additional failures from the developer | Medium | Collect exit codes in the loop and fail after all tests run, so the developer sees all failures in a single CI run |

## Decision

| # | Decision | Reason |
|---|----------|--------|
| 1 | Accepted | Real bug: `statusline.sh` changes escape CI coverage enforcement entirely |
| 2 | Accepted | Reproducibility is a CI best practice; unpinned dependencies cause intermittent failures that are hard to diagnose |
| 3 | Rejected | The caching logic adds maintenance complexity (cache invalidation, key management) disproportionate to the ~2 min saved; the project has low CI volume where this cost is acceptable |
| 4 | Accepted | Seeing all failures in one CI run reduces the fix-push-wait cycle; the current behavior forces serial debugging |
