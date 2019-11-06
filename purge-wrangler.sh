#!/bin/sh

# purge-wrangler.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 6.2.0

# ----- ENVIRONMENT

# Script and options
(script="${BASH_SOURCE}"
option=""
single_user_mode="$(sysctl -n kern.singleuser)"

# Enable case-insensitive comparisons
shopt -s nocasematch

# Text management
bold="$(tput bold)"
normal="$(tput sgr0)"
underline="$(tput smul)"

# User interface artifacts
gap=" "
mark=">>"

# Script binary
local_bin="/usr/local/bin"
script_bin="${local_bin}/purge-wrangler"
tmp_script="${local_bin}/purge-wrangler-new"
is_bin_call=0
call_script_file=""

# Script version
script_major_ver="6" && script_minor_ver="2" && script_patch_ver="0"
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

# Thunderbolt patch references
hex_thunderboltswitchtype="494F5468756E646572626F6C74537769746368547970653"
hex_thunderboltcheck="4883C3174889DF31F631D2E8000000004883F803"
hex_thunderboltcheck_patch="4883C3174889DF31F631D2E8000000004883F800"
hex_selected_thunderbolt="${hex_thunderboltcheck}"
hex_selected_thunderbolt_patch="${hex_thunderboltcheck_patch}"

# NVIDIA patch references
hex_nvda_bypass="494F50434954756E6E656C6C6564"
hex_nvda_bypass_patch="494F50434954756E6E656C6C6571"
hex_nvda_clamshell="F0810D790A0300000200008B35730A0300"
hex_nvda_clamshell_patch="F0810D790A0300000000008B35730A0300"

# Ti82 patch references
hex_skipenum="554889E54157415641554154534881EC2801"
hex_skipenum_patch="554889E531C05DC341554154534881EC2801"

# Patch status indicators
amdlegacy_enabled=2
tbswitch_enabled=2
nvidia_enabled=2
binpatch_enabled=0
ti82_enabled=2
nvdawebdrv_patched=2
using_nvdawebdrv=0

# Supported GPU architectures
supported_amd_archs=("Polaris" "Vega" "Navi")
supported_nv_archs=("GK" "GF")

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
amdlegacy_integrity_hash="b64e399fa4d350b723170eb69780741c3f54af94570b995a201d70d540771500e67081b235c05deca95ad5e44cf1ba529766e47ff3b5f62eeb94161c80b0e29a"

# General backup path
support_dirpath="/Library/Application Support/Purge-Wrangler/"
backupkext_dirpath="${support_dirpath}Kexts/"
prompticon_downloadurl="http://raw.githubusercontent.com/mayankk2308/purge-wrangler/${script_ver}/resources/pw.png"
prompticon_filepath="${support_dirpath}pw.png"
prompticon_integrity_hash="28a86c463d184c19c666252a948148c24702990fc06d5b99e419c04efd6475324606263cf38c5a76be3f971c49aeecf89be61b1b8cbe68b73b33c69a903803c5"

## Deprecated manifest
manifest="${support_dirpath}manifest.wglr"

# Property Lists
pb="/usr/libexec/PlistBuddy"
webdriver_plistpath="/usr/local/bin/webdriver.plist"
scriptconfig_filepath="${support_dirpath}io.egpu.purge-wrangler.config.plist"
set_iognvda_pcitunnelled=":IOKitPersonalities:3:IOPCITunnelCompatible bool"
set_nvdastartup_pcitunnelled=":IOKitPersonalities:NVDAStartup:IOPCITunnelCompatible bool"
set_nvdastartup_requiredos=":IOKitPersonalities:NVDAStartup:NVDARequiredOS"
plist_defaultstring="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">\n<dict>\n</dict>\n</plist>"

# --- SCRIPT HELPERs

## -- User Interface and Utilities

### Printf newline
printfn() {
  printf '%b\n' "${@}"
}

### Clear print
printfc() {
  printf "\033[2K\r"
  printfn "${@}"
}

### Prompt for a yes/no action
yesno_action() {
  local prompt="${1}"
  local yesaction="${2}"
  local noaction="${3}"
  local no_newline="${4}"
  [[ -z "${no_newline}" ]] && printfn
  read -n1 -p "${prompt} [Y/N]: " userinput
  printf "\033[2K\r"
  [[ ${userinput} == "Y" ]] && eval "${yesaction}" && return
  [[ ${userinput} == "N" ]] && eval "${noaction}" && return
  printfn "Invalid choice. Please try again."
  yesno_action "${prompt}" "${yesaction}" "${noaction}"
}

### Object downloader
obj_download() {
  local url="${1}"
  local dst="${2}"
  local integrity_hash="${3}"
  curl -qLs  -o "${dst}" "${url}"
  [[ "$(shasum -a 512 "${dst}" | awk '{ print $1 }')" != "${integrity_hash}" ]] && rm -rf "${dst}" 2>/dev/null 1>&2 || return 0
}

## -- Binary Patching Mechanism (P1 -> P2 -> P3)

### Optional: Check binary patchability
check_bin_patchability() {
  local target_binary="${1}"
  local find="${2}"
  local dump="$(hexdump -ve '1/1 "%.2X"' "${target_binary}")"
  [[ "${dump}" == *"${find}"* ]] && return 0 || return 1
}

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
  sed -i "" -e "s/${find}/${replace}/g" "${scratch_hex}" 2>/dev/null 1>&2
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
  printfn "${plist_defaultstring}" >> "${scriptconfig_filepath}"
  modify_plist "${scriptconfig_filepath}" "Add" ":OSVersionAtPatch string" "${macos_ver}"
  modify_plist "${scriptconfig_filepath}" "Add" ":OSBuildAtPatch string" "${macos_build}"
  modify_plist "${scriptconfig_filepath}" "Add" ":DidApplyBinPatch bool" "false"
  modify_plist "${scriptconfig_filepath}" "Add" ":DidApplyPatchNVDAWebDrv bool" "false"
}

