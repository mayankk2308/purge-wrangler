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
binpatch_enabled=0
ti82_enabled=2
nvdawebdrv_patched=2

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

# General backup path
support_dirpath="/Library/Application Support/Purge-Wrangler/"
backupkext_dirpath="${support_dirpath}Kexts/"
prompticon_downloadurl="http://raw.githubusercontent.com/mayankk2308/purge-wrangler/${script_ver}/resources/pw.png"
prompticon_filepath="${support_dirpath}pw.png"

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
  echo
  read -n1 -p "${prompt} [Y/N]: " userinput
  [[ ${userinput} == "Y" ]] && eval "${yesaction}" && return
  [[ ${userinput} == "N" ]] && eval "${noaction}" && return
  echo -e "\n\nInvalid choice. Please try again."
  yesno_action "${prompt}" "${yesaction}" "${noaction}"
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
  $pb -c "${command} ${key} ${value}" "${target_plist}" 2>/dev/null 1>&2
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
  $pb -c "Add :DidApplyPatchNVDAWebDrv bool false" "${scriptconfig_filepath}"
}

### Updates the configuration as necessary
update_config() {
  generate_config
  check_patch
  local status=("false" "true" "false")
  $pb -c "Set :OSVersionAtPatch ${macos_ver}" "${scriptconfig_filepath}"
  $pb -c "Set :OSBuildAtPatch ${macos_build}" "${scriptconfig_filepath}"
  $pb -c "Set :DidApplyBinPatch ${status[${binpatch_enabled}]}" "${scriptconfig_filepath}"
  $pb -c "Set :DidApplyPatchNVDAWebDrv ${status[${nvdawebdrv_patched}]}" "${scriptconfig_filepath}"
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
  curl -q -L -s -o "${prompticon_filepath}" "${prompticon_downloadurl}"
  [[ ! -s "${prompticon_filepath}" || "$(cat "${prompticon_filepath}")" == "404: Not Found" ]] && rm -f "${prompticon_filepath}" 2>/dev/null 1>&2
  su "${SUDO_USER}" -c "launchctl load -w \"${agent_plistpath}\""
}

### System report generation
generate_sys_report() {
  echo -e "${bold}Generating report...${normal}"
  local report_dirpath="/Users/${SUDO_USER}/Desktop/PWR-$(date +%Y-%m-%d-%H-%M-%S)"
  mkdir -p "${report_dirpath}"
  detect_discrete_gpu_vendor
  detect_mac_model
  rsync "${scriptconfig_filepath}" "${report_dirpath}/PatchState.plist"
  $pb -c "Add :SysDiscreteGPU string ${dgpu_vendor}" "${report_dirpath}/PatchState.plist"
  $pb -c "Add :IsDesktopMac string ${is_desktop_mac}" "${report_dirpath}/PatchState.plist"
  system_profiler -xml SPThunderboltDataType > "${report_dirpath}/ThunderboltDevices.plist"
  zip -r -j -X "${report_dirpath}.zip" "${report_dirpath}" 1>/dev/null 2>&1
  rm -r "${report_dirpath}"
  chown "${SUDO_USER}" "${report_dirpath}.zip"
  echo -e "Report generated on the Desktop."
}

# --- SCRIPT SOFTWARE UPDATE SYSTEM

### Perform software update
perform_software_update() {
  echo -e "\n\n${bold}Downloading...${normal}"
  curl -q -L -s -o "${tmp_script}" "${latest_release_dwld}"
  [[ "$(cat "${tmp_script}")" == "Not Found" ]] && echo -e "Download failed.\n${bold}Continuing without updating...${normal}" && rm "${tmp_script}" && return
  echo -e "Download complete.\n${bold}Updating...${normal}"
  chmod 700 "${tmp_script}" && chmod +x "${tmp_script}"
  rm "${script}" && mv "${tmp_script}" "${script}"
  chown "${SUDO_USER}" "${script}"
  echo -e "Update complete. ${bold}Relaunching...${normal}"
  "${script}"
  exit 0
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
    yesno_action "${bold}Would you like to update?${normal}" "perform_software_update" "echo -e \"\n\n${bold}Proceeding without updating...${normal}\""
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
  if [[ ! -s "${agc_kextpath}" || ! -s "${agw_binpath}" || ! -s "${iondrv_kextpath}" || ! -s "${iog_binpath}" || ! -s "${iotfam_kextpath}" || ! -s "${iotfam_binpath}" ]]
  then
    echo -e "\nUnexpected system configuration or missing files."
    yesno_action "${bold}Run Recovery?${normal}" "recover_sys" "echo && exit"
    echo
    exit
  fi
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
  binpatch_enabled=0
  [[ ! -f "${agw_binpath}" || ! -f "${iog_binpath}" || ! -f "${iotfam_binpath}" ]] && return
  local hex_agwbin="$(hexdump -ve '1/1 "%.2X"' "${agw_binpath}")"
  local hex_iogbin="$(hexdump -ve '1/1 "%.2X"' "${iog_binpath}")"
  local hex_iotfambin="$(hexdump -ve '1/1 "%.2X"' "${iotfam_binpath}")"
  local nvdawebdrv_iopcitunnelcompat="$($pb -c "Print :IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible" "${nvdastartupweb_plistpath}" 2>/dev/null)"
  [[ ! -e "${nvdastartupweb_kextpath}" ]] && nvdawebdrv_patched=2 || nvdawebdrv_patched=0
  [[ "${nvdawebdrv_iopcitunnelcompat}" == "true" ]] && nvdawebdrv_patched=1
  [[ -d "${amdlegacy_kextpath}" ]] && amdlegacy_enabled=1 || amdlegacy_enabled=0
  [[ "${hex_agwbin}" =~ "${system_thunderbolt_ver}" && "${system_thunderbolt_ver}" != "${hex_thunderboltswitchtype}"3 ]] && tbswitch_enabled=1 || tbswitch_enabled=0
  [[ "${hex_iogbin}" =~ "${hex_iopcitunnelled_patch}" ]] && nvidia_enabled=1 || nvidia_enabled=0
  [[ "${hex_iotfambin}" =~ "${hex_skipenum_patch}" ]] && ti82_enabled=1 || ti82_enabled=0
  [[ ${tbswitch_enabled} == "1" || ${ti82_enabled} == "1" || ${nvidia_enabled} == "1" ]] && binpatch_enabled=1
}

