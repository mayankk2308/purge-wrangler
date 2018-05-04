#!/bin/sh

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 3.0.0
# Re-designed from the ground up for scalable patches and a user-friendly
# command-line + menu-driven interface.

# Invaluable Contributors
# ----- TB1/2 Patch
#       @mac_editor <-- @fricorico for reverse-engineering, egpu.io
# ----- NVIDIA eGPU Patch
#       @goalque <-- @fr34k for reverse-engineering, egpu.io
# ----- TB Detection
#       @owenrw <-- fix for incorrect TB-reporting devices, egpu.io
# ----- Testing
#       @techyowl <-- especially for early versions of scripts, egpu.io
#       @itsage <-- provided me with NVIDIA eGPU, egpu.io

# ----- COMMAND LINE ARGS

# Setup command args
SCRIPT="$BASH_SOURCE"
OPTION=""

if [[ "$0" != "$SCRIPT" ]]
then
  OPTION="$2"
else
  OPTION="$1"
fi
# ----- ENVIRONMENT

# Enable case-insensitive comparisons
shopt -s nocasematch

# Script binary
SCRIPT_BIN="/usr/local/bin/purge-wrangler"
SCRIPT_FILE=""

# Script version
SCRIPT_VER="3.0.0"

# User input
INPUT=""

# Text management
BOLD=`tput bold`
NORMAL=`tput sgr0`

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
TB_VER_ERR=3

# Arg-Function map
t=1
n=2
c=3
u=4
r=5
h=6
v=7
s=8
y=9
b=10
q=11

# Input-Function map
IF["$t"]="patch_tb"
IF["$n"]="patch_nv"
IF["$c"]="check_patch_status"
IF["$u"]="uninstall"
IF["$r"]="recover_sys"
IF["$h"]="usage"
IF["$v"]="show_script_version"
IF["$s"]="disable_hibernation"
IF["$y"]="enable_hibernation"
IF["$b"]="initiate_reboot"
IF["$q"]="quit"

# System information
MACOS_VER=`sw_vers -productVersion`
MACOS_BUILD=`sw_vers -buildVersion`
SYS_TB_VER=""

# AppleGPUWrangler references
TB_SWITCH_HEX="494F5468756E646572626F6C74537769746368547970653"
R13_TEST_REF="3C24E81DBDFFFF41F7C500000001757F"
R13_TEST_PATCH="3C24E81DBDFFFF41F7C500000000757F"

# Patch status indicators
TB_PATCH_STATUS=""
NV_PATCH_STATUS=""

# Kext paths
EXT_PATH="/System/Library/Extensions/"
AGC_PATH="${EXT_PATH}AppleGraphicsControl.kext"
SUB_AGW_PATH="/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler"
AGW_BIN="${AGC_PATH}${SUB_AGW_PATH}"

# Backup paths
SUPPORT_DIR="/Library/Application Support/Purge-Wrangler/"
BACKUP_KEXT_DIR="${SUPPORT_DIR}Kexts/"
BACKUP_AGC="${BACKUP_KEXT_DIR}AppleGraphicsControl.kext"
BACKUP_AGW_BIN="${BACKUP_AGC}${SUB_AGW_PATH}"
MANIFEST="${SUPPORT_DIR}manifest.wglr"
SCRATCH_HEX="${SUPPORT_DIR}AppleGPUWrangler.hex"
SCRATCH_BIN="${SUPPORT_DIR}AppleGPUWrangler.bin"

# ----- SYSTEM CONFIGURATION MANAGER

# Elevate privileges
elevate_privileges()
{
  if [[ `id -u` != 0 ]]
  then
    sudo "$SCRIPT" "$OPTION"
    exit 0
  fi
}

# System integrity protection check
check_sip()
{
  if [[ `csrutil status | grep -i enabled` ]]
  then
    echo "System Integrity Protection needs to be disabled before proceeding.\n"
    exit $SIP_ON_ERR
  fi
}

