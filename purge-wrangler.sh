#!/usr/bin/env bash

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 4.2.2

# Invaluable Contributors
# ----- TB1/2 Patch
#       - AppleGPUWrangler Thunderbolt
#       © @mac_editor (+ @fricorico) at egpu.io
# ----- Legacy AMD GPUs
#       - automate-eGPU.kext -> AMDLegacySupport.kext
#       - Updated & Simplified to AMDLegacySupport @mac_editor
#       © @goalque at egpu.io
# ----- New NVIDIA eGPU Patch
#       - AppleGPUWrangler Discrete
#       - IOGraphicsFamily
#       © @goalque at egpu.io
# ----- TB Detection
#       @owenrw at egpu.io
# ----- Testing
#       @itsage for most up-to-date releases, at egpu.io
#       @techyowl for early versions, at egpu.io

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
SCRIPT_MAJOR_VER="4" && SCRIPT_MINOR_VER="2" && SCRIPT_PATCH_VER="2"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"

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

# Patch status indicators
AMD_PATCH_STATUS=""
NV_PATCH_STATUS=""

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
  curl -L -s -o "${TMP_SCRIPT}" "${LATEST_RELEASE_DWLD}"
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
  read -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n${BOLD}Proceeding without updating...${NORMAL}" && sleep 1 && return
  echo -e "\nInvalid choice. Try again."
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${LOCAL_BIN}"
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest")"
  LATEST_RELEASE_VER="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo -e "\n>> ${BOLD}Software Update${NORMAL}\n\nA script update (${BOLD}${LATEST_RELEASE_VER}${NORMAL}) is available.\nYou are currently on ${BOLD}${SCRIPT_VER}${NORMAL}."
    prompt_software_update
  fi
}

# ----- SYSTEM CONFIGURATION MANAGER

# Check caller
validate_caller() {
  [[ "${1}" == "bash" && ! "${2}" ]] && echo -e "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit $EXEC_ERR
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
  [[ ! -s "${AGC_PATH}" || ! -s "${AGW_BIN}" || ! -s "${IONDRV_PATH}" || ! -s "${IOG_BIN}" ]] && echo -e "\nSystem could be unbootable. Consider ${BOLD}macOS Recovery${NORMAL}.\n" && sleep 1
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
  [[ ! -f "${AGW_BIN}" || ! -f "${IOG_BIN}" ]] && AMD_PATCH_STATUS=2 && NV_PATCH_STATUS=2 && return
  AGW_HEX="$(hexdump -ve '1/1 "%.2X"' "${AGW_BIN}")"
  IOG_HEX="$(hexdump -ve '1/1 "%.2X"' "${IOG_BIN}")"
  [[ "${AGW_HEX}" =~ "${SYS_TB_VER}" && "${SYS_TB_VER}" != "${TB_SWITCH_HEX}"3 || -d "${AMD_LEGACY_KEXT}" ]] && AMD_PATCH_STATUS=1 || AMD_PATCH_STATUS=0
  [[ "${IOG_HEX}" =~ "${PATCHED_PCI_TUNNELLED_HEX}" ]] && NV_PATCH_STATUS=1 || NV_PATCH_STATUS=0
}

# Patch status check
check_patch_status() {
  PATCH_STATUSES=("Disabled" "Enabled" "Unknown")
  echo -e "\n>> ${BOLD}Check Patch Status${NORMAL}\n"
  echo -e "${BOLD}AMD Patch${NORMAL}: ${PATCH_STATUSES[$AMD_PATCH_STATUS]}"
  echo -e "${BOLD}NVIDIA Patch${NORMAL}: ${PATCH_STATUSES[$NV_PATCH_STATUS]}\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_sys_extensions
  check_patch
  DID_INSTALL_LEGACY_KEXT=0
  USING_WEB_DRV=0
}

# ----- OS MANAGEMENT