### Updates the configuration as necessary
update_config() {
  generate_config
  check_patch
  local status=("false" "true" "false")
  modify_plist "${scriptconfig_filepath}" "Set" ":OSVersionAtPatch" "${macos_ver}"
  modify_plist "${scriptconfig_filepath}" "Set" ":OSBuildAtPatch" "${macos_build}"
  modify_plist "${scriptconfig_filepath}" "Set" ":DidApplyBinPatch" "${status[${binpatch_enabled}]}"
  modify_plist "${scriptconfig_filepath}" "Set" ":DidApplyPatchNVDAWebDrv" "${status[${nvdawebdrv_patched}]}"
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
  printfn "${plist_defaultstring}" >> "${agent_plistpath}"
  $pb -c "Add :Label string ${script_launchagent}" "${agent_plistpath}"
  $pb -c "Add :OnDemand bool false" "${agent_plistpath}"
  $pb -c "Add :LaunchOnlyOnce bool true" "${agent_plistpath}"
  $pb -c "Add :RunAtLoad bool true" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments array" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments:0 string ${script_bin}" "${agent_plistpath}"
  $pb -c "Add :ProgramArguments:1 string -l" "${agent_plistpath}"
  chown "${SUDO_USER}" "${agent_plistpath}"
  obj_download "${prompticon_downloadurl}" "${prompticon_filepath}" "${prompticon_integrity_hash}"
  su "${SUDO_USER}" -c "launchctl load -w \"${agent_plistpath}\""
}

# --- SCRIPT SOFTWARE UPDATE SYSTEM

### Perform software update
perform_software_update() {
  printfn "${bold}Downloading...${normal}"
  curl -qLs -o "${tmp_script}" "${latest_release_dwld}"
  [[ "$(cat "${tmp_script}")" == "404: Not Found" ]] && printfn "Download failed.\n${bold}Continuing without updating...${normal}" && rm "${tmp_script}" && return
  printfn "Download complete.\n${bold}Updating...${normal}"
  chmod 700 "${tmp_script}" && chmod +x "${tmp_script}"
  rm "${script}" && mv "${tmp_script}" "${script}"
  chown "${SUDO_USER}" "${script}"
  printfn "Update complete."
  "${script}" "${option}"
  exit 0
}

### Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${local_bin}"
  [[ "${is_bin_call}" == 0 ]] && return
  latest_script_data="$(curl -q -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest")"
  latest_release_ver="$(printfn "${latest_script_data}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  latest_release_dwld="$(printfn "${latest_script_data}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  latest_major_ver="$(printfn "${latest_release_ver}" | cut -d '.' -f1)"
  latest_minor_ver="$(printfn "${latest_release_ver}" | cut -d '.' -f2)"
  latest_patch_ver="$(printfn "${latest_release_ver}" | cut -d '.' -f3)"
  if [[ $latest_major_ver > $script_major_ver || ($latest_major_ver == $script_major_ver && $latest_minor_ver > $script_minor_ver)\
   || ($latest_major_ver == $script_major_ver && $latest_minor_ver == $script_minor_ver && $latest_patch_ver > $script_patch_ver) && ! -z "${latest_release_dwld}" ]]
  then
    printfn "${mark}${gap}${bold}Software Update${normal}\n\nSoftware updates are available.\n\nOn Your System    ${bold}${script_ver}${normal}\nLatest Available  ${bold}${latest_release_ver}${normal}\n"
    perform_software_update
  fi
}

# --- SYSTEM CONFIGURATION MANAGER

### Check caller
validate_caller() {
  [[ -z "${script}" ]] && printfn "\n${bold}Cannot execute${normal}.\nPlease see the README for instructions.\n" && exit
  [[ "${1}" != "${script}" ]] && option="${3}" || option="${2}"
  [[ "${script}" == "${script_bin}" ]] && is_bin_call=1
}

### Elevate privileges
elevate_privileges() {
  if [[ $(id -u) != 0 ]]
  then
    sudo /bin/sh "${script}" "${option}"
    exit
  fi
}

### System integrity protection check
check_sip() {
  if [[ ! -z "$(csrutil status | grep -i enabled)" ]]
  then
    printfn "\nPlease disable ${bold}System Integrity Protection${normal}.\n"
    exit
  fi
}

### Check if system volume is writable
mount_attempt=0
check_sys_volume() {
  if [[ ! -w "${sysextensions_path}" ]]
  then
    if [[ ${mount_attempt} == 0 ]]
    then
      mount -uw / 2>/dev/null 1>&2
      mount_attempt=1
      check_sys_volume
      return
    fi
    printfn "\nYour system volume is ${bold}read-only${normal}. PurgeWrangler cannot proceed.\n"
    exit
  fi
}

### Old patch(es) selector
select_older_patches() {
  is_10151_or_newer=0
  hex_selected_thunderbolt="${hex_thunderboltswitchtype}3"
  hex_selected_thunderbolt_patch="${system_thunderbolt_ver}"
}

### macOS compatibility check
check_macos_version() {
  is_10151_or_newer=1
  local macos_major_ver="$(printfn "${macos_ver}" | cut -d '.' -f2)"
  local macos_minor_ver="$(printfn "${macos_ver}" | cut -d '.' -f3)"
  [[ (${macos_major_ver} < 13) || (${macos_minor_ver} == 13 && ${macos_minor_ver} < 4) ]] && printfn "\n${bold}macOS 10.13.4 or later${normal} required.\n" && exit
  [[ (${macos_major_ver} < 15) || (${macos_major_ver} == 15 && ${macos_minor_ver} < 1) ]] && select_older_patches
}

