#!/usr/bin/env bash
# Bootstrap step: hand the real pipeline to Buildkite.
#
# A committed script rather than an inline `buildkite-agent pipeline upload`,
# because the self-hosted agents run with no-command-eval=true and refuse
# anything that is not a path in the checkout.
set -euo pipefail
buildkite-agent pipeline upload .buildkite/pipeline.yml
