#!/bin/sh

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308 @ github, mac_editor @ egpu.io)
# License: Specified in LICENSE.md.

# ----- COMMAND LINE ARGS

# Script
SCRIPT="$0"

# Option
OPTION="$1"

# ----- ENVIRONMENT

# Script version
SCRIPT_VER="3.0.0"

# User Input
INPUT=""

# Text management
BOLD=`tput bold`
NORMAL=`tput sgr0`
UNDERLINE=`tput smul`

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
TB_VER_ERR=3

# Input-Function Map
IF[1]="patch_tb"
IF[2]="patch_nv"
IF[3]="check_sys"
IF[4]="uninstall"
IF[5]="recover_sys"
IF[6]="reboot_sys"
IF[7]="quit"

# System Information
MACOS_VER=`sw_vers -productVersion`
MACOS_BUILD=`sw_vers -buildVersion`
SYS_TB_VER=""

# AppleGPUWrangler References
TB_SWITCH_HEX="494F5468756E646572626F6C74537769746368547970653"

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
SCRATCH_FILE="${SUPPORT_DIR}AppleGPUWrangler.p"

# ----- SYSTEM CONFIGURATION MANAGER

# Elevate privileges
elevate_privileges()
{
  if [[ `id -u` != 0 ]]
  then
    sudo "$0" "$OPTION"
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
    echo "\nThis script requires macOS 10.13.6 or later.\n"
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

# Cumulative system check
perform_sys_check()
{
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
}

# ----- OS MANAGEMENT

# Reboot sequence/message
prompt_reboot()
{
  if [[ "$OPTION" != "-f" ]]
  then
    echo "${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
  fi
}

# Rebuild kernel cache
invoke_kext_caching()
{
  if [[ "$OPTION" != "-f" ]]
  then
    echo "${BOLD}Rebuilding kext cache...${NORMAL}"
    touch "$EXT_PATH"
    kextcache -q -update-volume /
    echo "Rebuild complete."
  fi
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

# ----- RECOVERY SYSTEM

# Recovery logic
recover_sys()
{
  if [[ -s "$BACKUP_AGC" ]]
  then
    echo "\n>> ${BOLD}Recover System${NORMAL}\n"
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

quit()
{
  echo "\n${BOLD}Later then${NORMAL}. Buh bye!\n"
  exit 0
}

provide_menu_selection()
{
  echo "
   ${BOLD}1.${NORMAL} TB1/2 Patch
   ${BOLD}2.${NORMAL} NVIDIA eGPU + TB1/2 Patch (if needed)
   ${BOLD}3.${NORMAL} System Check
   ${BOLD}4.${NORMAL} Uninstall Patch(es)
   ${BOLD}5.${NORMAL} Recover System
   ${BOLD}6.${NORMAL} Reboot System
   ${BOLD}7.${NORMAL} Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-7]: " INPUT
  if [[ "$INPUT" < 1 || "$INPUT" > 7 ]]
  then
    echo "\nInvalid selection. Try again."
    provide_menu_selection
    return
  fi
  "${IF[${INPUT}]}"
}

# ----- SCRIPT DRIVER

main()
{
  perform_sys_check
  clear
  echo ">> ${BOLD}PurgeWrangler ($SCRIPT_VER)${NORMAL}"
  provide_menu_selection
}

main