# Sanitize system permissions and caches
sanitize_system() {
  echo -e "${BOLD}Sanitizing system...${NORMAL}"
  chmod -R 755 "${AGC_PATH}" "${IOG_PATH}" "${IONDRV_PATH}" "${NVDA_STARTUP_WEB_PATH}" "${NVDA_STARTUP_PATH}" "${AMD_LEGACY_KEXT}" 1>/dev/null 2>&1
  chown -R root:wheel "${AGC_PATH}" "${IOG_PATH}" "${IONDRV_PATH}" "${NVDA_STARTUP_WEB_PATH}" "${NVDA_STARTUP_PATH}" "${AMD_LEGACY_KEXT}" 1>/dev/null 2>&1
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
  echo -e "${MANIFEST_STR}" > "${MANIFEST}"
}

# Primary procedure
execute_backup() {
  mkdir -p "${BACKUP_KEXT_DIR}"
  rsync -rt "${AGC_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${IOG_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -rt "${IONDRV_PATH}" "${BACKUP_KEXT_DIR}"
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
      echo -e "Backup already exists."
    else
      echo -e "\n${BOLD}Last Backup${NORMAL}: ${MANIFEST_MACOS_VER} ${BOLD}[${MANIFEST_MACOS_BUILD}]${NORMAL}"
      echo -e "${BOLD}Current System${NORMAL}: ${MACOS_VER} ${BOLD}[${MACOS_BUILD}]${NORMAL}\n"
      echo -e "${BOLD}Updating backup...${NORMAL}"
      rm -r "${BACKUP_AGC}" "${BACKUP_IOG}" "${BACKUP_IONDRV}" "${BACKUP_NVDA_STARTUP_PATH}" 2>/dev/null
      if [[ $AMD_PATCH_STATUS == 1 || $NV_PATCH_STATUS == 1 ]]
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

# ----- CORE PATCH

# Conclude patching sequence
end_patch() {
  sanitize_system
  write_manifest
  echo -e "${BOLD}Patch complete.\n\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# Patch specified plist
patch_plist() {
  TARGET_PLIST="${1}"
  COMMAND="${2}"
  KEY="${3}"
  VALUE="${4}"
  $PlistBuddy -c "${COMMAND} ${KEY} ${VALUE}" "${TARGET_PLIST}"
}

# Install AMDLegacySupport.kext
run_legacy_kext_installer() {
  echo -e "${BOLD}Downloading AMDLegacySupport...${NORMAL}"
  curl -L -s -o "${AMD_LEGACY_ZIP}" "${AMD_LEGACY_DL}"
  [[ ! -e "${AMD_LEGACY_ZIP}" ]] && echo -e "Could not download.\n\n${BOLD}Continuing...${NORMAL}" && return
  echo -e "Download complete.\n${BOLD}Installing...${NORMAL}"
  [[ -d "${AMD_LEGACY_KEXT}" ]] && rm -r "${AMD_LEGACY_KEXT}"
  unzip -d "${TP_EXT_PATH}" "${AMD_LEGACY_ZIP}" 1>/dev/null 2>&1
  rm -r "${AMD_LEGACY_ZIP}" "${TP_EXT_PATH}/__MACOSX" 1>/dev/null 2>&1
  echo -e "Installation complete.\n\n${BOLD}Continuing patch....${NORMAL}"
  DID_INSTALL_LEGACY_KEXT=1
}

# Prompt AMDLegacySupport.kext install
install_legacy_kext() {
  [[ -d "${AMD_LEGACY_KEXT}" ]] && return
  echo -e "\nIt is possible to use legacy AMD GPUs if needed.\Legacy AMD GPUs refer to eGPUs not sanctioned as ${BOLD}\"supported by Apple\"${NORMAL}.\n"
  read -p "Enable ${BOLD}Legacy${NORMAL} AMD eGPUs? [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && echo && run_legacy_kext_installer && return
  [[ "${INPUT}" == "N" ]] && echo && return
  echo -e "\nInvalid option.\n" && install_legacy_kext
}

# Patch TB1/2 block
patch_tb() {
  echo -e "\n>> ${BOLD}Enable AMD eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}"
  [[ -e "${AUTOMATE_EGPU_KEXT}" ]] && rm -r "${AUTOMATE_EGPU_KEXT}"
  [[ ${NV_PATCH_STATUS} == 1 ]] && echo -e "System has previously been patched for ${BOLD}NVIDIA eGPUs${NORMAL}.\nPlease uninstall before proceeding.\n" && return
  install_legacy_kext
  if [[ "${SYS_TB_VER}" == "${TB_SWITCH_HEX}3" ]]
  then
    echo -e "No thunderbolt patch required for this Mac.\n"
    [[ ${DID_INSTALL_LEGACY_KEXT} == 1 ]] && end_patch
    return
  fi
  if [[ ${AMD_PATCH_STATUS} == 1 ]]
  then
    echo -e "System has already been patched for ${BOLD}AMD eGPUs${NORMAL}.\n"
    [[ ${DID_INSTALL_LEGACY_KEXT} == 1 ]] && end_patch
    return
  fi
  backup_system
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
  rm - r "${INSTALLER_PKG_EXPANDED}" "${INSTALLER_PKG}" 2>/dev/null 1>&2
  echo -e "Data retrieved.\n${BOLD}Downloading drivers (${DRIVER_VERSION})...${NORMAL}"
  curl --connect-timeout 15 -# -o "${INSTALLER_PKG}" "${DOWNLOAD_URL}"
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
  $PlistBuddy -c "Set ${NVDA_REQUIRED_OS} \"\"" "${NVDA_STARTUP_PKG_KEXT}/Contents/Info.plist" 2>/dev/null 1>&2
  chown -R root:wheel "${NVDA_STARTUP_PKG_KEXT}"
  rm -r "${INSTALLER_PKG}"
  pkgutil --flatten-full "${INSTALLER_PKG_EXPANDED}" "${INSTALLER_PKG}" 2>/dev/null 1>&2
  echo -e "Package sanitized.\n${BOLD}Installing...${NORMAL}"
  INSTALLER_ERR="$(installer -target "/" -pkg "${INSTALLER_PKG}" 2>&1 1>/dev/null)"
  [[ -z "${INSTALLER_ERR}" ]] && echo -e "Installation complete.\n\n${BOLD}Continuing patch...${NORMAL}" || echo -e "Installation failed."
  rm -r "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}"
  rm "${WEBDRIVER_PLIST}"
}

# Run Webdriver installation procedure
run_webdriver_installer() {
  echo -e "${BOLD}Fetching webdriver information...${NORMAL}"
  WEBDRIVER_DATA="$(curl -s "https://gfe.nvidia.com/mac-update")"
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
  if [[ -z "${DRIVER_DL}" || -z "${DRIVER_VER}" ]]
  then
    echo -e "Latest Available Driver: ${BOLD}${LATEST_DRIVER_MACOS_BUILD}${NORMAL}\nYour macOS Build: ${BOLD}${MACOS_BUILD}${NORMAL}\n"
    echo -e "Patching ${BOLD}minor${NORMAL} macOS version differences is ${BOLD}usually safe${NORMAL},\nbut does not necessarily imply guaranteed functionality.\n"
    read -p "Patch ${BOLD}Web Drivers${NORMAL} (${BOLD}${LATEST_DRIVER_MACOS_BUILD}${NORMAL} -> ${BOLD}${MACOS_BUILD}${NORMAL})? [Y/N]: " INPUT
    [[ "${INPUT}" == "N" ]] && echo -e "\nInstallation ${BOLD}aborted${NORMAL}." && rm "${WEBDRIVER_PLIST}" 2>/dev/null && return
    [[ "${INPUT}" == "Y" ]] && echo -e "\n${BOLD}Proceeding...${NORMAL}" && install_web_drivers "${LATEST_DRIVER_VER}" "${LATEST_DRIVER_DL}" && return
    echo -e "\nInvalid option. Installation ${BOLD}aborted${NORMAL}." && return
  fi
  install_web_drivers "${DRIVER_VER}" "${DRIVER_DL}"
}

# Prompt NVIDIA Web Driver installation
prompt_web_driver_install() {
  if [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]]
  then
    if [[ ! -z "$(${PlistBuddy} -c "Print ${NVDA_REQUIRED_OS}" "${NVDA_STARTUP_WEB_PLIST_PATH}" 2>/dev/null)" ]]
    then
      echo -e "\nInstalled ${BOLD}NVIDIA Web Drivers${NORMAL} are specifying macOS build.\n"
      read -p "${BOLD}Remove limitation${NORMAL}? [Y/N]: " INPUT
      if [[ "${INPUT}" != "Y" ]]
      then
        echo -e "\nDrivers unchanged.\n"
      else
        echo -e "\n${BOLD}Patching drivers...${NORMAL}"
        $PlistBuddy -c "Set ${NVDA_REQUIRED_OS} \"\"" 2>/dev/null 1>&2
        echo -e "Drivers patched.\n"
      fi
    fi
    return
  fi
  echo -e "\n${BOLD}NVIDIA Web Drivers${NORMAL} are required for ${BOLD}NVIDIA 9xx${NORMAL} GPUs or newer.\nIf you are using an older macOS-supported NVIDIA GPU,\nweb drivers are not needed.\n"
  read -p "Install ${BOLD}NVIDIA Web Drivers${NORMAL}? [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && USING_WEB_DRV=1 && echo && run_webdriver_installer && return
  [[ "${INPUT}" == "N" ]] && echo -e "\nProceeding with ${BOLD}native macOS drivers${NORMAL}...\n" && return
  echo -e "\nInvalid option.\n" && prompt_web_driver_install
}

# Patch for NVIDIA eGPUs
patch_nv() {
  echo -e "\n>> ${BOLD}Enable NVIDIA eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}"
  [[ $NV_PATCH_STATUS == 1 ]] && echo -e "System has already been patched for ${BOLD}NVIDIA eGPUs${NORMAL}.\n" && return
  [[ $AMD_PATCH_STATUS == 1 ]] && echo -e "System has previously been patched for ${BOLD}AMD eGPUs${NORMAL}.\nPlease uninstall before proceeding.\n" && return
  prompt_web_driver_install
  [[ $USING_WEB_DRV == 1 && ! -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]] && echo -e "\n${BOLD}NVIDIA Web Drivers${NORMAL} requested, but not installed.\n" && return
  if [[ $USING_WEB_DRV == 1 ]]
  then
    nvram nvda_drv=1
    NVDA_STARTUP_PLIST_TO_PATCH="${NVDA_STARTUP_WEB_PLIST_PATH}"
  else
    nvram -d nvda_drv 2>/dev/null
    NVDA_STARTUP_PLIST_TO_PATCH="${NVDA_STARTUP_PLIST_PATH}"
  fi
  backup_system
  echo -e "${BOLD}Patching components...${NORMAL}"
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
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

# In-place re-patcher
uninstall() {
  echo -e "\n>> ${BOLD}Uninstall Patches${NORMAL}\n"
  [[ $AMD_PATCH_STATUS == 0 && $NV_PATCH_STATUS == 0 ]] && echo -e "No patches detected.\nSystem already clean.\n" && return
  echo -e "${BOLD}Uninstalling...${NORMAL}"
  if [[ -d "${AMD_LEGACY_KEXT}" ]]
  then
    echo -e "${BOLD}Removing legacy support...${NORMAL}"
    rm -r "${AMD_LEGACY_KEXT}"
    echo -e "Removal successful."
  fi
  echo -e "${BOLD}Reverting binaries...${NORMAL}"
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  [[ $AMD_PATCH_STATUS == 1 ]] && generic_patcher "${SYS_TB_VER}" "${TB_SWITCH_HEX}"3 "${SCRATCH_AGW_HEX}"
  if [[ $NV_PATCH_STATUS == 1 ]]
  then
    generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_IOG_HEX}"
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_AGW_HEX}"
    [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" && "$(cat "${NVDA_STARTUP_WEB_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_WEB_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    [[ "$(cat "${NVDA_STARTUP_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    generate_new_bin "${SCRATCH_IOG_HEX}" "${SCRATCH_IOG_BIN}" "${IOG_BIN}"
    [[ "$(cat "${IONDRV_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${IONDRV_PLIST_PATH}" "Delete" "${NDRV_PCI_TUN_CP}"
  fi
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  echo -e "Binaries reverted."
  sanitize_system
  write_manifest
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

# Remove NVIDIA Web Drivers
remove_web_drivers() {
  echo
  read -p "Remove ${BOLD}NVIDIA Web Drivers${NORMAL}? [Y/N]: " INPUT
  if [[ "${INPUT}" == "Y" ]]
  then
    echo -e "\n${BOLD}Uninstalling drivers...${NORMAL}"
    WEBDRIVER_UNINSTALLER="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
    [[ ! -s "${WEBDRIVER_UNINSTALLER}" ]] && echo -e "Could not find NVIDIA uninstaller.\n" && return
    installer -target "/" -pkg "${WEBDRIVER_UNINSTALLER}" 2>&1 1>/dev/null
    nvram -d nvda_drv
    echo -e "Drivers uninstalled.\nIf in ${BOLD}Single User Mode${NORMAL}, only driver selection changed.\n" && return
  fi
  [[ "${INPUT}" == "N" ]] && echo && return
  echo -e "\nInvalid option.\n" && remove_web_drivers
}

# Recovery logic
recover_sys() {
  echo -e "\n>> ${BOLD}System Recovery${NORMAL}\n\n${BOLD}Recovering...${NORMAL}"
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
    read -p "System may already be clean. Still ${BOLD}attempt recovery${NORMAL}? [Y/N]: " INPUT
    [[ "${INPUT}" == "N" ]] && echo -e "Recovery ${BOLD}cancelled${NORMAL}.\n" && return
    [[ "${INPUT}" != "Y" ]] && echo -e "Invalid choice. Recovery ${BOLD}safely aborted${NORMAL}.\n" && return
    echo -e "\n${BOLD}Attempting recovery...${NORMAL}"
  fi
  echo -e "${BOLD}Restoring files from backup...${NORMAL}"
  [[ -d "${BACKUP_KEXT_DIR}" ]] && rsync -rt "${BACKUP_KEXT_DIR}"* "${EXT_PATH}"
  [[ "$(cat "${NVDA_STARTUP_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
  if [[ -f "${NVDA_STARTUP_WEB_PLIST_PATH}" ]]
  then
    [[ "$(cat "${NVDA_STARTUP_WEB_PLIST_PATH}" | grep -i "IOPCITunnelCompatible")" ]] && patch_plist "${NVDA_STARTUP_WEB_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    remove_web_drivers
  fi
  echo -e "Files restored."
  sanitize_system
  echo -e "Recovery complete.\n\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n\nRefer to the ${BOLD}macOS eGPU Troubleshooting Guide${NORMAL} in the ${BOLD}How-To's${NORMAL}\nsection of ${UNDERLINE}egpu.io${NORMAL} for further troubleshooting if needed.\n"
}

# ----- USER INTERFACE

# Ask for main menu
ask_menu() {
  read -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && perform_sys_check && clear && echo -e "\n>> ${BOLD}PurgeWrangler (${SCRIPT_VER})${NORMAL}" && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo -e "
   >> ${BOLD}Patching System${NORMAL}           >> ${BOLD}System Management${NORMAL}
   ${BOLD}1.${NORMAL} Enable AMD eGPUs          ${BOLD}5.${NORMAL} System Recovery
   ${BOLD}2.${NORMAL} Enable NVIDIA eGPUs       ${BOLD}6.${NORMAL} Sanitize System
   ${BOLD}3.${NORMAL} Check Patch Status        ${BOLD}7.${NORMAL} Reboot System
   ${BOLD}4.${NORMAL} Uninstall Patches

   ${BOLD}0.${NORMAL} Quit
  "
  read -p "${BOLD}What next?${NORMAL} [0-7]: " INPUT
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
    -s|--status|3)
    check_patch_status;;
    -u|--uninstall|4)
    uninstall;;
    -r|--recover|5)
    recover_sys;;
    -ss|--sanitize-system|6)
    echo -e "\n>> ${BOLD}Sanitize System${NORMAL}\n"
    sanitize_system
    echo;;
    -rb|--reboot|7)
    echo -e "\n>> ${BOLD}Reboot System${NORMAL}\n"
    read -p "${BOLD}Reboot${NORMAL} now? [Y/N]: " INPUT
    [[ "${INPUT}" == "Y" ]] && echo -e "\n${BOLD}Rebooting...${NORMAL}" && reboot && exit
    [[ "${INPUT}" != "Y" ]] && echo -e "\nReboot aborted.\n" && ask_menu;;
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
  validate_caller "${1}" "${2}"
  perform_sys_check
  process_args "${2}"
}

begin "${0}" "${1}"