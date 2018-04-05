# PurgeWrangler
This script enables external graphics on Thunderbolt 1/2 Macs, which is actively blocked in macOS **10.13.4**.

## Requirements
This script requires the following specifications:
* Mac with **Thunderbolt 1/2**
* **macOS 10.13.4** or later

It is recommended that you have a backup of the system. Testing was done on a **Mid-2014 MacBook Pro w/ GeForce GT 750M**.

## Usage
Please follow these steps:

### Step 1
Disable **system integrity protection** for macOS using **Terminal** in **Recovery**:
```bash
$ csrutil disable
$ reboot
```

### Step 2
Boot back into macOS and run the following commands:
```bash
$ cd /path/to/script/purge-wrangler.sh
$ sudo chmod +x purge-wrangler.sh

# tb1 for Thunderbolt 1 Macs, tb2 for Thunderbolt 2 Macs, not both together
$ sudo ./purge-wrangler.sh patch [tb1 tb2]

# For example, to patch a Thunderbolt 2 mac
$ sudo ./purge-wrangler.sh patch tb2
```

Your mac will now behave like an iGPU-only device.

## Troubleshooting
If you are unable to boot into macOS, boot into recovery, launch **Terminal** and type in the following commands:
```bash
$ cd /Volumes/<boot_disk_name>

# Check if you have backup of AppleGraphicsControl.kext and proceed only if you do
$ ls Library/Application\ Support/Purge-Wrangler/

$ rm -r /System/Library/Extensions/AppleGraphicsControl.kext
$ mv Library/Application\ Support/Purge-Wrangler/* System/Library/Extensions/
$ reboot
```

## Additional Options
To uninstall changes:
```bash
$ sudo ./purge-wrangler.sh uninstall
```

For help with how to use the script:
```bash
$ sudo ./purge-wrangler.sh help
```

**Uninstallation recommended before updating macOS.**

## References
Many thanks to **@itsage**, **@fricorico**, **@goalque**, and many others at [egpu.io](https://egpu.io) for the insightful discussion that led me to the fix.

## Disclaimer
This script moves core system files associated with macOS. While any of the potential issues with its application are recoverable, please use this script at your discretion. I will not be liable for any damages to your operating system.

## License
See the license file for more information.
