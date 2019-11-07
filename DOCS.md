# PurgeWrangler for Advanced Users & Developers
**Document Revision**: 6.0.0+

With every open source project, testing and collaboration are key in building trust and ensuring an efficient, bug-free, and smooth user experience. This document serves as a guide for advanced users willing to try unreleased versions of the script, and developers to add functionality and capability to **purge-wrangler.sh**.

## The Basics
This document assumes you are familiar with the pre-requisites and capabilities of the script. If not, it is best that you read them in the [README](./README.md) and try out the release version of the script before diving into testing or development.

### Getting Pre-Release Builds
If you are an advanced user willing to test the newest unreleased versions of **purge-wrangler.sh**, use the following command to install the latest build of the script:
```bash
curl -qLs https://bit.ly/2U1zdF5 > purge-wrangler.sh; bash purge-wrangler.sh; rm purge-wrangler.sh
```
If using **git**, it may be preferable to keep a working local clone of the repository. This can be done with:
```bash
git clone https://github.com/mayankk2308/purge-wrangler.git
```
Always know that unreleased builds of the script can potentially cause problems and may even render your system unbootable in worst-case scenarios. For example, if a new build of the script has a bug in its recovery mechanism, it may leave the system unbootable. It is recommended to use an [extra installation of macOS](https://support.apple.com/en-us/HT208891) for testing.

### Script Options
There are convenient command-line arguments for the script that advanced users may prefer using, enumerated in the following table.

| Menu | CLI Arg | Description |
| :------: | :--: | :---------- |
| Setup eGPU | `-a` | Automatically set up eGPU based on your system configuration and external GPU. |
| Uninstall | `-u` | Uninstalls **any** system modifications made by the script in-place. This is the *recommended* uninstallation mechanism. |
| System Status | `-s` | Shows the current status of some of the components of the system and any modifications made using the script. |

Running without arguments launches the menu. Recovery mechanism is not user-accessible from script version **6.2.0** or later. The script will only run recovery automatically when it detects a system executing it in single user mode.

### Reporting Problems
Use the [Issues](https://github.com/mayankk2308/purge-wrangler/issues) section on the repository to report any problems with the script. Please follow the templates for bug reports and feature requests. Try not to open duplicate issues.

### Contributing
Code contributions are done only via pull requests. Please use the [Pull Requests](https://github.com/mayankk2308/purge-wrangler/pulls) section on the repository to contribute. All contributions will be reviewed and tested thoroughly. If you are contributing a new patch, feel free to add yourself to the [README](./README.md) as a contributor for the patch.

### Recovering From Worst-Case Scenarios
All worst-case scenarios can be easily recoverable by simply reinstalling [macOS via recovery](https://support.apple.com/en-us/HT204904). I recommend having an additional [bootable installer](https://support.apple.com/en-us/HT201372) ready as well, to not have to always download the entire operating system each time. After reinstalling macOS, get rid of outdated script components:
```bash
sudo rm /usr/local/bin/purge-wrangler && \
sudo rm -rf /Library/Application\ Support/Purge-Wrangler
```
If you want to switch back to a release build:
- Uninstall all patches from the script.
- Remove all components of the script as shown above.
- Use the command in [README](./README.md) to install the latest release.

In case of a situation where the uninstallation mechanism has a bug, it is wiser to reinstall macOS and clean out the script components as described above.

## Deep Dive
This section dives deeper into some key mechanisms involved in **purge-wrangler.sh** and how you can leverage them to add your own capabilities. This section is updated according to the document revision, which corresponds to the planned/deployed script version.

API definitions will be of the following format:

- `<function name>`
  - **<arg 1>**
  - **<arg 2>**
  ...

### User Interface APIs
**purge-wrangler.sh** includes simple and easy-to-use APIs to create standardized, elegant, and simple user interactions.

#### Yes/No Prompts
Yes/no prompts provide a standard way to ask yes/no questions to the user. Having a standard mechanism for this ensures a consistent user interface and less bugs in processing input.

##### API Definition
The yes/no prompt generation API consists of just one function:
- `yesno_action`
  - **prompt**, *String*: Message or prompt to ask for input.
  - **yesaction**, *String*: Action to take on affirmation. This is `eval`uated.
  - **noaction**, *String*: Action to take on cancellation. This is `eval`uated.
  - **noecho**, *Any*: By default, prompts `echo` before asking for input. This disables this.

##### Example
This example requests the user for confirmation for running recovery:
```bash
yesno_action "${bold}Run Recovery?${normal}" "recover_sys" "exit"
```
where `recover_sys` is a defined function.


#### Menu Generation
Newer builds of the script incorporate a standardized menu generation and input processing mechanism that reduces code size and chances of introducing bugs.

##### API Definition
The menu generation API consists of two primary functions:
- `generate_menu`
  - **header**, *String*: Describes the menu.
  - **indent_level**, *Integer*: Indents the menu by this number of spaces.
  - **gap_after**, *Integer*: Leaves a space after this number of items in the menu (`0` = no gap).
  - **should_clear**, *Boolean*: Determines whether or not to clear before presenting menu.
  - **items**, *(String)*: Items to display.
- `autoprocess_input`
  - **message**, *String*: Message or prompt to ask for input.
  - **caller**, *String*: The calling function's name. Can provide multiple functions using `&&`.
  - **exit_action**, *String*: Command(s) to run on exiting the menu.
  - **prompt_back**, *Boolean*: Determines whether or not to prompt a return to menu.
  - **actions**, *(String)*: Actions for every item - could be functions or commands.

##### Example
Here's a sample of how a menu can be created:
```bash
### An example menu
present_menu() {

  # Describe menu items
  local menu_items=("Setup eGPU" "Uninstall" "Quit")

  # Describe menu actions - should correspond to items above
  local menu_actions=("auto_setup_egpu" "uninstall" "exit")

  # Generate the menu
  generate_menu "PurgeWrangler (${script_ver})" "0" "0" "1" "${menu_items[@]}"

  # Process user input for this menu
  autoprocess_input "What next?" "present_menu" "exit" "true" "${menu_actions[@]}"
}
```

#### Patching Mechanisms
Patching is always a **3-step** process - creating a hexadecimal patchable representation of a binary, replacing hex values in this representation, and converting back to an executable, now patched. The reason for using three separate functions is to allow for multiple patches in a single binary with ease.

One cool aspect about the patching mechanisms that you might notice is the lack of `rm` and preference of `rsync`. This is done to minimize the potential of losing files completely, however it does not necessarily protect against corruption. Corruption fallbacks are dealt with by the recovery mechanism described ahead.

##### API Definition
The patching mechanisms consist of three primary functions:
- `create_hexrepresentation`
  - **target_binary**, *String*: Binary executable to convert.
- `patch_binary`
  - **target_binary**, *String*: Executable to patch.
  - **find**, *String*: Value in hex to search for in binary.
  - **replace**, *String*: Value in hex to replace with in binary.
- `create_patched_binary`
  - **target_binary**, *String*: Binary executable to create patched binary for.

##### Example
This example demonstrates how to patch a kext binary:
```bash
local extension_to_patch="/System/Library/Extensions/SomeExtension.kext/Contents/MacOS/SomeExtension"
create_hexrepresentation "${extension_to_patch}"
patch_binary "${extension_to_patch}" "AB02EF" "BB02EF"
create_patched_binary "${extension_to_patch}"
```
Keep in mind that it is wise to add checks and handle any edge cases (previously patched system, for example), and always ensure that patches can work alongside already-present patches.

The above is only an example - the hex values do not mean anything. Finding the right hex values to patch or replace requires reverse engineering expertise. I personally prefer using [Ghidra](https://ghidra-sre.org) for macOS reverse engineering and patch testing.

## Additional Features
**purge-wrangler.sh** has some other nifty features to customize your patching setup as desired. This includes the ability to specify the web driver version you wish to install, and individually apply patches.

### AMD Legacy Support
This option is present at **[5] More Options > [1] AMD Legacy Support**. This installs a codeless **AMDLegacySupport** kext to **/Library/Extensions/** to add `IOPCITunnelCompatible: true` values for more AMD GPU architectures, thus enabling them over Thunderbolt. This will automatically be done if a legacy AMD GPU is detected.

### Ti82 Support
This option is present at **[5] More Options > [2] Enable Ti82 Support**. Ti82 patching is required to enable early **Thunderbolt 3** devices that macOS declares as *"Unsupported"*. If detected during eGPU configuration, this patch is automatically applied, but more information about the GPU is required since it could not be read.

### NVIDIA Web Drivers
This option is present at **[5] More Options > [3] Install NVIDIA Web Drivers**. The script includes a comprehensive system to install NVIDIA Web Drivers directly from NVIDIA servers. The latest updates to the script bring the ability to specify a web driver version you would like to install. This is useful in cases where an older driver works better. However, during automatic eGPU setup, there will be no option to specify web driver versions.

### System Diagnosis
This option is present at **[5] More Options > [4] System Diagnosis**. This checks for edge-case configurations such as macs with discrete NVIDIA GPUs. By default, system diagnosis runs after applying patches in the automatic setup workflow.

### Recovery
This option is present at **[4] Recovery**. Fundamentally, the end result of running **Uninstall** or **Recovery** is supposed to be the same. However, since patching and unpatching are non-atomic operations, there may be an undefined number of unprecedented situations where the mechanisms go wrong and files are lost/misplaced. In such a scenario, undoing patches would not work. By maintaining an invariant that a **kext backup** must occur before any patch, any patching failure can be recovered even if the uninstallation mechanism fails by relying on the last backup (hence called 'recovery'). In this case a cure is better than prevention. When the script is executed in [Single User Mode](http://osxdaily.com/2018/10/29/boot-single-user-mode-mac/), this operation is executed by default and no other capabilities are available.

## What's Ahead
It is clear that **Apple** will never be incorporating support for external GPUs for **Thunderbolt 1/2** Macs, and for now, neither for **NVIDIA eGPUs**. My hope is that as long as we see operating system updates for the last **Thunderbolt 2** Mac, the patches continue to function. Beyond that, we have to move on to other things (and devices :p).
