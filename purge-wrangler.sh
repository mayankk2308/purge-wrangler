#!/usr/bin/env bash

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 6.0.0

# ----- COMMAND LINE ARGS

# Setup command args + data
script="${BASH_SOURCE}"
option=""

# ----- ENVIRONMENT

# Enable case-insensitive comparisons
shopt -s nocasematch

# Text management
bold="$(tput bold)"
normal="$(tput sgr0)"
underline="$(tput smul)"

# Script binary
local_bin="/usr/local/bin"
script_bin="${local_bin}/purge-wrangler"
tmp_script="${local_bin}/purge-wrangler-new"
is_bin_call=0
call_script_file=""

# Script version
script_major_ver="6" && script_minor_ver="0" && script_patch_ver="0"
script_ver="${script_major_ver}.${script_minor_ver}.${script_patch_ver}"
latest_script_data=""
latest_release_dwld=""

# Script preference plist
script_launchagent="io.egpu.purge-wrangler-agent"

# User userinput
userinput=""

# System information
macos_ver="$(sw_vers -productVersion)"
macos_build="$(sw_vers -buildVersion)"
system_thunderbolt_ver=""

# AppleGPUWrangler references
hex_thunderboltswitchtype="494F5468756E646572626F6C74537769746368547970653"

# IOGraphicsFamily references
hex_iopcitunnelled="494F50434954756E6E656C6C6564"
hex_iopcitunnelled_patch="494F50434954756E6E656C6C6571"

# IOThunderboltFamily references
hex_skipenum="554889E54157415641554154534881EC2801"
hex_skipenum_patch="554889E531C05DC341554154534881EC2801"

# Patch status indicators
amdlegacy_enabled=2
tbswitch_enabled=2
nvidia_enabled=2
ti82_enabled=2

# System Discrete GPU
dgpu_vendor=""

# General kext paths
sysextensions_path="/System/Library/Extensions/"
libextensions_path="/Library/Extensions/"

## AppleGPUWrangler
agc_kextpath="${sysextensions_path}AppleGraphicsControl.kext"
agc_binsubpath="/Contents/PlugIns/AppleGPUWrangler.kext/Contents/MacOS/AppleGPUWrangler"
agw_binpath="${agc_kextpath}${agc_binsubpath}"

## IONDRVSupport
iondrv_kextpath="${sysextensions_path}IONDRVSupport.kext"
iondrv_plistpath="${iondrv_kextpath}/Info.plist"

## IOGraphicsFamily
iog_kextpath="${sysextensions_path}IOGraphicsFamily.kext"
iog_subpath="/IOGraphicsFamily"
iog_binpath="${iog_kextpath}${iog_subpath}"

## IOThunderboltFamily
iotfam_kextpath="${sysextensions_path}IOThunderboltFamily.kext"
iotfam_binsubpath="/Contents/MacOS/IOThunderboltFamily"
iotfam_binpath="${iotfam_kextpath}${iotfam_binsubpath}"
didinstall_ti82=0

## NVDAStartup
nvdastartup_kextpath="${sysextensions_path}NVDAStartup.kext"
nvdastartup_plistpath="${nvdastartup_kextpath}/Contents/Info.plist"

## NVDAStartupWeb
nvdastartupweb_kextpath="${libextensions_path}NVDAStartupWeb.kext"
nvdastartupweb_plistpath="${nvdastartupweb_kextpath}/Contents/Info.plist"

## NVDAEGPUSupport
deprecated_nvsolution_kextpath="${libextensions_path}NVDAEGPUSupport.kext"

## AMDLegacySupport
deprecated_automate_egpu_kextpath="${libextensions_path}automate-eGPU.kext"
amdlegacy_downloadurl="http://raw.githubusercontent.com/mayankk2308/purge-wrangler/${script_ver}/resources/AMDLegacySupport.kext.zip"
amdlegacy_downloadpath="${libextensions_path}AMDLegacySupport.kext.zip"
amdlegacy_kextpath="${libextensions_path}AMDLegacySupport.kext"
didinstall_amdlegacy=0

# General backup path
support_dirpath="/Library/Application Support/Purge-Wrangler/"
backupkext_dirpath="${support_dirpath}Kexts/"

## Deprecated manifest
manifest="${support_dirpath}manifest.wglr"

# pb configuration
pb="/usr/libexec/PlistBuddy"
set_iognvda_pcitunnelled=":IOKitPersonalities:3:IOPCITunnelCompatible bool"
set_nvdastartup_pcitunnelled=":IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool"
set_nvdastartup_requiredos=":IOKitPersonalities:NVDAStartup:NVDARequiredOS"

# Property list generation defaults
plist_defaultstring="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">\n<dict>\n</dict>\n</plist>"

# Script configuration path
scriptconfig_filepath="${support_dirpath}io.egpu.purge-wrangler.config.plist"

# Webdriver information
webdriver_plistpath="/usr/local/bin/webdriver.plist"
using_nvdawebdrv=0

# --- SCRIPT HELPERs

## -- User Interface

### Prompt for a yes/no action
yesno_action() {
  local prompt="${1}"
  local yesaction="${2}"
  local noaction="${3}"
  local userinput=""
  echo
  read -n1 -p "${prompt} [Y/N]: " userinput
  [[ ${userinput} == "Y" ]] && echo && eval "${yesaction}" && echo && return
  [[ ${userinput} == "N" ]] && echo && eval "${noaction}" && echo && return
  echo -e "\nInvalid choice. Please try again."
  yesno_action
}

## -- Binary Patching Mechanism (P1 -> P2 -> P3)

### P1: Create hex representation for target binary
create_hexrepresentation() {
  local target_binary="${1}"
  local scratch_hex="${target_binary}.hex"
  hexdump -ve '1/1 "%.2X"' "${target_binary}" > "${scratch_hex}"
}