### Display patch statuses
check_patch_status() {
  local status=("Disabled" "Enabled" "Unknown")
  local drv_status=("Clean" "Patched" "Absent")
  echo -e "${bold}Ti82 Devices${normal}      ${status[${ti82_enabled}]}"
  echo -e "${bold}TB1/2 AMD eGPUs${normal}   ${status[$tbswitch_enabled]}"
  echo -e "${bold}Legacy AMD eGPUs${normal}  ${status[$amdlegacy_enabled]}"
  echo -e "${bold}NVIDIA eGPUs${normal}      ${status[$nvidia_enabled]}"
  echo -e "${bold}Web Drivers${normal}       ${drv_status[$nvdawebdrv_patched]}"
}

### Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  retrieve_tb_ver
  elevate_privileges
  check_sys_extensions
  check_patch
  deprecate_manifest
  using_nvdawebdrv=0
}

# ----- OS MANAGEMENT

### Sanitize system permissions and caches
sanitize_system() {
  echo -e "${bold}Sanitizing system...${normal}"
  chmod -R 755 "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  chown -R root:wheel "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  echo -e "System sanitized."
}

# ----- BACKUP SYSTEM

### Primary procedure
execute_backup() {
  mkdir -p "${backupkext_dirpath}"
  rsync -rt "${agc_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iog_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iondrv_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${iotfam_kextpath}" "${backupkext_dirpath}"
  rsync -rt "${nvdastartup_kextpath}" "${backupkext_dirpath}"
}

### Backup procedure
backup_system() {
  echo -e "${bold}Backing up...${normal}"
  if [[ ! -z $(find "${backupkext_dirpath}" -mindepth 1 -print -quit 2>/dev/null) && -s "${scriptconfig_filepath}" ]]
  then
    local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
    local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
    if [[ "${prev_macos_ver}" == "${macos_ver}" && "${prev_macos_build}" == "${macos_build}" ]]
    then
      if [[ ${binpatch_enabled} == 0 ]]
      then
        execute_backup
        echo -e "Backup refreshed."
        update_config
        return
      fi
      echo -e "Backup already exists."
    else
      echo -e "\n${bold}Last Backup${normal}     ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
      echo -e "${bold}Current System${normal}  ${macos_ver} ${bold}[${macos_build}]${normal}\n"
      echo -e "${bold}Updating backup...${normal}"
      if [[ ${binpatch_enabled} == 1 ]]
      then
        echo -e "${bold}Uninstalling patch(es) before updating backup...${normal}\n"
        uninstall
      fi
      execute_backup
      update_config
      echo -e "Update complete."
    fi
  else
    execute_backup
    update_config
    echo -e "Backup complete."
  fi
}

# --- CORE PATCHWORK

### Conclude patching sequence
end_binary_modifications() {
  update_config
  sanitize_system
  [[ "${2}" == -no-agent ]] && rm -rf "/Users/${SUDO_USER}/Library/LaunchAgents/${script_launchagent}.plist" || create_launchagent
  local message="${1}"
  echo -e "${bold}${message}\n\n${bold}System ready.${normal} Reboot required."
  yesno_action "${bold}Reboot Now?${normal}" "echo -e \"\n\n${bold}Rebooting...${normal}\" && reboot" "echo -e \"\n\nReboot aborted.\""
}

