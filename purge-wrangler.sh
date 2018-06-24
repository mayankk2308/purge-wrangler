#!/bin/sh

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 4.0.0
# PurgeWrangler 4 introduces @goalque's sweet new NVIDIA eGPU patch
# and makes important codebase refinements.

# Invaluable Contributors
# ----- TB1/2 Patch
#       (c) @mac_editor (+ @fricorico) at egpu.io
# ----- New NVIDIA eGPU Patch
#       (c) @goalque at egpu.io
# ----- TB Detection
#       @owenrw at egpu.io
# ----- Testing
#       @techyowl at egpu.io
#       @itsage at egpu.io

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
SCRIPT_MAJOR_VER="4" && SCRIPT_MINOR_VER="0" && SCRIPT_PATCH_VER="0"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"

# User input
INPUT=""

# Text management
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
TB_VER_ERR=3
EXEC_ERR=4

# System information
MACOS_VER=`sw_vers -productVersion`
MACOS_BUILD=`sw_vers -buildVersion`
SYS_TB_VER=""

# AppleGPUWrangler references
TB_SWITCH_HEX="494F5468756E646572626F6C74537769746368547970653"

# IOGraphicsFamily references
PCI_TUNNELLED_HEX="494F50434954756E6E656C6C6564"
PATCHED_PCI_TUNNELLED_HEX="494F50434954756E6E656C6C6571"

# Patch status indicators
TB_PATCH_STATUS=""
NV_PATCH_STATUS=""

# Kext paths
EXT_PATH="/System/Library/Extensions/"
AGC_PATH="${EXT_PATH}AppleGraphicsControl.kext"
SUB_AGW_PATH="/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler"
AGW_BIN="${AGC_PATH}${SUB_AGW_PATH}"
IONDRV_PATH="${EXT_PATH}IONDRVSupport.kext"
IONDRV_PLIST_PATH="${IONDRV_PATH}/Info.plist"
IOG_PATH="${EXT_PATH}IOGraphicsFamily.kext"
SUB_IOG_PATH="/IOGraphicsFamily"
IOG_BIN="${IOG_PATH}${SUB_IOG_PATH}"
NVDA_STARTUP_PATH="/Library/Extensions/NVDAStartupWeb.kext"
NVDA_PLIST_PATH="${NVDA_STARTUP_PATH}/Contents/Info.plist"

# Backup paths
SUPPORT_DIR="/Library/Application Support/Purge-Wrangler/"
BACKUP_KEXT_DIR="${SUPPORT_DIR}Kexts/"
BACKUP_AGC="${BACKUP_KEXT_DIR}AppleGraphicsControl.kext"
BACKUP_AGW_BIN="${BACKUP_AGC}${SUB_AGW_PATH}"
BACKUP_IOG="${BACKUP_KEXT_DIR}IOGraphicsFamily.kext"
BACKUP_IOG_BIN="${BACKUP_IOG}${SUB_IOG_PATH}"
MANIFEST="${SUPPORT_DIR}manifest.wglr"
SCRATCH_AGW_HEX="${SUPPORT_DIR}AppleGPUWrangler.hex"
SCRATCH_AGW_BIN="${SUPPORT_DIR}AppleGPUWrangler.bin"
SCRATCH_IOG_HEX="${SUPPORT_DIR}IOGraphicsFamily.hex"
SCRATCH_IOG_BIN="${SUPPORT_DIR}IOGraphicsFamily.bin"

# PlistBuddy Configuration
PlistBuddy="/usr/libexec/PlistBuddy"
NDRV_PCI_TUN_CP=":IOKitPersonalities:3:IOPCITunnelCompatible bool"
NVDA_PCI_TUN_CP=":IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool"

# Installation Info
MANIFEST_MACOS_VER=""
MANIFEST_MACOS_BUILD=""

# ----- SCRIPT SOFTWARE UPDATE SYSTEM

# Perform software update
perform_software_update() {
  echo "${BOLD}Downloading...${NORMAL}"
  curl -L -s "${LATEST_RELEASE_DWLD}" > "${TMP_SCRIPT}"
  echo "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo "Update complete. ${BOLD}Relaunching...${NORMAL}"
  "${SCRIPT}"
  exit 0
}

