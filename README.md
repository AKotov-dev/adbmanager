ADBManager - Manager for Android devices using ADB
---
+ Dependencies: adb iproute2 sakura nmap p7zip imagemagick gtk2  
+ Working directory (settings, temporary files): ~/.adbmanager  
+ Packages installation script: ~/.adbmanager/install_packages.sh (created automatically)
+ If [IconExtractor.apk](https://github.com/AKotov-dev/adbmanager/tree/main/IconExtractor) is installed, the path to application icons: /storage/emulated/0/Pictures/IconExtractor/icons
  
**Note:** It is advisable to connect the devices via the `USB-2.0` port of your computer ([info](https://www.systutorials.com/how-to-force-a-usb-3-0-port-to-work-in-usb-2-0-mode-in-linux/)).
    
The program is designed for visual and easy management of the ADB-Server and connection of Android smartphones. Allows you to monitor the status of the `adb` service, manage it, and control the list of connected devices. Allows you to manage your smartphone: search for installed packages by part name, install, delete APK, screenshot, reboot (Normal, Bootloader, Recovery mode) and shutdown the device. For advanced users, there is an Android Shell terminal and an SD-Card file manager.  
  
Starting with `v3.6`, the application manager can display application icons from a connected device. This requires installing the `IconExtractor.apk`.
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Applications1.png)
  
Starting with `v3.4`, fine-tuning for `Android TV Box` with truncated launchers (gear icon) has been added. Now missing settings can be made via `ADB`.
  
Starting from `v3.3`, multiple installation of `APK`, `APKS` and `XAPK` packages is supported. Files are selected in the file selection window using the `Ctrl+Mouse`. Installation of `XAPK`packages with a single package architecture (32 bits or 64 bits) is supported. The presence of packages of both architectures (32 bits + 64 bits) in `XAPK` is not supported.
  
Starting from `v2.9`, it is possible to enable, disable and delete non-removable applications for Android >= 6.  
  
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
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShots/Screenshot11.png)  
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
