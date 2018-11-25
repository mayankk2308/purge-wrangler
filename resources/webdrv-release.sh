#!/usr/bin/env bash

# webdrv-release.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 1.0.0

bold="$(tput bold)"
normal="$(tput sgr0)"
PlistBuddy="/usr/libexec/PlistBuddy"

fetch_webdrv_info() {
  local wd_plist=".webdrv.plist"
  local data="$(curl -s "https://gfe.nvidia.com/mac-update")"
  if [[ -z "${data}" ]]
  then
    echo -e "Unable to fetch data.\n"
    return
  fi
  echo "${data}" > "${wd_plist}"
  if [[ ! -f "${wd_plist}" ]]
  then
    echo -e "Unable to extract data.\n"
    rm -f "${wd_plist}" 2>/dev/null
    return
  fi
  local latest_drv_ver="$(${PlistBuddy} -c "Print :updates:0:version" "${wd_plist}")"
  local latest_drv_build="$(${PlistBuddy} -c "Print :updates:0:OS" "${wd_plist}")"
  echo -e "${bold}Latest Web Driver${normal}: ${latest_drv_ver}"
  echo -e "${bold}Supported OS Build${normal}: ${latest_drv_build}"
  echo -e "${bold}Your OS Build${normal}: $(sw_vers -buildVersion)"
  rm -f "${wd_plist}" 2>/dev/null
}

fetch_webdrv_info