### Ensure presence of system extensions
check_sys_extensions() {
  if [[ ! -s "${agc_kextpath}" || ! -s "${agw_binpath}" || ! -s "${iondrv_kextpath}" || ! -s "${iog_binpath}" || ! -s "${iotfam_kextpath}" || ! -s "${iotfam_binpath}" ]]
  then
    printfn "\nUnexpected system configuration or missing files."
    yesno_action "${bold}Run Recovery?${normal}" "recover_sys" "exit"
    printfn
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
  [[ "${hex_agwbin}" =~ "${hex_selected_thunderbolt_patch}" && "${system_thunderbolt_ver}" != "${hex_thunderboltswitchtype}"3 ]] && tbswitch_enabled=1 || tbswitch_enabled=0
  [[ "${hex_iogbin}" =~ "${hex_nvda_bypass_patch}" ]] && nvidia_enabled=1 || nvidia_enabled=0
  [[ "${hex_iotfambin}" =~ "${hex_skipenum_patch}" ]] && ti82_enabled=1 || ti82_enabled=0
  [[ ${tbswitch_enabled} == "1" || ${ti82_enabled} == "1" || ${nvidia_enabled} == "1" ]] && binpatch_enabled=1
}

### Display patch statuses
check_patch_status() {
  printfn "${mark}${gap}${bold}System Status${normal}\n"
  local status=("Disabled" "Enabled" "Unknown")
  local drv_status=("Clean" "Patched" "Absent")
  printfn "${bold}Ti82 Devices${normal}      ${status[${ti82_enabled}]}"
  printfn "${bold}TB1/2 AMD eGPUs${normal}   ${status[$tbswitch_enabled]}"
  printfn "${bold}Legacy AMD eGPUs${normal}  ${status[$amdlegacy_enabled]}"
  printfn "${bold}NVIDIA eGPUs${normal}      ${status[$nvidia_enabled]}"
  printfn "${bold}Web Drivers${normal}       ${drv_status[$nvdawebdrv_patched]}"
}

### Cumulative system check
perform_sys_check() {
  check_sip
  retrieve_tb_ver
  check_macos_version
  elevate_privileges
  check_sys_volume
  check_sys_extensions
  check_patch
  deprecate_manifest
  using_nvdawebdrv=0
}

# ----- OS MANAGEMENT

### Sanitize system permissions and caches
sanitize_system() {
  printfn "${bold}Sanitizing system...${normal}"
  chmod -R 755 "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  chown -R root:wheel "${agc_kextpath}" "${iog_kextpath}" "${iondrv_kextpath}" "${nvdastartupweb_kextpath}" "${nvdastartup_kextpath}" "${amdlegacy_kextpath}" "${iotfam_kextpath}" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  printfn "System sanitized."
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
  printfn "${bold}Backing up...${normal}"
  if [[ ! -z $(find "${backupkext_dirpath}" -mindepth 1 -print -quit 2>/dev/null) && -s "${scriptconfig_filepath}" ]]
  then
    local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
    local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
    if [[ "${prev_macos_ver}" == "${macos_ver}" && "${prev_macos_build}" == "${macos_build}" ]]
    then
      if [[ ${binpatch_enabled} == 0 ]]
      then
        execute_backup
        printfn "Backup refreshed."
        update_config
        return
      fi
      printfn "Backup already exists."
    else
      printfn "\n${bold}Last Backup${normal}     ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
      printfn "${bold}Current System${normal}  ${macos_ver} ${bold}[${macos_build}]${normal}\n"
      printfn "${bold}Updating backup...${normal}"
      if [[ ${binpatch_enabled} == 1 ]]
      then
        printfn "${bold}Uninstalling patch(es) before updating backup...${normal}\n"
        uninstall
      fi
      execute_backup
      update_config
      printfn "Update complete."
    fi
  else
    execute_backup
    update_config
    printfn "Backup complete."
  fi
}

# --- CORE PATCHWORK

### Run clean reboot
clean_reboot() {
  osascript -e 'tell application "Finder" to restart' &
}

### Reboot prompt
reboot_action() {
  [[ ${1} == -f ]] && printfn "${mark}${gap}${bold}Reboot${normal}"
  yesno_action "${bold}Reboot Now?${normal}" "printfn \"${bold}Rebooting...
  ${normal}\" && clean_reboot && exit" "printfn \"Reboot aborted.\""
}

### Conclude patching sequence
end_binary_modifications() {
  update_config
  sanitize_system
  [[ "${2}" == -no-agent ]] && rm -rf "/Users/${SUDO_USER}/Library/LaunchAgents/${script_launchagent}.plist" || create_launchagent
  [[ ${single_user_mode} == 1 ]] && reboot 1>/dev/null 2>&1 && exit
  local message="${1}"
  printfn "${bold}${message}\n\n${bold}Reboot${normal} to apply changes."
  reboot_action
}

### Install AMDLegacySupport.kext
install_amd_legacy_kext() {
  [[ "${1}" == -end ]] && printfn "${mark}${gap}${bold}AMD Legacy Support${normal}\n"
  [[ -d "${amdlegacy_kextpath}" ]] && printfn "${bold}AMDLegacySupport.kext${normal} already installed." && return
  printfn "${bold}Downloading AMDLegacySupport...${normal}"
  obj_download "${amdlegacy_downloadurl}" "${amdlegacy_downloadpath}" "${amdlegacy_integrity_hash}"
  [[ ! -e "${amdlegacy_downloadpath}" ]] && printfn "Could not download." && return 0
  printfn "Download complete."
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  unzip -d "${libextensions_path}" "${amdlegacy_downloadpath}" 1>/dev/null 2>&1
  rm -r "${amdlegacy_downloadpath}" "${libextensions_path}/__MACOSX" 1>/dev/null 2>&1
  if [[ "${1}" == -end ]]; then end_binary_modifications "Installation complete."; fi
}

### Enable Ti82
enable_ti82() {
  [[ "${1}" == -end ]] && printfn "${mark}${gap}${bold}Enable Ti82 Support${normal}\n" && backup_system
  [[ ${ti82_enabled} == 1 ]] && printfn "Ti82 support is already enabled on this system." && return
  printfn "${bold}Enabling Ti82 support...${normal}"
  check_bin_patchability "${iotfam_binpath}" "${hex_skipenum}"
  [[ $? == 1 ]] && printfn "${bold}Unable to patch${normal} for Ti82 devices." && generate_sys_report && return 0
  create_hexrepresentation "${iotfam_binpath}"
  patch_binary "${iotfam_binpath}" "${hex_skipenum}" "${hex_skipenum_patch}"
  create_patched_binary "${iotfam_binpath}"
  printfn "Ti82 support enabled."
  if [[ "${1}" == -end ]]; then end_binary_modifications "Patch complete."; fi
}

