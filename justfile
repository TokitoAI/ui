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

# No `--locked` here, unlike the other repos. This crate deliberately does not
# commit Cargo.lock — .gitignore lists it, the usual library convention — so
# there is nothing to lock against, and a fresh CI checkout fails outright with
# "cannot create the lock file because --locked was passed". The flag only
# buys something once a lockfile is committed.
# Lints, denying warnings.
clippy:
    cargo clippy --all-targets -- -D warnings

# Replaces the workflow's bare `cargo build`: this compiles the same code and
# then actually runs something with it.
# Test suite.
test:
    cargo test

# Broken intra-doc links are errors here, not warnings.
# Documentation builds clean.
doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --no-deps

# Crate resolves. Fast local inner loop only.
check:
    cargo check
