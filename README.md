# ![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal](https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_100x26.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

**purge-wrangler.sh** enables unsupported external GPU configurations on macOS for almost all macs. Before proceeding, please read through this **entire document** to familiarize yourself with the script, the community, and the resources available you in case you find that you need help.

## Contents
A quick run-through of what's included in this document:
- [Pre-Requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites)
- [Installation](https://github.com/mayankk2308/purge-wrangler#installation)
- [Script Options](https://github.com/mayankk2308/purge-wrangler#script-options)
- [Recovery](https://github.com/mayankk2308/purge-wrangler#recovery)
- [Post-Install](https://github.com/mayankk2308/purge-wrangler#post-install)
- [Hardware Chart](https://github.com/mayankk2308/purge-wrangler#hardware-chart)
- [More Tools](https://github.com/mayankk2308/purge-wrangler#more-tools)
- [Troubleshooting](https://github.com/mayankk2308/purge-wrangler#troubleshooting)
- [References](https://github.com/mayankk2308/purge-wrangler#references)
- [Disclaimer](https://github.com/mayankk2308/purge-wrangler#disclaimer)
- [License](https://github.com/mayankk2308/purge-wrangler#license)
- [Support](https://github.com/mayankk2308/purge-wrangler#support)

## Pre-Requisites
| Configuration | Requirement | Description |
| :-----------: | :---------: | :---------- |
| **macOS** | 10.13.4+ | Use [automate-eGPU.sh]() for older macOS versions. Also read **Apple's** [external GPU support document](https://support.apple.com/en-us/HT208544). |
| **System Integrity Protection** | Disabled | When enabled, SIP prevents patching macOS. SIP can be disabled as described in this [article](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).  |
| **Secure Boot on T2** | No Security | When active, this prevents booting of patched versions of macOS. Settings can be adjusted as shown in this [article](https://support.apple.com/en-us/HT208330).  |
| **External Boot on T2** | Enabled | An *optional* but recommended setting. You can change this as described [here](https://support.apple.com/en-us/HT208330).  |
| **Backup** | Recommended | A system backup is always recommended before modifying core operating system components. |

## Installation
Install using **Terminal**:
```bash
curl -q -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"browser_download_url":[ \t]*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-wrangler.sh && chmod +x purge-wrangler.sh && ./purge-wrangler.sh && rm purge-wrangler.sh
```

Future use:
```bash
purge-wrangler
```

Re-use the full installation command if the shortcut fails to function. **purge-wrangler.sh** requires [administrator privileges](https://support.apple.com/en-us/HT202035) to function.

### About NVIDIA Setups
If you plan on using a 900 series or newer NVIDIA GPU, **check for compatibility first**:
```bash
curl -q -s https://raw.githubusercontent.com/mayankk2308/purge-wrangler/master/resources/webdrv-release.sh | bash
```
It is best to follow recommendations as advised in the script.

## Script Options
| Argument | Menu | Description |
| :------: | :--: | :---------- |
| `-ea` or `--enable-amd` | AMD eGPUs | Patches macOS on **Thunderbolt 1/2** macs to allow native external GPU support as if on a **Thunderbolt 3** mac. Also asks if you want enable **legacy AMD GPU** support and **Ti82** enclosures. |
| `-en` or `--enable-nv` | NVIDIA eGPUs | **Downloads** the necessary drivers, patch them if needed, and patch macOS to enable support for **NVIDIA GPUs** (credits: @goalque). |
| `-u` or `--uninstall` | Uninstall | Uninstalls **any** system modifications made by the script in-place. This is the *recommended* uninstallation mechanism. |
| `-r` or `--recover` | Recovery | Restores untouched macOS configuration prior to script modifications from a clean component backup. This is a more robust cleanup. |
| `-s` or `--status` | Status | Shows the current status of some of the components of the system and the any modifications made using the script. |
| `-t8` or `--ti82` | Ti82 Enclosures | Patches macOS to enable non-supported thunderbolt devices such as **Ti82** enclosures (credits: @khaosT), though it may be sensitive to macOS updates.  |
| `-nw` or `--nvidia-web` | NVIDIA Web Drivers | Allows installation of **NVIDIA Web Drivers** without any system modifications, useful for managing the drivers easily. |
| `-a` or `--anomaly-detect` | Anomaly Detection | Scans the current system to detect any anomalies that may hinder external GPU support and cause issues such as black screens and slow interface. |
| `-p` or `--prefs` | Script Preferences | Allows management of preferences for queries that the script asks for when patching. This allows users to set defaults, such as always installing web drivers. |
| `-d` or `--donate` | Donate | Launches the default web browser with the set donation link - essentially the same as the **PayPal** button on this page. |

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-wrangler -r
```
This will restore your system to a clean state.

## Post-Install
It is recommended to leave **SIP** disabled as long as patches are in effect. All conditions specified in [pre-requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites) must persist.

### Software Updates
Updates to the operating system re-write system kernel extensions, undoing all patches applied previously via the script. In such a case, a dialog box will notify you that the patches have been undone, and will suggest re-applying them. The sample applies to NVIDIA Web Drivers.

## Hardware Chart
With NVIDIA GPUs, **hot-unplugging** capability is not supported.

| Built-In GPU(s) | External GPU | Dependency | Complications |
| :-------------: | :----------: | :--------: | :------------ |
| **Intel** | AMD | macOS Drivers | Some models may require plugging in the eGPU after boot. |
| **Intel** | NVIDIA | NVIDIA Web Drivers | Drivers need to be available for the running macOS version. |
| **NVIDIA** | AMD | macOS Drivers | Only internal monitor can be used for eGPU-accelerated applications. |
| **NVIDIA** | NVIDIA | NVIDIA Web Drivers | OpenCL/GL compute capabilities may be lost due to NVIDIA Web Drivers. |
| **AMD** | AMD | macOS Drivers | Native or like-native support without any significant complications. |
| **AMD** | NVIDIA | NVIDIA Web Drivers | Conflicting framebuffers may require hot-plugging eGPU and then logging out and in. |
| **Intel**, **NVIDIA** | AMD | macOS Drivers | Use [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) if you need external monitors over eGPU. |
| **Intel**, **NVIDIA** | NVIDIA | NVIDIA Web Drivers | Use [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) to resolve loss of OpenCL/GL compute. |
| **Intel**, **AMD** | AMD | macOS Drivers | Native or native-like support without any significant complications. |
| **Intel**, **AMD** | NVIDIA | NVIDIA Web Drivers | Slow/black screens  which may require switching **mux** to the iGPU or logging out and in after hot-plugging. |

**NVIDIA Web Drivers** are **not required** for *most* **Kepler-based** GPUs as macOS already includes the drivers, which are recommended instead as they are up-to-date and are likely to work much better within macOS versus NVIDIA's provided drivers.

## More Tools
| Problem | Tool | Mac GPU(s) | Description |
| :------: | :--: | :--------: | :---------- |
| Loss of **OpenCL/GL** | [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) | **Intel**, **NVIDIA** | Optimizes NVIDIA eGPUs for macs with discrete NVIDIA GPUs.
| Black Screens on AMD eGPUs | [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) | **Intel**, **NVIDIA** | Optimizes AMD eGPUs for macs with discrete NVIDIA GPUs.
| Black Screens/Lag/Distortions on NVIDIA eGPUs | Workaround | **Intel**, **AMD** | Switch mux to iGPU. Hot-plugging eGPU at different times may help, or [consider this](https://egpu.io/forums/gpu-monitor-peripherals/tensorflow-gpu-1-8-with-macos-10-13-6-black-screen-problem/#post-48321). |
| eGPU on Internal Display | [set-eGPU.sh](https://github.com/mayankk2308/set-egpu) | Any | Set GPU preferences for macOS applications. |
| No Boot with eGPU | Workaround | Certain Macs | Some macs cannot boot with certain eGPUs plugged in. Use this [boot procedure](https://egpu.io/forums/builds/mid-2014-macbook-pro-gt750m-gtx107016gbps-tb2-aorus-gaming-box-macos-10-13-6-mac_editor/). |

## Troubleshooting
| Resource | Description |
| :------: | :---------- |
| [eGPU.io Build Guides](https://egpu.io/build-guides/) | See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds. |
| [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/) | Some basics on external GPUs in macOS. |
| [eGPU.io Community](https://egpu.io/forums/) | Ask about, request help, learn more, and share your eGPU experience with the community. |
| [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/) | The reddit community is a wonderful place to request additional help for your new setup, and to find fellow eGPU users. |

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
The bundled license prevents any commercial use, redistribution, and compilation/assembly to obscure code for any purposes. This software comes without any warranty or guaranteed support. By using the script, you **agree** to adhere to this license. See the [LICENSE](./LICENSE.md).

## Support
Consider **starring** the repository or donating via **PayPal**:

[![paypal](https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_100x26.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **purge-wrangler.sh**.
