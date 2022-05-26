ADBManager - ADB server manager for Android devices
---
The program is designed for visual and easy management of the ADB-Server and connection of Android smartphones. Allows you to monitor the status of the "adb" service, manage it, and control the list of connected devices. Allows you to manage your smartphone: search for installed packages by part name, install, delete APK, backup, restore, screenshot, reboot (Normal, Bootloader, Recovery mode) and shutdown the device. For advanced users, there is an Android Shell terminal and an SD-Card file manager.  

Access permissions via USB
---
`Linux Mint:` sudo usermod -aG plugdev $LOGNAME; reboot  
`Mageia Linux:` groupadd adbusers; usermod -aG adbusers $LOGNAME  
replace the file /usr/lib/udev/rules.d/51-android.rules with a file from the repository and reboot

Connecting via ADB over Wi-Fi
---
+ Connect the smartphone via USB  
+ Press the `emulator` button and `Switch to TCP/IP mode`  
+ Disconnect the smartphone from the USB  
+ Press the `emulator` button and enter the IP address of the smartphone

Tested in Mageia-8 and Linux Mint-20.  

Dependencies: adb, iproute2, sakura, nmap  
Free icons: https://icon-icons.com/ru/

![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager-v2.6-1.png)  
  
![](https://github.com/AKotov-dev/adbmanager/blob/main/ScreenShot/ADBManager-v2.6-2.png)
