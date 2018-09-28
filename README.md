![Header](https://raw.githubusercontent.com/mayankk2308/purge-wrangler/master/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal][image-1]][1]
# PurgeWrangler
A lot has happened with **macOS 10.13.4** and eGPU support, but noticeably - the lack of:
* **NVIDIA eGPU** support
* **Thunderbolt 1/2** support

**PurgeWrangler** aims to remedy this by patching *kernel extensions* on disk to bypass thunderbolt checks and enable NVIDIA eGPUs.


## Requirements
This script requires the following specifications:
* Mac with **Thunderbolt**
* **macOS 10.13.4** or later

A system backup is highly recommended. Although the patches and recovery techniques have been refined over time, having a fallback is always important.

## Usage
To get yourself acquainted with eGPU support on macOS and some technical foreword, consider reading the [macOS Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/) at [egpu.io](https://egpu.io). To use **PurgeWrangler**, please follow these steps:

### Step 1
Disable **system integrity protection** for macOS using **Terminal** in **Recovery**:
```bash
$ csrutil disable
$ reboot
```

### Step 2
Boot back into macOS, then copy-paste the following into **Terminal**:
```bash
curl -s "https://api.github.com/repos/mayankk2308/purge-wrangler/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-wrangler.sh && chmod +x purge-wrangler.sh && ./purge-wrangler.sh && rm purge-wrangler.sh
```

This will automatically install the latest version of **purge-wrangler.sh**.

Alternatively, download [purge-wrangler.sh](https://github.com/mayankk2308/purge-wrangler/releases). Then run the following in **Terminal**:
```bash
$ cd Downloads
$ chmod +x purge-wrangler.sh
$ ./purge-wrangler.sh
```

You will be prompted to enter your account password for **superuser permissions**. On first-time use, the script will auto-install itself as a binary into `/usr/local/bin/`. This enables much simpler future use. To use the script again, just type the following in **Terminal**:
```bash
$ purge-wrangler
```

This is supported on **3.0.0** or later. Automatic updates are supported from **3.1.0** or later.

## Options
PurgeWrangler makes it super-easy to perform actions with an interactive menu, and is recommended for most users. Providing no arguments to the script defaults to the menu.

![PurgeWrangler Menu](https://raw.githubusercontent.com/mayankk2308/purge-wrangler/master/resources/purge-wrangler-menu.png)

For advanced users that may sometimes prefer bypassing the menu, the script provides convenient arguments in an attempt to be as user-friendly as possible.

#### 1. Enable AMD eGPUs (`-ea|--enable-amd`)
For **Thunderbolt 3** macs, allows the use of unofficial (non-Apple supported) AMD eGPUs such as the **Fiji** architecture GPUs. For older **Thunderbolt** models, bypasses the thunderbolt requirement and optionally allows use of unofficial AMD eGPUs. To use unofficial eGPUs, agree to enabling unofficial cards when prompted in the script.

#### 2. Enable NVIDIA eGPUs (`-en|--enable-nv`)
All **Thunderbolt** macs require extensive patching for NVIDIA eGPUs. This option downloads the necessary NVIDIA drivers, patches any macOS version requirements if needed, and finally applies the necessary system patches needed to allow eGPU acceleration.

#### 3. Patch Status Check (`-s|--status`)
Check to see what patches are installed on the system.

#### 4. Uninstall Patches (`-u|--uninstall`)
Uninstall any patches without restoring backed-up files, in-place.

#### 5. System Recovery (`-r|--recover`)
Recover original untouched macOS configuration prior to script modifications.

#### 6. Sanitize System (`-ss|--sanitize-system`)
Resolve permission issues with target kernel extensions and rebuild kernel cache.

#### 7. Reboot System (`-rb|--reboot`)
Reboot the system.

## Troubleshooting
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
$ mount -uw /
$ cd /path/to/script/
$ purge-wrangler
```

## References
Many thanks to **@itsage**, **@fricorico**, **@goalque**, **@fr34k**, and many others at [egpu.io](https://egpu.io) for the insightful discussion that has culminated into this project.

## Disclaimer
This script moves core system files associated with macOS. While any of the potential issues with its application are recoverable, please use this script at your discretion. I will not be liable for any damages to your system.

## License
See the license file for more information.

## Donate
A *thank you* suffices, but for those kind souls who would love to contribute:

[![paypal][image-1]][1]

[image-1]:	https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif
[1]:	https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=mac_editor&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest
