#!/usr/bin/env bash

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 5.1.3

# ----- COMMAND LINE ARGS

# Setup command args + data
SCRIPT="${BASH_SOURCE}"
OPTION=""
LATEST_SCRIPT_INFO=""
LATEST_RELEASE_DWLD=""

# ----- ENVIRONMENT

# Enable case-insensitive comparisons
shopt -s nocasematch

# Script binary
LOCAL_BIN="/usr/local/bin"
SCRIPT_BIN="${LOCAL_BIN}/purge-wrangler"
TMP_SCRIPT="${LOCAL_BIN}/purge-wrangler-new"
BIN_CALL=0
SCRIPT_FILE=""

# Script version
SCRIPT_MAJOR_VER="5" && SCRIPT_MINOR_VER="1" && SCRIPT_PATCH_VER="3"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"

# Script preference plist
PW_PLIST_ID="io.egpu.purge-wrangler"

# Preference options (0: Ask, 1: Always, 2: Never, 3: Undefined)
NVDA_WEB_INSTALLS=0
NVDA_WEB_INSTALLS_KEY="NVDAWebInstall"
NVDA_WEB_PATCH_INSTALLS=0
NVDA_WEB_PATCH_INSTALLS_KEY="NVDAWebPatchInstall"
AMD_LEGACY_INSTALLS=0
AMD_LEGACY_INSTALLS_KEY="AMDLegacyInstall"
TI82_INSTALLS=0
TI82_INSTALLS_KEY="TI82Install"
NVDA_WEB_UNINSTALLS=0
NVDA_WEB_UNINSTALLS_KEY="NVDAWebUninstall"

# Preference intermediate
PREF_RESULT=3

# User input
INPUT=""

# Text management
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"
UNDERLINE="$(tput smul)"

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
TB_VER_ERR=3
EXEC_ERR=4
UNKNOWN_SYSTEM_ERR=5

# System information
MACOS_VER="$(sw_vers -productVersion)"
MACOS_BUILD="$(sw_vers -buildVersion)"
SYS_TB_VER=""

# AppleGPUWrangler references
TB_SWITCH_HEX="494F5468756E646572626F6C74537769746368547970653"

# IOGraphicsFamily references
PCI_TUNNELLED_HEX="494F50434954756E6E656C6C6564"
PATCHED_PCI_TUNNELLED_HEX="494F50434954756E6E656C6C6571"

# IOThunderboltFamily references
SKIPNUM_HEX="554889E54157415641554154534881EC2801"
PATCHED_SKIPNUM_HEX="554889E531C05DC341554154534881EC2801"
BLOCK_HEX="554889E54157415641554154534881EC9801"
PATCHED_BLOCK_HEX="554889E531C05DC341554154534881EC9801"

# Patch status indicators
LEG_PATCH_STATUS=""
TB_PATCH_STATUS=""
NV_PATCH_STATUS=""
TI82_PATCH_STATUS=""

# System Discrete GPU
DGPU_VENDOR=""

# General kext paths
EXT_PATH="/System/Library/Extensions/"
TP_EXT_PATH="/Library/Extensions/"

## AppleGPUWrangler
AGC_PATH="${EXT_PATH}AppleGraphicsControl.kext"
SUB_AGW_PATH="/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler"
AGW_BIN="${AGC_PATH}${SUB_AGW_PATH}"

## IONDRVSupport
IONDRV_PATH="${EXT_PATH}IONDRVSupport.kext"
IONDRV_PLIST_PATH="${IONDRV_PATH}/Info.plist"

## IOGraphicsFamily
IOG_PATH="${EXT_PATH}IOGraphicsFamily.kext"
SUB_IOG_PATH="/IOGraphicsFamily"
IOG_BIN="${IOG_PATH}${SUB_IOG_PATH}"

## IOThunderboltFamily
IOT_FAM="${EXT_PATH}IOThunderboltFamily.kext"
SUB_IOT_PATH="/Contents/MacOS/IOThunderboltFamily"
IOT_BIN="${IOT_FAM}${SUB_IOT_PATH}"
DID_INSTALL_TI82=0

## NVDAStartup
NVDA_STARTUP_PATH="${EXT_PATH}NVDAStartup.kext"
NVDA_STARTUP_PLIST_PATH="${NVDA_STARTUP_PATH}/Contents/Info.plist"

## NVDAStartupWeb
NVDA_STARTUP_WEB_PATH="${TP_EXT_PATH}NVDAStartupWeb.kext"
NVDA_STARTUP_WEB_PLIST_PATH="${NVDA_STARTUP_WEB_PATH}/Contents/Info.plist"

## NVDAEGPUSupport
NVDA_EGPU_KEXT="${TP_EXT_PATH}NVDAEGPUSupport.kext"

## AMDLegacySupport
AUTOMATE_EGPU_KEXT="${TP_EXT_PATH}automate-eGPU.kext"
AMD_LEGACY_DL="http://raw.githubusercontent.com/mayankk2308/purge-wrangler/${SCRIPT_VER}/resources/AMDLegacySupport.kext.zip"
AMD_LEGACY_ZIP="${TP_EXT_PATH}AMDLegacySupport.kext.zip"
AMD_LEGACY_KEXT="${TP_EXT_PATH}AMDLegacySupport.kext"
DID_INSTALL_LEGACY_KEXT=0

# General backup path
SUPPORT_DIR="/Library/Application Support/Purge-Wrangler/"
BACKUP_KEXT_DIR="${SUPPORT_DIR}Kexts/"

## AppleGPUWrangler
BACKUP_AGC="${BACKUP_KEXT_DIR}AppleGraphicsControl.kext"
BACKUP_AGW_BIN="${BACKUP_AGC}${SUB_AGW_PATH}"

## IOGraphicsFamily
BACKUP_IOG="${BACKUP_KEXT_DIR}IOGraphicsFamily.kext"
BACKUP_IOG_BIN="${BACKUP_IOG}${SUB_IOG_PATH}"

## IOThunderboltFamily
BACKUP_IOT="${BACKUP_KEXT_DIR}IOThunderboltFamily.kext"
BACKUP_IOT_BIN="${BACKUP_IOT}${SUB_IOT_PATH}"

## IONDRVSupport
BACKUP_IONDRV="${BACKUP_KEXT_DIR}IONDRVSupport.kext"

## NVDAStartup
BACKUP_NVDA_STARTUP_PATH="${BACKUP_KEXT_DIR}NVDAStartup.kext"

## Manifest
MANIFEST="${SUPPORT_DIR}manifest.wglr"

# Hexfiles & binaries
SCRATCH_AGW_HEX=".AppleGPUWrangler.hex"
SCRATCH_AGW_BIN=".AppleGPUWrangler.bin"
SCRATCH_IOG_HEX=".IOGraphicsFamily.hex"
SCRATCH_IOG_BIN=".IOGraphicsFamily.bin"
SCRATCH_IOT_HEX=".IOThunderboltFamily.hex"
SCRATCH_IOT_BIN=".IOThunderboltFamily.bin"

# PlistBuddy configuration
PlistBuddy="/usr/libexec/PlistBuddy"
NDRV_PCI_TUN_CP=":IOKitPersonalities:3:IOPCITunnelCompatible bool"
NVDA_PCI_TUN_CP=":IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool"
NVDA_REQUIRED_OS=":IOKitPersonalities:NVDAStartup:NVDARequiredOS"

# Installation information
MANIFEST_MACOS_VER=""
MANIFEST_MACOS_BUILD=""

# Webdriver information
WEBDRIVER_PLIST="/usr/local/bin/webdriver.plist"
USING_WEB_DRV=0

# ----- SCRIPT SOFTWARE UPDATE SYSTEM

# Perform software update
perform_software_update() {
  echo -e "${BOLD}Downloading...${NORMAL}"
  curl -q -L -s -o "${TMP_SCRIPT}" "${LATEST_RELEASE_DWLD}"
  [[ "$(cat "${TMP_SCRIPT}")" == "Not Found" ]] && echo -e "Download failed.\n${BOLD}Continuing without updating...${NORMAL}" && sleep 1 && rm "${TMP_SCRIPT}" && return
  echo -e "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo -e "Update complete. ${BOLD}Relaunching...${NORMAL}"
  sleep 1
  "${SCRIPT}"
  exit 0
}

# Prompt for update
prompt_software_update() {
  echo
  read -n1 -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n${BOLD}Proceeding without updating...${NORMAL}" && sleep 1 && return
  echo -e "\nInvalid choice. Try again."
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${LOCAL_BIN}"
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -q -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest")"
  LATEST_RELEASE_VER="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo -e "\n>> ${BOLD}Software Update${NORMAL}\n\nSoftware updates are available.\n\nOn Your System    ${BOLD}${SCRIPT_VER}${NORMAL}\nLatest Available  ${BOLD}${LATEST_RELEASE_VER}${NORMAL}\n\nFor the best experience, stick to the latest release."
    prompt_software_update
  fi
}

# ----- SYSTEM CONFIGURATION MANAGER

# Create LaunchAgent
create_launchagent() {
  AGENT="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>io.egpu.purge-wrangler-agent</string>
    <key>OnDemand</key>
    <false/>
    <key>LaunchOnlyOnce</key>
    <true/>
    <key>UserName</key>
    <string>${SUDO_USER}</string>
    <key>RunAtLoad</key>
		<true/>
    <key>ProgramArguments</key>
    <array>
      <string>${SCRIPT_BIN}</string>
      <string>-1</string>
    </array>
</dict>
</plist>"
  AGENT_LOC="/Users/${SUDO_USER}/Library/LaunchAgents/"
  mkdir -p "${AGENT_LOC}"
  AGENT_PLIST="${AGENT_LOC}io.egpu.purge-wrangler-agent.plist"
  echo "${AGENT}" > "${AGENT_PLIST}"
  chown "${SUDO_USER}" "${AGENT_PLIST}"
}

# Write preferences
write_preferences() {
  PREF_RESULT=3
  defaults write "${PW_PLIST_ID}" "${NVDA_WEB_INSTALLS_KEY}" -int ${NVDA_WEB_INSTALLS} 2>/dev/null
  defaults write "${PW_PLIST_ID}" "${NVDA_WEB_PATCH_INSTALLS_KEY}" -int ${NVDA_WEB_PATCH_INSTALLS} 2>/dev/null
  defaults write "${PW_PLIST_ID}" "${NVDA_WEB_UNINSTALLS_KEY}" -int ${NVDA_WEB_UNINSTALLS} 2>/dev/null
  defaults write "${PW_PLIST_ID}" "${AMD_LEGACY_INSTALLS_KEY}" -int ${AMD_LEGACY_INSTALLS} 2>/dev/null
  defaults write "${PW_PLIST_ID}" "${TI82_INSTALLS_KEY}" -int ${TI82_INSTALLS} 2>/dev/null
}

# Read preferences
read_preferences() {
  NVDA_WEB_INSTALLS="$(defaults read "${PW_PLIST_ID}" "${NVDA_WEB_INSTALLS_KEY}" 2>/dev/null)"
  NVDA_WEB_PATCH_INSTALLS="$(defaults read "${PW_PLIST_ID}" "${NVDA_WEB_PATCH_INSTALLS_KEY}" 2>/dev/null)"
  NVDA_WEB_UNINSTALLS="$(defaults read "${PW_PLIST_ID}" "${NVDA_WEB_UNINSTALLS_KEY}" 2>/dev/null)"
  AMD_LEGACY_INSTALLS="$(defaults read "${PW_PLIST_ID}" "${AMD_LEGACY_INSTALLS_KEY}" 2>/dev/null)"
  TI82_INSTALLS="$(defaults read "${PW_PLIST_ID}" "${TI82_INSTALLS_KEY}" 2>/dev/null)"
  [[ -z "${NVDA_WEB_INSTALLS}" || (( ${NVDA_WEB_INSTALLS} < 0 )) ]] && NVDA_WEB_INSTALLS=3
  [[ -z "${NVDA_WEB_PATCH_INSTALLS}" || (( ${NVDA_WEB_PATCH_INSTALLS} < 0 )) ]] && NVDA_WEB_INSTALLS=3
  [[ -z "${NVDA_WEB_UNINSTALLS}" || (( ${NVDA_WEB_UNINSTALLS} < 0 )) ]] && NVDA_WEB_UNINSTALLS=3
  [[ -z "${AMD_LEGACY_INSTALLS}" || (( ${AMD_LEGACY_INSTALLS} < 0 )) ]] && AMD_LEGACY_INSTALLS=3
  [[ -z "${TI82_INSTALLS}" || (( ${TI82_INSTALLS} < 0 )) ]] && TI82_INSTALLS=3
}

# Read & prepare preferences
prepare_preferences() {
  PREF_DATA="$(defaults read "${PW_PLIST_ID}" 2>/dev/null)"
  [[ -z "${PREF_DATA}" ]] && write_preferences || read_preferences
}

# Check caller
validate_caller() {
  [[ "${1}" == "bash" && -z "${2}" ]] && echo -e "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit $EXEC_ERR
  [[ "${1}" != "${SCRIPT}" ]] && OPTION="${3}" || OPTION="${2}"
  [[ "${SCRIPT}" == "${SCRIPT_BIN}" || "${SCRIPT}" == "purge-wrangler" ]] && BIN_CALL=1
}

# Elevate privileges
elevate_privileges() {
  if [[ $(id -u) != 0 ]]
  then
    sudo bash "${SCRIPT}" "${OPTION}"
    exit
  fi
}

# System integrity protection check
check_sip() {
  [[ $(csrutil status | grep -i enabled) ]] && echo -e "\nPlease disable ${BOLD}System Integrity Protection${NORMAL}.\n" && exit $SIP_ON_ERR
}

# macOS Version check
check_macos_version() {
  MACOS_MAJOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo -e "\n${BOLD}macOS 10.13.4 or later${NORMAL} required.\n" && exit $MACOS_VER_ERR
}

# Ensure presence of system extensions
check_sys_extensions() {
  [[ ! -s "${AGC_PATH}" || ! -s "${AGW_BIN}" || ! -s "${IONDRV_PATH}" || ! -s "${IOG_BIN}" || ! -s "${IOT_FAM}" || ! -s "${IOT_BIN}" ]] && echo -e "\nSystem could be unbootable. Consider ${BOLD}macOS Recovery${NORMAL}.\n" && sleep 1
}

# Check if system volume is writable - attempt mount as writable
SYS_VOL_MOUNT_ATTEMPT=0
check_sys_volume() {
  if [[ ! -w "${EXT_PATH}" ]]
  then
    if [[ ${SYS_VOL_MOUNT_ATTEMPT} == 0 ]]
    then
      mount -uw / 2>/dev/null 1>&2
      SYS_VOL_MOUNT_ATTEMPT=1
      check_sys_volume
      return
    fi
    echo -e "\nYour system volume is ${BOLD}read-only${NORMAL}\n. PurgeWrangler cannot proceed."
    exit
  fi
}

# Retrieve thunderbolt version
retrieve_tb_ver() {
  TB_VER="$(ioreg | grep AppleThunderboltNHIType)"
  [[ "${TB_VER}[@]" =~ "NHIType3" ]] && SYS_TB_VER="${TB_SWITCH_HEX}"3 && return
  [[ "${TB_VER}[@]" =~ "NHIType2" ]] && SYS_TB_VER="${TB_SWITCH_HEX}"2 && return
  [[ "${TB_VER}[@]" =~ "NHIType1" ]] && SYS_TB_VER="${TB_SWITCH_HEX}"1 && return
  echo -e "\nUnsupported/Invalid version of Thunderbolt detected.\n" && exit $TB_VER_ERR
}

