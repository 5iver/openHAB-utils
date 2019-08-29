# openHAB-utils
Utilities for use with [openHAB](https://www.openhab.org/)

### [Zigbee and Z-Wave manual install](https://github.com/openhab-5iver/openHAB-utils/tree/master/Zigbee%20and%20Z-Wave%20manual%20install) (BASH)
<ul>
  
_**NOTE: The development Z-Wave binding has been [merged into the master branch](https://community.openhab.org/t/zwave-binding-updates/51080), so only choose the development branch for Z-Wave if Chris has instructed you to do so (he may throw a test jar out there).**_

  This script is interactive and will prompt for input. It must be copied to, and executed from, the addons directory on the openHAB server, **using the same account that runs openHAB**. 
  After downloading, be sure to set the permissions so that it can be executed (`chmod u+x zzManualInstall.sh`), or run it with `bash zzManualInstall.sh`. 
  If using a package installation (like openHABian), execute the script with `sudo -E -u openhab bash zzManualInstaller.sh`. 
  At this time, there is very little error checking in the case of a failure in the script, so you should verify that it has run successfully when it completes, i.e. run `list -s | grep -i zig` in Karaf. 
  This script can:
  * Download and manually install/upgrade the current snapshot or development Zigbee binding, with a chosen version of the [ZsmartSystems libraries](https://github.com/zsmartsystems/com.zsmartsystems.zigbee)
  * Download and manually install/upgrade the snapshot or development version of the [Z-Wave binding](https://github.com/openhab/org.openhab.binding.zwave/tree/development)
  * Uninstall existing versions of the bindings. If they were manually installed, the jars are first backed up.
  * Install openhab-transport-serial
  
  If you would prefer to not use the menu driven interface, you can use it from the commandline. 
  This is useful if you would like to execute it from a rule. Currently, only installs/upgrades can be performed when running from commandline. 
  
Here is the output of `zzManualInstal.sh --help`...
```
This script is capable of downloading and manually installing the latest development or master branch builds of the Z-Wave and Zigbee bindings, and/or the openhab-transport-serial
feature. The script must reside inside the addons folder and be executed on the machine running OH. Before a binding is installed, any previous versions will be
uninstalled. Any manually installed versions will also be backed up by moving them to addons/archive. The installation of any binding will also include the installation
of the opemnhab-transport-serial feature. After using this script, you can uninstall the bindings by deleting their jars from addons or you can use this script.

!!!!! If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, they must be removed from the file or the old version will reinstall !!!!!

Usage: zzManualInstaller.sh [OPTION]...

If executed without the ACTION argument, menus will be displayed for each option

    --ACTION                  Accepted values: zigbee, zwave, both. Specify which bindings to install/upgrade.
    --ZWAVE_BRANCH            Accepted values: development, master. Default: master. Specify the development or master branch for Z-Wave.
    --ZIGBEE_BRANCH           Accepted values: development, master. Default: master. Specify the development or master branch for Zigbee.
    --ZSMARTSYSTEMS_VERSION   Default: latest version, based on selected branch. Specify the version of the ZSmartSystems libraries.
    --HELP                    Display this help and exit
```

Here is how to install/upgrade the development Z-Wave binding from commandline...

    bash zzManualInstall.sh --ACTION zwave --ZWAVE_BRANCH development


**Here are the steps this script performs, and which you could choose to do manually**

1. Access the Karaf console
2. Check for previously installed versions of the bindings... `list -s | grep zwave` or `list -s | grep zigbee`
3. Uninstall any previously installed versions of the bindings... `bundle:uninstall org.openhab.binding.zwave` or `bundle:uninstall org.openhab.binding.zigbee`. This may need to be repeated, if multiple versions have been installed. Also, remove zwave and zigbee from the addons.cfg, if you've previously added it there.
4. Remove any Zigbee or Z-Wave jar files in the `/addons/` directory.
5. Download the Z-Wave jar and save to `/addons/`. The references to the OH version in this link will need to be updated in the future as the versions change. Replace `${OH_VERSION}` with the current snapshot version of OH (i.e., 2.5.0):
```
https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zwave/artifact/org.openhab.addons.bundles/org.openhab.binding.zwave/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar)
```
6. For Zigbee, download all of these, or just the ones pertinent to your coordinator (replace `${ZSMARTSYSTEMS_VERSION}` with the current version of the libraries (i.e., 1.2.1) and `${OH_VERSION}` with the current snaphsot version of OH (i.e., 2.5.0):
```
https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee-${ZSMARTSYSTEMS_VERSION}.jar
https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.xbee/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.xbee-${ZSMARTSYSTEMS_VERSION}.jar
https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.ember/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.ember-${ZSMARTSYSTEMS_VERSION}.jar
https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.telegesis/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.telegesis-${ZSMARTSYSTEMS_VERSION}.jar
https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.cc2531/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.cc2531-${ZSMARTSYSTEMS_VERSION}.jar

https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zigbee.cc2531/artifact/org.openhab.addons.bundles/org.openhab.binding.zigbee.cc2531/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.cc2531-${OH_VERSION}-SNAPSHOT.jar
https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zigbee.ember/artifact/org.openhab.addons.bundles/org.openhab.binding.zigbee.ember/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.ember-${OH_VERSION}-SNAPSHOT.jar
https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zigbee.telegesis/artifact/org.openhab.addons.bundles/org.openhab.binding.zigbee.telegesis/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.telegesis-${OH_VERSION}-SNAPSHOT.jar
https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zigbee.xbee/artifact/org.openhab.addons.bundles/org.openhab.binding.zigbee.xbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.xbee-${OH_VERSION}-SNAPSHOT.jar
https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.addons.bundles%24org.openhab.binding.zigbee/artifact/org.openhab.addons.bundles/org.openhab.binding.zigbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee-${OH_VERSION}-SNAPSHOT.jar
```
7. Back in the Karaf console, install the serial transport feature: `feature:install openhab-transport-serial`
8. Download xstream and copy the jar file to /addons/... 
```
http://central.maven.org/maven2/org/apache/servicemix/bundles/org.apache.servicemix.bundles.xstream/1.4.7_1/org.apache.servicemix.bundles.xstream-1.4.7_1.jar
```
</ul>

### [Backup and upgrade manual installation](https://github.com/openhab-5iver/openHAB-utils/tree/master/Backup%20and%20upgrade%20manual%20installation)
<ul>
  This script is interactive and will prompt for input. It will perform a full backup of a manual installation (single directory), and then perform an upgrade. This may be obsolete, since there are official backup and restore scripts, but I haven't looked through them yet.
</ul>