### Install AMDLegacySupport.kext
install_amd_legacy_kext() {
  [[ -d "${amdlegacy_kextpath}" ]] && echo -e "${bold}AMDLegacySupport.kext${normal} already installed." && return
  echo -e "${bold}Downloading AMDLegacySupport...${normal}"
  curl -q -L -s -o "${amdlegacy_downloadpath}" "${amdlegacy_downloadurl}"
  if [[ ! -e "${amdlegacy_downloadpath}" || ! -s "${amdlegacy_downloadpath}" || "$(cat "${amdlegacy_downloadpath}")" == "404: Not Found" ]]
  then
    echo -e "Could not download."
    rm -rf "${amdlegacy_downloadpath}" 2>/dev/null
    return
  fi
  echo -e "Download complete.\n${bold}Installing...${normal}"
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  unzip -d "${libextensions_path}" "${amdlegacy_downloadpath}" 1>/dev/null 2>&1
  rm -r "${amdlegacy_downloadpath}" "${libextensions_path}/__MACOSX" 1>/dev/null 2>&1
  [[ "${1}" == -end ]] && end_binary_modifications "Installation complete."
}

### Enable Ti82
enable_ti82() {
  [[ ${ti82_enabled} == 1 ]] && echo -e "Ti82 support is already enabled on this system." && return
  echo "${bold}Enabling Ti82 support...${normal}"
  create_hexrepresentation "${iotfam_binpath}"
  patch_binary "${iotfam_binpath}" "${hex_skipenum}" "${hex_skipenum_patch}"
  create_patched_binary "${iotfam_binpath}"
  echo -e "Ti82 support enabled."
  [[ "${1}" == -end ]] && end_binary_modifications "Patch complete."
}

### Patch TB1/2 block
patch_tb() {
  echo -e "${bold}Patching for AMD eGPUs...${normal}"
  [[ -e "${deprecated_automate_egpu_kextpath}" ]] && rm -r "${deprecated_automate_egpu_kextpath}"
  [[ ${nvidia_enabled} == 1 ]] && echo -e "System has previously been patched for ${bold}NVIDIA eGPUs${normal}." && return
  [[ ${tbswitch_enabled} == 1 ]] && echo -e "System has already been patched for ${bold}AMD eGPUs${normal}." && return
  [[ "${system_thunderbolt_ver}" == "${hex_thunderboltswitchtype}3" ]] && echo -e "No thunderbolt patch required for this Mac." && return
  echo -e "${bold}Patching components...${normal}"
  create_hexrepresentation "${agw_binpath}"
  patch_binary "${agw_binpath}" "${hex_thunderboltswitchtype}"3 "${system_thunderbolt_ver}"
  create_patched_binary "${agw_binpath}"
  echo -e "Components patched."
  [[ "${1}" == -end ]] && end_binary_modifications "Patch complete."
}

### Download and install NVIDIA Web Drivers
install_web_drivers() {
  local installerpkg_path="/usr/local/NVDAInstall.pkg"
  local installerpkgexpanded_path="/usr/local/NVDAInstall"
  local nvdadrv_ver="${1}"
  local nvdadrv_downloadurl="${2}"
  rm -r "${installerpkgexpanded_path}" "${installerpkg_path}" 2>/dev/null 1>&2
  echo -e "${bold}Downloading drivers (${nvdadrv_ver})...${normal}"
  curl -q --connect-timeout 15 --progress-bar -o "${installerpkg_path}" "${nvdadrv_downloadurl}"
  if [[ ! -s "${installerpkg_path}" ]]
  then
    rm -r "${installerpkg_path}" 2>/dev/null 1>&2
    echo "Unable to download."
    return
  fi
  echo -e "Download complete.\n${bold}Sanitizing package...${normal}"
  pkgutil --expand-full "${installerpkg_path}" "${installerpkgexpanded_path}"
  sed -i "" -e "/installation-check/d" "${installerpkgexpanded_path}/Distribution"
  local nvdastartup_pkgkextpath="$(find "${installerpkgexpanded_path}" -maxdepth 1 | grep -i NVWebDrivers)/Payload/Library/Extensions/NVDAStartupWeb.kext"
  if [[ ! -d "${nvdastartup_pkgkextpath}" ]]
  then
    rm -r "${installerpkg_path}" "${installerpkgexpanded_path}" 2>/dev/null 1>&2
    echo "Unable to patch driver."
    return
  fi
  $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${nvdastartup_pkgkextpath}/Contents/Info.plist" 2>/dev/null 1>&2
  chown -R root:wheel "${nvdastartup_pkgkextpath}"
  rm -r "${installerpkg_path}"
  pkgutil --flatten-full "${installerpkgexpanded_path}" "${installerpkg_path}" 2>/dev/null 1>&2
  echo -e "Package sanitized.\n${bold}Installing...${normal}"
  local installer_err="$(installer -target "/" -pkg "${installerpkg_path}" 2>&1 1>/dev/null)"
  [[ -z "${installer_err}" ]] && echo -e "Installation complete." || echo -e "Installation failed."
  rm -r "${installerpkg_path}" "${installerpkgexpanded_path}"
  rm "${webdriver_plistpath}"
}