# macOS Version check
check_macos_version()
{
  MACOS_MAJOR_VER=`echo $MACOS_VER | cut -d '.' -f2`
  MACOS_MINOR_VER=`echo $MACOS_VER | cut -d '.' -f3`
  if [[ ("$MACOS_MAJOR_VER" < 13) || ("$MACOS_MAJOR_VER" == 13 && "$MACOS_MINOR_VER" < 4) ]]
  then
    echo "\nThis script requires macOS 10.13.4 or later.\n"
    exit $MACOS_VER_ERR
  fi
}

# Retrieve thunderbolt version
retrieve_tb_ver()
{
  TB_VER=`ioreg | grep AppleThunderboltNHIType`
  if [[ "$TB_VER[@]" =~ "NHIType3" ]]
  then
    SYS_TB_VER="$TB_SWITCH_HEX"3
  elif [[ "$TB_VER[@]" =~ "NHIType2" ]]
  then
    SYS_TB_VER="$TB_SWITCH_HEX"2
  elif [[ "$TB_VER[@]" =~ "NHIType1" ]]
  then
    SYS_TB_VER="$TB_SWITCH_HEX"1
  else
    echo "\nUnsupported/Invalid version of Thunderbolt detected.\n"
    exit $TB_VER_ERR
  fi
}

# Patch check
check_patch()
{
  if [[ `hexdump -ve '1/1 "%.2X"' "$AGW_BIN" | grep "$SYS_TB_VER"` && "$SYS_TB_VER" != "$TB_SWITCH_HEX"3 ]]
  then
    TB_PATCH_STATUS=1
  else
    TB_PATCH_STATUS=0
  fi
  if [[ `hexdump -ve '1/1 "%.2X"' "$AGW_BIN" | grep "$R13_TEST_PATCH"` ]]
  then
    NV_PATCH_STATUS=1
  else
    NV_PATCH_STATUS=0
  fi
}

# Patch status check
check_patch_status()
{
  echo "\n>> ${BOLD}Patch Status Check${NORMAL}\n"
  if [[ "$TB_PATCH_STATUS" == 0 ]]
  then
    echo "${BOLD}Thunderbolt 1/2${NORMAL}: Not Detected"
  else
    echo "${BOLD}Thunderbolt 1/2${NORMAL}: Detected"
  fi
  if [[ "$NV_PATCH_STATUS" == 0 ]]
  then
    echo "${BOLD}NVIDIA Universal${NORMAL}: Not Detected\n"
  else
    echo "${BOLD}NVIDIA Universal${NORMAL}: Detected\n"
  fi
}

# Cumulative system check
perform_sys_check()
{
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_patch
}

# ----- OS MANAGEMENT