### P2: Primary binary patching mechanism
patch_binary() {
  local target_binary="${1}"
  local find="${2}"
  local replace="${3}"
  local scratch_hex="${target_binary}.hex"
  sed -i "" -e "s/${find}/${replace}/g" "${scratch_hex}"
}

### P3: Generic binary generator for given hex file
create_patched_binary() {
  local target_binary="${1}"
  local scratch_hex="${target_binary}.hex"
  local scratch_binary="${scratch_hex}.bin"
  xxd -r -p "${scratch_hex}" "${scratch_binary}"
  rm "${target_binary}" "${scratch_hex}" && mv "${scratch_binary}" "${target_binary}"
}

## -- PLIST Patching Mechanism

### Patch specified plist
modify_plist() {
  local target_plist="${1}"
  local command="${2}"
  local key="${3}"
  local value="${4}"
  $pb -c "${command} ${key} ${value}" "${target_plist}" 2>/dev/null
}

## -- Configuration Handling

### Generates a configuration property list if needed
generate_config() {
  mkdir -p "${support_dirpath}"
  [[ -f "${scriptconfig_filepath}" ]] && return
  > "${scriptconfig_filepath}"
  echo -e "${plist_defaultstring}" >> "${scriptconfig_filepath}"
  $pb -c "Add :OSVersionAtPatch string ${macos_ver}" "${scriptconfig_filepath}"
  $pb -c "Add :OSBuildAtPatch string ${macos_build}" "${scriptconfig_filepath}"
  $pb -c "Add :DidApplyBinPatch bool false" "${scriptconfig_filepath}"
}

### Updates the configuration as necessary
update_config() {
  generate_config
  check_patch
  local status=("false" "true" "false")
  $pb -c "Set :OSVersionAtPatch ${macos_ver}" "${scriptconfig_filepath}"
  $pb -c "Set :OSBuildAtPatch ${macos_build}" "${scriptconfig_filepath}"
  $pb -c "Set :DidApplyBinPatch ${status[((${tbswitch_enabled} | ${nvidia_enabled} | ${ti82_enabled}))]}" "${scriptconfig_filepath}"
}

### Deprecate manifest
deprecate_manifest() {
  [[ ! -f "${manifest}" ]] && return
  macos_ver="$(sed "3q;d" "${manifest}")"
  macos_build="$(sed "4q;d" "${manifest}")"
  local manifest_patch="$(sed -n "9,11p" "${manifest}")"
  update_config
  [[ ${manifest_patch} =~ 1 ]] && $pb -c "Set :DidApplyBinPatch true" "${scriptconfig_filepath}"
  macos_ver="$(sw_vers -productVersion)"
  macos_build="$(sw_vers -buildVersion)"
  rm -f "${manifest}"
}


### Create LaunchAgent
create_launchagent() {
  local agent_dirpath="/Users/${SUDO_USER}/Library/LaunchAgents/"
  mkdir -p "${agent_dirpath}"
  local agent_plistpath="${agent_dirpath}${script_launchagent}.plist"
  > "${agent_plistpath}"
  echo -e "${plist_defaultstring}" >> "${agent_plistpath}"
  $pb -c "Add :Label string ${script_launchagent}" "${agent_plistpath}"
  $pb -c "Add :OnDemand bool false" "${agent_plistpath}"
  $pb -c "Add :LaunchOnlyOnce bool true" "${agent_plistpath}"
  $pb -c "Add :RunAtLoad bool true" "${agent_plistpath}"
  $pb -c "Add :UserName string ${SUDO_USER}" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments array" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments:0 string ${script_bin}" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments:1 string --on-launch-check" "${agent_plistpath}"
  chown "${SUDO_USER}" "${agent_plistpath}"
}

# --- SCRIPT SOFTWARE UPDATE SYSTEM

### Perform software update
perform_software_update() {
  echo -e "${bold}Downloading...${normal}"
  curl -q -L -s -o "${tmp_script}" "${latest_release_dwld}"
  [[ "$(cat "${tmp_script}")" == "Not Found" ]] && echo -e "Download failed.\n${bold}Continuing without updating...${normal}" && sleep 1 && rm "${tmp_script}" && return
  echo -e "Download complete.\n${bold}Updating...${normal}"
  chmod 700 "${tmp_script}" && chmod +x "${tmp_script}"
  rm "${script}" && mv "${tmp_script}" "${script}"
  chown "${SUDO_USER}" "${script}"
  echo -e "Update complete. ${bold}Relaunching...${normal}"
  sleep 1
  "${script}"
  exit 0
}

### Prompt for update
prompt_software_update() {
  echo
  read -n1 -p "${bold}Would you like to update?${normal} [Y/N]: " userinput
  echo
  [[ "${userinput}" == "Y" ]] && echo && perform_software_update && return
  [[ "${userinput}" == "N" ]] && echo -e "\n${bold}Proceeding without updating...${normal}" && sleep 1 && return
  echo -e "\nInvalid choice. Try again."
  prompt_software_update
}

### Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${local_bin}"
  [[ "${is_bin_call}" == 0 ]] && return
  latest_script_data="$(curl -q -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest")"
  latest_release_ver="$(echo -e "${latest_script_data}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  latest_release_dwld="$(echo -e "${latest_script_data}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  latest_major_ver="$(echo -e "${latest_release_ver}" | cut -d '.' -f1)"
  latest_minor_ver="$(echo -e "${latest_release_ver}" | cut -d '.' -f2)"
  latest_patch_ver="$(echo -e "${latest_release_ver}" | cut -d '.' -f3)"
  if [[ $latest_major_ver > $script_major_ver || ($latest_major_ver == $script_major_ver && $latest_minor_ver > $script_minor_ver) || ($latest_major_ver == $script_major_ver && $latest_minor_ver == $script_minor_ver && $latest_patch_ver > $script_patch_ver) && ! -z "${latest_release_dwld}" ]]
  then
    echo -e "\n>> ${bold}Software Update${normal}\n\nSoftware updates are available.\n\nOn Your System    ${bold}${script_ver}${normal}\nLatest Available  ${bold}${latest_release_ver}${normal}\n\nFor the best experience, stick to the latest release."
    yesno_action "${bold}Would you like to update?${normal}" "perform_software_update" "echo -e \"\n${bold}Proceeding without updating...${normal}\" && sleep 1"
  fi
}

