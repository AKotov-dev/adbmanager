ADBManager - ADB manager for Android devices
---
The program is designed for visual and easy management of the ADB-Server and connection of Android smartphones. Allows you to monitor the status of the `adb` service, manage it, and control the list of connected devices. Allows you to manage your smartphone: search for installed packages by part name, install, delete APK, screenshot, reboot (Normal, Bootloader, Recovery mode) and shutdown the device. For advanced users, there is an Android Shell terminal and an SD-Card file manager.  
  
Starting from `v2.9`, it is possible to enable, disable and delete non-removable applications for Android >= 6.  
  
Access to the device via USB and rules
---
Update the rules for Android devices on your computer, include the active user in the `adbusers` group and reboot:  
```
su/password
groupadd adbusers #if ADBManager is not installed from the package (portable)
usermod -aG adbusers $(logname)
cd /usr/lib/udev/rules.d
wget https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules -O ./51-android.rules
reboot
```
  
Connecting via ADB over Wi-Fi
---
+ Connect the smartphone via USB  
+ Press the `emulator` button and `Switch to TCP/IP mode`  
+ Disconnect the smartphone from the USB  
+ Press the `emulator` button and enter the IP address of the smartphone

Tested in Mageia-8/9 and Linux Mint-20.  

Dependencies: adb, iproute2, sakura, nmap, gtk2  
Free icons: https://icon-icons.com/ru/

![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager1.png)  
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager2.png)
  
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