### Reset webdriver data
reset_nvdawebdrv_stats() {
  nvdawebdrv_lastcompatible_ver=""
  nvdawebdrv_lastcompatible_downloadurl=""
  nvdawebdrv_latest_ver=""
  nvdawebdrv_latest_macosbuild=""
  nvdawebdrv_latest_downloadurl=""
  nvdawebdrv_alreadypresentos=""
  nvdawebdrv_target_ver=""
  nvdawebdrv_target_downloadurl=""
  nvdawebdrv_canpatchlatest=3
}

### Populate webdriver data
get_nvdawebdrv_stats() {
  reset_nvdawebdrv_stats
  nvdawebdrv_target_ver="${1}"
  echo -e "\n${bold}Fetching data...${normal}"
  [[ -f "${nvdastartupweb_plistpath}" ]] && nvdawebdrv_alreadypresentos="$(${pb} -c "Print ${set_nvdastartup_requiredos}" "${nvdastartupweb_plistpath}" 2>/dev/null)"
  local webdriver_data="$(curl -q -s "https://gfe.nvidia.com/mac-update")"
  [[ -z "${webdriver_data}" ]] && return
  echo -e "${webdriver_data}" > "${webdriver_plistpath}"
  local index=0
  local current_macos_build="${macos_build}"
  local currentdriver_downloadurl=""
  local currentdriver_ver=""
  while [[ ! -z "${current_macos_build}" ]]
  do
    currentdriver_downloadurl="$($pb -c "Print :updates:${index}:downloadURL" "${webdriver_plistpath}" 2>/dev/null)"
    currentdriver_ver="$($pb -c "Print :updates:${index}:version" "${webdriver_plistpath}" 2>/dev/null)"
    current_macos_build="$($pb -c "Print :updates:${index}:OS" "${webdriver_plistpath}" 2>/dev/null)"
    if [[ ! -z "${currentdriver_ver}" && "${nvdawebdrv_target_ver}" == "${currentdriver_ver}" ]]
    then
      nvdawebdrv_target_ver="${currentdriver_ver}"
      nvdawebdrv_target_downloadurl="${currentdriver_downloadurl}"
      return
    fi
    if [[ ${index} == 0 ]]
    then
      nvdawebdrv_latest_downloadurl="${currentdriver_downloadurl}"
      nvdawebdrv_latest_ver="${currentdriver_ver}"
      nvdawebdrv_latest_macosbuild="${current_macos_build}"
    fi
    [[ "${current_macos_build}" == "${macos_build}" ]] && break
    (( index++ ))
  done
  if [[ -z "${currentdriver_downloadurl}" || -z "${currentdriver_ver}" ]]
  then
    local currentdriver_majormacosbuild="${nvdawebdrv_latest_macosbuild:0:2}"
    local macos_major_build="${macos_build:0:2}"
    if (( ${currentdriver_majormacosbuild} - ${macos_major_build} != 0 ))
    then
      nvdawebdrv_canpatchlatest=2
    else
      nvdawebdrv_canpatchlatest=1
    fi
  else
    nvdawebdrv_canpatchlatest=0
    nvdawebdrv_lastcompatible_ver="${currentdriver_ver}"
    nvdawebdrv_lastcompatible_downloadurl="${currentdriver_downloadurl}"
  fi
  echo -e "Data retrieved."
}

### Patch NVIDIA Web Driver version
patch_nvdawebdrv_version() {
  echo -e "\n\n${bold}Patching drivers...${normal}"
  $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${nvdastartupweb_plistpath}" 2>/dev/null 1>&2
  echo -e "Drivers patched."
}

### Current webdriver possibilities
webdriver_possibilities() {
  if [[ "${3}" == -already-present ]]
  then
    [[ "${nvdawebdrv_alreadypresentos}" == "${macos_build}" ]] && echo -e "Appropriate NVIDIA Web Drivers are ${bold}already installed${normal}." && return
    echo -e "\nInstalled ${bold}NVIDIA Web Drivers${normal} are specifying incorrect macOS build."
    [[ "${4}" != "-prompt" ]] && echo "${bold}Resolving...${normal}" && patch_nvdawebdrv_version 1>/dev/null && echo "Resolved." && return
    yesno_action "${bold}Attempt to Rectify${normal}?" "patch_nvdawebdrv_version" "echo -e \"\n\nDrivers unchanged.\""
  else
    local recommendation=("Not Required" "Suggested" "Not Advised" "Cannot Determine")
    echo -e "\nWeb drivers will require patching.\n${bold}Patch Recommendation${normal}: ${recommendation[${nvdawebdrv_canpatchlatest}]}"
    yesno_action "${bold}Patch?${normal}" "echo -e \"\n\" && install_web_drivers \"${1}\" \"${2}\"" "echo -e \"\n\nInstallation aborted.\" && return"
  fi
}

