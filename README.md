# openHAB-utils
Utilizes for use with [openHAB](https://www.openhab.org/)

### [Development Zigbee and Zwave install script](https://github.com/openhab-5iver/openHAB-utils/tree/master/Development%20Zigbee%20and%20Zwave%20binding%20install%20script)
  This script is interactive and will prompt for input and must be run from the machine runing openHAB. Currently, it requires to be run under the root account of the machine running openHAB, but this limitation may not be needed. At this point, there is no error checking in the case of a failure in the script, so you should verify that it has run successfully. Based on user input, this script will:
  * Remove existing versions of the bindings that were selected to be installed. If they were manually installed, the jars are backup up first.
  * Install the serial transport
  * Download and install the snapshot Zigbee binding with a chosen version of the ZsmartSystems libraries
  * Download and install the development version of the Z-Wave binding