# Patch check
check_patch() {
  [[ ! -f "${AGW_BIN}" || ! -f "${IOG_BIN}" ]] && TB_PATCH_STATUS=2 && NV_PATCH_STATUS=2 && return
  AGW_HEX="$(hexdump -ve '1/1 "%.2X"' "${AGW_BIN}")"
  IOG_HEX="$(hexdump -ve '1/1 "%.2X"' "${IOG_BIN}")"
  IOT_HEX="$(hexdump -ve '1/1 "%.2X"' "${IOT_BIN}")"
  [[ -d "${AMD_LEGACY_KEXT}" ]] && LEG_PATCH_STATUS=1 || LEG_PATCH_STATUS=0
  [[ "${AGW_HEX}" =~ "${SYS_TB_VER}" && "${SYS_TB_VER}" != "${TB_SWITCH_HEX}"3 ]] && TB_PATCH_STATUS=1 || TB_PATCH_STATUS=0
  [[ "${IOG_HEX}" =~ "${PATCHED_PCI_TUNNELLED_HEX}" ]] && NV_PATCH_STATUS=1 || NV_PATCH_STATUS=0
  [[ "${IOT_HEX}" =~ "${PATCHED_SKIPNUM_HEX}" ]] && TI82_PATCH_STATUS=1 || TI82_PATCH_STATUS=0
}

# Patch status check
check_patch_status() {
  PATCH_STATUSES=("Disabled" "Enabled" "Unknown")
  echo -e "\n>> ${BOLD}System Status${NORMAL}\n"
  echo -e "${BOLD}Legacy AMD eGPUs${NORMAL}  ${PATCH_STATUSES[$LEG_PATCH_STATUS]} "
  echo -e "${BOLD}TB1/2 AMD eGPUs${NORMAL}   ${PATCH_STATUSES[$TB_PATCH_STATUS]}"
  echo -e "${BOLD}NVIDIA eGPUs${NORMAL}      ${PATCH_STATUSES[$NV_PATCH_STATUS]}"
  echo -e "${BOLD}Ti82 Devices${NORMAL}      ${PATCH_STATUSES[${TI82_PATCH_STATUS}]}\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_sys_volume
  prepare_preferences
  check_sys_extensions
  check_patch
  DID_INSTALL_LEGACY_KEXT=0
  DID_INSTALL_TI82=0
  USING_WEB_DRV=0
}

# ----- OS MANAGEMENT

# Sanitize system permissions and caches
sanitize_system() {
  echo -e "${BOLD}Sanitizing system...${NORMAL}"
  chmod -R 755 "${AGC_PATH}" "${IOG_PATH}" "${IONDRV_PATH}" "${NVDA_STARTUP_WEB_PATH}" "${NVDA_STARTUP_PATH}" "${AMD_LEGACY_KEXT}" "${IOT_FAM}" 1>/dev/null 2>&1
  chown -R root:wheel "${AGC_PATH}" "${IOG_PATH}" "${IONDRV_PATH}" "${NVDA_STARTUP_WEB_PATH}" "${NVDA_STARTUP_PATH}" "${AMD_LEGACY_KEXT}" "${IOT_FAM}" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  echo -e "System sanitized."
}

# ----- PATCHING SYSTEM

# Generic hex file generator for given binary -> given destination file
generate_hex() {
  TARGET_BIN="${1}"
  SCRATCH_HEX="${2}"
  hexdump -ve '1/1 "%.2X"' "${TARGET_BIN}" > "${SCRATCH_HEX}"
}

# Generic binary generator for given hex file -> given destination file
generate_new_bin() {
  SCRATCH_HEX="${1}"
  SCRATCH_BIN="${2}"
  TARGET_BIN="${3}"
  xxd -r -p "${SCRATCH_HEX}" "${SCRATCH_BIN}"
  rm "${TARGET_BIN}" "${SCRATCH_HEX}" && mv "${SCRATCH_BIN}" "${TARGET_BIN}"
}

# Primary patching mechanism
generic_patcher() {
  ORIGINAL="${1}"
  NEW="${2}"
  SCRATCH_HEX="${3}"
  sed -i "" -e "s/${ORIGINAL}/${NEW}/g" "${SCRATCH_HEX}"
}

# ----- BACKUP SYSTEM

# Write manifest file
write_manifest() {
  [[ ! -d "${SUPPORT_DIR}" ]] && return
  MANIFEST_STR=""
  if [[ -s "${BACKUP_AGC}" ]]
  then
    UNPATCHED_AGW_KEXT_SHA="$(shasum -a 512 -b "${BACKUP_AGW_BIN}" | awk '{ print $1 }')"
    PATCHED_AGW_KEXT_SHA="$(shasum -a 512 -b "${AGW_BIN}" | awk '{ print $1 }')"
    MANIFEST_STR="${UNPATCHED_AGW_KEXT_SHA}\n${PATCHED_AGW_KEXT_SHA}"
  fi
  MANIFEST_STR="${MANIFEST_STR}\n${MACOS_VER}\n${MACOS_BUILD}"
  if [[ -s "${BACKUP_IOG}" ]]
  then
    UNPATCHED_IOG_KEXT_SHA="$(shasum -a 512 -b "${BACKUP_IOG_BIN}" | awk '{ print $1 }')"
    PATCHED_IOG_KEXT_SHA="$(shasum -a 512 -b "${IOG_BIN}" | awk '{ print $1 }')"
    MANIFEST_STR="${MANIFEST_STR}\n${UNPATCHED_IOG_KEXT_SHA}\n${PATCHED_IOG_KEXT_SHA}"
  fi
  if [[ -s "${BACKUP_IOT}" ]]
  then
    UNPATCHED_IOT_KEXT_SHA="$(shasum -a 512 -b "${BACKUP_IOT_BIN}" | awk '{ print $1 }')"
    PATCHED_IOT_KEXT_SHA="$(shasum -a 512 -b "${IOT_BIN}" | awk '{ print $1 }')"
    MANIFEST_STR="${MANIFEST_STR}\n${UNPATCHED_IOT_KEXT_SHA}\n${PATCHED_IOT_KEXT_SHA}"
  fi
  check_patch
  MANIFEST_STR="${MANIFEST_STR}\n${TB_PATCH_STATUS}\n${TI82_PATCH_STATUS}\n${NV_PATCH_STATUS}"
  echo -e "${MANIFEST_STR}" > "${MANIFEST}"
}

# Primary procedure
execute_backup() {
  mkdir -p "${BACKUP_KEXT_DIR}"
  rsync -rt "${AGC_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${IOG_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${IONDRV_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${IOT_FAM}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${NVDA_STARTUP_PATH}" "${BACKUP_KEXT_DIR}"
}