### Run Webdriver installation procedure
run_webdriver_installer() {
  get_nvdawebdrv_stats
  [[ ! -z "${nvdawebdrv_alreadypresentos}" ]] && webdriver_possibilities "" "" "-already-present" "${1}" && return
  case ${nvdawebdrv_canpatchlatest} in
    0)
    install_web_drivers "${nvdawebdrv_lastcompatible_ver}" "${nvdawebdrv_lastcompatible_downloadurl}";;
    1)
    [[ "${1}" == -prompt ]] && webdriver_possibilities "${nvdawebdrv_latest_ver}" "${nvdawebdrv_latest_downloadurl}" && return
    install_web_drivers "${nvdawebdrv_latest_ver}" "${nvdawebdrv_latest_downloadurl}";;
    2|3)
    [[ "${1}" == -prompt ]] && webdriver_possibilities "${nvdawebdrv_latest_ver}" "${nvdawebdrv_latest_downloadurl}" && return
    echo -e "No compatible or suitably patchable NVIDIA driver available.";;
  esac
}

### Install specified version of Web Drivers
install_ver_spec_webdrv() {
  echo -e "Specify a ${bold}Webdriver version${normal} to install (${bold}L = Latest${normal}).\nExisting drivers will be overwritten.\n${bold}Example${normal}: 387.10.10.10.25.161\n"
  read -p "${bold}Version${normal} [L|Q]: " userinput
  [[ -z "${userinput}" || "${userinput}" == Q ]] && echo -e "\nNo changes made." && return
  get_nvdawebdrv_stats "${userinput}"
  [[ "${userinput}" != "L" && -z "${nvdawebdrv_target_downloadurl}" ]] && echo -e "No driver found for specified version." && return
  [[ "${userinput}" != "L" ]] && install_web_drivers "${nvdawebdrv_target_ver}" "${nvdawebdrv_target_downloadurl}" || install_web_drivers "${nvdawebdrv_latest_ver}" "${nvdawebdrv_latest_downloadurl}"
  using_nvdawebdrv=1
}

### Run NVIDIA eGPU patcher
run_patch_nv() {
  if [[ "${1}" == -prompt ]]
  then
    [[ -f "${nvdastartupweb_plistpath}" ]] && nvdawebdrv_alreadypresentos="$(${pb} -c "Print ${set_nvdastartup_requiredos}" "${nvdastartupweb_plistpath}" 2>/dev/null)"
    if [[ ! -z "${nvdawebdrv_alreadypresentos}" ]]
    then
      webdriver_possibilities "" "" "-already-present" "-prompt"
      using_nvdawebdrv=1
    else
      yesno_action "Install ${bold}NVIDIA Web Drivers${normal}?" "echo && using_nvdawebdrv=1 && run_webdriver_installer -prompt && echo" "echo -e \"\n\""
    fi
  fi
  local nvdastartupplist_topatch="${nvdastartupweb_plistpath}"
  if (( ${using_nvdawebdrv} == 1 ))
  then
    [[ ! -f "${nvdastartupweb_plistpath}" ]] && echo -e "${bold}NVIDIA Web Drivers${normal} requested, but not installed." && return
    nvram nvda_drv=1
  else
    nvram -d nvda_drv 2>/dev/null
    nvdastartupplist_topatch="${nvdastartup_plistpath}"
  fi
  create_hexrepresentation "${agw_binpath}"
  create_hexrepresentation "${iog_binpath}"
  patch_binary "${agw_binpath}" "${hex_iopcitunnelled}" "${hex_iopcitunnelled_patch}"
  patch_binary "${iog_binpath}" "${hex_iopcitunnelled}" "${hex_iopcitunnelled_patch}"
  create_patched_binary "${agw_binpath}"
  create_patched_binary "${iog_binpath}"
  modify_plist "${iondrv_plistpath}" "Add" "${set_iognvda_pcitunnelled}" "true"
  modify_plist "${nvdastartupplist_topatch}" "Add" "${set_nvdastartup_pcitunnelled}" "true"
  rm -r "${deprecated_automate_egpu_kextpath}" 2>/dev/null 1>&2
  rm -r "${deprecated_nvsolution_kextpath}" 2>/dev/null 1>&2
  [[ "${2}" == -end ]] && end_binary_modifications "Patch complete."
}

