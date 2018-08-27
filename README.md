# openHAB-utils
Utilizes for use with [openHAB](https://www.openhab.org/)

### [Development Zigbee and Zwave install script](https://github.com/openhab-5iver/openHAB-utils/tree/master/Development%20Zigbee%20and%20Zwave%20binding%20install%20script) (BASH)
  This script is interactive and will prompt for input. It requires to be executed from the /addons directory on the openHAB server, using the same account that runs openHAB. After downloading, be sure to set the permissions so that it can be executed (chmod u+x zzManualInstall.sh), or run it with `bash zzManualInstall.sh`. At this time, there is very little error checking in the case of a failure in the script, so you should verify that it has run successfully when it completes, i.e. run `list -s | grep -i zig` in Karaf. This script can:
  * Download and manually install/upgrade the current snapshot or development Zigbee binding, with a chosen version of the [ZsmartSystems libraries](https://github.com/zsmartsystems/com.zsmartsystems.zigbee)
  * Download and manually install/upgrade the snapshot or development version of the [Z-Wave binding](https://github.com/openhab/org.openhab.binding.zwave/tree/development)
  * Uninstall existing versions of the bindings. If they were manually installed, the jars are first backed up.
  * Install the serial transport
  
  If you would prefer to not use the menu driven interface, you can use it from the commandline. This is useful if you would like to execute it from a rule. Currently, only installs/upgrades can be performed when running from commandline. 
  
Here is the output of zzManualInstal.sh --help...
```
This script is capable of downloading and manually installing the latest development or master branch builds of the Z-Wave and Zigbee bindings, and/or the openhab-transport-serial
feature. The script must reside inside the addons folder and be executed on the machine running OH. Before a binding is installed, any previous versions will be
uninstalled. Any manually installed versions will also be backed up by moving them to /addons/archive. The installation of any binding will also include the installation
of the opemnhab-serial-transport feature. After using this script, you can uninstall the bindings by deleting their jars from /addons or you can use this script.

!!!!! If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, they must be removed from the file or the old version will reinstall !!!!!

Usage: ./zzManualInstaller.sh [OPTION]...

If executed without the ACTION argument, menus will be displayed for each option

    --ACTION                  Accepted values: zigbee, zwave, both. Specify which bindings to install/upgrade.
    --ZWAVE_BRANCH            Accepted values: development, master. Default: master. Specify the development or master branch for Z-Wave.
    --ZIGBEE_BRANCH           Accepted values: development, master. Default: master. Specify the development or master branch for Zigbee.
    --ZSMARTSYSTEMS_VERSION   Default: latest version, based on selected branch. Specify the version of the ZSmartSystems libraries.
    --KARAF_ACCOUNT           Default: openhab. Specify an account for the Karaf SSH login.
    --HELP                    Display this help and exit
```

Here is how to install/upgrade the development Z-Wave binding from commandline...

    bash zzManualInstall.sh --ACTION zwave --ZWAVE_BRANCH development
