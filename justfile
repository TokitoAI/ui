# ui build recipes.
#
# CI calls these; it does not inline build logic of its own. That keeps the
# pipeline definition a thin caller, makes a CI migration mechanical rather than
# interpretive, and means `just ci` locally runs exactly what CI runs.
#
# Linux only — this is a library the desktop app consumes, and Windows coverage
# comes from building the app itself at release time.

export CARGO_TERM_COLOR := "always"
export RUST_BACKTRACE := "1"

_default:
    @just --list --unsorted

# `check` is deliberately not part of `ci`: cargo check and cargo clippy keep
# separate build fingerprints, so running both type-checks the crate twice, and
# `clippy --all-targets` already covers everything check does.
# Everything CI runs.
ci: fmt-check clippy test doc

# The fast inner loop: what you want before pushing.
pre-push: fmt-check clippy test

# Formatting is clean.
fmt-check:
    cargo fmt --all -- --check

# Formats in place. Not part of any CI aggregate.
fmt:
    cargo fmt --all

# `--locked` matters here: without it clippy will quietly update Cargo.lock, and
# a later `--locked` command then passes against the rewritten lock, so a
# dependency drift lands with nothing failing.
# Lints, denying warnings.
clippy:
    cargo clippy --locked --all-targets -- -D warnings

# Replaces the workflow's bare `cargo build`: this compiles the same code and
# then actually runs something with it.
# Test suite.
test:
    cargo test --locked

# Broken intra-doc links are errors here, not warnings.
# Documentation builds clean.
doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked

# Lockfile and crate resolve without changes. Fast local inner loop only.
check:
    cargo check --locked
