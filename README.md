# openHAB-utils
Utilizes for use with [openHAB](https://www.openhab.org/)

### [Development Zigbee and Zwave install script](https://github.com/openhab-5iver/openHAB-utils/tree/master/Development%20Zigbee%20and%20Zwave%20binding%20install%20script) (BASH)
  This script is interactive and will prompt for input. It requires to be executed from the /addons directory on the openHAB server, using the same account that runs openHAB. After downloading, be sure to set the permissions so that it can be executed (chmod u+x devZwaveZigbee.sh). At this time, there is very little error checking in the case of a failure in the script, so you should verify that it has run successfully when it completes, i.e. run 'list -s | grep -i zig' in Karaf. This script can:
  * Remove existing versions of the bindings. If they were manually installed, the jars are first backed up.
  * Install the serial transport
  * Download and install the current snapshot Zigbee binding with a chosen version of the [ZsmartSystems libraries](https://github.com/zsmartsystems/com.zsmartsystems.zigbee)
  * Download and install the development version of the [Z-Wave binding](https://github.com/openhab/org.openhab.binding.zwave/tree/development)
  
  If you would prefer to not use the menu driven interface, you can use it from the commandline. Currently, only installs can be performed when using it this way. Valid ACTIONS are 'zigbee', 'zwave' and 'both'. The OH_VERSION argument is always required. The ZSMARTSYSTEMS_VERSION argument is only required for installing the Zigbee binding. An ACCOUNT argument can be used if you have changed the Karaf SSH account.
  
    ./devZwaveZigbee.sh --OH_VERSION 2.4.0 --ZSMARTSYSTEMS_VERSION 1.0.14 --ACTION both
