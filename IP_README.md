# ![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal](https://www.paypalobjects.com/digitalassets/c/website/marketing/apac/C2/logos-buttons/optimize/34_Yellow_PayPal_Pill_Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

**Document Revision**: 6.0.0+

**purge-wrangler.sh** enables unsupported external GPU configurations on macOS for almost all macs. Before proceeding, please read through this **entire document** to familiarize yourself with the script, the community, and the resources available you in case you find that you need help.

## Requirements
| Configuration | Specification | When | Description |
| :-----------: | :-----------: | :---: | :---------- |
| **macOS** | 10.13.4+ | Always | Use [automate-eGPU.sh](https://github.com/goalque/automate-eGPU) for older macOS versions. Also read **Apple's** [external GPU support document](https://support.apple.com/en-us/HT208544). |
| **System Integrity Protection** | Disabled | Always | When enabled, SIP prevents patching macOS. SIP can be disabled as described in this [article](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).  |
| **Secure Boot on T2** | No Security | Always | When active, this prevents booting of patched versions of macOS. Settings can be adjusted as shown in this [article](https://support.apple.com/en-us/HT208330).  |
| **External Boot on T2** | Enabled | Optional | An *optional* but recommended setting. You can change this as described [here](https://support.apple.com/en-us/HT208330).  |
| **Backup** | Recommended | Always | A system backup is always recommended before modifying core operating system components. |

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

#### For NVIDIA eGPUs
If you plan on using a **non-Kepler** NVIDIA eGPU, **check for compatibility first**:
```bash
curl -qLs https://bit.ly/2Z63Cn0 | bash
```
It is best to follow recommendations as advised in the script.

## Script Options
| Argument | Menu | Description |
| :------: | :--: | :---------- |
| Setup eGPU | `-a` | Automatically set up eGPU based on your system configuration and external GPU. |
| Uninstall | `-u` | Uninstalls **any** system modifications made by the script in-place. This is the *recommended* uninstallation mechanism. |
| Recovery | `-r` | Restores untouched macOS configuration prior to script modifications from a clean component backup. This is a more robust cleanup. |
| System Status | `-s` | Shows the current status of some of the components of the system and the any modifications made using the script. |

Running without arguments launches the menu.

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-wrangler -r
```
This will restore your system to a clean state.

## Hardware Chart
With NVIDIA GPUs, **hot-unplugging** capability is not supported.

| Integrated GPU | Discrete GPU | External GPU | Dependency | Complications |
| :------------: | :----------: | :----------: | :--------: | :------------ |
| **Intel** | None | AMD | macOS Drivers | Some models may require plugging in the eGPU after boot. |
| **Intel** | None | NVIDIA | NVIDIA Web Drivers | Drivers need to be available for the running macOS version. |
| None | **NVIDIA** | AMD | macOS Drivers | Only internal monitor can be used. Apps can be accelerated using [set-eGPU.sh](https://github.com/mayankk2308/set-egpu). |
| None | **NVIDIA** | NVIDIA | NVIDIA Web Drivers | OpenCL/GL compute capabilities may be lost due to NVIDIA Web Drivers. |
| None | **AMD** | AMD | macOS Drivers | Native or like-native support without any significant complications. |
| None | **AMD** | NVIDIA | NVIDIA Web Drivers | Conflicting framebuffers may require hot-plugging eGPU and then logging out and in. |
| **Intel** | **NVIDIA** | AMD | macOS Drivers | Use [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) if you need external monitors over eGPU. |
| **Intel** | **NVIDIA** | NVIDIA | NVIDIA Web Drivers | Use [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda) to resolve OpenCL/GL compute loss, and use this [boot procedure](https://egpu.io/forums/builds/mid-2014-macbook-pro-gt750m-gtx107016gbps-tb2-aorus-gaming-box-macos-10-13-6-mac_editor/). |
| **Intel** | **AMD** | AMD | macOS Drivers | Native or native-like support without any significant complications. |
| **Intel** | **AMD** | NVIDIA | NVIDIA Web Drivers | Slow/black screens  which may require switching **mux** to the iGPU or logging out and in after hot-plugging. |

**NVIDIA Web Drivers** are **not required** for **Kepler-based** GPUs as macOS already includes the drivers.

## Troubleshooting
- [eGPU.io Build Guides](https://egpu.io/build-guides/): See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds.
- [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/): Some basics on external GPUs in macOS.
- [eGPU.io Community](https://egpu.io/forums/): Ask about, request help, learn more, and share your eGPU experience with the community.
- [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/): A wonderful place to request additional help for your new setup, and to find fellow eGPU users.

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
Consider **starring** the repository or donating via:

[![paypal](https://www.paypalobjects.com/digitalassets/c/website/marketing/apac/C2/logos-buttons/optimize/34_Yellow_PayPal_Pill_Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **purge-wrangler.sh**.
