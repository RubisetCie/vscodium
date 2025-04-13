#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "ORG_NAME=\"${ORG_NAME}\""

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
else
  if [[ "${CI_BUILD}" != "no" ]]; then
    clang++ --version
  fi
fi

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  if [[ "${CI_BUILD}" != "no" && "${OS_NAME}" == "osx" ]]; then
    CXX=clang++ npm ci && break
  else
    npm ci && break
  fi

  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://go.microsoft.com/fwlink/?LinkID=533484#vscode"
setpath_json "product" "extensionsGallery" '{"serviceUrl":"https://marketplace.visualstudio.com/_apis/public/gallery","itemUrl":"https://marketplace.visualstudio.com/items","extensionUrlTemplate":"https://www.vscode-unpkg.net/_gallery/{publisher}/{name}/latest","resourceUrlTemplate":"https://{publisher}.vscode-unpkg.net/{publisher}/{name}/{version}/{path}","controlUrl":"https://main.vscode-cdn.net/extensions/marketplace.json","publisherUrl":"https://marketplace.visualstudio.com/publishers","nlsBaseUrl":"https://www.vscode-unpkg.net/_lp/"}'
setpath_json "product" "extensionEnabledApiProposals" '{"ms-azuretools.vscode-dev-azurecloudshell":["contribEditSessions"],"ms-vscode.vscode-selfhost-test-provider":["testObserver","testRelatedCode"],"VisualStudioExptTeam.vscodeintellicode-completions":["inlineCompletionsAdditions"],"ms-vsliveshare.vsliveshare":["contribMenuBarHome","contribShareMenu","contribStatusBarItems","diffCommand","documentFiltersExclusive","fileSearchProvider","findTextInFiles","notebookCellExecutionState","notebookLiveShare","terminalDimensions","terminalDataWriteEvent","textSearchProvider"],"ms-vscode.js-debug":["portsAttributes","findTextInFiles","workspaceTrust","tunnels"],"ms-toolsai.vscode-ai-remote":["resolvers"],"ms-python.python":["codeActionAI","contribEditorContentMenu","quickPickSortByLabel","portsAttributes","testObserver","quickPickItemTooltip","terminalDataWriteEvent","terminalExecuteCommandEvent","notebookReplDocument","notebookVariableProvider","terminalShellEnv","terminalShellType"],"ms-python.vscode-python-envs": ["terminalShellEnv", "terminalShellType"],"ms-dotnettools.dotnet-interactive-vscode":["notebookMessaging"],"GitHub.codespaces":["contribEditSessions","contribMenuBarHome","contribRemoteHelp","contribViewsRemote","resolvers","tunnels","terminalDataWriteEvent","treeViewReveal","notebookKernelSource"],"ms-vscode.azure-repos":["extensionRuntime","fileSearchProvider","textSearchProvider"],"ms-vscode.remote-repositories":["canonicalUriProvider","contribEditSessions","contribRemoteHelp","contribMenuBarHome","contribViewsRemote","contribViewsWelcome","contribShareMenu","documentFiltersExclusive","editSessionIdentityProvider","extensionRuntime","fileSearchProvider","quickPickSortByLabel","workspaceTrust","shareProvider","scmActionButton","scmSelectedProvider","scmValidation","textSearchProvider","timeline"],"ms-vscode-remote.remote-wsl":["resolvers","contribRemoteHelp","contribViewsRemote","telemetry"],"ms-vscode-remote.remote-ssh":["resolvers","tunnels","terminalDataWriteEvent","contribRemoteHelp","contribViewsRemote","telemetry"],"ms-vscode.remote-server":["resolvers","tunnels","contribViewsWelcome"],"ms-vscode.remote-explorer":["contribRemoteHelp","contribViewsRemote","extensionsAny"],"ms-vscode-remote.remote-containers":["contribEditSessions","resolvers","portsAttributes","tunnels","workspaceTrust","terminalDimensions","contribRemoteHelp","contribViewsRemote"],"ms-vscode.js-debug-nightly":["portsAttributes","findTextInFiles","workspaceTrust","tunnels"],"ms-vscode.lsif-browser":["documentFiltersExclusive"],"ms-vscode.vscode-speech":["speech"],"GitHub.vscode-pull-request-github":["activeComment","codiconDecoration","codeActionRanges","commentingRangeHint","commentReactor","commentReveal","commentThreadApplicability","contribAccessibilityHelpContent","contribCommentEditorActionsMenu","contribCommentPeekContext","contribCommentThreadAdditionalMenu","contribCommentsViewThreadMenus","contribEditorContentMenu","contribMultiDiffEditorMenus","contribShareMenu","diffCommand","quickDiffProvider","shareProvider","tabInputTextMerge","tokenInformation","treeViewMarkdownMessage"],"GitHub.copilot":["inlineCompletionsAdditions"],"GitHub.copilot-nightly":["inlineCompletionsAdditions"],"GitHub.copilot-chat":["interactive","terminalDataWriteEvent","terminalExecuteCommandEvent","terminalSelection","terminalQuickFixProvider","chatParticipantAdditions","defaultChatParticipant","embeddings","chatEditing","chatProvider","mappedEditsProvider","aiRelatedInformation","codeActionAI","findTextInFiles","findTextInFiles2","textSearchProvider","textSearchProvider2","activeComment","commentReveal","contribSourceControlInputBoxMenu","contribCommentEditorActionsMenu","contribCommentThreadAdditionalMenu","contribCommentsViewThreadMenus","newSymbolNamesProvider","findFiles2","chatReferenceDiagnostic","extensionsAny","authLearnMore","testObserver","aiTextSearchProvider","chatReadonlyPromptReference","documentFiltersExclusive","chatParticipantPrivate","contribDebugCreateConfiguration","inlineEdit","inlineCompletionsAdditions","chatReferenceBinaryData","languageModelSystem","languageModelCapabilities","languageModelDataPart","chatStatusItem"],"GitHub.remotehub":["contribRemoteHelp","contribMenuBarHome","contribViewsRemote","contribViewsWelcome","documentFiltersExclusive","extensionRuntime","fileSearchProvider","quickPickSortByLabel","workspaceTrust","scmSelectedProvider","scmValidation","textSearchProvider","timeline"],"ms-python.gather":["notebookCellExecutionState"],"ms-python.vscode-pylance":[],"ms-python.debugpy":["contribViewsWelcome","debugVisualization","portsAttributes"],"ms-toolsai.jupyter-renderers":["contribNotebookStaticPreloads"],"ms-toolsai.jupyter":["notebookDeprecated","notebookMessaging","notebookMime","portsAttributes","quickPickSortByLabel","notebookKernelSource","interactiveWindow","notebookControllerAffinityHidden","contribNotebookStaticPreloads","quickPickItemTooltip","notebookExecution","notebookCellExecution","notebookVariableProvider","notebookReplDocument"],"ms-toolsai.tensorboard":["portsAttributes"],"dbaeumer.vscode-eslint":[],"ms-vscode.azure-sphere-tools-ui":["tunnels"],"ms-azuretools.vscode-azureappservice":["terminalDataWriteEvent"],"ms-vscode.anycode":["extensionsAny"],"ms-vscode.cpptools":["terminalDataWriteEvent","chatParticipantAdditions"],"vscjava.vscode-java-pack":[],"ms-dotnettools.csdevkit":["inlineCompletionsAdditions"],"ms-dotnettools.vscodeintellicode-csharp":["inlineCompletionsAdditions"],"microsoft-IsvExpTools.powerplatform-vscode":["fileSearchProvider","textSearchProvider"],"microsoft-IsvExpTools.powerplatform-vscode-preview":["fileSearchProvider","textSearchProvider"],"TeamsDevApp.ms-teams-vscode-extension":["chatParticipantAdditions","languageModelSystem"],"ms-toolsai.datawrangler":[],"ms-vscode.vscode-commander":[],"ms-vscode.vscode-websearchforcopilot":[],"ms-vscode.vscode-copilot-vision":["chatReferenceBinaryData","codeActionAI"],"ms-autodev.vscode-autodev":["chatParticipantAdditions"]}'
setpath_json "product" "extensionsEnabledWithApiProposalVersion" '["GitHub.copilot-chat","ms-vscode.vscode-commander","ms-vscode.vscode-copilot-vision"]'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/RubisetCie/vscodium/blob/master/LICENSE"
setpath_json "product" "trustedExtensionPublishers" '["microsoft","github"]'
setpath_json "product" "trustedExtensionProtocolHandlers" '["vscode.git","vscode.github-authentication","vscode.microsoft-authentication"]'
setpath_json "product" "trustedExtensionAuthAccess" '{"github":["vscode.github","github.remotehub","ms-vscode.remote-server","github.vscode-pull-request-github","github.codespaces","github.copilot","github.copilot-chat","ms-vsliveshare.vsliveshare","ms-azuretools.vscode-azure-github-copilot"],"github-enterprise":["vscode.github","github.remotehub","ms-vscode.remote-server","github.vscode-pull-request-github","github.codespaces","github.copilot","github.copilot-chat","ms-vsliveshare.vsliveshare","ms-azuretools.vscode-azure-github-copilot"],"microsoft":["ms-vscode.azure-repos","ms-vscode.remote-server","ms-vsliveshare.vsliveshare","ms-azuretools.vscode-azure-github-copilot","ms-azuretools.vscode-azureresourcegroups","ms-edu.vscode-learning","ms-toolsai.vscode-ai","ms-toolsai.vscode-ai-remote"],"microsoft-sovereign-cloud":["ms-vscode.azure-repos","ms-vscode.remote-server","ms-vsliveshare.vsliveshare","ms-azuretools.vscode-azure-github-copilot","ms-azuretools.vscode-azureresourcegroups","ms-edu.vscode-learning","ms-toolsai.vscode-ai","ms-toolsai.vscode-ai-remote"],"__GitHub.copilot-chat":["ms-azuretools.vscode-azure-github-copilot"]}'
setpath_json "product" "linkProtectionTrustedDomains" '["https://*.visualstudio.com","https://*.microsoft.com","https://aka.ms","https://*.gallerycdn.vsassets.io","https://*.github.com","https://login.microsoftonline.com","https://*.vscode.dev","https://*.github.dev","https://gh.io","https://portal.azure.com","https://raw.githubusercontent.com","https://private-user-images.githubusercontent.com","https://avatars.githubusercontent.com"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/RubisetCie/vscodium/issues/new"
setpath "product" "requestFeatureUrl" "https://go.microsoft.com/fwlink/?LinkID=533482"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://go.microsoft.com/fwlink/?LinkID=533687"

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "VSCodium - Insiders"
  setpath "product" "nameLong" "VSCodium - Insiders"
  setpath "product" "applicationName" "codium-insiders"
  setpath "product" "dataFolderName" ".vscodium-insiders"
  setpath "product" "linuxIconName" "vscodium-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "vscodium-insiders"
  setpath "product" "serverApplicationName" "codium-server-insiders"
  setpath "product" "serverDataFolderName" ".vscodium-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.vscodium.VSCodiumInsiders"
  setpath "product" "win32AppUserModelId" "VSCodium.VSCodiumInsiders"
  setpath "product" "win32DirName" "VSCodium Insiders"
  setpath "product" "win32MutexName" "vscodiuminsiders"
  setpath "product" "win32NameVersion" "VSCodium Insiders"
  setpath "product" "win32RegValueName" "VSCodiumInsiders"
  setpath "product" "win32ShellNameShort" "VSCodium Insiders"
  setpath "product" "win32AppId" "{{EF35BB36-FA7E-4BB9-B7DA-D1E09F2DA9C9}"
  setpath "product" "win32x64AppId" "{{B2E0DDB2-120E-4D34-9F7E-8C688FF839A2}"
  setpath "product" "win32arm64AppId" "{{44721278-64C6-4513-BC45-D48E07830599}"
  setpath "product" "win32UserAppId" "{{ED2E5618-3E7E-4888-BF3C-A6CCC84F586F}"
  setpath "product" "win32x64UserAppId" "{{20F79D0D-A9AC-4220-9A81-CE675FFB6B41}"
  setpath "product" "win32arm64UserAppId" "{{2E362F92-14EA-455A-9ABD-3E656BBBFE71}"
  setpath "product" "tunnelApplicationName" "codium-tunnel-insiders"
  setpath "product" "win32TunnelServiceMutex" "vscodiuminsiders-tunnelservice"
  setpath "product" "win32TunnelMutex" "vscodiuminsiders-tunnel"
