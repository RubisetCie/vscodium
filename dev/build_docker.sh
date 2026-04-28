#!/usr/bin/env bash
# shellcheck disable=SC1091

exists() { type -t "$1" &> /dev/null; }

export APP_NAME="VSCodium"
export CI_BUILD="no"
export OS_NAME="linux"
export SKIP_ASSETS="yes"
export VSCODE_LATEST="no"
export VSCODE_QUALITY="stable"

while getopts ":hilp" opt; do
  case "$opt" in
    h)
      printf "Usage: $0 (options)
Options:
  -h: Display this help message.
  -i: Build the Insiders version.
  -l: Build the latest version of Visual Studio Code.
  -p: Generate the packages/assets/installers.\n"
      exit 1
      ;;
    i)
      export VSCODE_QUALITY="insider"
      ;;
    l)
      export VSCODE_LATEST="yes"
      ;;
    p)
      export SKIP_ASSETS="no"
      ;;
    *)
      ;;
  esac
done

UNAME_ARCH=$( uname -m )

if [[ "${UNAME_ARCH}" == "x86_64" ]]; then
  export VSCODE_ARCH="x64"
else
  export npm_config_arch=armv7l
  export npm_config_force_process_config="true"
  export VSCODE_ARCH="armhf"
fi

echo "OS_NAME=\"${OS_NAME}\""
echo "SKIP_ASSETS=\"${SKIP_ASSETS}\""
echo "VSCODE_ARCH=\"${VSCODE_ARCH}\""
echo "VSCODE_LATEST=\"${VSCODE_LATEST}\""
echo "VSCODE_QUALITY=\"${VSCODE_QUALITY}\""

rm -rf vscode* VSCode*

. get_repo.sh
. build.sh

if [[ "${SKIP_ASSETS}" == "no" ]]; then
  . prepare_assets.sh
fi
