#!/bin/sh
# Script (purge-wrangler.sh), by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Version 1.1.0

# Parameters

# operation to perform ["" "uninstall" "help"]
operation="$1"

# Kext paths
ext_path="/System/Library/Extensions/"
agc_path="$ext_path"AppleGraphicsControl.kext
agw_bin="$agc_path"/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler

# Backup directory
backup_dir="/Library/Application Support/Purge-Wrangler/"

# IOThunderboltSwitchType reference
iotbswitchtype=494F5468756E646572626F6C74537769746368547970653

# Script help
usage()
{
  echo "
  Usage:

    ./purge-wrangler.sh [params]

    No arguments: Apply patch and reboot.

    uninstall: Remove all changes made by the script.

    Note: Do not uninstall if you upgraded your version of

    macOS before uninstalling."
}

# Check superuser access
check_sudo()
{
  if [[ "$(id -u)" != 0 ]]
  then
    echo "This script requires superuser access. Please run with 'sudo'.\n"
    exit
  fi
}

# Check system integrity protection status
check_sys_integrity_protection()
{
  if [[ `csrutil status | grep -i "enabled"` ]]
  then
    echo "
    System Integrity Protection needs to be disabled before proceeding.

    Boot into recovery, launch Terminal and execute: 'csrutil disable'\n"
    exit
  fi
}

# Check version of macOS High Sierra
check_macos_version()
{
  macos_ver=`sw_vers -productVersion`
  if [[ "$macos_ver" == "10.13" ||  "$macos_ver" == "10.13.1" || "$macos_ver" == "10.13.2" || "$macos_ver" == "10.13.3" ]]
  then
    echo "
    This version of macOS does not require the patch.\n"
    exit
  fi
}

# Check thunderbolt version/availability
# Credit: learex @ github.com / fr34k @ egpu.io
check_tb_version()
{
  tb="$(system_profiler SPThunderboltDataType | grep Speed)"
  if [[ "$tb[@]" =~ "20" ]]
  then
    tb_version="$iotbswitchtype"2
  elif [[ "$tb[@]" =~ "10" ]]
  then
    tb_version="$iotbswitchtype"1
  else
    echo "Unsupported/Invalid version of thunderbolt or none provided."
    exit
  fi
}

# Rebuild kernel cache
invoke_kext_caching()
{
  echo "Rebuilding kext cache..."
  touch "$ext_path"
  kextcache -q -update-volume /
}

# Reboot sequence
initiate_reboot()
{
  for time in {5..0}
  do
    printf "Restarting in $time s...\r"
    sleep 1
  done
  reboot
}

# Repair kext and binary permissions
repair_permissions()
{
  echo "Repairing permissions..."
  chmod 700 "$agw_bin"
  chown -R root:wheel "$agc_path"
  invoke_kext_caching
}

# Primary patching mechanism
generic_patcher()
{
  offending_hex="$1"
  patched_hex="$2"
  hexdump -ve '1/1 "%.2X"' "$agw_bin" |
  sed "s/$offending_hex/$patched_hex/g" |
  xxd -r -p > AppleGPUWrangler.p
  rm "$agw_bin"
  mv AppleGPUWrangler.p "$agw_bin"
  repair_permissions
}

# In-place re-patcher
# Backup directory for emergency recovery only
uninstall()
{
  echo "Uninstalling..."
  generic_patcher "$tb_version" "$iotbswitchtype"3
  echo "Uninstallation Complete.\n"
  initiate_reboot
}

# Backup system
backup_system()
{
  mkdir -p "$backup_dir"
  rsync -r "$agc_path" "$backup_dir"
}

# Patch TB3 check
apply_patch()
{
  echo "Patching..."
  generic_patcher "$iotbswitchtype"3 "$tb_version"
  echo "Patch Complete.\n"
  initiate_reboot
}

# Recovery system
start_recovery()
{
  if [[ -d "$backup_dir" ]]
  then
    echo "Recovering..."
    rm -r "$agc_path"
    rsync -r "$backup_dir"* "$ext_path"
    repair_permissions
    echo "Recovery complete.\n"
    initiate_reboot
  else
    echo "Could not find valid backup. Recovery failed."
  fi
}

# Hard checks
check_sudo
check_sys_integrity_protection
check_macos_version

# Option handlers
if [[ "$operation" == "" ]]
then
  check_tb_version
  backup_system
  apply_patch
elif [[ "$operation" == "uninstall" ]]
then
  check_tb_version
  uninstall
elif [[ "$operation" == "recover" ]]
then
  start_recovery
elif [[ "$operation" == "help" ]]
then
  usage
  exit
fi