### Patch for NVIDIA eGPUs
patch_nv() {
  echo -e "${bold}Patching for NVIDIA eGPUs...${normal}"
  [[ -e "${nvdastartupweb_kextpath}" && ${nvdawebdrv_patched} == 0 ]] && run_patch_nv "${1}" "${2}" && return
  [[ ${nvidia_enabled} == 1 ]] && echo -e "System has already been patched for ${bold}NVIDIA eGPUs${normal}." && return
  [[ ${tbswitch_enabled} == 1 ]] && echo -e "System has previously been patched for ${bold}AMD eGPUs${normal}." && return
  run_patch_nv "${1}" "${2}"
}

# Run webdriver uninstallation process
run_webdriver_uninstaller() {
  echo -e "${bold}Uninstalling NVIDIA drivers...${normal}"
  nvram -d nvda_drv
  local webdriver_uninstaller="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
  [[ ! -s "${webdriver_uninstaller}" ]] && echo -e "None found." && return
  installer -target "/" -pkg "${webdriver_uninstaller}" 2>&1 1>/dev/null
  echo -e "Drivers uninstalled.\nIf in ${bold}Single User Mode${normal}, driver only deactivated." && return
}

### In-place re-patcher
uninstall() {
  [[ ${amdlegacy_enabled} == "0" && ${binpatch_enabled} == "0" && ! -e "${nvdastartupweb_kextpath}" ]] && echo -e "No patches detected.\n${bold}System already clean.${normal}" && return
  echo -e "${bold}Uninstalling...${normal}"
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  [[ -e "${nvdastartupweb_kextpath}" ]] && yesno_action "Remove ${bold}NVIDIA Web Drivers${normal}?" "echo -e \"\n\" && run_webdriver_uninstaller" "echo -e \"\n\""
  echo -e "${bold}Reverting binaries...${normal}"
  if [[ ${ti82_enabled} == 1 ]]
  then
    create_hexrepresentation "${iotfam_binpath}"
    patch_binary "${iotfam_binpath}" "${hex_skipenum_patch}" "${hex_skipenum}"
    create_patched_binary "${iotfam_binpath}"
  fi
  create_hexrepresentation "${agw_binpath}"
  [[ ${tbswitch_enabled} == 1 ]] && patch_binary "${agw_binpath}" "${system_thunderbolt_ver}" "${hex_thunderboltswitchtype}"3
  if [[ ${nvidia_enabled} == 1 ]]
  then
    create_hexrepresentation "${iog_binpath}"
    patch_binary "${iog_binpath}" "${hex_iopcitunnelled_patch}" "${hex_iopcitunnelled}"
    patch_binary "${agw_binpath}" "${hex_iopcitunnelled_patch}" "${hex_iopcitunnelled}"
    create_patched_binary "${iog_binpath}"
    modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    modify_plist "${iondrv_plistpath}" "Delete" "${set_iognvda_pcitunnelled}"
  fi
  create_patched_binary "${agw_binpath}"
  echo -e "Binaries reverted."
  [[ "${1}" == -end ]] && end_binary_modifications "Uninstallation Complete." -no-agent
}

# ----- BINARY MANAGER

