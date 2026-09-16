#!/usr/bin/env bash
# Reference implementation. Every repo carries its own copy at
# .buildkite/steps/run-in-image.sh, because no-command-eval requires the script
# to live in the checkout being built.
#
# Usage:  .buildkite/steps/run-in-image.sh ci-linux
#
# Runs a just recipe inside the pinned CI image against the current checkout.
set -euo pipefail

: "${CI_IMAGE:?pipeline.yml must set CI_IMAGE to a digest-pinned image}"

recipe="${1:?a just recipe is required}"
shift || true

# --user 0:0 is load-bearing under ROOTLESS Docker, and is the opposite of what
# it looks like.
#
# Rootless Docker maps container uid 0 to the host user running the daemon
# (bkagent). So "root" in the container writes files owned by bkagent on the
# host — exactly what we want for a bind-mounted checkout. Running as a non-zero
# container uid instead maps to a *subuid* (165536+), leaving files in the
# Buildkite checkout owned by a uid that does not exist on the host, which
# breaks the next build's `git clean`.
#
# It grants no privilege on the host: the whole daemon is unprivileged.
docker_args=(
  --rm
  --user 0:0
  --volume "$PWD:/work"
  --workdir /work
)

# Persist the cargo registry and the target directory across jobs. Without this
# every build recompiles every dependency from scratch — sccache is not wired up
# yet (it needs the Azure Blob backend from Part 1; SCCACHE_GHA_ENABLED was a
# GitHub-Actions-only thing and does not exist here).
docker_args+=(
  --volume "tokito-cargo-registry:/usr/local/cargo/registry"
  --volume "tokito-cargo-git:/usr/local/cargo/git"
  --volume "tokito-target-${BUILDKITE_PIPELINE_SLUG:-local}:/work/target"
)

# Private TokitoAI git dependencies (ui, catalog, schematic-core) need a
# credential. Mint a one-hour GitHub App installation token rather than baking
# in a long-lived PAT — this is what replaces VTRON_DEPS_TOKEN.
if [ -x /usr/local/bin/tokito-gh-token ]; then
  GH_TOKEN="$(/usr/local/bin/tokito-gh-token)"
  export GH_TOKEN
  docker_args+=(--env GH_TOKEN)
fi

exec docker run "${docker_args[@]}" "$CI_IMAGE" bash -euo pipefail -c '
  # The container starts as root for the reason above, then drops to an
  # unprivileged uid for the build itself — because PostgreSQL refuses to run
  # as uid 0, and pg-embed starts one for the DB integration tests:
  #
  #   embedded PostgreSQL failed after retries
  #   Caused by: PostgreSQL could not be initialized.
  #
  # So: root sets up ownership on the cache volumes, then hands off. Everything
  # the build writes goes to those volumes or /tmp, never into the bind-mounted
  # checkout, so the host copy stays owned by the agent user.
  BUILD_UID=5000
  useradd -m -u "$BUILD_UID" build 2>/dev/null || true
  chown -R "$BUILD_UID" /work/target /usr/local/cargo/registry /usr/local/cargo/git 2>/dev/null || true

  # --system, not --global: the build runs as a different user than the one
  # writing this config, so it has to land somewhere both can read.
  git config --system --add safe.directory /work

  if [ -n "${GH_TOKEN:-}" ]; then
    git config --system \
      url."https://x-access-token:${GH_TOKEN}@github.com/TokitoAI/".insteadOf \
      "https://github.com/TokitoAI/"
  fi

  exec setpriv --reuid="$BUILD_UID" --regid="$BUILD_UID" --clear-groups \
    env HOME=/home/build \
        PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        CARGO_HOME=/usr/local/cargo \
        RUSTUP_HOME=/usr/local/rustup \
        CARGO_TERM_COLOR=always \
        RUST_BACKTRACE=1 \
    just "$@"
' bash "$recipe" "$@"
