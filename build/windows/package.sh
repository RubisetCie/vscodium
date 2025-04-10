#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

if [[ "${CI_BUILD}" == "no" ]]; then
  exit 1
fi

tar -xzf ./vscode.tar.gz

cd vscode || { echo "'vscode' dir not found"; exit 1; }

for i in {1..5}; do # try 5 times
  npm ci && break
  if [[ $i -eq 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."
done

node build/azure-pipelines/distro/mixin-npm

. ../build/windows/rtf/make.sh

npm run gulp "vscode-win32-${VSCODE_ARCH}-min-ci"

# build command-line if everything is set-up
if [[ "${RUST_TOOLCHAIN}" != "none" ]]; then
  export VCPKG_ROOT=$VCPKG_INSTALLATION_ROOT
  wd="$PWD"
  cd cli && cargo build --release --target "${RUST_TARGET}" && mv "target/${RUST_TARGET}/release/code.exe" "$wd/../VSCode-win32-${VSCODE_ARCH}/bin/codium-tunnel.exe"
  cd "$wd"
fi

cd ..
