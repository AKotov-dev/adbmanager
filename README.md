ADBManager - Manager for Android devices using ADB
---
+ Dependencies (RPM): adb iproute2 sakura nmap p7zip graphicsmagick xdg-utils qtbase6-common qt6pas gtk2
+ Dependencies (DEB): adb iproute2 sakura nmap p7zip graphicsmagick xdg-utils libgtk2.0-0 libqt6core6 libqt6gui6 libqt6widgets6 libqt6network6 libqt6printsupport6 libqt6pas6  
+ Working directory (settings, temporary files): ~/.adbmanager/{icons,tmp}  
+ Packages installation script: ~/.adbmanager/install_packages.sh (created automatically)
+ `IconExtractor.apk`: /storage/emulated/0/Pictures/IconExtractor/icons (icon cache)
  
**Note:** It is advisable to connect the devices via the `USB-2.0` port of your computer ([info](https://www.systutorials.com/how-to-force-a-usb-3-0-port-to-work-in-usb-2-0-mode-in-linux/)).
  
**Announcement:** Detailed instructions for building and setting up ADBManager on `macOS` were prepared by `Andrii Murashkin` (@murich) and are available [here](https://github.com/murich/adbmanager).
  
`ADBManager` offers a clean and intuitive interface to control the ADB server and manage connected Android devices. It lets you monitor the ADB service, browse connected devices, and perform common actions like searching installed apps, installing or uninstalling APKs, taking screenshots, rebooting (normal, bootloader, or recovery), or shutting down the device. Advanced users can take advantage of the built-in Android shell terminal and SD card file manager.  

### Qt6 Support

`ADBManager` now supports `Qt6` widgets alongside the classic `GTK2` interface.  
Two separate builds are available in the same source tree.

### Building

- **Command line:**  
  ```bash
  lazbuild --build-mode=Release adbmanager.lpi   # GTK2
  lazbuild --build-mode=Qt6 adbmanager.lpi       # Qt6

**Lazarus IDE:**
1. Select the Build Configuration from the top-left drop-down (`Release` for GTK2, `Qt6` for Qt6).
2. Go to `Project` → `Build`.

**Output binaries (same folder):**
+ adbmanager → GTK2
+ adbmanager-qt → Qt6

**Note:** Building `Qt6` in Mageia requires installing the `qt6pas` and `qt6pas-devel` packages.

Starting with `v3.8`, you can now export a complete list of installed packages and their states (enabled/disabled) through the **PoUpMenu**. This is useful for experimenting with disabling unnecessary packages to speed up your device. For package list analysis, you can consult **ChatGPT** or other experienced users. The author is not responsible for any consequences from changes, so make sure to back up your data.
  
Starting with `v3.7`, a double click in the SDCard manager opens 40+ file formats (multimedia, documents, archives, etc.) via `xdg-open`. Of course, the appropriate applications must be installed on the computer to open them.
  
Starting with `v3.6`, the application manager can display application icons from a connected device. This requires installing the [IconExtractor.apk](https://github.com/AKotov-dev/adbmanager/tree/main/IconExtractor). On Android_6-10, you will need to grant permission to access media storage.
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Applications3.png)
  
Starting with `v3.4`, fine-tuning for `Android TV Box` with truncated launchers (gear icon) has been added. Now missing settings can be made via `ADB`.
  
Starting from `v3.3`, multiple installation of `APK`, `APKS` and `XAPK` packages is supported. Files are selected in the file selection window using the `Ctrl+Mouse`. Installation of `XAPK`packages with a single package architecture (32 bits or 64 bits) is supported. The presence of packages of both architectures (32 bits + 64 bits) in `XAPK` is not supported.
  
Access to the device via USB and rules
---
Update the rules for Android devices on your computer, include the active user in the `adbusers` group and reboot:  
```
su/password
groupadd adbusers; usermod -aG adbusers $(logname)
wget https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules -O /etc/udev/rules.d/51-android.rules
reboot
```
  
Connecting via ADB over Wi-Fi
---
+ Connect the smartphone via USB  
+ Press the `emulator` button and `Switch to TCP/IP mode`  
+ Disconnect the smartphone from the USB  
+ Press the `emulator` button and enter the IP address of the smartphone

**Note:** When connecting to the device via network, do not forget to disable the firewall (`TCP:5555`).  
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Screenshot9.png)  
#### Possible errors when installing packages
+ [INSTALL_FAILED_NO_MATCHING_ABIS: ...] - the package architecture is not suitable for your device
+ [INSTALL_FAILED_ALREADY_EXISTS: ...] - before installing, remove the previous package with this name

#### Recommendations for installing XAPK packages
1. Download files only from trusted and verified sources to minimize the risk of infecting your device with malware
2. Enable permission to install from unknown sources in your device's security settings, while being aware of the potential risks
3. Remember that installing apps from third-party sources may violate Google's security policy and lead to unwanted consequences

![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Screenshot12.png)  
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Screenshot13.png)  

Translations
--
+ en - English
+ de - German (completed, doktor5000)
+ es - Spanish (in progress, Rizado)
+ fr - French (free/author)
+ it - Italian (free/author)
+ ru - Russian  
  
If you would like to add to this list then get in touch.  
To create your own translation, download the main translation template: [adbmanager.pot](https://raw.githubusercontent.com/AKotov-dev/adbmanager/main/adbmanager/languages/adbmanager.pot)
  
Install and run the `PoEdit` editor. Open in it: `Menu`-`File`-`Create from POT/PO file` and select the file `adbmanager.pot`. Immediately specify the language into which you want to translate and... `Menu`-`File`-`Save As...` Specify the file name `adbmanager.xx.po`, where `xx` is the language prefix.  
  
**Note:** Due to the release of an additional ADBManager version with Qt widgets, the primary translation files remain the original adbmanager.xx.po. Any subsequent duplication for the Qt version (adbmanager-qt.xx.po) can be performed using the script 1-translation_gtk-qt.sh.