### Patch TB1/2 block
patch_tb() {
  printfn "${bold}Patching for AMD eGPUs...${normal}"
  [[ "${1}" == -prompt ]] && yesno_action "Enable ${bold}Legacy AMD Support${normal}?" "install_amd_legacy_kext && printfn" "printfn \"Skipping legacy kext.\n\""
  [[ -e "${deprecated_automate_egpu_kextpath}" ]] && rm -r "${deprecated_automate_egpu_kextpath}"
  [[ ${nvidia_enabled} == 1 ]] && printfn "System has previously been patched for ${bold}NVIDIA eGPUs${normal}." && return
  [[ ${tbswitch_enabled} == 1 ]] && printfn "System has already been patched for ${bold}AMD eGPUs${normal}." && return
  [[ "${system_thunderbolt_ver}" == "${hex_thunderboltswitchtype}3" ]] && printfn "No patch required for this Mac." && return
  check_bin_patchability "${agw_binpath}" "${hex_selected_thunderbolt}"
  [[ $? == 1 ]] && printfn "${bold}Unable to patch${normal} for TB1/2 AMD eGPUs." && generate_sys_report && return 0
  create_hexrepresentation "${agw_binpath}"
  patch_binary "${agw_binpath}" "${hex_selected_thunderbolt}" "${hex_selected_thunderbolt_patch}"
  create_patched_binary "${agw_binpath}"
  printfn "Patches applied."
}

### Download and install NVIDIA Web Drivers
install_web_drivers() {
  local installerpkg_path="/usr/local/NVDAInstall.pkg"
  local installerpkgexpanded_path="/usr/local/NVDAInstall"
  local nvdadrv_ver="${1}"
  local nvdadrv_downloadurl="${2}"
  rm -r "${installerpkgexpanded_path}" "${installerpkg_path}" 2>/dev/null 1>&2
  printfn "${bold}Downloading drivers (${nvdadrv_ver})...${normal}"
  curl -q --connect-timeout 15 --progress-bar -o "${installerpkg_path}" "${nvdadrv_downloadurl}"
  if [[ ! -s "${installerpkg_path}" ]]
  then
    rm -r "${installerpkg_path}" 2>/dev/null 1>&2
    printfn "Unable to download."
    return
  fi
  printfn "Download complete.\n${bold}Sanitizing package...${normal}"
  pkgutil --expand-full "${installerpkg_path}" "${installerpkgexpanded_path}"
  sed -i "" -e "/installation-check/d" "${installerpkgexpanded_path}/Distribution"
  local nvdastartup_pkgkextpath="$(find "${installerpkgexpanded_path}" -maxdepth 1 | grep -i NVWebDrivers)/Payload/Library/Extensions/NVDAStartupWeb.kext"
  if [[ ! -d "${nvdastartup_pkgkextpath}" ]]
  then
    rm -r "${installerpkg_path}" "${installerpkgexpanded_path}" 2>/dev/null 1>&2
    printfn "Unable to patch driver."
    return
  fi
  $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${nvdastartup_pkgkextpath}/Contents/Info.plist" 2>/dev/null 1>&2
  chown -R root:wheel "${nvdastartup_pkgkextpath}"
  rm -r "${installerpkg_path}"
  pkgutil --flatten-full "${installerpkgexpanded_path}" "${installerpkg_path}" 2>/dev/null 1>&2
  printfn "Package sanitized.\n${bold}Installing...${normal}"
  local installer_err="$(installer -target "/" -pkg "${installerpkg_path}" 2>&1 1>/dev/null)"
  [[ -e "${nvdastartupweb_kextpath}" ]] && printfn "Installation complete." || printfn "Installation failed."
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
  printfn "${bold}Fetching driver information...${normal}"
  [[ -f "${nvdastartupweb_plistpath}" ]] && nvdawebdrv_alreadypresentos="$(${pb} -c "Print ${set_nvdastartup_requiredos}" "${nvdastartupweb_plistpath}" 2>/dev/null)"
  local webdriver_data="$(curl -q -s "https://gfe.nvidia.com/mac-update")"
  [[ -z "${webdriver_data}" ]] && return
  printfn "${webdriver_data}" > "${webdriver_plistpath}"
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
    (( ${currentdriver_majormacosbuild} - ${macos_major_build} != 0 )) && nvdawebdrv_canpatchlatest=2 || nvdawebdrv_canpatchlatest=1
  else
    nvdawebdrv_canpatchlatest=0
    nvdawebdrv_lastcompatible_ver="${currentdriver_ver}"
    nvdawebdrv_lastcompatible_downloadurl="${currentdriver_downloadurl}"
  fi
  printfn "Information fetched."
}

### Patch NVIDIA Web Driver version
patch_nvdawebdrv_version() {
  printfn "${bold}Patching drivers...${normal}"
  $pb -c "Set ${set_nvdastartup_requiredos} \"${macos_build}\"" "${nvdastartupweb_plistpath}" 2>/dev/null 1>&2
  printfn "Drivers patched."
}

