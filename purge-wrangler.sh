#!/bin/sh
# Script (purge-wrangler.sh), by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Version 3.0.0
script_ver="3.0.0"

# --------------- ENVIRONMENT SETUP ---------------

# Text management
bold=`tput bold`
normal=`tput sgr0`
underline=`tput smul`

# Operation to perform ["" "amd-patch" "nv-patch" "uninstall" "recover" "check-patch" "version" "help"]
operation="$1"

# Only for devs who know what they're doing ["" "-f" "-nc"]
advanced_operation="$2"

# Kext paths
ext_path="/System/Library/Extensions/"
agc_path="$ext_path"AppleGraphicsControl.kext
sub_agw_path="/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler"
agw_bin="$agc_path$sub_agw_path"

# Backup paths
support_dir="/Library/Application Support/Purge-Wrangler/"
backup_kext_dir="$support_dir"Kexts/
backup_agc="$backup_kext_dir"AppleGraphicsControl.kext
backup_agw_bin="$backup_agc$sub_agw_path"
manifest="$support_dir"manifest.wglr
scratch_file="$support_dir"AppleGPUWrangler.p

# Patch state
tb_patch_status=""
nv_patch_status=""

# IOThunderboltSwitchType reference
iotbswitchtype_ref="494F5468756E646572626F6C74537769746368547970653"
sys_iotbswitchtype=""

# Function reference
r13_test_ref="3C24E81DBDFFFF41F7C500000001757F"
r13_test_patch="3C24E81DBDFFFF41F7C500000000757F"

# System information
macos_ver=`sw_vers -productVersion`
macos_build=`sw_vers -buildVersion`

# Script help
usage()
{
  echo "
  ${bold}Usage${normal}:

    ./purge-wrangler.sh [${underline}params${normal}] [${underline}advanced-params${normal}]

    ${bold}Basics${normal}:

    \t${underline}${bold}No arguments${normal}: Same as amd-patch - standard Apple eGPU support.

    \t${underline}${bold}amd-patch${normal}: Apply patch for AMD eGPUs.

    \t${underline}${bold}nv-patch${normal}: Apply patch for NVDA eGPUs.

    \t${underline}${bold}uninstall${normal}: Repatch kext to default.

    \t${underline}${bold}recover${normal}: Recover system from backup.

    \t${underline}${bold}check-patch${normal}: Check if patch has been applied.

    \t${underline}${bold}version${normal}: See current script version.

    \t${underline}${bold}help${normal}: See script help.

    ${bold}Advanced Options${normal}:

    \t${underline}${bold}-f${normal}: Force override checks and manifest.

    \t${underline}${bold}-nc${normal}: Avoid clear screen on invocation.\n"
}

# --------------- SYSTEM CHECKS ---------------

# Check superuser access
check_sudo()
{
  if [[ "$(id -u)" != 0 && "$operation" != "help" ]]
  then
    sudo "$0" "$operation" "$advanced_operation"
    exit
  fi
}

# Check system integrity protection status
check_sys_integrity_protection()
{
  if [[ `csrutil status | grep -i enabled` ]]
  then
    echo "
    System Integrity Protection needs to be ${bold}disabled${normal} before proceeding.

    Boot into recovery, launch Terminal and execute: ${bold}'csrutil disable'${normal}\n"
    exit
  fi
}

# Check version of macOS High Sierra
check_macos_version()
{
  if [[ "$macos_ver" == "10.13" ||  "$macos_ver" == "10.13.1" || "$macos_ver" == "10.13.2" || "$macos_ver" == "10.13.3" ]]
  then
    echo "
    This version of macOS does not require the patch.\n"
    exit
  fi
}

# Check thunderbolt version/availability
# Credit: @owenrw @ github
check_sys_iotbswitchtype()
{
  tb="$(ioreg | grep AppleThunderboltNHIType)"
  if [[ "$tb[@]" =~ "NHIType3" ]]
  then
    if [[ "$operation" == "nv-patch" ]]
    then
      sys_iotbswitchtype="$iotbswitchtype_ref"3
    else
      echo "This mac does not require any patching for AMD eGPUs.\n"
      exit
    fi
  elif [[ "$tb[@]" =~ "NHIType2" ]]
  then
    sys_iotbswitchtype="$iotbswitchtype_ref"2
  elif [[ "$tb[@]" =~ "NHIType1" ]]
  then
    sys_iotbswitchtype="$iotbswitchtype_ref"1
  else
    echo "Unsupported/Invalid version of thunderbolt.\n"
    exit
  fi
}

