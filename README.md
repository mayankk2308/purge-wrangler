# ![Header](/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-wrangler.svg?style=for-the-badge)
![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-wrangler/total.svg?style=for-the-badge) [![paypal](https://www.paypalobjects.com/digitalassets/c/website/marketing/apac/C2/logos-buttons/optimize/34_Yellow_PayPal_Pill_Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@icloud.com&lc=US&item_name=Development%20of%20PurgeWrangler&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

**Document Revision**: 6.0.0+

### DO NOT CLONE OR DOWNLOAD. READ THIS DOCUMENT ENTIRELY BEFORE PROCEEDING. 

**purge-wrangler.sh** enables unsupported external GPU configurations on macOS for almost all macs. Before proceeding, please read through this **entire document** to familiarize yourself with the script, the community, and the resources available you in case you find that you need help.

## Requirements
| Configuration | Specification | Notes |
| :-----------: | :-----------: | :---- |
| **macOS Version** | 10.13.4 or later | Read **Apple's** [external GPU support document](https://support.apple.com/en-us/HT208544). |
| **System Integrity Protection** | Disabled | When enabled, SIP prevents patching macOS. SIP can be disabled as described in this [article](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).  |
| **Secure Boot on T2** | No Security | For macs with T2 chip. Settings can be adjusted as shown in this [article](https://support.apple.com/en-us/HT208330).  |

A system backup is **always recommended** before using patches on macOS. I suggest using [Time Machine](https://support.apple.com/en-us/HT201250). Unsupported installation of newer operating systems on legacy Macs via **dosdude** patches is not supported at this time. An internet connection is required for downloading some patches.

## Installation
Few things of **note** before you install:
- If you are using **macOS 10.15.1 or later**, ensure you are running script **v6.1.0** or later. If this is your first time installing, the following instructions will ensure you get the latest version automatically. For previous users, the script will prompt for an update automatically.
- If you are using an NVIDIA 9xx or newer GPU, only **macOS High Sierra** is supported. Newer macOS versions do not have available web drivers to accelerate these GPUs. The script will not proceed to patch if appropriate web drivers are not available for your system.
- If you have a **Ti82** enclosure such **Razer Core V1** and **Akitio Thunder3**, the script will not be able to determine the GPU installed inside it automatically. In this scenario, the script will ask you what GPU you are using (AMD or NVIDIA).
- If you are using an AMD GPU not listed in [Apple's eGPU support document](https://support.apple.com/en-us/HT208544), such as the **R9 Nano**, legacy support will have to be enabled. In most cases, this will be done automatically. However, as above, if you have a Ti82 enclosure, the script will ask you if you would like to install this.

Just copy-paste the following command into **Terminal** to download and install:
```bash
curl -qLs $(curl -qLs https://bit.ly/2WtIESm | grep '"browser_download_url":' | cut -d'"' -f4) > purge-wrangler.sh; bash purge-wrangler.sh; rm purge-wrangler.sh
```

Future use:
```bash
purge-wrangler
```

Re-use the full installation command if the shortcut fails to function. **purge-wrangler.sh** requires [administrator privileges](https://support.apple.com/en-us/HT202035) to function.

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-wrangler
```
This will restore your system to a clean state.

## Hardware Chart
With NVIDIA GPUs, **hot-unplugging** capability is not supported. Additionally, **NVIDIA Web Drivers** are **not required** for **Kepler-based** GPUs as macOS already includes the drivers.

<details>
<summary>See Table</summary>

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

</details>

## Troubleshooting
This section includes a nifty FAQ and additional resources that you can use to get help.

### FAQ
These are some of the most frequently asked questions regarding this script and eGPU support in general. Of course, the list is not exhaustive, so always search for more information via other resources for questions not listed here.

<details>
<summary>See Questions</summary>

#### Why is eGPU not working on Thunderbolt 1/2 system on Catalina?
See installation notes. If you are running **macOS 10.15.1 or later**, use script version **v6.1.0** or newer.

#### Why did the script fail to detect my enclosure?
Assuming hardware is appropriately configured and not defective, the only case when the script fails to detect eGPU configurations is when the enclosure has a Ti82 controller, which macOS does not support by default. Hence detection fails. Simply answer the questions the script asks to proceed with your setup.

#### Can I enable System Integrity Protection after running the patch?
No. Patched systems may become unbootable if you do so. Keep SIP disabled at all times your system is patched state.

#### Do I require NVIDIA Web Drivers?
If asked this question while setting up your eGPU, the answer depends on the NVIDIA GPU you are using. See the installation notes for more insight. Essentially, you don't need these if you are using Kepler GPUs.

#### Why do patched NVIDIA drivers not work on macOS Mojave or later?
In macOS Mojave, Apple removed the necessary APIs that NVIDIA-provided graphics drivers used for accelerating their graphics processors. The script uses a simple check to see if it is possible to run NVIDIA drivers for an older macOS version, and patches it for the new version if so. If not, then patching terminates.

#### Are NVIDIA RTX GPUs supported on macOS?
No. They require NVIDIA drivers, which macOS does not have. Plus, third-party GPU drivers are not supported as of macOS Mojave - see questions above.

#### Should I enable AMD Legacy Support if asked?
As explained in the installation section, you only need this for AMD GPUs **not** mentioned in Apple's [eGPU Support document](https://support.apple.com/en-us/HT208544), such as the **R9 Nano** or **R9 Fury**. Enabling this for any other GPUs yields no benefit, but is also not harmful.

#### What happens if I update a patched macOS system?
After a macOS version update or security updates, purge-wrangler patches are removed. In this scenario, you may see a prompt after rebooting that will suggest reinstalling the patches. Choosing to do so will launch Terminal and run the setup procedure immediately.

#### What happens if I connect two eGPUs?
One of the eGPUs would be detected. If you are trying to set up an NVIDIA and AMD eGPU simultaneously, connect the NVIDIA eGPU only for the patching sequence. AMD eGPUs will continue to function post-patch. Basically connect the eGPU that has least support.

#### What's the latest supported macOS version?
Unless announced or advised otherwise, consider all releases from **macOS 10.13.4** up to the latest publicly available release as compatible. Note that NVIDIA compatibility depends on the GPU and availability of drivers.

#### Script recognizes my GPU as a generic AMD or NVIDIA device. Is that ok?
The script uses an online repository to retrieve the GPU device name for the connected eGPU. In case internet is absent, a generic vendor name (AMD or NVIDIA) is shown instead. This does not affect the necessary logic that determines the required patches. However, in case of NVIDIA GPUs and legacy AMD GPUs, internet will be required in case driver downloads are necessary.

</details>

### Get Help
If you are stuck somewhere, reach out to fellow users:
- [eGPU.io Build Guides](https://egpu.io/build-guides/): See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds.
- [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/): Some basics on external GPUs in macOS.
- [eGPU.io Community](https://egpu.io/forums/): Ask about, request help, learn more, and share your eGPU experience with the community.
- [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/): A wonderful place to request additional help for your new setup, and to find fellow eGPU users.

## Advanced Users & Developers
For advanced users and developers willing to test unreleased versions of the script or contributing to the development of the script or its patches, consider reading the [PurgeWrangler for Advanced Users & Developers](./DOCS.md) document.

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