### Current webdriver possibilities
webdriver_possibilities() {
  if [[ "${3}" == -already-present ]]
  then
    [[ "${nvdawebdrv_alreadypresentos}" == "${macos_build}" ]] && printfn "Appropriate NVIDIA Web Drivers are ${bold}already installed${normal}." && return
    printfn "Installed ${bold}NVIDIA Web Drivers${normal} are specifying incorrect macOS build."
    [[ "${4}" != "-prompt" ]] && printfn "${bold}Resolving...${normal}" && patch_nvdawebdrv_version 1>/dev/null && printfn "Resolved." && return
    yesno_action "${bold}Attempt to Rectify${normal}?" "patch_nvdawebdrv_version" "printfn \"Drivers unchanged.\n\""
  else
    local recommendation=("Not Required" "Suggested" "Not Advised" "Cannot Determine")
    printfn "\nWeb drivers will require patching.\n${bold}Patch Recommendation${normal}: ${recommendation[${nvdawebdrv_canpatchlatest}]}"
    yesno_action "${bold}Patch?${normal}" "install_web_drivers \"${1}\" \"${2}\"" "printfn \"Installation aborted.\n\" && return"
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
    printfn "No compatible or suitably patchable NVIDIA driver available.";;
  esac
}

### Install specified version of Web Drivers
install_ver_spec_webdrv() {
  printfn "${mark}${gap}${bold}Install NVIDIA Web Drivers${normal}\n"
  printfn "Specify a ${bold}Webdriver version${normal} to install (${bold}L = Latest${normal}).\nExisting drivers will be overwritten.\n${bold}Example${normal}: 387.10.10.10.25.161\n"
  read -p "${bold}Version${normal} [L|Q]: " userinput
  printfn
  [[ -z "${userinput}" || "${userinput}" == Q ]] && printfn "No changes made." && return
  get_nvdawebdrv_stats "${userinput}"
  [[ "${userinput}" != "L" && -z "${nvdawebdrv_target_downloadurl}" ]] && printfn "No driver found for specified version." && return
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
      yesno_action "Install ${bold}NVIDIA Web Drivers${normal}?" "using_nvdawebdrv=1 && run_webdriver_installer -prompt" "printfn \"Skipping web drivers.\n\""
    fi
  fi
  local nvdastartupplist_topatch="${nvdastartupweb_plistpath}"
  if (( ${using_nvdawebdrv} == 1 ))
  then
    [[ ! -f "${nvdastartupweb_plistpath}" ]] && printfn "${bold}NVIDIA Web Drivers${normal} required, but not installed." && return
    nvram nvda_drv=1
  else
    nvram -d nvda_drv 2>/dev/null
    nvdastartupplist_topatch="${nvdastartup_plistpath}"
  fi
  check_bin_patchability "${agw_binpath}" "${hex_nvda_bypass}"
  local pass=$?
  check_bin_patchability "${iog_binpath}" "${hex_nvda_bypass}"
  pass=$(( ${pass} + $? ))
  (( ${pass} != 0 )) && printfn "${bold}Unable to patch${normal} for NVIDIA eGPUs." && generate_sys_report && return 0
  create_hexrepresentation "${agw_binpath}"
  create_hexrepresentation "${iog_binpath}"
  patch_binary "${agw_binpath}" "${hex_nvda_bypass}" "${hex_nvda_bypass_patch}"
  patch_binary "${iog_binpath}" "${hex_nvda_bypass}" "${hex_nvda_bypass_patch}"
  create_patched_binary "${agw_binpath}"
  create_patched_binary "${iog_binpath}"
  modify_plist "${iondrv_plistpath}" "Add" "${set_iognvda_pcitunnelled}" "true"
  modify_plist "${nvdastartupplist_topatch}" "Add" "${set_nvdastartup_pcitunnelled}" "true"
  rm -r "${deprecated_automate_egpu_kextpath}" 2>/dev/null 1>&2
  rm -r "${deprecated_nvsolution_kextpath}" 2>/dev/null 1>&2
  printfn "Patches applied."
}

### Patch for NVIDIA eGPUs
patch_nv() {
  printfn "${bold}Patching for NVIDIA eGPUs...${normal}"
  [[ -e "${nvdastartupweb_kextpath}" && ${nvdawebdrv_patched} == 0 ]] && run_patch_nv "${1}" && return
  [[ ${nvidia_enabled} == 1 ]] && printfn "System has already been patched for ${bold}NVIDIA eGPUs${normal}." && return
  [[ ${tbswitch_enabled} == 1 ]] && printfn "System has previously been patched for ${bold}AMD eGPUs${normal}." && return
  run_patch_nv "${1}"
}

# Run webdriver uninstallation process
run_webdriver_uninstaller() {
  nvram -d nvda_drv
  local webdriver_uninstaller="/Library/PreferencePanes/NVIDIA Driver Manager.prefPane/Contents/MacOS/NVIDIA Web Driver Uninstaller.app/Contents/Resources/NVUninstall.pkg"
  [[ ! -s "${webdriver_uninstaller}" ]] && return
  printfn "${bold}Uninstalling NVIDIA drivers...${normal}"
  installer -target "/" -pkg "${webdriver_uninstaller}" 2>&1 1>/dev/null
  [[ ${single_user_mode} == 0 ]] && printfn "Drivers Uninstalled." || printfn "Drivers deactivated."
}

### Retrieve GPU name
get_gpu_name() {
  local id="${1}"
  local vendor="${2}"
  local device_names="$(curl -s "http://pci-ids.ucw.cz/read/PC/${vendor}/${id}" | grep -i "itemname" | sed -E "s/.*Name\: (.*)$/\1/")"
  local device_name="$(printfn "${device_names}" | tail -1 | cut -d '[' -f2)"
  local egpu_arch="$(printfn "${device_names}" | tail -1 | cut -d '[' -f1)"
  if [[ ! -z "${device_name}" ]]
  then
    printfn "${device_name%?}:${egpu_arch}"
  else
    [[ ${vendor} == "10de" ]] && printfn "NVIDIA"
    [[ ${vendor} == "1002" ]] && printfn "AMD"
  fi
}