else
  setpath "product" "nameShort" "VSCodium"
  setpath "product" "nameLong" "VSCodium"
  setpath "product" "applicationName" "codium"
  setpath "product" "linuxIconName" "vscodium"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "vscodium"
  setpath "product" "serverApplicationName" "codium-server"
  setpath "product" "serverDataFolderName" ".vscodium-server"
  setpath "product" "darwinBundleIdentifier" "com.vscodium"
  setpath "product" "win32AppUserModelId" "VSCodium.VSCodium"
  setpath "product" "win32DirName" "VSCodium"
  setpath "product" "win32MutexName" "vscodium"
  setpath "product" "win32NameVersion" "VSCodium"
  setpath "product" "win32RegValueName" "VSCodium"
  setpath "product" "win32ShellNameShort" "VSCodium"
  setpath "product" "win32AppId" "{{763CBF88-25C6-4B10-952F-326AE657F16B}"
  setpath "product" "win32x64AppId" "{{88DA3577-054F-4CA1-8122-7D820494CFFB}"
  setpath "product" "win32arm64AppId" "{{67DEE444-3D04-4258-B92A-BC1F0FF2CAE4}"
  setpath "product" "win32UserAppId" "{{0FD05EB4-651E-4E78-A062-515204B47A3A}"
  setpath "product" "win32x64UserAppId" "{{2E1F05D1-C245-4562-81EE-28188DB6FD17}"
  setpath "product" "win32arm64UserAppId" "{{57FD70A5-1B8D-4875-9F40-C5553F094828}"
  setpath "product" "tunnelApplicationName" "codium-tunnel"
  setpath "product" "win32TunnelServiceMutex" "vscodium-tunnelservice"
  setpath "product" "win32TunnelMutex" "vscodium-tunnel"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "${RELEASE_VERSION%-insider}"

replace 's|Microsoft Corporation|VSCodium|' package.json

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "VSCodium - Insiders"
  setpath "resources/server/manifest" "short_name" "VSCodium - Insiders"
else
  setpath "resources/server/manifest" "name" "VSCodium"
  setpath "resources/server/manifest" "short_name" "VSCodium"
fi

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|VSCodium|' build/lib/electron.js
replace 's|Microsoft Corporation|VSCodium|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 VSCodium|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 VSCodium|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to vscodium
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/codium-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/codium/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|VSCodium|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/RubisetCie/vscodium#download-install|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|VSCodium Team https://github.com/VSCodium/vscodium/graphs/contributors|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|VSCodium|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/RubisetCie/vscodium#download-install|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|VSCodium Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|VSCodium Team https://github.com/VSCodium/vscodium/graphs/contributors|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|VSCodium|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/RubisetCie/vscodium#download-install|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|VSCodium|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|VSCodium|' build/win32/code.iss
fi

cd ..
