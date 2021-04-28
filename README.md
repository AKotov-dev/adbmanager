ADBManager - Graphical ADB server manager for Android devices
---
The program is designed for visual and easy management of the ADB-Server and connection of Android smartphones. Allows you to monitor the status of the "adb" service, manage it, and control the list of connected devices. Allows you to manage your smartphone: search for installed packages by part name, install, delete APK, backup, restore, reboot (Normal, Bootloader, Recovery mode) and shutdown the device. Tested in Mageia-8 and Linux Mint-20.  

Dependencies: adb, iproute2, sakura  
Free icons: https://icon-icons.com/ru/

**Access permissions via USB:**  
Linux Mint: sudo usermod -a -G plugdev $USER; reboot  
Mageia Linux: su/password; usermod -a -G usb $USER; reboot

![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager1.png)  

![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager2.png)