### Retrieve eGPU data
retrieve_egpu_data() {
  egpu_vendor=$(printfn "${ioreg_info}" | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4 | sed -E 's/^(.{2})(.{2}).*$/\2\1/')
  egpu_dev_id=$(printfn "${ioreg_info}" | grep \"device-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4 | sed -E 's/^(.{2})(.{2}).*$/\2\1/')
}

### Retrieve Ti82 need
get_ti82_need() {
  local ti82_data="$(system_profiler SPThunderboltDataType 2>/dev/null | grep -i unsupported)"
  [[ -z ${ti82_data} ]] && printfn "No" || printfn "Yes"
}

### Detect eGPU
detect_egpu() {
  printfn "${bold}Plug-in eGPU${normal}. Press ESC if you are not plugging in eGPU.\n"
  egpu_vendor=""
  egpu_dev_id=""
  IFS=''
  for (( i = 20; i > 0; i-- ))
  do
    printf "\033[2K\r"
    printf "${bold}Detecting eGPU (${i})...${normal}"
    needs_ti82="$(get_ti82_need)"
    [[ "${needs_ti82}" == "Yes" ]] && printfc "Detection not possible. Ti82 override needed first." && return
    ioreg_info="$(ioreg -n display@0)"
    retrieve_egpu_data
    local key=""
    read -r -s -n 1 -t 1 key
    if [[ ! -z "${egpu_vendor}" ]]
    then
      legacy_amd_needed=1
      webdrv_needed=1
      local name_data="$(get_gpu_name "${egpu_dev_id}" "${egpu_vendor}")"
      local egpu_name="$(printfn "${name_data}" | cut -d ":" -f1)"
      egpu_arch="$(printfn "${name_data}" | cut -d ":" -f2)"
      for arch in "${supported_amd_archs[@]}"; do
        if [[ "${egpu_arch}" =~ "${arch}" ]]; then
          legacy_amd_needed=0
          break
        fi
      done
      for arch in "${supported_nv_archs[@]}"; do
        if [[ "${egpu_arch}" =~ "${arch}" ]]; then
          webdrv_needed=0
          break
        fi
      done
      printfc "${bold}External GPU${normal}\t${egpu_name}"
      printfn "${bold}GPU Arch${normal}\t${egpu_arch}"
      printfn "${bold}Thunderbolt${normal}\t${system_thunderbolt_ver: -1}"
      return
    fi
    [[ "${key}" == $'\e' ]] && printfc "eGPU detection skipped. Please provide more information." && return
  done
  printfc "Detection failed. Please provide more information."
}

### Manual eGPU setup
manual_setup_egpu() {
  [[ "${needs_ti82}" == "No" ]] && yesno_action "${bold}Enable Ti82${normal}?" "enable_ti82 && printfn" "printfn \"Skipping Ti82 support.\n\"" -n
  local menu_items=("AMD" "NVIDIA" "Cancel")
  local menu_actions=("patch_tb -prompt" "patch_nv -prompt" "printfn \"Further patching aborted.\"")
  generate_menu "eGPU Vendor" "0" "-1" "0" "${menu_items[@]}"
  autoprocess_input "Choice" "" "" "false" "${menu_actions[@]}"
}

### Automatic eGPU setup
auto_setup_egpu() {
  printfn "${mark}${gap}${bold}Setup eGPU${normal}\n"
  [[ ${binpatch_enabled} == "1" || ${amdlegacy_enabled} == "1" ]] && printfn "System has previously been modified. Uninstall first." && return
  detect_egpu
  printfn
  backup_system
  printfn
  [[ ${needs_ti82} == "Yes" ]] && enable_ti82 && printfn
  if [[ "${egpu_vendor}" == "1002" ]]
  then
    if [[ "${egpu_arch}" =~ "Navi" && ${is_10151_or_newer} != 1 ]]; then
      printfn "${bold}Navi${normal} eGPUs require ${bold}macOS 10.15.1${normal} or later."
    else
      [[ ${legacy_amd_needed} == 1 ]] && install_amd_legacy_kext && printfn
      patch_tb
    fi
  elif [[ "${egpu_vendor}" == "10de" ]]
  then
    [[ ${webdrv_needed} == 1 ]] && run_webdriver_installer && using_nvdawebdrv=1 && printfn
    patch_nv
  else
    manual_setup_egpu
  fi
  check_patch
  [[ ${binpatch_enabled} != "1" && ${amdlegacy_enabled} != "1" ]] && return
  printfn
  print_anomalies
  printfn
  end_binary_modifications "Modifications complete."
}

### In-place re-patcher
uninstall() {
  printfn "${mark}${gap}${bold}Uninstall${normal}\n"
  [[ ${amdlegacy_enabled} == "0" && ${binpatch_enabled} == "0" && ! -e "${nvdastartupweb_kextpath}" ]] && printfn "No patches detected.\n${bold}System already clean.${normal}" && return
  printfn "${bold}Uninstalling...${normal}"
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  [[ -e "${nvdastartupweb_kextpath}" ]] && yesno_action "Remove ${bold}NVIDIA Web Drivers${normal}?" "run_webdriver_uninstaller" "printfn \"Skipping web drivers.\n\""
  printfn "${bold}Reverting binaries...${normal}"
  if [[ ${ti82_enabled} == 1 ]]
  then
    create_hexrepresentation "${iotfam_binpath}"
    patch_binary "${iotfam_binpath}" "${hex_skipenum_patch}" "${hex_skipenum}"
    create_patched_binary "${iotfam_binpath}"
  fi
  create_hexrepresentation "${agw_binpath}"
  [[ ${tbswitch_enabled} == 1 ]] && patch_binary "${agw_binpath}" "${hex_selected_thunderbolt_patch}" "${hex_selected_thunderbolt}"
  if [[ ${nvidia_enabled} == 1 ]]
  then
    create_hexrepresentation "${iog_binpath}"
    patch_binary "${iog_binpath}" "${hex_nvda_bypass_patch}" "${hex_nvda_bypass}"
    patch_binary "${iog_binpath}" "${hex_nvda_clamshell_patch}" "${hex_nvda_clamshell}"
    patch_binary "${agw_binpath}" "${hex_nvda_bypass_patch}" "${hex_nvda_bypass}"
    create_patched_binary "${iog_binpath}"
    modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
    modify_plist "${iondrv_plistpath}" "Delete" "${set_iognvda_pcitunnelled}"
  fi
  create_patched_binary "${agw_binpath}"
  printfn "Binaries reverted."
  end_binary_modifications "Uninstallation Complete." -no-agent
}

# ----- BINARY MANAGER

### Binary first-time setup
first_time_setup() {
  [[ $is_bin_call == 1 ]] && return
  script_sha="$(shasum -a 512 -b "${script}" | awk '{ print $1 }')"
  bin_sha=""
  [[ -s "${script_bin}" ]] && bin_sha="$(shasum -a 512 -b "${script_bin}" | awk '{ print $1 }')"
  [[ "${bin_sha}" == "${script_sha}" ]] && return
  rsync "${script}" "${script_bin}"
  chown "${SUDO_USER}" "${script_bin}"
  chmod 755 "${script_bin}"
}

# --- RECOVERY SYSTEM

### Perform recovery
perform_recovery() {
  printfn "${bold}Recovering...${normal}"
  rsync -rt "${backupkext_dirpath}"* "${sysextensions_path}"
  modify_plist "${nvdastartup_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
  modify_plist "${nvdastartupweb_plistpath}" "Delete" "${set_nvdastartup_pcitunnelled}"
  run_webdriver_uninstaller
  printfn "System restored."
  end_binary_modifications "Recovery complete." -no-agent
}

### Recovery logic
recover_sys() {
  printfn "${mark}${gap}${bold}Recovery${normal}\n"
  [[ -d "${amdlegacy_kextpath}" ]] && rm -r "${amdlegacy_kextpath}"
  [[ ! -e "${scriptconfig_filepath}" || ! -d "${backupkext_dirpath}" ]] && printfn "Nothing to recover." && return
  local prev_macos_ver="$($pb -c "Print :OSVersionAtPatch" "${scriptconfig_filepath}")"
  local prev_macos_build="$($pb -c "Print :OSBuildAtPatch" "${scriptconfig_filepath}")"
  if [[ "${prev_macos_ver}" != "${macos_ver}" || "${prev_macos_build}" != "${macos_build}" ]]
  then
    printfn "\n${bold}Last Backup${normal}     ${prev_macos_ver} ${bold}[${prev_macos_build}]${normal}"
    printfn "${bold}Current System${normal}  ${macos_ver} ${bold}[${macos_build}]${normal}\n"
    printfn "OS version ${bold}discrepancy${normal} detected with kext backup. macOS Recovery recommended instead."
    yesno_action "Still ${bold}perform recovery${normal}?" "perform_recovery" "printfn \"Recovery aborted.\""
  else
    perform_recovery
  fi
}

# ----- ANOMALY MANAGER

### Detect discrete GPU vendor
detect_discrete_gpu_vendor() {
  local dgpu_ioreg="$(ioreg -n GFX0@0)"
  dgpu_vendor="$(printfn "${dgpu_ioreg}" | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4 | sed -E 's/^(.{2})(.{2}).*$/\2\1/')"
  dgpu_dev_id="$(printfn "${dgpu_ioreg}" | grep \"device-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4 | sed -E 's/^(.{2})(.{2}).*$/\2\1/')"
}

### Detect Mac Model
detect_mac_model() {
  local model_id="$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Model Identifier/ {print $3}')"
  [[ "${model_id}" == *"MacBook"* ]] && is_desktop_mac=0 || is_desktop_mac=1
}

### Compute anomaly states
anomaly_states() {
  detect_mac_model
  detect_discrete_gpu_vendor
  resolution_needed=0
  [[ ${is_desktop_mac} == 1 ]] && resolution_needed="-1" && return
  if [[ "${dgpu_vendor}" == "10de" ]]
  then
    [[ -f "${nvdastartupweb_plistpath}" && ${nvidia_enabled} == 1 ]] && resolution_needed=1 && return
    [[ ${tbswitch_enabled} == 1 ]] && resolution_needed=2 && return
  elif [[ "${dgpu_vendor}" == "1002" ]]
  then
    [[ ${nvidia_enabled} == 1 ]] && resolution_needed=3 && return
  fi
}

### Print anomalies, if any
print_anomalies() {
  printfn "${bold}Analyzing system...${normal}"
  anomaly_states
  case "${resolution_needed}" in
    1) printfn "\n${bold}Problem${normal}     Loss of OpenCL/GL on all NVIDIA GPUs.\n${bold}Resolution${normal}  Use ${bold}purge-nvda.sh${normal} NVIDIA optimizations.";;
    2) printfn "\n${bold}Problem${normal}     Black screens on monitors connected to eGPU.\n${bold}Resolution${normal}  Use ${bold}purge-nvda.sh${normal} AMD optimizations.";;
    3) printfn "\n${bold}Problem${normal}     Black screens/slow performance with eGPU.\n${bold}Resolution${normal}  Use \`${bold}pmset -a gpuswitch 0${normal}\` to force iGPU.";;
    *) [[ ${is_desktop_mac} == 1 ]] && printfn "No resolutions to any anomalies if present. See README." || printfn "No anomalies expected.";;
  esac
}