### Binary first-time setup
first_time_setup() {
  [[ $is_bin_call == 1 ]] && return
  call_script_file="$(pwd)/$(echo -e "${script}")"
  [[ "${script}" == "${0}" ]] && call_script_file="$(echo -e "${call_script_file}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${call_script_file}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${script_bin}" ]] && BIN_SHA="$(shasum -a 512 -b "${script_bin}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  rsync "${call_script_file}" "${script_bin}"
  chown "${SUDO_USER}" "${script_bin}"
  chmod 755 "${script_bin}"
}

# --- RECOVERY SYSTEM

### Perform recovery
perform_recovery() {
  echo -e "${bold}Recovering...${normal}"
  rsync -rt "${backupkext_dirpath}"* "${sysextensions_path}"
  modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
  modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
  run_webdriver_uninstaller
  echo -e "System restored."
  end_binary_modifications "Recovery complete." -no-agent
}

### Recovery logic
recover_sys() {
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  [[ ! -e "${scriptconfig_filepath}" || ! -d "${backupkext_dirpath}" ]] && echo -e "\nNothing to recover.\n\nConsider ${bold}system recovery${normal} or ${bold}rebooting${normal}." && return
  local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
  local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
  if [[ "${prev_macos_ver}" != "${macos_ver}" || "${prev_macos_build}" != "${macos_build}" ]]
  then
    echo -e "\n${bold}Last Backup${normal}     ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
    echo -e "${bold}Current System${normal}  ${macos_ver} ${bold}[${macos_build}]${normal}\n"
    [[ ${binpatch_enabled} == 1 ]] && echo -e "No relevant backup available. Better to ${bold}uninstall${normal}." || echo -e "System may already be clean."
    yesno_action "Still ${bold}attempt recovery${normal}?" "echo -e \"\n\" && perform_recovery" "echo -e \"\n\nRecovery aborted.\""
  else
    perform_recovery
  fi
}

# ----- ANOMALY MANAGER

### Detect discrete GPU vendor
detect_discrete_gpu_vendor() {
  dgpu_vendor="$(ioreg -n GFX0@0 | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4)"
  [[ "${dgpu_vendor}" == "de10" ]] && dgpu_vendor="NVIDIA" && return
  [[ "${dgpu_vendor}" == "0210" ]] && dgpu_vendor="AMD" && return
  dgpu_vendor="None"
}

### Detect Mac Model
detect_mac_model() {
  is_desktop_mac=false
  local model_id="$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')"
  [[ ! "MacBook" =~ "${model_id}" ]] && is_desktop_mac=true
}

### Invoke purge-nvda.sh (3.0.5 or later)
# Check connectivity before attempting
invoke_purge_nvda() {
  local purge_nvda_dirpath="/usr/local/bin/purge-nvda"
  echo -e "${bold}Invoking purge-nvda.sh...${normal}"
  curl -q -s "https://api.github.com/repos/mayankk2308/purge-nvda/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"browser_download_url":[ \t]*"([^"]+)".*/\1/' | xargs curl -L -s -0 > "${purge_nvda_dirpath}"
  chmod +x "${purge_nvda_dirpath}"
  chown "${SUDO_USER}" "${purge_nvda_dirpath}"
  purge-nvda "${1}" "${2}" 2>/dev/null 1>&2
  echo "Anomaly resolution attempted."
}

### Invoke pmset
invoke_pmset() {
  echo -e "${bold}Invoking pmset...${normal}"
  pmset -a gpuswitch 0 2>/dev/null
  echo -e "Mux changed to iGPU."
}

### Compute anomaly states
anomaly_states() {
  detect_mac_model
  detect_discrete_gpu_vendor
  will_use_ext_disp=0
  resolution_needed=0
  yesno_action "Will you be using an ${bold}external monitor${normal}?" "will_use_ext_disp=1" "will_use_ext_disp=0"
  [[ ${will_use_ext_disp} == 0 ]] && return
  [[ ${is_desktop_mac} == 1 ]] && resolution_needed="-1" && return
  if [[ "${dgpu_vendor}" == "NVIDIA" ]]
  then
    [[ -f "${nvdastartupweb_plistpath}" && ${nvidia_enabled} == 1 ]] && resolution_needed=1 && return
    [[ ${tbswitch_enabled} == 1 ]] && resolution_needed=2 && return
  elif [[ "${dgpu_vendor}" == "AMD" ]]
  then
    [[ ${nvidia_enabled} == 1 ]] && resolution_needed=3 && return
  fi
}

### Resolve anomalies
resolve_anomalies() {
  case "${resolution_needed}" in
    1)
    [[ "${1}" == -bypass ]] && invoke_purge_nvda -on -no-rbno-st && return
    yesno_action "${bold}Attempt resolution${normal}?" "echo -e \"\n\" && invoke_purge_nvda -on -no-rb" "echo -e \"\n\nNo action taken.\" && return";;
    2)
    [[ "${1}" == -bypass ]] && invoke_purge_nvda -fa -no-rbno-st && return
    yesno_action "${bold}Attempt resolution${normal}?" "echo -e \"\n\" && invoke_purge_nvda -fa -no-rb" "echo -e \"\n\nNo action taken.\" && return";;
    3)
    [[ "${1}" == -bypass ]] && invoke_pmset && return
    yesno_action "${bold}Attempt resolution${normal}?" "echo -e \"\n\" && invoke_pmset" "echo -e \"\n\nNo action taken.\" && return";;
  esac
}

### Print anomalies, if any
print_anomalies() {
  echo -e "\n\n${bold}Discrete GPU${normal}: ${dgpu_vendor}\n"
  case "${resolution_needed}" in
    1)
    echo -e "${bold}Problem${normal}     Loss of OpenCL/GL on all NVIDIA GPUs."
    echo -e "${bold}Resolution${normal}  Use ${bold}purge-nvda.sh${normal} NVIDIA optimizations.";;
    2)
    echo -e "${bold}Problem${normal}     Black screens on monitors connected to eGPU."
    echo -e "${bold}Resolution${normal}  Use ${bold}purge-nvda.sh${normal} AMD optimizations.";;
    3)
    echo -e "${bold}Problem${normal}     Black screens/slow performance with eGPU.";;
    *)
    [[ ${is_desktop_mac} == 1 ]] && echo "No resolutions to any anomalies if present." || echo "No anomalies found.";;
  esac
}

### Anomaly detection
detect_anomalies() {
  echo -e "\n\nAnomaly Detection will check your system to ${bold}find\npotential hiccups${normal} based on the applied system patches."
  anomaly_states
  print_anomalies
  resolve_anomalies
}

# --- USER INTERFACE

### Request donation
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest"
  echo -e "\n\nSee your ${bold}web browser${normal}."
}