# Prompt for update
prompt_software_update() {
  read -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo "\n${BOLD}Proceeding without updating...${NORMAL}" && return
  echo "\nInvalid choice. Try again.\n"
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${LOCAL_BIN}"
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest")"
  LATEST_RELEASE_VER="$(echo "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo "\n>> ${BOLD}Software Update${NORMAL}\n\nA script update (${BOLD}${LATEST_RELEASE_VER}${NORMAL}) is available.\nYou are currently on ${BOLD}${SCRIPT_VER}${NORMAL}."
    prompt_software_update
  fi
}

# ----- SYSTEM CONFIGURATION MANAGER

# Check caller
validate_caller() {
  [[ "$1" == "sh" && ! "$2" ]] && echo "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit $EXEC_ERR
  [[ "$1" != "$SCRIPT" ]] && OPTION="$3" || OPTION="$2"
  [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "purge-wrangler" ]] && BIN_CALL=1
}

# Elevate privileges
elevate_privileges() {
  if [[ $(id -u) != 0 ]]
  then
    sudo sh "${SCRIPT}" "${OPTION}"
    exit 0
  fi
}

# System integrity protection check
check_sip() {
  [[ $(csrutil status | grep -i enabled) ]] && echo "\nPlease disable ${BOLD}System Integrity Protection${NORMAL}.\n" && exit $SIP_ON_ERR
}

# macOS Version check
check_macos_version() {
  MACOS_MAJOR_VER="$(echo "$MACOS_VER" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo "$MACOS_VER" | cut -d '.' -f3)"
  [[ ("$MACOS_MAJOR_VER" < 13) || ("$MACOS_MAJOR_VER" == 13 && "$MACOS_MINOR_VER" < 4) ]] && echo "\n${BOLD}macOS 10.13.4 or later${NORMAL} required.\n" && exit $MACOS_VER_ERR
}

# Retrieve thunderbolt version
retrieve_tb_ver() {
  TB_VER=`ioreg | grep AppleThunderboltNHIType`
  [[ "$TB_VER[@]" =~ "NHIType3" ]] && SYS_TB_VER="$TB_SWITCH_HEX"3 && return
  [[ "$TB_VER[@]" =~ "NHIType2" ]] && SYS_TB_VER="$TB_SWITCH_HEX"2 && return
  [[ "$TB_VER[@]" =~ "NHIType1" ]] && SYS_TB_VER="$TB_SWITCH_HEX"1 && return
  echo "\nUnsupported/Invalid version of Thunderbolt detected.\n" && exit $TB_VER_ERR
}

# Patch check
check_patch() {
  if [[ `hexdump -ve '1/1 "%.2X"' "$AGW_BIN" | grep "$SYS_TB_VER"` && "$SYS_TB_VER" != "$TB_SWITCH_HEX"3 ]]
  then
    TB_PATCH_STATUS=1
  else
    TB_PATCH_STATUS=0
  fi
  if [[ `hexdump -ve '1/1 "%.2X"' "$IOG_BIN" | grep "$PATCHED_PCI_TUNNELLED_HEX"` ]]
  then
    [[ "$SYS_TB_VER" != "$TB_SWITCH_HEX"3 ]] && TB_PATCH_STATUS=1
    NV_PATCH_STATUS=1
  else
    NV_PATCH_STATUS=0
  fi
}

# Patch status check
check_patch_status() {
  echo "\n>> ${BOLD}Check Patch Status${NORMAL}\n"
  [[ "$TB_PATCH_STATUS" == 0 ]] && echo "${BOLD}Thunderbolt Override${NORMAL}: Not Detected" || echo "${BOLD}Thunderbolt Override${NORMAL}: Detected"
  [[ "$NV_PATCH_STATUS" == 0 ]] && echo "${BOLD}NVIDIA Patch${NORMAL}: Not Detected\n" || echo "${BOLD}NVIDIA Patch${NORMAL}: Detected\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_patch
}

# ----- OS MANAGEMENT

# Reboot sequence
initiate_reboot() {
  echo
  for time in {5..0}
  do
    printf "Restarting in ${BOLD}${time}s${NORMAL}...\r"
    sleep 1
  done
  reboot
}

# Disable hibernation
disable_hibernation() {
  echo "\n>> ${BOLD}Disable Hibernation${NORMAL}\n\n${BOLD}Disabling hibernation...${NORMAL}"
  pmset -a autopoweroff 0
  pmset -a standby 0
  pmset -a hibernatemode 0
  echo "Hibernation disabled.\n"
}

# Revert hibernation settings
restore_sleep() {
  echo "\n>> ${BOLD}Restore Sleep Configuration${NORMAL}\n\n${BOLD}Restoring default sleep settings...${NORMAL}"
  pmset restoredefaults
  echo "Restore complete.\n"
}