# --- SYSTEM CONFIGURATION MANAGER

### Check caller
validate_caller() {
  [[ "${1}" == "bash" && -z "${2}" ]] && echo -e "\n${bold}Cannot execute${normal}.\nPlease see the README for instructions.\n" && exit
  [[ "${1}" != "${script}" ]] && option="${3}" || option="${2}"
  [[ "${script}" == "${script_bin}" || "${script}" == "purge-wrangler" ]] && is_bin_call=1
}

### Elevate privileges
elevate_privileges() {
  if [[ $(id -u) != 0 ]]
  then
    sudo bash "${script}" "${option}"
    exit
  fi
}

### System integrity protection check
check_sip() {
  if [[ ! -z "$(csrutil status | grep -i enabled)" ]]
  then
    echo -e "\nPlease disable ${bold}System Integrity Protection${normal}.\n"
    exit
  fi
}

### macOS compatibility check
check_macos_version() {
  local macos_major_ver="$(echo -e "${macos_ver}" | cut -d '.' -f2)"
  local macos_minor_ver="$(echo -e "${macos_ver}" | cut -d '.' -f3)"
  [[ (${macos_major_ver} < 13) || (${macos_minor_ver} == 13 && ${macos_minor_ver} < 4) ]] && echo -e "\n${bold}macOS 10.13.4 or later${normal} required.\n" && exit
}

### Ensure presence of system extensions
check_sys_extensions() {
  [[ ! -s "${agc_kextpath}" || ! -s "${agw_binpath}" || ! -s "${iondrv_kextpath}" || ! -s "${iog_binpath}" || ! -s "${iotfam_kextpath}" || ! -s "${iotfam_binpath}" ]] && echo -e "\nSystem could be unbootable. Consider ${bold}macOS Recovery${normal}.\n" && sleep 1
}

### Retrieve thunderbolt version
retrieve_tb_ver() {
  local tb_type="$(ioreg | grep AppleThunderboltNHIType)"
  tb_type="${tb_type##*+-o AppleThunderboltNHIType}"
  tb_type="${tb_type::1}"
  system_thunderbolt_ver="${hex_thunderboltswitchtype}${tb_type}"
}

### Retrieve patch status
check_patch() {
  [[ ! -f "${agw_binpath}" || ! -f "${iog_binpath}" || ! -f "${iotfam_binpath}" ]] && return
  local hex_agwbin="$(hexdump -ve '1/1 "%.2X"' "${agw_binpath}")"
  local hex_iogbin="$(hexdump -ve '1/1 "%.2X"' "${iog_binpath}")"
  local hex_iotfambin="$(hexdump -ve '1/1 "%.2X"' "${iotfam_binpath}")"
  [[ -d "${amdlegacy_kextpath}" ]] && amdlegacy_enabled=1 || amdlegacy_enabled=0
  [[ "${hex_agwbin}" =~ "${system_thunderbolt_ver}" && "${system_thunderbolt_ver}" != "${hex_thunderboltswitchtype}"3 ]] && tbswitch_enabled=1 || tbswitch_enabled=0
  [[ "${hex_iogbin}" =~ "${hex_iopcitunnelled_patch}" ]] && nvidia_enabled=1 || nvidia_enabled=0
  [[ "${hex_iotfambin}" =~ "${hex_skipenum_patch}" ]] && ti82_enabled=1 || ti82_enabled=0
}

### Display patch statuses
check_patch_status() {
  local status=("Disabled" "Enabled" "Unknown")
  echo -e "\n>> ${bold}Patch Status${normal}\n"
  echo -e "${bold}TB1/2 AMD eGPUs${normal}   ${status[$tbswitch_enabled]}"
  echo -e "${bold}Legacy AMD eGPUs${normal}  ${status[$amdlegacy_enabled]}"
  echo -e "${bold}NVIDIA eGPUs${normal}      ${status[$nvidia_enabled]}"
  echo -e "${bold}Ti82 Devices${normal}      ${status[${ti82_enabled}]}\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_sys_extensions
  check_patch
  deprecate_manifest
  didinstall_amdlegacy=0
  didinstall_ti82=0
  using_nvdawebdrv=0
}

# ----- OS MANAGEMENT

# Sanitize system permissions and caches
sanitize_system() {
  echo -e "${bold}Sanitizing system...${normal}"
  chmod -R 755 "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  chown -R root:wheel "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  echo -e "System sanitized."
}

# ----- BACKUP SYSTEM

# Primary procedure
execute_backup() {
  mkdir -p "${backupkext_dirpath}"
  rsync -rt "${agc_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iog_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iondrv_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iotfam_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${nvdastartup_kextpath}" "${backupkext_dirpath}"
}

# Backup procedure
backup_system() {
  echo -e "${bold}Backing up...${normal}"
  if [[ $(find "${backupkext_dirpath}" -mindepth 1 -print -quit 2>/dev/null) && -s "${scriptconfig_filepath}" ]]
  then
    local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
    local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
    if [[ "${prev_macos_ver}" == "${macos_ver}" && "${prev_macos_build}" == "${macos_build}" ]]
    then
      if [[ ${tbswitch_enabled} == 0 && ${nvidia_enabled} == 0 && ${ti82_enabled} == 0 ]]
      then
        execute_backup
        echo -e "Backup refreshed."
        update_config
        return
      fi
      echo -e "Backup already exists."
    else
      echo -e "\n${bold}Last Backup${normal}: ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
      echo -e "${bold}Current System${normal}: ${macos_ver} ${bold}[${macos_build}]${normal}\n"
      echo -e "${bold}Updating backup...${normal}"
      if [[ ${tbswitch_enabled} == 1 || ${nvidia_enabled} == 1 || ${ti82_enabled} == 1 ]]
      then
        echo -e "${bold}Uninstalling patch before backup update...${normal}"
        uninstall
        echo -e "${bold}Re-running script...${normal}" && sleep 1
        "${script}" "${option}"
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
  update_config
  create_launchagent
  echo -e "${bold}Patch complete.\n\n${bold}System ready.${normal} Restart now to apply changes.\n"
}