### Anomaly detection
detect_anomalies() {
  printfn "${mark}${gap}${bold}System Diagnosis${normal}\n"
  print_anomalies
}

# --- USER INTERFACE

### Request donation
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest"
  printfn "See your ${bold}web browser${normal}."
}

### Generate system report
generate_sys_report() {
  [[ ${1} == -standalone ]] && printfn "${mark}${gap}${bold}System Log${normal}\n"
  printfn "${bold}Generating system log...${normal}"
  logfiles="pwlog-$(date +%Y-%m-%d-%H-%M-%S)"
  report_dirpath="/Users/${SUDO_USER}/Desktop/${logfiles}"
  mkdir -p "${report_dirpath}"
  rsync "${scriptconfig_filepath}" "${report_dirpath}/PatchState.plist"
  rsync -r "${backupkext_dirpath}" "${report_dirpath}/Backup Kexts"
  system_profiler SPSoftwareDataType 2>/dev/null | grep -Eiv 'Boot Volume|Name' > "${report_dirpath}/Mac.log"
  system_profiler SPHardwareDataType 2>/dev/null | grep -Eiv 'Serial|UUID' >> "${report_dirpath}/Mac.log"
  system_profiler SPThunderboltDataType 2>/dev/null > "${report_dirpath}/ThunderboltDevices.log"
  system_profiler SPDisplaysDataType 2>/dev/null > "${report_dirpath}/GPUs.log"
  system_profiler SPPCIDataType 2>/dev/null > "${report_dirpath}/PCI.log"
  system_profiler SPExtensionsDataType 2>/dev/null > "${report_dirpath}/Extensions.log"
  ioreg_info="$(ioreg -n display@0)"
  retrieve_egpu_data
  printfn "${egpu_dev_id} ${egpu_vendor}" > "${report_dirpath}/eGPU.log"
  get_gpu_name "${egpu_dev_id}" "${egpu_vendor}" >> "${report_dirpath}/eGPU.log"
  kextstat > "${report_dirpath}/Kextstat.log"
  current_dir="$(pwd)"
  cd "/Users/${SUDO_USER}/Desktop"
  zip -r -X "${logfiles}.zip" "${logfiles}" 2>/dev/null 1>&2
  cd "${current_dir}"
  rm -r "${report_dirpath}"
  chown "${SUDO_USER}" "${report_dirpath}.zip"
  printfn "Log generated on the Desktop.\n\nOpen an ${bold}issue${normal} on Github and share this file."
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
    set outcome to (display dialog theDialogText buttons {\"Never\", \"No\", \"Yes\"} default button \"Yes\" cancel button \"No\")
  else
    set outcome to (display dialog theDialogText buttons {\"Never\", \"No\", \"Yes\"} default button \"Yes\" cancel button \"No\" with icon promptIcon)
  end if
  if (outcome = {button returned:\"Yes\"}) then
	  tell application \"Terminal\"
		  activate
		  do script \"purge-wrangler -a\"
	  end tell
  else if (outcome = {button returned:\"Never\"}) then
    do shell script \"rm ~/Library/LaunchAgents/io.egpu.purge-wrangler-agent.plist\"
  end if" 2>/dev/null 1>&2
  sleep 10
}

### Show update prompt
show_update_prompt() {
  check_macos_version
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

### Generalized args processor
autoprocess_args() {
  local choice="${1}" && shift
  local caller="${2}" && shift
  local actions=("${@}")
  printf "\033[2K\r"
  if [[ ${choice} =~ ^[0-9]+$ && (( ${choice} > 0 && ${choice} -le ${#actions[@]} )) ]]
  then
    eval "${actions[(( ${choice} - 1 ))]}"
    return
  fi
  printfn "Invalid choice."
  return
}

### Generalized input request
autoprocess_input() {
  local message="${1}" && shift
  local caller="${1}" && shift
  local exit_action="${1}" && shift
  local prompt_back="${1}" && shift
  local actions=("${@}")
  local readonce=""
  (( ${#actions[@]} < 10 )) && readonce="-n1"
  read ${readonce} -p "${bold}${message}${normal} [1-${#actions[@]}]: " userinput
  autoprocess_args "${userinput}" "${caller}" "${actions[@]}"
  [[ "${prompt_back}" == true ]] && yesno_action "${bold}Back to menu?${normal}" "${caller}" "${exit_action}"
}

### Generalized menu generator
generate_menu() {
  local header="${1}" && shift
  local indent_level="${1}" && shift
  local gap_after="${1}" && shift
  local should_clear="${1}" && shift
  local items=("${@}")
  local indent=""
  for (( i = 0; i < ${indent_level}; i++ ))
  do
    indent="${indent} "
  done
  [[ ${should_clear} == 1 ]] && clear
  printfn "${indent}${mark}${gap}${bold}${header}${normal}\n"
  for (( i = 0; i < ${#items[@]}; i++ ))
  do
    num=$(( i + 1 ))
    printfn "${indent}${gap}${bold}${num}${normal}. ${items[${i}]}"
    (( ${num} == ${gap_after} )) && printfn
  done
  printfn
}

### Args processor
process_cli_args() {
  case "${1}" in
    -a) auto_setup_egpu && printfn;;
    -u) uninstall && printfn;;
    -s) check_patch_status && printfn;;
    *) first_time_setup && present_menu;;
  esac
}

### Present more options
present_more_options_menu() {
  local menu_items=("Add AMD Legacy Support" "Enable Ti82 Support" "Install NVIDIA Web Drivers" "System Diagnosis & Logging" "Reboot" "Back")
  local menu_actions=("install_amd_legacy_kext -end" "enable_ti82 -end" "install_ver_spec_webdrv" "detect_anomalies && printfn && generate_sys_report -standalone" "reboot_action -f" "present_menu")
  generate_menu "More Options" "0" "3" "1" "${menu_items[@]}"
  autoprocess_input "What next?" "perform_sys_check && present_more_options_menu" "present_menu" "true" "${menu_actions[@]}"
}

### Script menu
present_menu() {
  local menu_items=("Setup eGPU" "System Status" "Uninstall" "More Options" "Donate" "Quit")
  local menu_actions=("auto_setup_egpu" "check_patch_status" "uninstall" "present_more_options_menu" "donate" "exit")
  generate_menu "PurgeWrangler (${script_ver})" "0" "3" "1" "${menu_items[@]}"
  autoprocess_input "What next?" "perform_sys_check && present_menu" "exit" "true" "${menu_actions[@]}"
}

# --- SCRIPT DRIVER

### Primary execution routine
begin() {
  [[ "${2}" == "-l" ]] && show_update_prompt && return
  validate_caller "${1}" "${2}"
  perform_sys_check
  [[ ${single_user_mode} == 1 ]] && recover_sys && return
  fetch_latest_release
  process_cli_args "${option}"
}

begin "${0}" "${1}")