# Rebuild kernel cache
invoke_kext_caching() {
  echo "${BOLD}Rebuilding kext cache...${NORMAL}"
  touch "${EXT_PATH}"
  kextcache -q -update-volume /
  echo "Rebuild complete."
}

# Repair kext and binary permissions
repair_permissions() {
  echo "${BOLD}Repairing permissions...${NORMAL}"
  chmod 755 "${AGW_BIN}"
  chmod 755 "${IOG_BIN}"
  chown -R root:wheel "$AGC_PATH"
  chown -R root:wheel "$IOG_PATH"
  chown -R root:wheel "$IONDRV_PATH"
  [[ -d "${NVDA_STARTUP_PATH}" ]] && chown -R root:wheel "${NVDA_STARTUP_PATH}"
  echo "Permissions set."
  invoke_kext_caching
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
  rm "${TARGET_BIN}" && rm "${SCRATCH_HEX}" && mv "${SCRATCH_BIN}" "${TARGET_BIN}"
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
  MANIFEST_STR="${MACOS_VER}\n${MACOS_BUILD}"
  if [[ -s "${BACKUP_AGC}" ]]
  then
    UNPATCHED_AGW_KEXT_SHA=`shasum -a 512 -b "$BACKUP_AGW_BIN" | awk '{ print $1 }'`
    PATCHED_AGW_KEXT_SHA=`shasum -a 512 -b "$AGW_BIN" | awk '{ print $1 }'`
    MANIFEST_STR="${MANIFEST_STR}\n${UNPATCHED_AGW_KEXT_SHA}\n${PATCHED_AGW_KEXT_SHA}"
  fi
  if [[ -s "${BACKUP_IOG}" ]]
  then
    UNPATCHED_IOG_KEXT_SHA=`shasum -a 512 -b "$BACKUP_IOG_BIN" | awk '{ print $1 }'`
    PATCHED_IOG_KEXT_SHA=`shasum -a 512 -b "$IOG_BIN" | awk '{ print $1 }'`
    MANIFEST_STR="${MANIFEST_STR}\n${UNPATCHED_IOG_KEXT_SHA}\n${PATCHED_IOG_KEXT_SHA}"
  fi
  echo "${MANIFEST_STR}" > "${MANIFEST}"
}

# Primary procedure
execute_backup() {
  mkdir -p "${BACKUP_KEXT_DIR}"
  rsync -r "${AGC_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -r "${IOG_PATH}" "${BACKUP_KEXT_DIR}"
  rsync -r "${IONDRV_PATH}" "${BACKUP_KEXT_DIR}"
}

# Backup procedure
backup_system() {
  echo "${BOLD}Backing up...${NORMAL}"
  if [[ -s "${BACKUP_AGC}" && -s "${MANIFEST}" ]]
  then
    MANIFEST_MACOS_VER=`sed "1q;d" "${MANIFEST}"` && MANIFEST_MACOS_BUILD=`sed "2q;d" "${MANIFEST}"`
    if [[ "${MANIFEST_MACOS_VER}" == "${MACOS_VER}" && "${MANIFEST_MACOS_BUILD}" == "${MACOS_BUILD}" ]]
    then
      echo "Backup already exists."
    else
      echo "Different build/version of macOS detected. ${BOLD}Updating backup...${NORMAL}"
      rm -r "$AGC_PATH" && rm -r "$IOG_PATH" && rm -r "$IONDRV_PATH"
      if [[ "$TB_PATCH_STATUS" == 1 || "$NV_PATCH_STATUS" == 1 ]]
      then
        echo "${BOLD}Uninstalling patch before backup update...${NORMAL}"
        uninstall
        echo "${BOLD}Re-running script...${NORMAL}"
        "$SCRIPT" "$OPTION"
        exit
      fi
      execute_backup
      echo "Update complete."
    fi
  else
    execute_backup
    echo "Backup complete."
  fi
}

# ----- CORE PATCH