# Install AMDLegacySupport.kext
run_legacy_kext_installer() {
  echo -e "${bold}Downloading AMDLegacySupport...${normal}"
  curl -q -L -s -o "${amdlegacy_downloadpath}" "${amdlegacy_downloadurl}"
  if [[ ! -e "${amdlegacy_downloadpath}" || ! -s "${amdlegacy_downloadpath}" || "$(cat "${amdlegacy_downloadpath}")" == "404: Not Found" ]]
  then
    echo -e "Could not download.\n\n${bold}Continuing remaining patches...${normal}"
    rm -rf "${amdlegacy_downloadpath}" 2>/dev/null
    return
  fi
  echo -e "Download complete.\n${bold}Installing...${normal}"
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  unzip -d "${libextensions_path}" "${amdlegacy_downloadpath}" 1>/dev/null 2>&1
  rm -r "${amdlegacy_downloadpath}" "${libextensions_path}/__MACOSX" 1>/dev/null 2>&1
  echo -e "Installation complete.\n\n${bold}Continuing...${normal}"
  didinstall_amdlegacy=1
}

# Prompt AMDLegacySupport.kext install
install_legacy_kext() {
  [[ -d "${amdlegacy_kextpath}" ]] && return
  echo -e "\nIt is possible to use legacy AMD GPUs if needed.\nLegacy AMD GPUs refer to eGPUs not sanctioned as ${bold}\"supported by Apple\"${normal}.\n"
  if [[ ${AMD_LEGACY_INSTALLS} != 1 && ${AMD_LEGACY_INSTALLS} != 2 ]]
  then
    read -n1 -p "Enable ${bold}Legacy${normal} AMD eGPUs? [Y/N]: " userinput
    echo
    [[ "${userinput}" == "Y" ]] && echo && run_legacy_kext_installer && return
    [[ "${userinput}" == "N" ]] && return
    echo -e "\nInvalid option.\n" && install_legacy_kext
  elif [[ ${AMD_LEGACY_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${bold}always${normal} install legacy support.\n${bold}Proceeding...${normal}\n"
    run_legacy_kext_installer
  else
    echo -e "Your preferences are set to ${bold}never${normal} install legacy support.\n${bold}Proceeding...${normal}\n"
  fi
}

# Patch for Ti82 support
patch_ti82() {
  echo "${bold}Enabling Ti82 support...${normal}"
  create_hexrepresentation "${iotfam_binpath}"
  patch_binary "${iotfam_binpath}" "${hex_skipenum}" "${hex_skipenum_patch}"
  create_patched_binary "${iotfam_binpath}"
  echo -e "Ti82 support enabled.\n\n${bold}Continuing...${normal}\n"
}

# Enable Ti82 independently
enable_ti82() {
  echo -e "\n>> ${bold}Ti82 Devices${normal}\n"
  if [[ ${ti82_enabled} == 0 ]]
  then
    backup_system
    echo "${bold}Enabling...${normal}"
    patch_ti82 1>/dev/null
    echo "Ti82 Enabled."
    end_patch
  else
    echo -e "Ti82 support is already enabled on this system.\n"
  fi
}

# Prompt for Ti82 patch
install_ti82() {
  [[ ${ti82_enabled} == 1 ]] && return
  echo -e "\nTo use certain TB3 eGPU enclosures that have ${bold}Ti82 controllers${normal},\nit is necessary to patch macOS to allow them to mount properly.\n"
  if [[ ${TI82_INSTALLS} != 1 && ${TI82_INSTALLS} != 2 ]]
  then
    read -n1 -p "Enable ${bold}Ti82${normal}? [Y/N]: " userinput
    echo
    [[ "${userinput}" == "Y" ]] && echo && didinstall_ti82=1 && patch_ti82 && return
    [[ "${userinput}" == "N" ]] && echo && return
    echo -e "\nInvalid option.\n" && install_ti82
  elif [[ ${TI82_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${bold}always${normal} install Ti82 support.\n${bold}Proceeding...${normal}\n"
    didinstall_ti82=1 && patch_ti82
  else
    echo -e "Your preferences are set to ${bold}never${normal} install Ti82 support.\n${bold}Proceeding...${normal}\n"
  fi
}

# Patch TB1/2 block
patch_tb() {
  echo -e "\n>> ${bold}AMD eGPUs${normal}\n\n${bold}Starting patch...${normal}"
  [[ -e "${deprecated_automate_egpu_kextpath}" ]] && rm -r "${deprecated_automate_egpu_kextpath}"
  [[ ${nvidia_enabled} == 1 ]] && echo -e "System has previously been patched for ${bold}NVIDIA eGPUs${normal}.\nPlease uninstall before proceeding.\n" && return
  backup_system
  install_legacy_kext
  install_ti82
  if [[ "${system_thunderbolt_ver}" == "${hex_thunderboltswitchtype}3" ]]
  then
    echo -e "No thunderbolt patch required for this Mac.\n"
    [[ ${didinstall_amdlegacy} == 1 || ${didinstall_ti82} == 1 ]] && end_patch
    return
  fi
  if [[ ${tbswitch_enabled} == 1 ]]
  then
    echo -e "System has already been patched for ${bold}AMD eGPUs${normal}.\n"
    [[ ${didinstall_amdlegacy} == 1 || ${didinstall_ti82} == 1 ]] && end_patch
    return
  fi
  echo -e "${bold}Patching components...${normal}"
  create_hexrepresentation "${agw_binpath}"
  patch_binary "${agw_binpath}" "${hex_thunderboltswitchtype}"3 "${system_thunderbolt_ver}"
  create_patched_binary "${agw_binpath}"
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
  echo -e "Data retrieved.\n${bold}Downloading drivers (${DRIVER_VERSION})...${normal}"
  curl -q --connect-timeout 15 --progress-bar -o "${INSTALLER_PKG}" "${DOWNLOAD_URL}"
  if [[ ! -s "${INSTALLER_PKG}" ]]
  then
    rm -r "${INSTALLER_PKG}" 2>/dev/null 1>&2
    echo "Unable to download."
    return
  fi
  echo -e "Download complete.\n${bold}Sanitizing package...${normal}"
  pkgutil --expand-full "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}"
  sed -i "" -e "/installation-check/d" "${INSTALLER_PKG_EXPANDED}/Distribution"
  NVDA_STARTUP_PKG_KEXT="$(find "${INSTALLER_PKG_EXPANDED}" -maxdepth 1 | grep -i NVWebDrivers)/Payload/Library/Extensions/NVDAStartupWeb.kext"
  if [[ ! -d "${NVDA_STARTUP_PKG_KEXT}" ]]
  then
    rm -r "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}" 2>/dev/null 1>&2
    echo "Unable to patch driver."
    return
  fi
  $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${NVDA_STARTUP_PKG_KEXT}/Contents/Info.plist" 2>/dev/null 1>&2
  chown -R root:wheel "${NVDA_STARTUP_PKG_KEXT}"
  rm -r "${INSTALLER_PKG}"
  pkgutil --flatten-full "${INSTALLER_PKG_EXPANDED}" "${INSTALLER_PKG}" 2>/dev/null 1>&2
  echo -e "Package sanitized.\n${bold}Installing...${normal}"
  INSTALLER_ERR="$(installer -target "/" -pkg "${INSTALLER_PKG}" 2>&1 1>/dev/null)"
  [[ -z "${INSTALLER_ERR}" ]] && echo -e "Installation complete.\n" || echo -e "Installation failed."
  rm -r "${INSTALLER_PKG}" "${INSTALLER_PKG_EXPANDED}"
  rm "${webdriver_plistpath}"
}

# Run Webdriver installation procedure
run_webdriver_installer() {
  echo -e "${bold}Fetching webdriver information...${normal}"
  WEBDRIVER_DATA="$(curl -q -s "https://gfe.nvidia.com/mac-update")"
  [[ -z "${WEBDRIVER_DATA}" ]] && echo -e "Could not install web drivers." && return
  echo -e "${WEBDRIVER_DATA}" > "${webdriver_plistpath}"
  [[ ! -f "${webdriver_plistpath}" ]] && echo -e "Could not extract web driver information." && return
  INDEX=0
  DRIVER_MACOS_BUILD="${macos_build}"
  LATEST_DRIVER_MACOS_BUILD=""
  DRIVER_DL=""
  LATEST_DRIVER_DL=""
  DRIVER_VER=""
  LATEST_DRIVER_VER=""
  while [[ ! -z "${DRIVER_MACOS_BUILD}" ]]
  do
    DRIVER_DL="$($pb -c "Print :updates:${INDEX}:downloadURL" "${webdriver_plistpath}" 2>/dev/null)"
    DRIVER_VER="$($pb -c "Print :updates:${INDEX}:version" "${webdriver_plistpath}" 2>/dev/null)"
    DRIVER_MACOS_BUILD="$($pb -c "Print :updates:${INDEX}:OS" "${webdriver_plistpath}" 2>/dev/null)"
    if [[ ${INDEX} == 0 ]]
    then
      LATEST_DRIVER_DL="${DRIVER_DL}"
      LATEST_DRIVER_VER="${DRIVER_VER}"
      LATEST_DRIVER_MACOS_BUILD="${DRIVER_MACOS_BUILD}"
    fi
    [[ "${DRIVER_MACOS_BUILD}" == "${macos_build}" ]] && break
    (( INDEX++ ))
  done
  if [[ (-z "${DRIVER_DL}" || -z "${DRIVER_VER}") ]]
  then
    [[ ${NVDA_WEB_PATCH_INSTALLS} == 2 ]] && echo -e "\nNo web driver available for your system at this time.\nYour preference ${bold}disables${normal} web driver patching." && return
    echo -e "Latest Available Driver: ${bold}${LATEST_DRIVER_MACOS_BUILD}${normal}\nYour macOS Build: ${bold}${macos_build}${normal}\n"
    DRIVER_MAJOR_BUILD="${LATEST_DRIVER_MACOS_BUILD:0:2}"
    MACOS_MAJOR_BUILD="${macos_build:0:2}"
    if (( ${DRIVER_MAJOR_BUILD} - ${MACOS_MAJOR_BUILD} != 0 ))
    then
      echo -e "${bold}Recommendation${normal}: Major OS version discrepancy detected.\n\t\tPatching ${bold}not recommended${normal}.\n"
    else
      echo -e "${bold}Recommendation${normal}: Minor OS version discrepancy detected.\n\t\tPatching ${bold}may be safe${normal}.\n"
    fi
    userinput=""
    if [[ ${NVDA_WEB_PATCH_INSTALLS} != 1 ]]
    then
      read -n1 -p "Patch ${bold}Web Drivers${normal} (${bold}${LATEST_DRIVER_MACOS_BUILD}${normal} -> ${bold}${macos_build}${normal})? [Y/N]: " userinput
      echo
      [[ "${userinput}" == "N" ]] && echo -e "\nInstallation ${bold}aborted${normal}.\n" && rm "${webdriver_plistpath}" 2>/dev/null && return
      [[ "${userinput}" == "Y" ]] && echo -e "\n${bold}Proceeding...${normal}" && install_web_drivers "${LATEST_DRIVER_VER}" "${LATEST_DRIVER_DL}" && return
      echo -e "\nInvalid option. Installation ${bold}aborted${normal}.\n" && return
    else
      echo -e "Your preference is set to ${bold}always${normal} patch web drivers.\n${bold}Proceeding...${normal}\n"
      sleep 1
      install_web_drivers "${LATEST_DRIVER_VER}" "${LATEST_DRIVER_DL}"
      return
    fi
  fi
  install_web_drivers "${DRIVER_VER}" "${DRIVER_DL}"
}

# Prompt NVIDIA Web Driver installation
prompt_web_driver_install() {
  if [[ -f "${nvdastartupweb_plistpath}" ]]
  then
    if [[ "$(${pb} -c "Print ${set_nvdastartup_requiredos}" "${nvdastartupweb_plistpath}" 2>/dev/null)" != "${macos_build}" ]]
    then
      echo -e "\nInstalled ${bold}NVIDIA Web Drivers${normal} are specifying incorrect macOS build.\n"
      read -n1 -p "${bold}Rectify${normal}? [Y/N]: " userinput
      echo
      if [[ "${userinput}" != "Y" ]]
      then
        echo -e "\nDrivers unchanged.\n"
      else
        echo -e "\n${bold}Patching drivers...${normal}"
        $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${nvdastartupweb_plistpath}" 2>/dev/null 1>&2
        echo -e "Drivers patched.\n"
      fi
    else
      echo -e "\nAppropriate NVIDIA Web Drivers are ${bold}already installed${normal}.\n"
    fi
    using_nvdawebdrv=1
    return
  fi
  echo -e "\n${bold}NVIDIA Web Drivers${normal} are required for ${bold}NVIDIA 9xx${normal} GPUs or newer.\nIf you are using an older macOS-supported NVIDIA GPU,\nweb drivers are not needed.\n"
  if [[ ${NVDA_WEB_INSTALLS} != 1 && ${NVDA_WEB_INSTALLS} != 2 ]]
  then
    read -n1 -p "Install ${bold}NVIDIA Web Drivers${normal}? [Y/N]: " userinput
    echo
    [[ "${userinput}" == "Y" ]] && using_nvdawebdrv=1 && echo && run_webdriver_installer && return
    [[ "${userinput}" == "N" ]] && echo && return
    echo -e "\nInvalid option." && prompt_web_driver_install
  elif [[ ${NVDA_WEB_INSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${bold}always${normal} install web drivers.\n${bold}Proceeding...${normal}"
    sleep 1
    using_nvdawebdrv=1 && echo && run_webdriver_installer && return
  else
    echo -e "Your preferences are set to ${bold}never${normal} install web drivers.\nProceeding with ${bold}native macOS drivers${normal}...\n"
    sleep 1
    return
  fi
}

# Patch for NVIDIA eGPUs
patch_nv() {
  echo -e "\n>> ${bold}NVIDIA eGPUs${normal}\n\n${bold}Starting patch...${normal}\n"
  [[ ${nvidia_enabled} == 1 ]] && echo -e "System has already been patched for ${bold}NVIDIA eGPUs${normal}.\n" && return
  [[ ${tbswitch_enabled} == 1 || ${amdlegacy_enabled} == 1 ]] && echo -e "System has previously been patched for ${bold}AMD eGPUs${normal}.\nPlease uninstall before proceeding.\n" && return
  backup_system
  prompt_web_driver_install
  [[ ${using_nvdawebdrv} == 1 && ! -f "${nvdastartupweb_plistpath}" ]] && echo -e "${bold}NVIDIA Web Drivers${normal} requested, but not installed.\n" && return
  echo -e "${bold}Continuing patch...${normal}\n"
  if [[ ${using_nvdawebdrv} == 1 ]]
  then
    nvram nvda_drv=1
    NVDA_STARTUP_PLIST_TO_PATCH="${nvdastartupweb_plistpath}"
  else
    nvram -d nvda_drv 2>/dev/null
    NVDA_STARTUP_PLIST_TO_PATCH="${nvdastartup_plistpath}"
  fi
  echo -e "${bold}Patching components...${normal}"
  install_ti82
  create_hexrepresentation "${agw_binpath}"
  create_hexrepresentation "${iog_binpath}"
  patch_binary "${agw_binpath}" "${hex_iopcitunnelled}" "${hex_iopcitunnelled_patch}"
  patch_binary "${iog_binpath}" "${hex_iopcitunnelled}" "${hex_iopcitunnelled_patch}"
  create_patched_binary "${agw_binpath}"
  create_patched_binary "${iog_binpath}"
  modify_plist "${iondrv_plistpath}" "Add" "${set_iognvda_pcitunnelled}" "true"
  modify_plist "${NVDA_STARTUP_PLIST_TO_PATCH}" "Add" "${set_nvdastartup_pcitunnelled}" "true"
  [[ -e "${deprecated_automate_egpu_kextpath}" ]] && rm -r "${deprecated_automate_egpu_kextpath}"
  [[ -d "${deprecated_nvsolution_kextpath}" ]] && echo -e "${bold}NVDAEGPUSupport.kext${normal} detected. ${bold}Removing...${normal}" && rm -r "${deprecated_nvsolution_kextpath}" && echo -e "Removal complete."
  echo -e "Components patched."
  end_patch
}

# Run webdriver uninstallation process
run_webdriver_uninstaller() {
  echo -e "\n${bold}Uninstalling drivers...${normal}"
  nvram -d nvda_drv
  WEBDRIVER_UNINSTALLER="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
  [[ ! -s "${WEBDRIVER_UNINSTALLER}" ]] && echo -e "Could not find NVIDIA uninstaller.\n" && return
  installer -target "/" -pkg "${WEBDRIVER_UNINSTALLER}" 2>&1 1>/dev/null
  echo -e "Drivers uninstalled.\nIf in ${bold}Single User Mode${normal}, only driver selection changed.\n" && return
}

# Remove NVIDIA Web Drivers
remove_web_drivers() {
  [[ ! -e "${nvdastartupweb_kextpath}" ]] && return
  echo
  if [[ ${NVDA_WEB_UNINSTALLS} != 1 && ${NVDA_WEB_UNINSTALLS} != 2 ]]
  then
    read -n1 -p "Remove ${bold}NVIDIA Web Drivers${normal}? [Y/N]: " userinput
    echo
    [[ "${userinput}" == "Y" ]] && run_webdriver_uninstaller && return
    [[ "${userinput}" == "N" ]] && echo && return
    echo -e "\nInvalid option." && remove_web_drivers
  elif [[ ${NVDA_WEB_UNINSTALLS} == 1 ]]
  then
    echo -e "Your preferences are set to ${bold}always${normal} uninstall web drivers.\n${bold}Proceeding...${normal}"
    run_webdriver_uninstaller
  else
    echo -e "Your preferences are set to ${bold}never${normal} uninstall web drivers.\n${bold}No action taken.${normal}\n"
  fi
}

# Uninstall Ti82
uninstall_ti82() {
  [[ ${ti82_enabled} == 0 ]] && return
  echo -e "${bold}Removing Ti82 support...${normal}"
  create_hexrepresentation "${iotfam_binpath}"
  patch_binary "${iotfam_binpath}" "${hex_skipenum_patch}" "${hex_skipenum}"
  create_patched_binary "${iotfam_binpath}"
  echo -e "Ti82 support disabled."
}

# In-place re-patcher
uninstall() {
  echo -e "\n>> ${bold}Uninstall${normal}\n"
  [[ ${amdlegacy_enabled} == 0 && ${tbswitch_enabled} == 0 && ${nvidia_enabled} == 0 && ${ti82_enabled} == 0 && ! -e "${nvdastartupweb_kextpath}" ]] && echo -e "No patches detected.\nSystem already clean.\n" && return
  echo -e "${bold}Uninstalling...${normal}"
  if [[ -d "${amdlegacy_kextpath}" ]]
  then
    echo -e "${bold}Removing legacy support...${normal}"
    rm -r "${amdlegacy_kextpath}"
    echo -e "Removal successful."
  fi
  remove_web_drivers
  uninstall_ti82
  echo -e "${bold}Reverting binaries...${normal}"
  create_hexrepresentation "${agw_binpath}"
  [[ ${tbswitch_enabled} == 1 ]] && patch_binary "${agw_binpath}" "${system_thunderbolt_ver}" "${hex_thunderboltswitchtype}"3
  if [[ ${nvidia_enabled} == 1 ]]
  then
    create_hexrepresentation "${iog_binpath}"
    patch_binary "${iog_binpath}" "${hex_iopcitunnelled_patch}" "${hex_iopcitunnelled}"
    patch_binary "${agw_binpath}" "${hex_iopcitunnelled_patch}" "${hex_iopcitunnelled}"
    [[ -f "${nvdastartupweb_plistpath}" && "$(cat "${nvdastartupweb_plistpath}" | grep -i "IOPCITunnelCompatible")" ]] && modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    [[ "$(cat "${nvdastartup_plistpath}" | grep -i "IOPCITunnelCompatible")" ]] && modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    create_patched_binary "${iog_binpath}"
    [[ "$(cat "${iondrv_plistpath}" | grep -i "IOPCITunnelCompatible")" ]] && modify_plist "${iondrv_plistpath}" "Delete" "${set_iognvda_pcitunnelled}"
  fi
  create_patched_binary "${agw_binpath}"
  echo -e "Binaries reverted."
  update_config
  sanitize_system
  echo -e "Uninstallation Complete.\n\n${bold}System ready.${normal} Restart now to apply changes.\n"
}

# ----- BINARY MANAGER

# Bin management procedure
install_bin() {
  rsync "${call_script_file}" "${script_bin}"
  chown "${SUDO_USER}" "${script_bin}"
  chmod 700 "${script_bin}" && chmod a+x "${script_bin}"
}

# Bin first-time setup
first_time_setup() {
  [[ $is_bin_call == 1 ]] && return
  call_script_file="$(pwd)/$(echo -e "${script}")"
  [[ "${script}" == "${0}" ]] && call_script_file="$(echo -e "${call_script_file}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${call_script_file}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${script_bin}" ]] && BIN_SHA="$(shasum -a 512 -b "${script_bin}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo -e "\n>> ${bold}System Management${normal}\n\n${bold}Installing...${normal}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${script_bin}"
  install_bin
  echo -e "Installation successful. ${bold}Proceeding...${normal}\n" && sleep 1
}

# ----- RECOVERY SYSTEM

# Recovery logic
recover_sys() {
  echo -e "\n>> ${bold}Recovery${normal}\n\n${bold}Recovering...${normal}"
  if [[ -d "${amdlegacy_kextpath}" ]]
  then
    echo -e "${bold}Removing legacy support...${normal}"
    rm -r "${amdlegacy_kextpath}"
    echo -e "Removal successful."
  fi
  [[ ! -e "${scriptconfig_filepath}" ]] && echo -e "Nothing to recover.\n\nConsider ${bold}system recovery${normal} or ${bold}rebooting${normal}.\n" && return
  local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
  local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
  if [[ "${prev_macos_ver}" != "${macos_ver}" || "${prev_macos_build}" != "${macos_build}" ]]
  then
    echo -e "\n${bold}Last Backup${normal}: ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
    echo -e "${bold}Current System${normal}: ${macos_ver} ${bold}[${macos_build}]${normal}\n"
    read -n1 -p "System may already be clean. Still ${bold}attempt recovery${normal}? [Y/N]: " userinput
    echo
    [[ "${userinput}" == "N" ]] && echo -e "Recovery ${bold}cancelled${normal}.\n" && return
    [[ "${userinput}" != "Y" ]] && echo -e "Invalid choice. Recovery ${bold}safely aborted${normal}.\n" && return
    echo -e "\n${bold}Attempting recovery...${normal}"
  fi
  echo -e "${bold}Restoring system...${normal}"
  [[ -d "${backupkext_dirpath}" ]] && rsync -rt "${backupkext_dirpath}"* "${sysextensions_path}"
  [[ "$(cat "${nvdastartup_plistpath}" | grep -i "IOPCITunnelCompatible")" ]] && modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
  if [[ -f "${nvdastartupweb_plistpath}" ]]
  then
    [[ "$(cat "${nvdastartupweb_plistpath}" | grep -i "IOPCITunnelCompatible")" ]] && modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    remove_web_drivers
  fi
  echo -e "System restored."
  update_config
  sanitize_system
  echo -e "Recovery complete.\n\n${bold}System ready.${normal} Restart now to apply changes.\n\nRefer to the ${bold}macOS eGPU Troubleshooting Guide${normal} in the ${bold}How-To's${normal}\nsection of ${underline}egpu.io${normal} for further troubleshooting if needed.\n"
}

# ----- ANOMALY MANAGER

# Detect discrete GPU vendor
detect_discrete_gpu_vendor() {
  dgpu_vendor="$(ioreg -n GFX0@0 | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4)"
  if [[ "${dgpu_vendor}" == "de10" ]]
  then
    dgpu_vendor="NVIDIA"
  elif [[ "${dgpu_vendor}" == "0210" ]]
  then
    dgpu_vendor="AMD"
  else
    dgpu_vendor="None"
  fi
}

# Anomaly detection
detect_anomalies() {
  echo -e "\n>> ${bold}Anomaly Detection${normal}\n"
  detect_discrete_gpu_vendor
  echo -e "Anomaly Detection will check your system to ${bold}find\npotential hiccups${normal} based on the applied system patches.\n\nPatches made from scripts such as ${bold}purge-nvda.sh${normal}\nare not detected at this time."
  echo -e "\n${bold}Discrete GPU${normal}: ${dgpu_vendor}\n"
  if [[ "${dgpu_vendor}" == "NVIDIA" ]]
  then
    if [[ ${nvidia_enabled} == 1 && -f "${nvdastartupweb_plistpath}" ]]
    then
      echo -e "${bold}Problem${normal}     Loss of OpenCL/GL on all NVIDIA GPUs."
      echo -e "${bold}Resolution${normal}  Apply patches using ${bold}purge-nvda.sh${normal}."
      echo -e "\t    This issue cannot be resolved on iMacs.\n"
    elif [[ ${tbswitch_enabled} == 1 ]]
    then
      echo -e "${bold}Problem${normal}     Black screens on monitors connected to eGPU."
      echo -e "${bold}Resolution${normal}  Apply patches using ${bold}purge-nvda.sh${normal}."
      echo -e "\t    This issue cannot be resolved on iMacs.\n"
    else
      echo -e "No expected anomalies with current configuration.\n"
    fi
  elif [[ "${dgpu_vendor}" == "AMD" ]]
  then
    if [[ ${nvidia_enabled} == 1 ]]
    then
      echo -e "${bold}Problem${normal}     Black screens/slow performance with eGPU."
      echo -e "${bold}Resolution${normal}  Disable then re-enable automatic graphics switching,"
      echo -e "\t    hot-plug eGPU, then log out and log in."
      echo -e "\t    This issue, if encountered, might only be resolved with\n\t    trial-error or using more advanced mux-based workarounds.\n"
    elif [[ ${tbswitch_enabled} == 1 ]]
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
  echo -e "\nSee your ${bold}web browser${normal}.\n"
}

# Show update prompt
show_update_prompt() {
  check_patch
  [[ ! -e "${scriptconfig_filepath}" ]] && sleep 10 && return
  local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
  local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
  local did_patch=="$($pb -c "Print :DidApplyBinPatch")"
  [[ ${tbswitch_enabled} == 1 || ${nvidia_enabled} == 1 || ${ti82_enabled} == 1 || ("${prev_macos_ver}" == "${macos_ver}" && "${prev_macos_build}" == "${macos_build}") || ${did_patch} == false ]] && sleep 10 && return
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

# Ask for main menu
ask_menu() {
  read -n1 -p "${bold}Back to menu?${normal} [Y/N]: " userinput
  echo
  [[ "${userinput}" == "Y" ]] && perform_sys_check && clear && echo -e "\n>> ${bold}PurgeWrangler (${script_ver})${normal}" && provide_menu_selection && return
  [[ "${userinput}" == "N" ]] && echo && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo -e "
   >> ${bold}eGPU Support${normal}         >> ${bold}More Options${normal}
   ${bold}1.${normal}  AMD eGPUs           ${bold}6.${normal}  Ti82 Devices
   ${bold}2.${normal}  NVIDIA eGPUs        ${bold}7.${normal}  NVIDIA Web Drivers
   ${bold}3.${normal}  Uninstall           ${bold}8.${normal}  Anomaly Detection
   ${bold}4.${normal}  Recovery            ${bold}9.${normal}  Script Preferences
   ${bold}5.${normal}  Status              ${bold}D.${normal}  Donate

   ${bold}0.${normal}  Quit
  "
  read -n1 -p "${bold}What next?${normal} [0-9|D]: " userinput
  echo
  if [[ ! -z "${userinput}" ]]
  then
    process_args "${userinput}"
  else
    echo && exit
  fi
  ask_menu
}

# Process user userinput
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
    echo -e "\n>> ${bold}NVIDIA Web Drivers${normal}"
    prompt_web_driver_install;;
    -a|--anomaly-detect|8)
    detect_anomalies;;
    -d|--donate|D|d)
    donate;;
    0)
    echo && exit;;
    "")
    fetch_latest_release
    first_time_setup
    clear && echo -e ">> ${bold}PurgeWrangler (${script_ver})${normal}"
    provide_menu_selection;;
    *)
    echo -e "\nInvalid option.\n";;
  esac
}

# ----- script DRIVER

# Primary execution routine
begin() {
  [[ "${2}" == "--on-launch-check" ]] && show_update_prompt && return
  validate_caller "${1}" "${2}"
  perform_sys_check
  process_args "${2}"
}

begin "${0}" "${1}"