### Notify
notify() {
  osascript -e "
  set promptIcon to \"nil\"
  set outcome to \"nil\"
  set theDialogText to \"${1}\"
  try
    set promptIcon to (POSIX file \"${prompticon_filepath}\") as alias
  end try
  if promptIcon is \"nil\" then
    set outcome to (display dialog theDialogText buttons {\"Never\", \"Later\", \"Apply\"} default button \"Apply\" cancel button \"Later\")
  else
    set outcome to (display dialog theDialogText buttons {\"Never\", \"Later\", \"Apply\"} default button \"Apply\" cancel button \"Later\" with icon promptIcon)
  end if
  if (outcome = {button returned:\"Apply\"}) then
	  tell application \"Terminal\"
		  activate
		  do script \"purge-wrangler\"
	  end tell
  else if (outcome = {button returned:\"Never\"}) then
    do shell script \"rm ~/Library/LaunchAgents/io.egpu.purge-wrangler-agent.plist\"
  end if" 2>/dev/null 1>&2
  sleep 10
}

### Show update prompt
show_update_prompt() {
  check_patch
  [[ ! -e "${scriptconfig_filepath}" ]] && sleep 10 && return
  local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
  local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
  local did_patch="$($pb -c "Print :DidApplyBinPatch" "${scriptconfig_filepath}")"
  local did_patch_nvdawebdrv="$($pb -c "Print :DidApplyPatchNVDAWebDrv" "${scriptconfig_filepath}")"
  [[ "${did_patch_nvdawebdrv}" == "true" && ${nvdawebdrv_patched} == 0 ]] && notify "There has been a change with previously patched NVIDIA Web Drivers. Re-apply PurgeWrangler patches to enable driver for eGPUs?" && return
  [[ ${binpatch_enabled} == "1" || ("${prev_macos_ver}" == "${macos_ver}" && "${prev_macos_build}" == "${macos_build}") || ${did_patch} == false ]] && sleep 10 && return
  notify "PurgeWrangler eGPU patches have been reset because macOS was updated. Would you like to re-enable patches?"
}

### Script menu
present_menu() {
  clear
  echo -e "➣  ${bold}PurgeWrangler (${script_ver})${normal}\n
   ➣  ${bold}Patch Manager${normal}     ➣  ${bold}More Options${normal}
   ${bold}1.${normal} Automatic         ${bold}6.${normal} Web Drivers
   ${bold}2.${normal} AMD eGPUs         ${bold}7.${normal} Status
   ${bold}3.${normal} NVIDIA eGPUs      ${bold}8.${normal} Uninstall
   ${bold}4.${normal} AMD Legacy GPUs   ${bold}9.${normal} Recovery
   ${bold}5.${normal} Ti82 Support      ${bold}D.${normal} Donate

   ${bold}0.${normal} Quit\n"
  read -n1 -p "${bold}What next?${normal} [0-9|D]: " userinput
  process_args "${userinput}"
  yesno_action "${bold}Back to menu?${normal}" "perform_sys_check && present_menu && return" "echo -e \"\n\" && exit"
}

### Process user input
process_args() {
  case "${1}" in
    -a|--auto|1)
    echo;;
    -ea|--enable-amd|2)
    echo -e "\n\n➣ ${bold}AMD eGPUs${normal}\n"
    backup_system
    patch_tb -end;;
    -en|--enable-nv|3)
    echo -e "\n\n➣ ${bold}NVIDIA eGPUs${normal}\n"
    backup_system
    patch_nv -prompt -end;;
    -al|--amd-legacy|4)
    echo -e "\n\n➣ ${bold}AMD Legacy GPUs${normal}\n"
    install_amd_legacy_kext -end;;
    -t8|--ti82|5)
    echo -e "\n\n➣ ${bold}Ti82 Support${normal}\n"
    backup_system
    enable_ti82 -end;;
    -nw|--nvidia-web|6)
    echo -e "\n\n➣ ${bold}NVIDIA Web Drivers${normal}\n"
    install_ver_spec_webdrv;;
    -s|--status|7)
    echo -e "\n\n➣ ${bold}Patch Status${normal}\n"
    check_patch_status;;
    -u|--uninstall|8)
    echo -e "\n\n➣ ${bold}Uninstall${normal}\n"
    uninstall -end;;
    -r|--recover|9)
    echo -e "\n\n➣ ${bold}Recovery${normal}\n"
    recover_sys;;
    -d|--donate|D|d)
    donate;;
    A|a)
    detect_anomalies;;
    0)
    echo -e "\n" && exit;;
    "")
    fetch_latest_release
    first_time_setup
    present_menu;;
    *)
    echo -e "\n\nInvalid option.";;
  esac
}

# --- SCRIPT DRIVER

### Primary execution routine
begin() {
  [[ "${2}" == "--on-launch-check" ]] && show_update_prompt && return
  validate_caller "${1}" "${2}"
  perform_sys_check
  process_args "${2}"
}

begin "${0}" "${1}"