# Conclude patching sequence
end_patch() {
  repair_permissions
  write_manifest
  echo "${BOLD}Patch complete.\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# Patch specified plist
patch_plist() {
  TARGET_PLIST="${1}"
  COMMAND="${2}"
  KEY="${3}"
  VALUE="${4}"
  $PlistBuddy -c "${COMMAND} ${KEY} ${VALUE}" "${TARGET_PLIST}"
}

# Patch TB1/2 block
patch_tb() {
  echo "\n>> ${BOLD}Enable AMD eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}"
  [[ "${SYS_TB_VER}" == "${TB_SWITCH_HEX}"3 ]] && echo "This mac does not require a thunderbolt patch.\n" && return
  [[ $TB_PATCH_STATUS == 1 ]] && echo "System has already been patched for AMD eGPUs.\n" && return
  backup_system
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  generic_patcher "${TB_SWITCH_HEX}"3 "${SYS_TB_VER}" "${SCRATCH_AGW_HEX}"
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  end_patch
}

# Patch for NVIDIA eGPUs
patch_nv() {
  echo "\n>> ${BOLD}Enable NVIDIA eGPUs${NORMAL}\n\n${BOLD}Starting patch...${NORMAL}"
  [[ $NV_PATCH_STATUS == 1 ]] && echo "System has already been patched for NVIDIA eGPUs.\n" && return
  [[ ! -f "${NVDA_PLIST_PATH}" ]] && echo "Please install NVIDIA Web Drivers before proceeding.\n" && return
  backup_system
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
  generic_patcher "${PCI_TUNNELLED_HEX}" "${PATCHED_PCI_TUNNELLED_HEX}" "${SCRATCH_AGW_HEX}"
  generic_patcher "${PCI_TUNNELLED_HEX}" "${PATCHED_PCI_TUNNELLED_HEX}" "${SCRATCH_IOG_HEX}"
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  generate_new_bin "${SCRATCH_IOG_HEX}" "${SCRATCH_IOG_BIN}" "${IOG_BIN}"
  patch_plist "${IONDRV_PLIST_PATH}" "Add" "${NDRV_PCI_TUN_CP}" "true"
  patch_plist "${NVDA_PLIST_PATH}" "Add" "${NVDA_PCI_TUN_CP}" "true"
  end_patch
}

# In-place re-patcher
uninstall() {
  [[ ! -d "${SUPPORT_DIR}" ]] && echo "\n${BOLD}No installation found${NORMAL}. No action taken.\n" && return
  echo "\n>> ${BOLD}Uninstall Patches${NORMAL}\n"
  [[ $TB_PATCH_STATUS == 0 && $NV_PATCH_STATUS == 0 ]] && echo "No patches detected. Uninstallation aborted. System clean.\n" && return
  echo "${BOLD}Uninstalling...${NORMAL}"
  generate_hex "${AGW_BIN}" "${SCRATCH_AGW_HEX}"
  [[ $TB_PATCH_STATUS == 1 ]] && generic_patcher "${SYS_TB_VER}" "${TB_SWITCH_HEX}"3 "${SCRATCH_AGW_HEX}"
  if [[ $NV_PATCH_STATUS == 1 ]]
  then
    generate_hex "${IOG_BIN}" "${SCRATCH_IOG_HEX}"
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_IOG_HEX}"
    generic_patcher "${PATCHED_PCI_TUNNELLED_HEX}" "${PCI_TUNNELLED_HEX}" "${SCRATCH_AGW_HEX}"
    [[ -f "${NVDA_PLIST_PATH}" && `cat "${NVDA_PLIST_PATH}" | grep -i "IOPCITunnelCompatible"` ]] && patch_plist "${NVDA_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
    generate_new_bin "${SCRATCH_IOG_HEX}" "${SCRATCH_IOG_BIN}" "${IOG_BIN}"
    [[ `cat "${IONDRV_PLIST_PATH}" | grep -i "IOPCITunnelCompatible"` ]] && patch_plist "${IONDRV_PLIST_PATH}" "Delete" "${NDRV_PCI_TUN_CP}"
  fi
  generate_new_bin "${SCRATCH_AGW_HEX}" "${SCRATCH_AGW_BIN}" "${AGW_BIN}"
  repair_permissions
  write_manifest
  echo "Uninstallation Complete.\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
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
  SCRIPT_FILE="$(pwd)/$(echo "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA=`shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }'`
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA=`shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }'`
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
}

# ----- RECOVERY SYSTEM