# Reboot sequence/message
prompt_reboot()
{
  echo "${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# Reboot sequence
initiate_reboot()
{
  echo
  for time in {5..0}
  do
    printf "Restarting in ${BOLD}${time}s${NORMAL}...\r"
    sleep 1
  done
  reboot
}

# Disable hibernation
disable_hibernation()
{
  echo "\n>> ${BOLD}Disable Hibernation${NORMAL}\n"
  echo "${BOLD}Disabling hibernation...${NORMAL}"
  pmset -a autopoweroff 0
  pmset -a standby 0
  pmset -a hibernatemode 0
  echo "Hibernation disabled.\n"
}

# Revert hibernation settings
enable_hibernation()
{
  echo "\n>> ${BOLD}Enable Hibernation${NORMAL}\n"
  echo "${BOLD}Enabling hibernation...${NORMAL}"
  pmset -a autopoweroff 1
  pmset -a standby 1
  pmset -a hibernatemode 3
  echo "Hibernation enabled.\n"
}

# Rebuild kernel cache
invoke_kext_caching()
{
  echo "${BOLD}Rebuilding kext cache...${NORMAL}"
  touch "$EXT_PATH"
  kextcache -q -update-volume /
  echo "Rebuild complete."
}

# Repair kext and binary permissions
repair_permissions()
{
  echo "${BOLD}Repairing permissions...${NORMAL}"
  chmod 700 "$AGW_BIN"
  chown -R root:wheel "$AGC_PATH"
  echo "Permissions set."
  invoke_kext_caching
}

# ----- PATCHING SYSTEM

generate_agw_hex()
{
  hexdump -ve '1/1 "%.2X"' "$AGW_BIN" > "$SCRATCH_HEX"
}

new_agw_bin()
{
  xxd -r -p "$SCRATCH_HEX" "$SCRATCH_BIN"
  rm "$AGW_BIN"
  rm "$SCRATCH_HEX"
  mv "$SCRATCH_BIN" "$AGW_BIN"
}

# Primary patching mechanism
generic_patcher()
{
  ORIGINAL="$1"
  NEW="$2"
  sed -i "" -e "s/${ORIGINAL}/${NEW}/g" "$SCRATCH_HEX"
}

# ----- BACKUP SYSTEM

# Write manifest file
# Line 1: Unpatched Kext SHA -- Kext in Backup directory
# Line 2: Patched Kext (in /S/L/E) SHA -- Kext in original location
# Line 3: macOS Version
# Line 4: macOS Build No.
write_manifest()
{
  UNPATCHED_KEXT_SHA=`shasum -a 512 -b "$BACKUP_AGW_BIN" | awk '{ print $1 }'`
  PATCHED_KEXT_SHA=`shasum -a 512 -b "$AGW_BIN" | awk '{ print $1 }'`
  echo "$UNPATCHED_KEXT_SHA\n$PATCHED_KEXT_SHA\n$MACOS_VER\n$MACOS_BUILD" > "$MANIFEST"
}

# Primary procedure
execute_backup()
{
  mkdir -p "$BACKUP_KEXT_DIR"
  rsync -r "$AGC_PATH" "$BACKUP_KEXT_DIR"
}

# Backup procedure
backup_system()
{
  echo "${BOLD}Backing up...${NORMAL}"
  if [[ -s "$BACKUP_AGC" && -s "$MANIFEST" ]]
  then
    MANIFEST_MACOS_VER=`sed "3q;d" "$MANIFEST"`
    MANIFEST_MACOS_BUILD=`sed "4q;d" "$MANIFEST"`
    if [[ "$MANIFEST_MACOS_VER" == "$MACOS_VER" && "$MANIFEST_MACOS_BUILD" == "$MACOS_BUILD" ]]
    then
      echo "Backup already exists."
    else
      echo "Different build/version of macOS detected. ${BOLD}Updating backup...${NORMAL}"
      rm -r "$BACKUP_AGC"
      if [[ "$TB_PATCH_STATUS" == 1 || "$NV_PATCH_STATUS" == 1 ]]
      then
        echo "${BOLD}Uninstalling patch before backup update...${NORMAL}"
        uninstall
        echo "${BOLD}Re-running script...${NORMAL}"
        sleep 3
        "$0" "$OPTION"
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

# Start patching sequence
begin_patch()
{
  echo "${BOLD}Starting patch...${NORMAL}"
  backup_system
  generate_agw_hex
}

# Conclude patching sequence
end_patch()
{
  new_agw_bin
  repair_permissions
  write_manifest
  echo "${BOLD}Patch complete.\n"
  prompt_reboot
}

# Patch TB1/2 block
patch_tb()
{
  if [[ "$SYS_TB_VER" == "$TB_SWITCH_HEX"3 ]]
  then
    echo "\nThis mac does not require a thunderbolt patch.\n"
    exit "$TB_VER_ERR"
  fi
  echo "\n>> ${BOLD}TB1/2 eGPU Patch${NORMAL}\n"
  begin_patch
  generic_patcher "$TB_SWITCH_HEX"3 "$SYS_TB_VER"
  end_patch
}

# Patch for NVIDIA eGPUs
patch_nv()
{
  echo "\n>> ${BOLD}Universal NVIDIA eGPU Patch${NORMAL}\n"
  begin_patch
  generic_patcher "$TB_SWITCH_HEX"3 "$SYS_TB_VER"
  generic_patcher "$R13_TEST_REF" "$R13_TEST_PATCH"
  end_patch
  echo "Please install ${BOLD}NVIDIAEGPUSupport + Web Drivers${NORMAL} for eGPU support.\n"
}

# In-place re-patcher
uninstall()
{
  if [[ -d "$SUPPORT_DIR" ]]
  then
    echo "\n>> ${BOLD}Uninstall Patches${NORMAL}\n"
    echo "${BOLD}Uninstalling...${NORMAL}"
    generate_agw_hex
    generic_patcher "$SYS_TB_VER" "$TB_SWITCH_HEX"3
    generic_patcher "$R13_TEST_PATCH" "$R13_TEST_REF"
    new_agw_bin
    repair_permissions
    write_manifest
    echo "Uninstallation Complete.\n"
    prompt_reboot
  else
    echo "\n${BOLD}No installation found${NORMAL}. No action taken.\n"
  fi
}

# ----- BINARY MANAGER

# Bin management procedure
install_bin()
{
  rsync "$SCRIPT_FILE" "$SCRIPT_BIN"
  chown "$SUDO_USER" "$SCRIPT_BIN"
  chmod 700 "$SCRIPT_BIN"
  chmod a+x "$SCRIPT_BIN"
}

# Bin first-time setup
first_time_setup()
{
  if [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "purge-wrangler" ]]
  then
    return 0
  fi
  SCRIPT_FILE="$(pwd)/$(echo "$SCRIPT")"
  if [[ "$SCRIPT" == "$0" ]]
  then
    SCRIPT_FILE="$(echo "$SCRIPT_FILE" | cut -c 1-)"
  fi
  SCRIPT_SHA=`shasum -a 512 -b "$SCRIPT_FILE" | awk '{ print $1 }'`
  if [[ ! -s "$SCRIPT_BIN" ]]
  then
    echo "\n>> ${BOLD}System Management${NORMAL}\n"
    echo "${BOLD}Creating binary...${NORMAL}"
    install_bin
    echo "Binary installed. ${BOLD}'purge-wrangler'${NORMAL} command now available. ${BOLD}Proceeding...${NORMAL}\n"
    sleep 2
    return 0
  fi
  BIN_SHA=`shasum -a 512 -b "$SCRIPT_BIN" | awk '{ print $1 }'`
  if [[ "$BIN_SHA" != "$SCRIPT_SHA" ]]
  then
    echo "\n>> ${BOLD}System Management${NORMAL}\n"
    echo "${BOLD}Updating binary...${NORMAL}"
    rm "$SCRIPT_BIN"
    install_bin
    echo "Binary updated. ${BOLD}Proceeding...${NORMAL}\n"
    sleep 2
  fi
}

# ----- RECOVERY SYSTEM

# Recovery logic
recover_sys()
{
  if [[ -s "$BACKUP_AGC" ]]
  then
    echo "\n>> ${BOLD}System Recovery${NORMAL}\n"
    echo "${BOLD}Recovering...${NORMAL}"
    rm -r "$AGC_PATH"
    rsync -r "$BACKUP_KEXT_DIR"* "$EXT_PATH"
    rm -r "$SUPPORT_DIR"
    repair_permissions
    echo "Recovery complete.\n"
    prompt_reboot
  else
    echo "\n${BOLD}Could not find valid backup${NORMAL}. Recovery not possible.\n"
  fi
}

# ----- USER INTERFACE

# Exit script
quit()
{
  echo "\n${BOLD}Later then${NORMAL}. Buh bye!\n"
  exit 0
}

# Print script version
show_script_version()
{
  echo "\nScript at ${BOLD}${SCRIPT_VER}${NORMAL}.\n"
}

# Print command line options
usage()
{
  echo "\n>> ${BOLD}Command Line Shortcuts${NORMAL}\n"
  echo " purge-wrangler ${BOLD}-[t n c u r h v s y b q]${NORMAL}"
  echo "
    ${BOLD}-t${NORMAL}: TB1/2 eGPU Patch
    ${BOLD}-n${NORMAL}: Universal NVIDIA eGPU Patch
    ${BOLD}-c${NORMAL}: Patch Status Check
    ${BOLD}-u${NORMAL}: Uninstall Patches
    ${BOLD}-r${NORMAL}: System Recovery
    ${BOLD}-h${NORMAL}: Command Line Shortcuts
    ${BOLD}-v${NORMAL}: Script Version
    ${BOLD}-s${NORMAL}: Disable Hibernation
    ${BOLD}-y${NORMAL}: Enable Hibernation
    ${BOLD}-b${NORMAL}: Reboot System
    ${BOLD}-q${NORMAL}: Quit\n"
}

# Input processing
process_input()
{
  ARG="$1"
  if [[ ! $ARG =~ ^[0-9]+$ || $ARG -le 0 || $ARG -ge 12 ]]
  then
    echo "\nInvalid option. Try again."
    provide_menu_selection
    return
  fi
  "${IF[${ARG}]}"
}

# Menu bypass
process_arg_bypass()
{
  if [[ "$OPTION" ]]
  then
    OPTION=`echo $OPTION | head -c 2 | tail -c 1`
    eval OPTION="${!OPTION}"
    process_input "$OPTION"
    exit 0
  fi
}

# Ask for main menu
ask_menu()
{
  read -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  if [[ "$INPUT" == "Y" ]]
  then
    perform_sys_check
    echo "\n>> ${BOLD}PurgeWrangler ($SCRIPT_VER)${NORMAL}"
    provide_menu_selection
  elif [[ "$INPUT" == "N" ]]
  then
    echo
    exit 0
  else
    echo "\nInvalid choice. Try again.\n"
    ask_menu
  fi
}

# Menu
provide_menu_selection()
{
  echo "
   ${BOLD}>> Patching System${NORMAL}               ${BOLD}>> Reverting & Recovery${NORMAL}
   ${BOLD}1.${NORMAL}  TB1/2 eGPU Patch             ${BOLD}4.${NORMAL}  Uninstall Patches
   ${BOLD}2.${NORMAL}  Universal NVIDIA eGPU Patch  ${BOLD}5.${NORMAL}  System Recovery
   ${BOLD}3.${NORMAL}  Patch Status Check

   ${BOLD}>> Additional Options${NORMAL}            ${BOLD}>> System Sleep Configuration${NORMAL}
   ${BOLD}6.${NORMAL}  Command-Line Shortcuts       ${BOLD}8.${NORMAL}  Disable Hibernation
   ${BOLD}7.${NORMAL}  Script Version               ${BOLD}9.${NORMAL}  Enable Hibernation

   ${BOLD}10.${NORMAL} Reboot System
   ${BOLD}11.${NORMAL} Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-11]: " INPUT
  process_input "$INPUT"
  ask_menu
}

# ----- LEGACY SCRIPT MANAGER

# Manage older script install
check_legacy_script_install()
{
  OLD_INSTALL_FILE="${SUPPORT_DIR}AppleGraphicsControl.kext"
  if [[ -d "$OLD_INSTALL_FILE" ]]
  then
    echo "\n>>${BOLD}Clean Up${NORMAL}\n"
    echo "${BOLD}Safely removing older installation${NORMAL}..."
    if [[ "$TB_PATCH_STATUS" == 1 || "$NV_PATCH_STATUS" == 1 ]]
    then
      uninstall
    fi
    rm -r "$SUPPORT_DIR"
    echo "Removal complete.\n"
    sleep 1
  fi
}

# ----- SCRIPT DRIVER

# Primary execution routine
begin()
{
  perform_sys_check
  first_time_setup
  check_legacy_script_install
  process_arg_bypass
  clear
  echo ">> ${BOLD}PurgeWrangler ($SCRIPT_VER)${NORMAL}"
  provide_menu_selection
}

begin