# Patch check
check_patch()
{
  if [[ `hexdump -ve '1/1 "%.2X"' "$agw_bin" | grep "$sys_iotbswitchtype"` && "$sys_iotbswitchtype" != "$iotbswitchtype_ref"3 ]]
  then
    tb_patch_status=1
  else
    tb_patch_status=0
  fi
  if [[ `hexdump -ve '1/1 "%.2X"' "$agw_bin" | grep "$r13_test_patch"` ]]
  then
    nv_patch_status=1
  else
    nv_patch_status=0
  fi
}

# Patch status check
check_patch_status()
{
  if [[ "$tb_patch_status" == 0 ]]
  then
    echo "Thunderbolt 1/2 patch not detected.\n"
  else
    echo "Thunderbolt 1/2 patch detected.\n"
  fi
  if [[ "$nv_patch_status" == 0 ]]
  then
    echo "NVIDIA patch not detected.\n"
  else
    echo "NVIDIA patch detected.\n"
  fi
}

# Manage older script install
check_legacy_script_install()
{
  old_install_file="$support_dir"AppleGraphicsControl.kext
  if [[ -d "$old_install_file" && "$advanced_operation" != "-f" ]]
  then
    echo "\nInstallation from ${bold}legacy version(s)${normal} of the script detected.\n"
    echo "\tSafely removing older installation...\n"
    if [[ "$tb_patch_status" == 1 || "$nv_patch_status" == 1 ]]
    then
      echo "${bold}Re-running script...${normal}\n"
      sleep 3
      "$0" "uninstall" "-f"
    fi
    rm -r "$support_dir"
    echo "\tRemoval complete.\n"
    echo "${bold}Re-running script...${normal}\n"
    sleep 3
    "$0" "$operation" "$advanced_operation"
    exit
  fi
}

# Hard checks
check_sudo
check_sys_integrity_protection
check_macos_version

# --------------- OS MANAGEMENT ---------------

# Reboot sequence/message
prompt_reboot()
{
  if [[ "$advanced_operation" != "-f" ]]
  then
    echo "${bold}System ready.${normal} Restart now to apply changes.\n"
  fi
}

# Rebuild kernel cache
invoke_kext_caching()
{
  if [[ "$advanced_operation" != "-f" ]]
  then
    echo "\t${bold}Rebuilding kext cache...${normal}\n"
    touch "$ext_path"
    kextcache -q -update-volume /
    echo "\tRebuild complete.\n"
  fi
}

# Repair kext and binary permissions
repair_permissions()
{
  echo "\t${bold}Repairing permissions...${normal}\n"
  chmod 700 "$agw_bin"
  chown -R root:wheel "$agc_path"
  echo "\tPermissions set.\n"
  invoke_kext_caching
}

# --------------- BACKUP SYSTEM ---------------

# Write manifest file
# Line 1: Unpatched Kext SHA -- Kext in Backup directory
# Line 2: Patched Kext (in /S/L/E) SHA -- Kext in original location
# Line 3: macOS Version
# Line 4: macOS Build No.
write_manifest()
{
  if [[ "$advanced_operation" != "-f" ]]
  then
    unpatched_kext_sha=`shasum -a 512 -b "$backup_agw_bin" | awk '{ print $1 }'`
    patched_kext_sha=`shasum -a 512 -b "$agw_bin" | awk '{ print $1 }'`
    echo "$unpatched_kext_sha\n$patched_kext_sha\n$macos_ver\n$macos_build" > "$manifest"
  fi
}

# Primary procedure
execute_backup()
{
  mkdir -p "$backup_kext_dir"
  rsync -r "$agc_path" "$backup_kext_dir"
}

