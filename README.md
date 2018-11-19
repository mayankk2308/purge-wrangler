![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal](https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_150x38.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)
# PurgeWrangler
**purge-wrangler.sh** enables unsupported external GPU configurations on macOS for almost all macs. Before proceeding, please read through this **entire document**.

## Index
A quick run-through of what's included in this document:
- [Pre-Requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites)
  - macOS requirements, pre-system configuration specifics, and more.
- [Installation](https://github.com/mayankk2308/purge-wrangler#installation)
  - Installing and running the script.
- [Script Options](https://github.com/mayankk2308/purge-wrangler#script-options)
  - Available capabilities and options in the script.
- [Recovery](https://github.com/mayankk2308/purge-wrangler#recovery)
  - Easy way to recover from an unbootable system using the script.
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

## Installation
**purge-wrangler.sh** auto-manages itself and provides multiple installation and recovery options. Once the **pre-requisites** are satisfied, install the script by running the following in **Terminal**:
```bash
curl -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-wrangler.sh && chmod +x purge-wrangler.sh && ./purge-wrangler.sh && rm purge-wrangler.sh
```

For future use, only the following will be required:
```bash
purge-wrangler
```

In case the command above does not work, you can re-use the long installation command and fix the issue.

## Script Options
PurgeWrangler makes it super-easy to perform actions with an interactive menu, and is recommended for most users. Providing no arguments to the script defaults to the menu. **Some options are coming soon in v5.1.0**.

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
| `-cl` or `--command-line-opts` | Command Line Options | Displays a list of command line options allowing advanced users to bypass the menu, useful for integration with other components and additional scripting if needed. |
| `-rb` or `--reboot` | System Reboot | Prompts the user to reboot the system, and instantly does so if after user consent, useful for easy command-line reboots. |
| `-p` or `--prefs` | Script Preferences | Allows management of preferences for queries that the script asks for when patching. This allows users to set defaults, such as always installing web drivers. |

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-wrangler -r
```
This will restore your system to a clean state as documented above.

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
See the license file for more information.

## Support
If you loved **purge-wrangler.sh**, consider **starring** the repository or if you would like to, donate via **PayPal**:

[![paypal](https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_150x38.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **purge-wrangler.sh**. This project is under *active* development at this time.