# Backup procedure
backup_system() {
  echo -e "${BOLD}Backing up...${NORMAL}"
  if [[ -s "${BACKUP_AGC}" && -s "${MANIFEST}" ]]
  then
    MANIFEST_MACOS_VER="$(sed "3q;d" "${MANIFEST}")" && MANIFEST_MACOS_BUILD="$(sed "4q;d" "${MANIFEST}")"
    if [[ "${MANIFEST_MACOS_VER}" == "${MACOS_VER}" && "${MANIFEST_MACOS_BUILD}" == "${MACOS_BUILD}" ]]
    then
      if [[ ${TB_PATCH_STATUS} == 0 && ${NV_PATCH_STATUS} == 0 && ${TI82_PATCH_STATUS} == 0 ]]
      then
        execute_backup
        echo -e "Backup refreshed."
        write_manifest
        return
      fi
      echo -e "Backup already exists."
    else
      echo -e "\n${BOLD}Last Backup${NORMAL}: ${MANIFEST_MACOS_VER} ${BOLD}[${MANIFEST_MACOS_BUILD}]${NORMAL}"
      echo -e "${BOLD}Current System${NORMAL}: ${MACOS_VER} ${BOLD}[${MACOS_BUILD}]${NORMAL}\n"
      echo -e "${BOLD}Updating backup...${NORMAL}"
      if [[ ${TB_PATCH_STATUS} == 1 || ${NV_PATCH_STATUS} == 1 || ${TI82_PATCH_STATUS} == 1 ]]
      then
        echo -e "${BOLD}Uninstalling patch before backup update...${NORMAL}"
        uninstall
        echo -e "${BOLD}Re-running script...${NORMAL}" && sleep 1
        "${SCRIPT}" "${OPTION}"
        exit
      fi
      execute_backup
      echo -e "Update complete."
    fi
  else
    execute_backup
    echo -e "Backup complete."
  fi
}

# ----- CORE PATCHING SYSTEM

