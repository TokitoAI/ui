# ui build recipes.
#
# CI calls these; it does not inline build logic of its own. That keeps the
# pipeline definition a thin caller, makes a CI migration mechanical rather than
# interpretive, and means `just ci` locally runs exactly what CI runs.
#
# Windows note: Buildkite does not support Git Bash for pipeline steps, so no
# recipe may depend on a POSIX shell.

set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Mirrors the workflow-level `env:` block so local runs behave identically.
export CARGO_TERM_COLOR := "always"
export RUST_BACKTRACE := "1"

_default:
    @just --list --unsorted

# `check` is deliberately not part of `ci`: cargo check and cargo clippy keep
# separate build fingerprints, so running both type-checks the crate twice, and
# `clippy --all-targets` already covers everything check does.
# Everything CI runs.
ci: fmt-check clippy test

# The fast inner loop: what you want before pushing.
pre-push: fmt-check clippy test

# Formatting is clean.
fmt-check:
    cargo fmt --all -- --check

# Formats in place. Not part of any CI aggregate.
fmt:
    cargo fmt --all

# `--locked` matters here: without it clippy will quietly update Cargo.lock, and
# the `test --locked` that follows then passes against the rewritten lock, so a
# dependency drift lands with nothing failing.
# Lints, denying warnings.
clippy:
    cargo clippy --locked --all-targets -- -D warnings

# Test suite.
test:
    cargo test --locked

# Lockfile and crate resolve without changes. Fast local inner loop only.
check:
    cargo check --locked
