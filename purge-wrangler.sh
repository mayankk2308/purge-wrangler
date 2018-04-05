#!/bin/sh
# Script (purge-wrangler.sh), by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Version 1.0.0

operation="$1"
tb_version="$2"

ext_path="/System/Library/Extensions/"
agc_path="$ext_path"AppleGraphicsControl.kext
agw_bin="$agc_path"/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler
backup_dir="/Library/Application Support/Purge-Wrangler/"
iotbswitchtype3=494F5468756E646572626F6C745377697463685479706533
iotbswitchtype2=494F5468756E646572626F6C745377697463685479706532
iotbswitchtype1=494F5468756E646572626F6C745377697463685479706531

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

check_sudo()
{
  if [[ "$(id -u)" != 0 ]]
  then
    echo "This script requires superuser access. Please run with 'sudo'.\n"
    exit
  fi
}

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

check_macos_version()
{
  macos_ver=`sw_vers -productVersion`
  if [[ "$macos_ver" == "10.13" ||  "$macos_ver" == "10.13.1" || "$macos_ver" == "10.13.2" || "$macos_ver" == "10.13.3" ]]
  then
    echo "
    This version of does not require the patch.\n"
    exit
  fi
}

check_tb_version()
{
  if [[ "$tb_version" == "tb1" ]]
  then
    tb_version="$iotbswitchtype1"
  elif [[ "$tb_version" == "tb2" ]]
  then
    tb_version="$iotbswitchtype2"
  else
    echo "Unsupported/Invalid version of thunderbolt or none provided."
    exit
  fi
}

invoke_kext_caching()
{
  echo "Rebuilding kext cache..."
  touch "$ext_path"
  kextcache -q -update-volume /
  echo "Patch Complete.\n"
}

initiate_reboot()
{
  for time in {5..0}
  do
    printf "Restarting in $time s...\r"
    sleep 1
  done
  reboot
}

repair_permissions()
{
  echo "Repairing permissions..."
  chmod 700 "$agw_bin"
  chown -R root:wheel "$agc_path"
  invoke_kext_caching
  initiate_reboot
}

# Automatic re-patching to normal will be implemented in a future release if
# deemed necessary
uninstall()
{
  if [[ -d "$backup_dir" ]]
  then
    echo "Uninstalling..."
    rm -r "$agc_path"
    rsync -r "$backup_dir"* "$ext_path"
    rm -r "$backup_dir"
    repair_permissions
    echo "Uninstallation complete.\n"
  else
    echo "Could not find valid installation."
  fi
}

apply_patch()
{
  echo "Patching..."
  mkdir -p "$backup_dir"
  rsync -r "$agc_path" "$backup_dir"
  hexdump -ve '1/1 "%.2X"' "$agw_bin" |
  sed "s/$iotbswitchtype3/$tb_version/g" |
  xxd -r -p > AppleGPUWrangler.p
  rm "$agw_bin"
  mv AppleGPUWrangler.p "$agw_bin"
  repair_permissions
}

check_sudo
check_sys_integrity_protection
check_macos_version

if [[ "$operation" == "patch" ]]
then
  check_tb_version
  apply_patch
elif [[ "$operation" == "uninstall" ]]
then
  uninstall
elif [[ "$operation" == "help" ]]
then
  usage
  exit
fi
