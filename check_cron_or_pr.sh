#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

if [[ "${GITHUB_ENV}" ]]; then
  echo "GITHUB_BRANCH=${GITHUB_BRANCH}" >> "${GITHUB_ENV}"
  echo "VSCODE_QUALITY=${VSCODE_QUALITY}" >> "${GITHUB_ENV}"
fi