# Backup procedure
backup_system()
{
  echo "${bold}Backing up...${normal}\n"
  if [[ -s "$backup_agc" && -s "$manifest" ]]
  then
    manifest_macos_ver=`sed "3q;d" "$manifest"`
    manifest_macos_build=`sed "4q;d" "$manifest"`
    if [[ "$manifest_macos_ver" == "$macos_ver" && "$manifest_macos_build" == "$macos_build" ]]
    then
      echo "Backup already exists.\n"
    else
      echo "Different build/version of macOS detected. ${bold}Updating backup...${normal}\n"
      rm -r "$backup_agc"
      if [[ "$patch_status" == 1 ]]
      then
        echo "${bold}Uninstalling patch before backup update...${normal}\n"
        echo "${bold}Re-running script...${normal}\n"
        sleep 3
        "$0" "uninstall" "-f"
        echo "System re-patched.\n"
        echo "${bold}Re-running script...${normal}\n"
        sleep 3
        "$0" "$operation" "$advanced_operation"
        exit
      fi
      execute_backup
      echo "Update complete.\n"
    fi
  else
    execute_backup
    echo "Backup complete.\n"
  fi
}

# --------------- PATCHING SYSTEM ---------------

# Primary patching mechanism
generic_patcher()
{
  offending_hex="$1"
  patched_hex="$2"
  hexdump -ve '1/1 "%.2X"' "$agw_bin" |
  sed "s/$offending_hex/$patched_hex/g" |
  xxd -r -p > "$scratch_file"
  rm "$agw_bin"
  mv "$scratch_file" "$agw_bin"
}

# In-place re-patcher
uninstall()
{
  if [[ -d "$support_dir" || "$advanced_operation" == "-f" ]]
  then
    echo "${bold}Uninstalling...${normal}\n"
    generic_patcher "$sys_iotbswitchtype" "$iotbswitchtype_ref"3
    generic_patcher "$r13_test_patch" "$r13_test_ref"
    repair_permissions
    echo "Uninstallation Complete.\n"
    prompt_reboot
  else
    echo "No installation found. No action taken.\n"
    exit
  fi
}

# Patch TB1/2 block + NVIDIA kernel panics
apply_patch()
{
  echo "${bold}Patching...${normal}\n"
  generic_patcher "$iotbswitchtype_ref"3 "$sys_iotbswitchtype"
  if [[ "$operation" == "nv-patch" ]]
  then
    generic_patcher "$r13_test_ref" "$r13_test_patch"
  fi
  repair_permissions
  echo "Patch Complete.\n"
  prompt_reboot
}

# --------------- RECOVERY SYSTEM ---------------

# Recovery procedure
start_recovery()
{
  if [[ -s "$backup_agc" ]]
  then
    echo "${bold}Recovering...${normal}\n"
    rm -r "$agc_path"
    rsync -r "$backup_kext_dir"* "$ext_path"
    rm -r "$support_dir"
    repair_permissions
    echo "Recovery complete.\n"
    prompt_reboot
  else
    echo "Could not find valid backup. Recovery not possible.\n"
  fi
}

# --------------- INPUT MANAGER ---------------

# Avoid clearing screen
if [[ "$advanced_operation" != "-nc" ]]
then
  clear
fi
echo "\n---------- ${bold}PURGE-WRANGLER ($script_ver)${normal} ----------\n"

# Option handlers
if [[ "$operation" == "" || "$operation" == "amd-patch" || "$operation" == "nv-patch" ]]
then
  check_sys_iotbswitchtype
  check_patch
  check_legacy_script_install
  backup_system
  apply_patch
  write_manifest
elif [[ "$operation" == "uninstall" ]]
then
  check_sys_iotbswitchtype
  check_patch
  check_legacy_script_install
  uninstall
  write_manifest
elif [[ "$operation" == "recover" ]]
then
  check_patch
  check_legacy_script_install
  start_recovery
elif [[ "$operation" == "help" ]]
then
  printf '\e[8;32;80t'
  usage
elif [[ "$operation" == "check-patch" ]]
then
  check_patch
  check_patch_status
elif [[ "$operation" == "version" ]]
then
  echo "Version: $script_ver\n"
else
  echo "Invalid option. Type ./purge-wrangler.sh help for more information.\n"
fi