# Recovery logic
recover_sys() {
  [[ ! -s "$BACKUP_KEXT_DIR" && ! -e "$MANIFEST" ]] && echo "\n${BOLD}Could not find valid backup${NORMAL}. Recovery not possible.\n" && return
  MANIFEST_MACOS_VER=`sed "1q;d" "${MANIFEST}"` && MANIFEST_MACOS_BUILD=`sed "2q;d" "${MANIFEST}"`
  echo "\n>> ${BOLD}System Recovery${NORMAL}\n"
  [[ "${MANIFEST_MACOS_VER}" != "${MACOS_VER}" || "${MANIFEST_MACOS_BUILD}" != "${MACOS_BUILD}" ]] && echo "System already clean. Recovery not required.\n" && return
  echo "${BOLD}Recovering...${NORMAL}"
  rm -r "${AGC_PATH}"
  rm -r "${IOG_PATH}"
  rm -r "${IONDRV_PATH}"
  rsync -r "${BACKUP_KEXT_DIR}"* "${EXT_PATH}" && rm -r "${SUPPORT_DIR}"
  [[ -f "${NVDA_PLIST_PATH}" && `cat "$NVDA_PLIST_PATH" | grep -i "IOPCITunnelCompatible"` ]] && patch_plist "${NVDA_PLIST_PATH}" "Delete" "${NVDA_PCI_TUN_CP}"
  repair_permissions
  echo "Recovery complete.\n${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# ----- USER INTERFACE

# Exit script
quit() {
  echo
  exit
}

# Print script version
show_script_version() {
  echo "\nScript at ${BOLD}${SCRIPT_VER}${NORMAL}.\n"
}

# Print command line options
usage() {
  echo "\n>> ${BOLD}Command Line Shortcuts${NORMAL}\n"
  echo " purge-wrangler ${BOLD}-[OPTION]${NORMAL}"
  echo "
    ${BOLD}-enable_amd${NORMAL}: Enable AMD eGPUs
    ${BOLD}-enable_nvda${NORMAL}: Enable NVIDIA eGPUs
    ${BOLD}-status${NORMAL}: Check Patch Status
    ${BOLD}-uninstall${NORMAL}: Uninstall Patches
    ${BOLD}-recover${NORMAL}: System Recovery
    ${BOLD}-shortcuts${NORMAL}: Command Line Shortcuts
    ${BOLD}-version${NORMAL}: Script Version
    ${BOLD}-disable_hibernation${NORMAL}: Disable Hibernation
    ${BOLD}-restore_sleep${NORMAL}: Reset Sleep Configuration
    ${BOLD}-reboot${NORMAL}: Reboot System
    ${BOLD}-quit${NORMAL}: Quit\n"
}

# Ask for main menu
ask_menu() {
  read -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  if [[ "${INPUT}" == "Y" ]]
  then
    perform_sys_check
    echo "\n>> ${BOLD}PurgeWrangler ($SCRIPT_VER)${NORMAL}"
    provide_menu_selection
  elif [[ "${INPUT}" == "N" ]]
  then
    echo
    exit
  else
    echo "\nInvalid choice. Try again.\n"
    ask_menu
  fi
}

# Menu
provide_menu_selection() {
  echo "
   ${BOLD}>> Patching System${NORMAL}               ${BOLD}>> Reverting & Recovery${NORMAL}
   ${BOLD}1.${NORMAL}  Enable AMD eGPUs             ${BOLD}4.${NORMAL}  Uninstall Patches
   ${BOLD}2.${NORMAL}  Enable NVIDIA eGPUs          ${BOLD}5.${NORMAL}  System Recovery
   ${BOLD}3.${NORMAL}  Check Patch Status

   ${BOLD}>> Additional Options${NORMAL}            ${BOLD}>> System Configuration${NORMAL}
   ${BOLD}6.${NORMAL}  Command-Line Shortcuts       ${BOLD}8.${NORMAL}  Disable Hibernation
   ${BOLD}7.${NORMAL}  Script Version               ${BOLD}9.${NORMAL}  Restore Sleep Configuration

   ${BOLD}10.${NORMAL} Reboot System
   ${BOLD}11.${NORMAL} Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-11]: " INPUT
  [[ ! -z "${INPUT}" ]] && process_args "${INPUT}" || echo "\nNo input provided.\n"
  ask_menu
}

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
    --shortcuts|6)
    usage;;
    -v|--version|7)
    show_script_version;;
    -dh|--disable-hibernation|8)
    disable_hibernation;;
    -rs|--restore-sleep|9)
    restore_sleep;;
    -rb|--reboot|10)
    initiate_reboot;;
    11)
    quit;;
    "")
    fetch_latest_release
    first_time_setup
    clear && echo ">> ${BOLD}PurgeWrangler ($SCRIPT_VER)${NORMAL}"
    provide_menu_selection;;
    *)
    echo "\nInvalid argument.\n";;
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
