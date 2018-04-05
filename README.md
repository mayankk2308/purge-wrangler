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
$ sudo ./purge-wrangler.sh
```

eGPUs should be enabled after reboot.

## Troubleshooting
If you are unable to boot into macOS, boot while pressing **CMD + S**, then enter the following commands:
```bash
$ mount -uw /
$ ./purge-wrangler.sh recover
```

## Additional Options
To uninstall changes:
```bash
$ sudo ./purge-wrangler.sh uninstall
```
To recover original kext:
```bash
$ sudo ./purge-wrangler.sh recover
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