# Conclude patching sequence
end_patch() {
  sanitize_system
  write_manifest
  create_launchagent
  echo -e "${BOLD}Patch complete.\n\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# Patch specified plist
patch_plist() {
  TARGET_PLIST="${1}"
  COMMAND="${2}"
  KEY="${3}"
  VALUE="${4}"
  $PlistBuddy -c "${COMMAND} ${KEY} ${VALUE}" "${TARGET_PLIST}" 2>/dev/null
}

# Install AMDLegacySupport.kext
run_legacy_kext_installer() {
  echo -e "${BOLD}Downloading AMDLegacySupport...${NORMAL}"
  curl -q -L -s -o "${AMD_LEGACY_ZIP}" "${AMD_LEGACY_DL}"
  if [[ ! -e "${AMD_LEGACY_ZIP}" || ! -s "${AMD_LEGACY_ZIP}" || "$(cat "${AMD_LEGACY_ZIP}")" == "404: Not Found" ]]
  then
    echo -e "Could not download.\n\n${BOLD}Continuing remaining patches...${NORMAL}"
    rm -rf "${AMD_LEGACY_ZIP}" 2>/dev/null
    return
  fi
  echo -e "Download complete.\n${BOLD}Installing...${NORMAL}"
  [[ -d "${AMD_LEGACY_KEXT}" ]] && rm -r "${AMD_LEGACY_KEXT}"
  unzip -d "${TP_EXT_PATH}" "${AMD_LEGACY_ZIP}" 1>/dev/null 2>&1
  rm -r "${AMD_LEGACY_ZIP}" "${TP_EXT_PATH}/__MACOSX" 1>/dev/null 2>&1
  echo -e "Installation complete.\n\n${BOLD}Continuing...${NORMAL}"
  DID_INSTALL_LEGACY_KEXT=1
}

# Prompt AMDLegacySupport.kext install
install_legacy_kext() {
  [[ -d "${AMD_LEGACY_KEXT}" ]] && return
  echo -e "\nIt is possible to use legacy AMD GPUs if needed.\nLegacy AMD GPUs refer to eGPUs not sanctioned as ${BOLD}\"supported by Apple\"${NORMAL}.\n"
  if [[ ${AMD_LEGACY_INSTALLS} != 1 && ${AMD_LEGACY_INSTALLS} != 2 ]]
  then
    read -n1 -p "Enable ${BOLD}Legacy${NORMAL} AMD eGPUs? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "Y" ]] && echo && run_legacy_kext_installer && return
    [[ "${INPUT}" == "N" ]] && return
    echo -e "\nInvalid option.\n" && install_legacy_kext
  elif [[ ${AMD_LEGACY_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${BOLD}always${NORMAL} install legacy support.\n${BOLD}Proceeding...${NORMAL}\n"
    run_legacy_kext_installer
  else
    echo -e "Your preferences are set to ${BOLD}never${NORMAL} install legacy support.\n${BOLD}Proceeding...${NORMAL}\n"
  fi
}

# Patch for Ti82 support
patch_ti82() {
  echo "${BOLD}Enabling Ti82 support...${NORMAL}"
  generate_hex "${IOT_BIN}" "${SCRATCH_IOT_HEX}"
  generic_patcher "${SKIPNUM_HEX}" "${PATCHED_SKIPNUM_HEX}" "${SCRATCH_IOT_HEX}"
  generate_new_bin "${SCRATCH_IOT_HEX}" "${SCRATCH_IOT_BIN}" "${IOT_BIN}"
  echo -e "Ti82 support enabled.\n\n${BOLD}Continuing...${NORMAL}\n"
}

# Enable Ti82 independently
enable_ti82() {
  echo -e "\n>> ${BOLD}Ti82 Devices${NORMAL}\n"
  if [[ ${TI82_PATCH_STATUS} == 0 ]]
  then
    backup_system
    echo "${BOLD}Enabling...${NORMAL}"
    patch_ti82 1>/dev/null
    echo "Ti82 Enabled."
    end_patch
  else
    echo -e "Ti82 support is already enabled on this system.\n"
  fi
}

# Prompt for Ti82 patch
install_ti82() {
  [[ ${TI82_PATCH_STATUS} == 1 ]] && return
  echo -e "\nTo use certain TB3 eGPU enclosures that have ${BOLD}Ti82 controllers${NORMAL},\nit is necessary to patch macOS to allow them to mount properly.\n"
  if [[ ${TI82_INSTALLS} != 1 && ${TI82_INSTALLS} != 2 ]]
  then
    read -n1 -p "Enable ${BOLD}Ti82${NORMAL}? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "Y" ]] && echo && DID_INSTALL_TI82=1 && patch_ti82 && return
    [[ "${INPUT}" == "N" ]] && echo && return
    echo -e "\nInvalid option.\n" && install_ti82
  elif [[ ${TI82_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${BOLD}always${NORMAL} install Ti82 support.\n${BOLD}Proceeding...${NORMAL}\n"
    DID_INSTALL_TI82=1 && patch_ti82
  else
    echo -e "Your preferences are set to ${BOLD}never${NORMAL} install Ti82 support.\n${BOLD}Proceeding...${NORMAL}\n"
  fi
}

# Patch TB1/2 block
patch_tb() {
  echo -e "\n>> ${BOLD}AMD eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}"
  [[ -e "${AUTOMATE_EGPU_KEXT}" ]] && rm -r "${AUTOMATE_EGPU_KEXT}"
  [[ ${NV_PATCH_STATUS} == 1 ]] && echo -e "System has previously been patched for ${BOLD}NVIDIA eGPUs${NORMAL}.\nPlease uninstall before proceeding.\n" && return
  backup_system
  install_legacy_kext
  install_ti82
  if [[ "${SYS_TB_VER}" == "${TB_SWITCH_HEX}3" ]]
  then
    echo -e "No thunderbolt patch required for this Mac.\n"
    [[ ${DID_INSTALL_LEGACY_KEXT} == 1 || ${DID_INSTALL_TI82} == 1 ]] && end_patch
    return
  fi
  if [[ ${TB_PATCH_STATUS} == 1 ]]
  then
    echo -e "System has already been patched for ${BOLD}AMD eGPUs${NORMAL}.\n"
    [[ ${DID_INSTALL_LEGACY_KEXT} == 1 || ${DID_INSTALL_TI82} == 1 ]] && end_patch
    return
  fi
  echo -e "${BOLD}Patching components...${NORMAL}"
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  generic_patcher "${TB_SWITCH_HEX}"3 "${SYS_TB_VER}" "${SCRATCH_AGW_HEX}"
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  echo -e "Components patched."
  end_patch
}

# Download and install NVIDIA Web Drivers
install_web_drivers() {
  INSTALLER_PKG="/usr/local/NVDAInstall.pkg"
  INSTALLER_PKG_EXPANDED="/usr/local/NVDAInstall"
  DRIVER_VERSION="${1}"
  DOWNLOAD_URL="${2}"
  rm -r "${INSTALLER_PKG_EXPANDED}" "${INSTALLER_PKG}" 2>/dev/null 1>&2
  echo -e "Data retrieved.\n${BOLD}Downloading drivers (${DRIVER_VERSION})...${NORMAL}"
  curl -q --connect-timeout 15 --progress-bar -o "${INSTALLER_PKG}" "${DOWNLOAD_URL}"
  if [[ ! -s "${INSTALLER_PKG}" ]]
  then
    rm -r "${INSTALLER_PKG}" 2>/dev/null 1>&2
    echo "Unable to download."
    return
  fi
  echo -e "Download complete.\n${BOLD}Sanitizing package...${NORMAL}"
  pkgutil --expand-full "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}"
  sed -i "" -e "/installation-check/d" "${INSTALLER_PKG_EXPANDED}/Distribution"
  NVDA_STARTUP_PKG_KEXT="$(find "${INSTALLER_PKG_EXPANDED}" -maxdepth 1 | grep -i NVWebDrivers)/Payload/Library/Extensions/NVDAStartupWeb.kext"
  if [[ ! -d "${NVDA_STARTUP_PKG_KEXT}" ]]
  then
    rm -r "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}" 2>/dev/null 1>&2
    echo "Unable to patch driver."
    return
  fi
  $PlistBuddy -c "Set ${NVDA_REQUIRED_OS} \"${MACOS_BUILD}\"" "${NVDA_STARTUP_PKG_KEXT}/Contents/Info.plist" 2>/dev/null 1>&2
  chown -R root:wheel "${NVDA_STARTUP_PKG_KEXT}"
  rm -r "${INSTALLER_PKG}"
  pkgutil --flatten-full "${INSTALLER_PKG_EXPANDED}" "${INSTALLER_PKG}" 2>/dev/null 1>&2
  echo -e "Package sanitized.\n${BOLD}Installing...${NORMAL}"
  INSTALLER_ERR="$(installer -target "/" -pkg "${INSTALLER_PKG}" 2>&1 1>/dev/null)"
  [[ -z "${INSTALLER_ERR}" ]] && echo -e "Installation complete.\n" || echo -e "Installation failed."
  rm -r "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}"
  rm "${WEBDRIVER_PLIST}"
}

# Run Webdriver installation procedure
run_webdriver_installer() {
  echo -e "${BOLD}Fetching webdriver information...${NORMAL}"
  WEBDRIVER_DATA="$(curl -q -s "https://gfe.nvidia.com/mac-update")"
  [[ -z "${WEBDRIVER_DATA}" ]] && echo -e "Could not install web drivers." && return
  echo -e "${WEBDRIVER_DATA}" > "${WEBDRIVER_PLIST}"
  [[ ! -f "${WEBDRIVER_PLIST}" ]] && echo -e "Could not extract web driver information." && return
  INDEX=0
  DRIVER_MACOS_BUILD="${MACOS_BUILD}"
  LATEST_DRIVER_MACOS_BUILD=""
  DRIVER_DL=""
  LATEST_DRIVER_DL=""
  DRIVER_VER=""
  LATEST_DRIVER_VER=""
  while [[ ! -z "${DRIVER_MACOS_BUILD}" ]]
  do
    DRIVER_DL="$($PlistBuddy -c "Print :updates:${INDEX}:downloadURL" "${WEBDRIVER_PLIST}" 2>/dev/null)"
    DRIVER_VER="$($PlistBuddy -c "Print :updates:${INDEX}:version" "${WEBDRIVER_PLIST}" 2>/dev/null)"
    DRIVER_MACOS_BUILD="$($PlistBuddy -c "Print :updates:${INDEX}:OS" "${WEBDRIVER_PLIST}" 2>/dev/null)"
    if [[ ${INDEX} == 0 ]]
    then
      LATEST_DRIVER_DL="${DRIVER_DL}"
      LATEST_DRIVER_VER="${DRIVER_VER}"
      LATEST_DRIVER_MACOS_BUILD="${DRIVER_MACOS_BUILD}"
    fi
    [[ "${DRIVER_MACOS_BUILD}" == "${MACOS_BUILD}" ]] && break
    (( INDEX++ ))
  done
  if [[ (-z "${DRIVER_DL}" || -z "${DRIVER_VER}") ]]
  then
    [[ ${NVDA_WEB_PATCH_INSTALLS} == 2 ]] && echo -e "\nNo web driver available for your system at this time.\nYour preference ${BOLD}disables${NORMAL} web driver patching." && return
    echo -e "Latest Available Driver: ${BOLD}${LATEST_DRIVER_MACOS_BUILD}${NORMAL}\nYour macOS Build: ${BOLD}${MACOS_BUILD}${NORMAL}\n"
    DRIVER_MAJOR_BUILD="${LATEST_DRIVER_MACOS_BUILD:0:2}"
    MACOS_MAJOR_BUILD="${MACOS_BUILD:0:2}"
    if (( ${DRIVER_MAJOR_BUILD} - ${MACOS_MAJOR_BUILD} != 0 ))
    then
      echo -e "${BOLD}Recommendation${NORMAL}: Major OS version discrepancy detected.\n\t\tPatching ${BOLD}not recommended${NORMAL}.\n"
    else
      echo -e "${BOLD}Recommendation${NORMAL}: Minor OS version discrepancy detected.\n\t\tPatching ${BOLD}may be safe${NORMAL}.\n"
    fi
    INPUT=""
    if [[ ${NVDA_WEB_PATCH_INSTALLS} != 1 ]]
    then
      read -n1 -p "Patch ${BOLD}Web Drivers${NORMAL} (${BOLD}${LATEST_DRIVER_MACOS_BUILD}${NORMAL} -> ${BOLD}${MACOS_BUILD}${NORMAL})? [Y/N]: " INPUT
      echo
      [[ "${INPUT}" == "N" ]] && echo -e "\nInstallation ${BOLD}aborted${NORMAL}.\n" && rm "${WEBDRIVER_PLIST}" 2>/dev/null && return
      [[ "${INPUT}" == "Y" ]] && echo -e "\n${BOLD}Proceeding...${NORMAL}" && install_web_drivers "${LATEST_DRIVER_VER}" "${LATEST_DRIVER_DL}" && return
      echo -e "\nInvalid option. Installation ${BOLD}aborted${NORMAL}.\n" && return
    else
      echo -e "Your preference is set to ${BOLD}always${NORMAL} patch web drivers.\n${BOLD}Proceeding...${NORMAL}\n"
      sleep 1
      install_web_drivers "${LATEST_DRIVER_VER}" "${LATEST_DRIVER_DL}"
      return
    fi
  fi
  install_web_drivers "${DRIVER_VER}" "${DRIVER_DL}"
}

# Prompt NVIDIA Web Driver installation
prompt_web_driver_install() {
  if [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]]
  then
    if [[ "$(${PlistBuddy} -c "Print ${NVDA_REQUIRED_OS}" "${NVDA_STARTUP_WEB_PLIST_PATH}" 2>/dev/null)" != "${MACOS_BUILD}" ]]
    then
      echo -e "\nInstalled ${BOLD}NVIDIA Web Drivers${NORMAL} are specifying incorrect macOS build.\n"
      read -n1 -p "${BOLD}Rectify${NORMAL}? [Y/N]: " INPUT
      echo
      if [[ "${INPUT}" != "Y" ]]
      then
        echo -e "\nDrivers unchanged.\n"
      else
        echo -e "\n${BOLD}Patching drivers...${NORMAL}"
        $PlistBuddy -c "Set ${NVDA_REQUIRED_OS} \"${MACOS_BUILD}\"" "${NVDA_STARTUP_WEB_PLIST_PATH}" 2>/dev/null 1>&2
        echo -e "Drivers patched.\n"
      fi
    else
      echo -e "\nAppropriate NVIDIA Web Drivers are ${BOLD}already installed${NORMAL}.\n"
    fi
    USING_WEB_DRV=1
    return
  fi
  echo -e "\n${BOLD}NVIDIA Web Drivers${NORMAL} are required for ${BOLD}NVIDIA 9xx${NORMAL} GPUs or newer.\nIf you are using an older macOS-supported NVIDIA GPU,\nweb drivers are not needed.\n"
  if [[ ${NVDA_WEB_INSTALLS} != 1 && ${NVDA_WEB_INSTALLS} != 2 ]]
  then
    read -n1 -p "Install ${BOLD}NVIDIA Web Drivers${NORMAL}? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "Y" ]] && USING_WEB_DRV=1 && echo && run_webdriver_installer && return
    [[ "${INPUT}" == "N" ]] && echo && return
    echo -e "\nInvalid option." && prompt_web_driver_install
  elif [[ ${NVDA_WEB_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${BOLD}always${NORMAL} install web drivers.\n${BOLD}Proceeding...${NORMAL}"
    sleep 1
    USING_WEB_DRV=1 && echo && run_webdriver_installer && return
  else
    echo -e "Your preferences are set to ${BOLD}never${NORMAL} install web drivers.\nProceeding with ${BOLD}native macOS drivers${NORMAL}...\n"
    sleep 1
    return
  fi
}

# Patch for NVIDIA eGPUs
patch_nv() {
  echo -e "\n>> ${BOLD}NVIDIA eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}\n"
  [[ ${NV_PATCH_STATUS} == 1 ]] && echo -e "System has already been patched for ${BOLD}NVIDIA eGPUs${NORMAL}.\n" && return
  [[ ${TB_PATCH_STATUS} == 1 || ${LEG_PATCH_STATUS} == 1 ]] && echo -e "System has previously been patched for ${BOLD}AMD eGPUs${NORMAL}.\nPlease uninstall before proceeding.\n" && return
  backup_system
  prompt_web_driver_install
  [[ ${USING_WEB_DRV} == 1 && ! -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]] && echo -e "${BOLD}NVIDIA Web Drivers${NORMAL} requested, but not installed.\n" && return
  echo -e "${BOLD}Continuing patch...${NORMAL}\n"
  if [[ ${USING_WEB_DRV} == 1 ]]
  then
    nvram nvda_drv=1
    NVDA_STARTUP_PLIST_TO_PATCH="${NVDA_STARTUP_WEB_PLIST_PATH}"
  else
    nvram -d nvda_drv 2>/dev/null
    NVDA_STARTUP_PLIST_TO_PATCH="${NVDA_STARTUP_PLIST_PATH}"
  fi
  echo -e "${BOLD}Patching components...${NORMAL}"
  install_ti82
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
  if [[ ! -e "${SCRATCH_AGW_HEX}" || ! -e "${SCRATCH_IOG_HEX}" ]]
  then
    echo -e "Unable to patch. Use ${BOLD}System Recovery${NORMAL} and retry."
    return
  fi
  generic_patcher "${PCI_TUNNELLED_HEX}" "${PATCHED_PCI_TUNNELLED_HEX}" "${SCRATCH_AGW_HEX}"
  generic_patcher "${PCI_TUNNELLED_HEX}" "${PATCHED_PCI_TUNNELLED_HEX}" "${SCRATCH_IOG_HEX}"
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  generate_new_bin "${SCRATCH_IOG_HEX}" "${SCRATCH_IOG_BIN}" "${IOG_BIN}"
  patch_plist "${IONDRV_PLIST_PATH}" "Add" "${NDRV_PCI_TUN_CP}" "true"
  patch_plist "${NVDA_STARTUP_PLIST_TO_PATCH}" "Add" "${NVDA_PCI_TUN_CP}" "true"
  [[ -e "${AUTOMATE_EGPU_KEXT}" ]] && rm -r "${AUTOMATE_EGPU_KEXT}"
  [[ -d "${NVDA_EGPU_KEXT}" ]] && echo -e "${BOLD}NVDAEGPUSupport.kext${NORMAL} detected. ${BOLD}Removing...${NORMAL}" && rm -r "${NVDA_EGPU_KEXT}" && echo -e "Removal complete."
  echo -e "Components patched."
  end_patch
}

# Run webdriver uninstallation process
run_webdriver_uninstaller() {
  echo -e "\n${BOLD}Uninstalling drivers...${NORMAL}"
  nvram -d nvda_drv
  WEBDRIVER_UNINSTALLER="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
  [[ ! -s "${WEBDRIVER_UNINSTALLER}" ]] && echo -e "Could not find NVIDIA uninstaller.\n" && return
  installer -target "/" -pkg "${WEBDRIVER_UNINSTALLER}" 2>&1 1>/dev/null
  echo -e "Drivers uninstalled.\nIf in ${BOLD}Single User Mode${NORMAL}, only driver selection changed.\n" && return
}

# Remove NVIDIA Web Drivers
remove_web_drivers() {
  [[ ! -e "${NVDA_STARTUP_WEB_PATH}" ]] && return
  echo
  if [[ ${NVDA_WEB_UNINSTALLS} != 1 && ${NVDA_WEB_UNINSTALLS} != 2 ]]
  then
    read -n1 -p "Remove ${BOLD}NVIDIA Web Drivers${NORMAL}? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "Y" ]] && run_webdriver_uninstaller && return
    [[ "${INPUT}" == "N" ]] && echo && return
    echo -e "\nInvalid option." && remove_web_drivers
  elif [[ ${NVDA_WEB_UNINSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${BOLD}always${NORMAL} uninstall web drivers.\n${BOLD}Proceeding...${NORMAL}"
    run_webdriver_uninstaller
  else
    echo -e "Your preferences are set to ${BOLD}never${NORMAL} uninstall web drivers.\n${BOLD}No action taken.${NORMAL}\n"
  fi
}

# Uninstall Ti82
uninstall_ti82() {
  [[ ${TI82_PATCH_STATUS} == 0 ]] && return
  echo -e "${BOLD}Removing Ti82 support...${NORMAL}"
  generate_hex "${IOT_BIN}" "${SCRATCH_IOT_HEX}"
  generic_patcher "${PATCHED_SKIPNUM_HEX}" "${SKIPNUM_HEX}" "${SCRATCH_IOT_HEX}"
  generate_new_bin "${SCRATCH_IOT_HEX}" "${SCRATCH_IOT_BIN}" "${IOT_BIN}"
  echo -e "Ti82 support disabled."
}

# In-place re-patcher
uninstall() {
  echo -e "\n>> ${BOLD}Uninstall${NORMAL}\n"
  [[ ${LEG_PATCH_STATUS} == 0 && ${TB_PATCH_STATUS} == 0 && ${NV_PATCH_STATUS} == 0 && ${TI82_PATCH_STATUS} == 0 && ! -e "${NVDA_STARTUP_WEB_PATH}" ]] && echo -e "No patches detected.\nSystem already clean.\n" && return
  echo -e "${BOLD}Uninstalling...${NORMAL}"
  if [[ -d "${AMD_LEGACY_KEXT}" ]]
  then
    echo -e "${BOLD}Removing legacy support...${NORMAL}"
    rm -r "${AMD_LEGACY_KEXT}"
    echo -e "Removal successful."
  fi
  remove_web_drivers
  uninstall_ti82
  echo -e "${BOLD}Reverting binaries...${NORMAL}"
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  if [[ ! -e "${SCRATCH_AGW_HEX}" ]]
  then
    echo -e "Unable to uninstall. Use ${BOLD}System Recovery${NORMAL}."
    return
  fi
  [[ ${TB_PATCH_STATUS} == 1 ]] && generic_patcher "${SYS_TB_VER}" "${TB_SWITCH_HEX}"3 "${SCRATCH_AGW_HEX}"
  if [[ ${NV_PATCH_STATUS} == 1 ]]
  then
    generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
    if [[ ! -e "${SCRATCH_IOG_HEX}" ]]
    then
      echo -e "Unable to uninstall. Use ${BOLD}System Recovery${NORMAL}."
      return
    fi
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_IOG_HEX}"
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_AGW_HEX}"
    [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" && "$(cat "${NVDA_STARTUP_WEB_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_WEB_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    [[ "$(cat "${NVDA_STARTUP_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    generate_new_bin "${SCRATCH_IOG_HEX}" "${SCRATCH_IOG_BIN}" "${IOG_BIN}"
    [[ "$(cat "${IONDRV_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${IONDRV_PLIST_PATH}" "Delete" "${NDRV_PCI_TUN_CP}"
  fi
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  echo -e "Binaries reverted."
  write_manifest
  sanitize_system
  echo -e "Uninstallation Complete.\n\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# ----- BINARY MANAGER

# Bin management procedure
install_bin() {
  rsync "${SCRIPT_FILE}" "${SCRIPT_BIN}"
  chown "${SUDO_USER}" "${SCRIPT_BIN}"
  chmod 700 "${SCRIPT_BIN}" && chmod a+x "${SCRIPT_BIN}"
}

# Bin first-time setup
first_time_setup() {
  [[ $BIN_CALL == 1 ]] && return
  SCRIPT_FILE="$(pwd)/$(echo -e "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo -e "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA="$(shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo -e "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo -e "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
}

# ----- RECOVERY SYSTEM

# Recovery logic
recover_sys() {
  echo -e "\n>> ${BOLD}Recovery${NORMAL}\n\n${BOLD}Recovering...${NORMAL}"
  if [[ -d "${AMD_LEGACY_KEXT}" ]]
  then
    echo -e "${BOLD}Removing legacy support...${NORMAL}"
    rm -r "${AMD_LEGACY_KEXT}"
    echo -e "Removal successful."
  fi
  [[ ! -e "$MANIFEST" ]] && echo -e "Nothing to recover.\n\nConsider ${BOLD}system recovery${NORMAL} or ${BOLD}rebooting${NORMAL}.\n" && return
  MANIFEST_MACOS_VER="$(sed "3q;d" "${MANIFEST}")" && MANIFEST_MACOS_BUILD="$(sed "4q;d" "${MANIFEST}")"
  if [[ "${MANIFEST_MACOS_VER}" != "${MACOS_VER}" || "${MANIFEST_MACOS_BUILD}" != "${MACOS_BUILD}" ]]
  then
    echo -e "\n${BOLD}Last Backup${NORMAL}: ${MANIFEST_MACOS_VER} ${BOLD}[${MANIFEST_MACOS_BUILD}]${NORMAL}"
    echo -e "${BOLD}Current System${NORMAL}: ${MACOS_VER} ${BOLD}[${MACOS_BUILD}]${NORMAL}\n"
    read -n1 -p "System may already be clean. Still ${BOLD}attempt recovery${NORMAL}? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "N" ]] && echo -e "Recovery ${BOLD}cancelled${NORMAL}.\n" && return
    [[ "${INPUT}" != "Y" ]] && echo -e "Invalid choice. Recovery ${BOLD}safely aborted${NORMAL}.\n" && return
    echo -e "\n${BOLD}Attempting recovery...${NORMAL}"
  fi
  echo -e "${BOLD}Restoring system...${NORMAL}"
  [[ -d "${BACKUP_KEXT_DIR}" ]] && rsync -rt "${BACKUP_KEXT_DIR}"* "${EXT_PATH}"
  [[ "$(cat "${NVDA_STARTUP_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
  if [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]]
  then
    [[ "$(cat "${NVDA_STARTUP_WEB_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_WEB_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    remove_web_drivers
  fi
  echo -e "System restored."
  write_manifest
  sanitize_system
  echo -e "Recovery complete.\n\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n\nRefer to the ${BOLD}macOS eGPU Troubleshooting Guide${NORMAL} in the ${BOLD}How-To's${NORMAL}\nsection of ${UNDERLINE}egpu.io${NORMAL} for further troubleshooting if needed.\n"
}

# ----- ANOMALY MANAGER

# Detect discrete GPU vendor
detect_discrete_gpu_vendor() {
  DGPU_VENDOR="$(ioreg -n GFX0@0 | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4)"
  if [[ "${DGPU_VENDOR}" == "de10" ]]
  then
    DGPU_VENDOR="NVIDIA"
  elif [[ "${DGPU_VENDOR}" == "0210" ]]
  then
    DGPU_VENDOR="AMD"
  else
    DGPU_VENDOR="None"
  fi
}

# Anomaly detection
detect_anomalies() {
  echo -e "\n>> ${BOLD}Anomaly Detection${NORMAL}\n"
  detect_discrete_gpu_vendor
  echo -e "Anomaly Detection will check your system to ${BOLD}find\npotential hiccups${NORMAL} based on the applied system patches.\n\nPatches made from scripts such as ${BOLD}purge-nvda.sh${NORMAL}\nare not detected at this time."
  echo -e "\n${BOLD}Discrete GPU${NORMAL}: ${DGPU_VENDOR}\n"
  if [[ "${DGPU_VENDOR}" == "NVIDIA" ]]
  then
    if [[ ${NV_PATCH_STATUS} == 1 && -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]]
    then
      echo -e "${BOLD}Problem${NORMAL}     Loss of OpenCL/GL on all NVIDIA GPUs."
      echo -e "${BOLD}Resolution${NORMAL}  Apply patches using ${BOLD}purge-nvda.sh${NORMAL}."
      echo -e "\t    This issue cannot be resolved on iMacs.\n"
    elif [[ ${TB_PATCH_STATUS} == 1 ]]
    then
      echo -e "${BOLD}Problem${NORMAL}     Black screens on monitors connected to eGPU."
      echo -e "${BOLD}Resolution${NORMAL}  Apply patches using ${BOLD}purge-nvda.sh${NORMAL}."
      echo -e "\t    This issue cannot be resolved on iMacs.\n"
    else
      echo -e "No expected anomalies with current configuration.\n"
    fi
  elif [[ "${DGPU_VENDOR}" == "AMD" ]]
  then
    if [[ ${NV_PATCH_STATUS} == 1 ]]
    then
      echo -e "${BOLD}Problem${NORMAL}     Black screens/slow performance with eGPU."
      echo -e "${BOLD}Resolution${NORMAL}  Disable then re-enable automatic graphics switching,"
      echo -e "\t    hot-plug eGPU, then log out and log in."
      echo -e "\t    This issue, if encountered, might only be resolved with\n\t    trial-error or using more advanced mux-based workarounds.\n"
    elif [[ ${TB_PATCH_STATUS} == 1 ]]
    then
      echo -e "No expected anomalies for your system.\n"
    else
      echo -e "No expected anomalies with current configuration.\n"
    fi
  else
    echo -e "No expected anomalies with current configuration.\n"
  fi
}

# ----- USER INTERFACE

# Request donation
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest"
  echo -e "\nSee your ${BOLD}web browser${NORMAL}.\n"
}

# Show update prompt
show_update_prompt() {
  check_patch
  [[ ! -e "${MANIFEST}" ]] && sleep 10 && return
  MANIFEST_MACOS_VER="$(sed "3q;d" "${MANIFEST}")" && MANIFEST_MACOS_BUILD="$(sed "4q;d" "${MANIFEST}")"
  MANIFEST_PATCH="$(sed -n "9,11p" "${MANIFEST}")"
  [[ ${TB_PATCH_STATUS} == 1 || ${NV_PATCH_STATUS} == 1 || ${TI82_PATCH_STATUS} == 1 || ("${MANIFEST_MACOS_VER}" == "${MACOS_VER}" && "${MANIFEST_MACOS_BUILD}" == "${MACOS_BUILD}") || ! ("${MANIFEST_PATCH}" =~ "1") ]] && sleep 10 && return
  osascript -e '
  set theDialogText to "PurgeWrangler patches have been disabled because macOS was updated.\n\nChoosing \"Never\" will not remind you until you re-apply the patches manually and the same situation arises.\n\nRe-apply patches to restore eGPU functionality?"
  set outcome to (display dialog theDialogText buttons {"Never", "Later", "Apply"} default button "Apply" cancel button "Later" with icon caution)
  if (outcome = {button returned:"Apply"}) then
	   tell application "Terminal"
		   activate
		     do script "purge-wrangler"
	    end tell
  else if (outcome = {button returned:"Never"}) then
    do shell script "rm ~/Library/LaunchAgents/io.egpu.purge-wrangler-agent.plist"
  end if' 2>/dev/null 1>&2
  sleep 10
}

# Present preference menu
present_pref() {
  clear
  MENU_TITLE="${1}"
  echo -e "\n>> ${BOLD}${MENU_TITLE}${NORMAL}"
  echo "
  ${BOLD}1.${NORMAL} Ask
  ${BOLD}2.${NORMAL} Always (Yes)
  ${BOLD}3.${NORMAL} Never (No)

  ${BOLD}0.${NORMAL} Cancel
  "
  read -n1 -p "${BOLD}Preference${NORMAL} [0-3]: " INPUT
  echo
  if [[ (( ${INPUT} < 0 )) || (( ${INPUT} > 3 )) ]]
  then
    echo -e "\nInvalid choice. Please try again."
    sleep 1
    manage_pw_preferences
    return
  fi
  echo
  [[ ${INPUT} == 0 ]] && return
  echo -e "Preference updated.\n"
  PREF_RESULT=$(( ${INPUT} - 1 ))
  (( ${PREF_RESULT} < 0 )) && PREF_RESULT=3
  sleep 1
}

# Manage specific preferences
manage_pw_preference() {
  CHOICE=${1}
  if [[ (( ${CHOICE} < 0 )) || (( ${INPUT} > 5 )) ]]
  then
    echo -e "\nInvalid choice. Please try again."
    sleep 1
    manage_pw_preferences
    return
  fi
  case ${CHOICE} in
    1)
    present_pref "AMD Legacy Support"
    (( ${PREF_RESULT} < 3 && ${PREF_RESULT} >= 0 )) && AMD_LEGACY_INSTALLS=${PREF_RESULT};;
    2)
    present_pref "Web Driver Installations"
    (( ${PREF_RESULT} < 3 && ${PREF_RESULT} >= 0 )) && NVDA_WEB_INSTALLS=${PREF_RESULT};;
    3)
    present_pref "Web Driver Version Patching"
    (( ${PREF_RESULT} < 3 && ${PREF_RESULT} >= 0 )) && NVDA_WEB_PATCH_INSTALLS=${PREF_RESULT};;
    4)
    present_pref "Web Driver Uninstallations"
    (( ${PREF_RESULT} < 3 && ${PREF_RESULT} >= 0 )) && NVDA_WEB_UNINSTALLS=${PREF_RESULT};;
    5)
    present_pref "TI82 Patching"
    (( ${PREF_RESULT} < 3 && ${PREF_RESULT} >= 0 )) && TI82_INSTALLS=${PREF_RESULT};;
    0)
    echo && return;;
  esac
  write_preferences
  manage_pw_preferences
}

# Manage prompt preferences
manage_pw_preferences() {
  clear
  read_preferences
  PREFS=("Ask" "Always" "Never" "Undefined")
  echo -e "\n>> ${BOLD}Preferences${NORMAL}"
  echo -e "
  ${BOLD}1.${NORMAL} AMD Legacy Support: ${BOLD}${PREFS[${AMD_LEGACY_INSTALLS}]}${NORMAL}
  ${BOLD}2.${NORMAL} Web Driver Installations: ${BOLD}${PREFS[${NVDA_WEB_INSTALLS}]}${NORMAL}
  ${BOLD}3.${NORMAL} Web Driver Version Patching: ${BOLD}${PREFS[${NVDA_WEB_PATCH_INSTALLS}]}${NORMAL}
  ${BOLD}4.${NORMAL} Web Driver Uninstallations: ${BOLD}${PREFS[${NVDA_WEB_UNINSTALLS}]}${NORMAL}
  ${BOLD}5.${NORMAL} TI82 Patching: ${BOLD}${PREFS[${TI82_INSTALLS}]}${NORMAL}

  ${BOLD}0.${NORMAL} Cancel

  Setting a preference for the above options will allow you to
  forego the ${BOLD}Y/N${NORMAL} questions relative to your setup.

  This feature will behave oddly if you have booted into Single User Mode.
  Avoid changing settings in that case.

  Choose an option to change your preference.\n"
  read -n1 -p "${BOLD}Modify${NORMAL} [0-5]: " INPUT
  echo
  manage_pw_preference ${INPUT}
}

# Ask for main menu
ask_menu() {
  read -n1 -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && perform_sys_check && clear && echo -e "\n>> ${BOLD}PurgeWrangler (${SCRIPT_VER})${NORMAL}" && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo -e "
   >> ${BOLD}eGPU Support${NORMAL}         >> ${BOLD}More Options${NORMAL}
   ${BOLD}1.${NORMAL}  AMD eGPUs           ${BOLD}6.${NORMAL}  Ti82 Devices
   ${BOLD}2.${NORMAL}  NVIDIA eGPUs        ${BOLD}7.${NORMAL}  NVIDIA Web Drivers
   ${BOLD}3.${NORMAL}  Uninstall           ${BOLD}8.${NORMAL}  Anomaly Detection
   ${BOLD}4.${NORMAL}  Recovery            ${BOLD}9.${NORMAL}  Script Preferences
   ${BOLD}5.${NORMAL}  Status              ${BOLD}D.${NORMAL}  Donate

   ${BOLD}0.${NORMAL}  Quit
  "
  read -n1 -p "${BOLD}What next?${NORMAL} [0-9|D]: " INPUT
  echo
  if [[ ! -z "${INPUT}" ]]
  then
    process_args "${INPUT}"
  else
    echo && exit
  fi
  ask_menu
}

# Process user input
process_args() {
  case "${1}" in
    -ea|--enable-amd|1)
    patch_tb;;
    -en|--enable-nv|2)
    patch_nv;;
    -u|--uninstall|3)
    uninstall;;
    -r|--recover|4)
    recover_sys;;
    -s|--status|5)
    check_patch_status;;
    -t8|--ti82|6)
    enable_ti82;;
    -nw|--nvidia-web|7)
    echo -e "\n>> ${BOLD}NVIDIA Web Drivers${NORMAL}"
    prompt_web_driver_install;;
    -a|--anomaly-detect|8)
    detect_anomalies;;
    -p|--prefs|9)
    manage_pw_preferences;;
    -d|--donate|D|d)
    donate;;
    0)
    echo && exit;;
    "")
    fetch_latest_release
    first_time_setup
    clear && echo -e ">> ${BOLD}PurgeWrangler (${SCRIPT_VER})${NORMAL}"
    provide_menu_selection;;
    *)
    echo -e "\nInvalid option.\n";;
  esac
}

# ----- SCRIPT DRIVER

# Primary execution routine
begin() {
  [[ "${2}" == "-1" ]] && show_update_prompt && return
  validate_caller "${1}" "${2}"
  perform_sys_check
  process_args "${2}"
}

begin "${0}" "${1}"