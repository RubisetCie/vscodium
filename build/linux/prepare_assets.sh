#!/usr/bin/env bash

cd vscode || { echo "'vscode' dir not found"; exit 1; }

if [[ -z "${VSCODE_SYSROOT_REPOSITORY}" ]]; then
  unset VSCODE_SYSROOT_REPOSITORY
fi

if [[ -z "${VSCODE_SYSROOT_VERSION}" ]]; then
  unset VSCODE_SYSROOT_VERSION
fi

if [[ -z "${VSCODE_SYSROOT_PREFIX}" ]]; then
  unset VSCODE_SYSROOT_PREFIX
fi

if [[ "${SHOULD_BUILD_DEB}" != "no" ]]; then
  npm run gulp "vscode-linux-${VSCODE_ARCH}-prepare-deb"
  npm run gulp "vscode-linux-${VSCODE_ARCH}-build-deb"
fi

if [[ "${SHOULD_BUILD_RPM}" != "no" ]]; then
  npm run gulp "vscode-linux-${VSCODE_ARCH}-prepare-rpm"
  npm run gulp "vscode-linux-${VSCODE_ARCH}-build-rpm"
fi

cd ..

if [[ "${SHOULD_BUILD_TAR}" != "no" ]]; then
  echo "Building and moving TAR"
  cd "VSCode-linux-${VSCODE_ARCH}"
  tar czf "../assets/${APP_NAME}-linux-${VSCODE_ARCH}-${RELEASE_VERSION}.tar.gz" .
  cd ..
fi

if [[ "${SHOULD_BUILD_DEB}" != "no" ]]; then
  echo "Moving DEB"
  files=( vscode/.build/linux/deb/*/deb/*.deb )
  filenew="${files[0]##*/}"
  filenew="${filenew//_/-}"
  mv "${files[0]}" "assets/$filenew"
fi

if [[ "${SHOULD_BUILD_RPM}" != "no" ]]; then
  echo "Moving RPM"
  mv vscode/.build/linux/rpm/*/*.rpm assets/
fi
