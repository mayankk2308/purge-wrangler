# ![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

**purge-wrangler.sh** enables unsupported external GPU configurations on macOS for almost all macs. Before proceeding, please read through this **entire document** to familiarize yourself with the script, the community, and the resources available you in case you find that you need help.

## Contents
A quick run-through of what's included in this document:
- [Pre-Requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites)
  - macOS requirements, pre-system configuration specifics, and more.
- [Installation](https://github.com/mayankk2308/purge-wrangler#installation)
  - Installing and running the script.
- [Script Options](https://github.com/mayankk2308/purge-wrangler#script-options)
  - Available capabilities and options in the script.
- [Recovery](https://github.com/mayankk2308/purge-wrangler#recovery)
  - Easy way to recover from an unbootable system using the script.
- [Post-Install](https://github.com/mayankk2308/purge-wrangler#post-install)
  - System configuration after script installation and some other things of note.
- [Hardware Chart](https://github.com/mayankk2308/purge-wrangler#hardware-chart)
  - See a brief overview of possible mac & eGPU combinations and any complications involved.
- [More Tools](https://github.com/mayankk2308/purge-wrangler#more-tools)
  - Additional tools that you may need for some specific edge-case systems.
- [Troubleshooting](https://github.com/mayankk2308/purge-wrangler#troubleshooting)
  - Additional resources and guides for eGPUs.
- [References](https://github.com/mayankk2308/purge-wrangler#references)
  - Special thanks to everyone involved.
- [Disclaimer](https://github.com/mayankk2308/purge-wrangler#disclaimer)
  - Please read the disclaimer before using this script.
- [License](https://github.com/mayankk2308/purge-wrangler#license)
  - By using this script, you consent to the license that the script comes bundled with.
- [Support](https://github.com/mayankk2308/purge-wrangler#support)
  - Support the developer if you'd like to.

## Pre-Requisites
Please read [Apple](https://support.apple.com/en-us/HT208544)'s external GPU documentation first to see what is already supported on macOS. The following is a table that summarizes **system requirements** for using this script:

| Configuration | Requirement | Description |
| :-----------: | :---------: | :---------- |
| **macOS** | 10.13.4+ | Older versions of macOS require different patching mechanisms that this script does not include. Please check [eGPU.io](https://egpu.io) for more information. |
| **System Integrity Protection** | Disabled | By default, this prevents system modifications that the script would like to make, and hence must be disabled. SIP can be disabled as described in this [article](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).  |
| **Secure Boot** | No Security | For macs with the **T2** coprocessor, this needs to be done to allow patched versions of macs to boot. You can change this setting as described in this [article](https://support.apple.com/en-us/HT208330).  |
| **External Boot** | Enabled | For macs with the **T2** coprocessor, an *optional* but recommended setting. You can change this as described [here](https://support.apple.com/en-us/HT208330).  |
| **Backup** | Recommended | While the script has been comprehensively tested and is mature, hacks are just that, hacks. A system backup is always recommended. |

## Installation
**purge-wrangler.sh** auto-manages itself and provides multiple installation and recovery options. Once the **pre-requisites** are satisfied, install the script by running the following in **Terminal**:
```bash
curl -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"browser_download_url":[ \t]*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-wrangler.sh && chmod +x purge-wrangler.sh && ./purge-wrangler.sh && rm purge-wrangler.sh
```

For future use, only the following will be required:
```bash
purge-wrangler
```

In case the command above does not work, you can re-use the long installation command and fix the issue.

**purge-wrangler.sh** requires **administrator privileges** and will request your password if run in a non-privileged shell. The script uses [sudo](https://support.apple.com/en-us/HT202035) to do so.

### Note About NVIDIA Setups
Modern NVIDIA GPUs (Maxwell or better) depend on NVIDIA Web Drivers which NVIDIA provides per macOS release. **Please ensure that there is a driver available for your current system**. You can check that using the following command:
```bash
curl -s https://raw.githubusercontent.com/mayankk2308/purge-wrangler/master/resources/webdrv-release.sh | bash
```
For minor macOS version variations (**10.13.4 -> 10.13.5** for example), you may use **purge-wrangler.sh** to install the drivers patched for your OS automatically, with high chance of success. **10.13 -> 10.14** and other major OS changes usually break web drivers, and patching will not be helpful. The script will provide recommendations (**v4.2.5+**) as needed.

## Script Options
PurgeWrangler makes it super-easy to perform actions with an interactive menu, and is recommended for most users. Providing no arguments to the script defaults to the menu.

| Argument | Menu | Description |
| :------: | :--: | :---------- |
| `-ea` or `--enable-amd` | AMD eGPUs | Patches macOS on **Thunderbolt 1/2** macs to allow native external GPU support as if on a **Thunderbolt 3** mac. Also asks if you want enable **legacy AMD GPU** support and **Ti82** enclosures. |
| `-en` or `--enable-nv` | NVIDIA eGPUs | **Downloads** the necessary drivers, patch them if needed, and patch macOS to enable support for **NVIDIA GPUs** (credits: @goalque). |
| `-u` or `--uninstall` | Uninstall | Uninstalls **any** system modifications made by the script in-place. This is the *recommended* uninstallation mechanism. |
| `-t8` or `--ti82` | Ti82 Enclosures | Patches macOS to enable non-supported thunderbolt devices such as **Ti82** enclosures (credits: @khaosT), though it may be sensitive to macOS updates.  |
| `-nw` or `--nvidia-web` | NVIDIA Web Drivers | Allows installation of **NVIDIA Web Drivers** without any system modifications, useful for managing the drivers easily. |
| `-a` or `--anomaly-detect` | Anomaly Detection | Scans the current system to detect any anomalies that may hinder external GPU support and cause issues such as black screens and slow interface. |
| `-s` or `--status` | Status | Shows the current status of some of the components of the system and the any modifications made using the script. |
| `-ss` or `--sanitize-system` | Sanitize | Fixes permissions and rebuilds kernel caches, useful for advanced users testing various modifcations to system kexts. |
| `-r` or `--recover` | Recovery | Restores untouched macOS configuration prior to script modifications from a clean component backup. This is a more robust cleanup. |
| `-rb` or `--reboot` | System Reboot | Prompts the user to reboot the system, and instantly does so if after user consent, useful for easy command-line reboots. |
| `-p` or `--prefs` | Script Preferences | Allows management of preferences for queries that the script asks for when patching. This allows users to set defaults, such as always installing web drivers. |

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-wrangler -r
```
This will restore your system to a clean state as documented above.

## Post-Install
After installing the script, all settings as described in [pre-requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites) must persist. For instance, **system integrity protection** must remain disabled as long as the system is in the *patched* state.

### Software Updates
At this time, we consider both **AMD** (for TB1/2 devices) and **NVIDIA** patches as foolproof. For NVIDIA users, please note that support depends on NVIDIA Web Drivers as well, so before updating, please ensure that there is a driver available for the new operating system.

Updates to the operating system re-write system kernel extensions, undoing all patches applied previously via the script. In such a case, a dialog box will notify you that the patches have been undone, and will suggest re-applying them.

## Hardware Chart
The hardware chart aims to provide a very simple overview of possible external GPU configurations with macs using the script, and highlight potential edge cases. Note that thunderbolt versions are mostly inconsequential to setup on macOS. The following is table that lists the possible configurations and any potential issues:

| Built-In GPU(s) | External GPU | Dependency | Complications |
| :-------------: | :----------: | :--------: | :------------ |
| **Intel** | AMD | macOS Drivers | Most intel-only macs are easy to set up. Some models may require plugging in the eGPU after boot. One of the more optimal configurations. |
| **Intel** | NVIDIA | NVIDIA Web Drivers | Setup depends on the availability of NVIDIA Web Drivers for most modern NVIDIA GPUs and for your macOS version. Hot-unplugging not supported. |
| **NVIDIA** | AMD | macOS Drivers | It may not be possible to run monitors connected to the eGPU, but the internal monitor can be used for eGPU-accelerated applications. |
| **NVIDIA** | NVIDIA | NVIDIA Web Drivers | OpenCL/GL compute capabilities may be lost if NVIDIA Web Drivers are involved. Older GPUs that can use macOS drivers will work fine. |
| **AMD** | AMD | macOS Drivers | Almost all setups should work nearly flawlessly with native hot-plug, unplug, and sudden un-plug support. One of the more optimal configurations. |
| **AMD** | NVIDIA | NVIDIA Web Drivers | Due to conflicting framebuffers, external monitors connected to the eGPU may not render. The setup may or may not work depending on specific system models. NVIDIA Web Driver dependency involved as well for newer GPUs. |
| **Intel**, **NVIDIA** | AMD | macOS Drivers | By default, monitors connected to the eGPU will not render, but this can be resolved via additional workarounds. See [more tools](https://github.com/mayankk2308/purge-wrangler#more-tools). |
| **Intel**, **NVIDIA** | NVIDIA | NVIDIA Web Drivers | OpenCL/GL compute capabilities may be lost if NVIDIA Web Drivers are involved. This can be resolved using additional workarounds. See [more tools](https://github.com/mayankk2308/purge-wrangler#more-tools). |
| **Intel**, **AMD** | AMD | macOS Drivers | Setup should work nearly flawlessly with native hot-plug, unplug, and sudden un-plug support. One of the more optimal configurations. |
| **Intel**, **AMD** | NVIDIA | NVIDIA Web Drivers | Mostly working setups, though some macs may encounter black screens on monitors connected to the eGPU. See [more tools](https://github.com/mayankk2308/purge-wrangler#more-tools) for additional workarounds. |

**NVIDIA Web Drivers** are **not required** for *most* **Kepler-based** GPUs as macOS already includes the drivers, which are recommended instead as they are up-to-date and are likely to work much better within macOS versus NVIDIA's provided drivers.

## More Tools
The **anomaly detection** feature in the script will mention anything extra that needs to be done for proper eGPU functionality for the system. Thunderbolt versions (mac or enclosure) are irrelevant with respect to macOS compatibility. A table of additional tools that you may require is as follows:

| Problem | Tool | Applies To | Description |
| :------: | :--: | :--------: | :---------- |
| Loss of **OpenCL/GL** | [PurgeNVDA](https://github.com/mayankk2308/purge-nvda) | **Intel**, **NVIDIA** | Resolves the issue on macs with Intel and NVIDIA GPUs (*a la* **MacBook Pro 15" 2012-14**) by disabling the discrete GPU only. Cannot apply to iMacs that do not have functional/disabled integrated GPUs.
| Black Screens on AMD eGPUs | [PurgeNVDA](https://github.com/mayankk2308/purge-nvda) | **Intel**, **NVIDIA** | Resolves the issue on macs with Intel and NVIDIA GPUs (*a la* **MacBook Pro 15" 2012-14**) by disabling NVIDIA framebuffers. Cannot apply to iMacs that do not have functional/disabled integrated GPUs.
| Black Screens on NVIDIA eGPUs | Workaround | **Intel**, **AMD** | The graphics mux needs to be switched to the integrated GPU before the system initializes the NVIDIA eGPU. Hot-plugging eGPU at different times (at login screen, after login, and so on) may help, or [consider this](https://egpu.io/forums/gpu-monitor-peripherals/tensorflow-gpu-1-8-with-macos-10-13-6-black-screen-problem/#post-48321). |
| eGPU on Internal Display | [Set-eGPU](https://github.com/mayankk2308/set-egpu) | Any | If on **High Sierra**, use the script to enable apps to use the eGPU without requiring monitors. macOS **Mojave** or later has this built-in. |
| No Boot with eGPU | Workaround | Certain Macs | Some macs cannot boot with certain eGPUs plugged in. A timed-plug is required, as described in this [build guide](https://egpu.io/forums/builds/mid-2014-macbook-pro-gt750m-gtx107016gbps-tb2-aorus-gaming-box-macos-10-13-6-mac_editor/) (see the boot process). |

Unfortunately, as evident, iMacs facing similar complications are harder to resolve because of the absence of a functional Intel GPU. Otherwise the same fixes for the dual GPU notebooks would be applicable.

## Troubleshooting
Troubleshooting plays an important role in any kind of hack/patch. New OSes and hardware tend to bring with them new problems and challenges. The hardware chart aims to cover all variances of problems with eGPUs so far, but there can be some specific missed edge cases. The following is a list of additional resources rich in information:

| Resource | Description |
| :------: | :---------- |
| [eGPU.io Build Guides](https://egpu.io/build-guides/) | See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds. |
| [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/) | Learn about some basics of eGPUs in macOS and find out what means what. This guide does not cover any Windows/Bootcamp-related efforts. |
| [eGPU.io Community](https://egpu.io/forums/) | The eGPU.io forums are a great place to post concerns and doubts about your setup. Be sure to search the forum before posting as there might be high chance your doubt has already been answered. |
| [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/) | The reddit community is a wonderful place to request additional help for your new setup, and a good place to find fellow eGPU users. |

My username on both communities is [@mac_editor](https://egpu.io/forums/profile/mac_editor). Feel free to mention my username on eGPU.io posts - I get an email notifying me of the same. In any case, with thousands of members, the community is a welcoming place. Don't be shy!

## References
Many thanks to:
- [@itsage](https://egpu.io/forums/profile/itsage/): For testing the recent releases of the script.
- [@fricorico](https://egpu.io/forums/profile/fricorico/): For help in investigating patches for Thunderbolt 1/2 macs.
- [@goalque](https://egpu.io/forums/profile/goalque/): For finding patches for NVIDIA eGPUs.
- [@fr34k](https://egpu.io/forums/profile/fr34k/): For investigating macOS components for NVIDIA patches.

And the [eGPU.io](https://egpu.io) community for their support and insightful discussion.

## Disclaimer
This script moves core system files associated with macOS. While any of the potential issues with its application are recoverable, please use this script at your discretion. I will not be liable for any damages to your system.

## License
The bundled license prevents any commercial use, redistribution, and compilation/assembly to obscure code for any purposes. This software comes without any warranty or guaranteed support. By using the script, you **agree** to adhere to this license. For more information, please see the [LICENSE](./LICENSE.md).

## Support
If you loved **purge-wrangler.sh**, consider **starring** the repository or if you would like to, donate via **PayPal**:

[![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **purge-wrangler.sh**. This project is under *active* development at this time.
