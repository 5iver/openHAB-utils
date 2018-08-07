#!/bin/bash
GREY_RED='\033[0;37;41m'
GREEN_DARK='\033[0;32;40m'
BLUE_DARK='\033[1;34;40m'
BLINKING='\033[5;37;41m'
NC='\033[0m' # Reset

start()
{
    clear
    currentAccount=$(whoami)
    #if [ "${currentAccount}" != "root" ] && [ "${currentAccount}" != "openhab" ] && [ "${currentAccount}" != "openhabian" ]; then
    if [ "${currentAccount}" != "root" ]; then
        #echo; echo; echo; echo; echo; echo -e ${DARK_RED}"This script must be run under the root, openhab or openhabian account!"; echo -e ${NC}; exit
        echo; echo; echo; echo -e "${BLINKING}!!!!!${GREY_RED} This script MUST be run under the root account! ${BLINKING}!!!!!${NC}"; echo; echo; exit
    fi

    echo; echo; echo -e ${GREEN_DARK}"This script will do a manual install of the latest development Zwave and Zigbee bindings, and it must be executed on the machine running"
    echo "OH. Any versions installed through PaperUI or Habmin will be uninstalled, and manually installed versions will be renamed to backup the old jars."
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, Exit and remove them from the file or the old version will reinstall! ${BLINKING}!!!!!${NC}"; echo
    select bindings in "Install Zigbee" "Install Z-Wave" "Install both" "Exit"; do
        case $bindings in
            "Install Zigbee" ) break;;
            "Install Z-Wave" ) break;;
            "Install both" ) break;;
            "Exit" ) exit;;
        esac
    done

    account=openhab
    echo; echo -e ${GREEN_DARK}"Connecting to Karaf via ssh to remove duplicate bindings, and to install openhab-serial-transport. If you have changed the default Karaf SSH username,"
    echo "choose Exit, remove manually installed Zigbee/Z-Wave jars, and run 'feature:install openhab-serial-transport' from Karaf before running this script again."
    echo -e "If you are using openHABian, use '${NC}openhabian${GREEN_DARK}' for the password. Otherwise, use '${NC}habopen${GREEN_DARK}'"${NC}; echo
    select yn in "Not using openHABian" "Using openHABian" "Exit"; do
        case $yn in
            "Not using openHABian" ) break;;
            "Using openHABian" ) account=openhabian; break;;
            "Exit" ) exit;;
        esac
    done
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        karafFunction="
        bundle:uninstall com.zsmartsystems.zigbee
        bundle:uninstall com.zsmartsystems.zigbee.dongle.cc2531
        bundle:uninstall com.zsmartsystems.zigbee.dongle.ember
        bundle:uninstall com.zsmartsystems.zigbee.dongle.telegesis
        bundle:uninstall com.zsmartsystems.zigbee.dongle.xbee

        bundle:uninstall org.openhab.binding.zigbee
        bundle:uninstall org.openhab.binding.zigbee.cc2531
        bundle:uninstall org.openhab.binding.zigbee.ember
        bundle:uninstall org.openhab.binding.zigbee.telegesis
        bundle:uninstall org.openhab.binding.zigbee.xbee"
    fi
    if [[ "${bindings}" = "Install Z-Wave" || "${bindings}" = "Install both" ]]; then
        karafFunction="${karafFunction}
        bundle:uninstall org.openhab.binding.zwave"
    fi
    karafFunction="${karafFunction}
        feature:install openhab-transport-serial
        logout"
    echo; echo -e ${BLUE_DARK}"Removing non-manually installed binding(s) and installing openhab-serial-transport..."${NC}
    #ssh -p 8101 -o StrictHostKeyChecking=no -l ${account} localhost "feature:install openhab-transport-serial; logout"
    ssh -p 8101 -o StrictHostKeyChecking=no -l ${account} localhost ${karafFunction}

    inputs
}

inputs()
{
    clear; echo; echo; echo; echo -e ${GREEN_DARK}"What is the path to addons (manual install: /opt/openhab2/addons, apt-get install: /usr/share/openhab2/addons)?"${NC}; echo
    select ohAddons in "/opt/openhab2/addons" "/usr/share/openhab2/addons" "Other"; do
        case $ohAddons in
            "/opt/openhab2/addons" ) break;;
            "/usr/share/openhab2/addons" ) break;;
            "Other" ) get_addons_path; break;;
        esac
    done

    echo; echo; echo; echo -e ${GREEN_DARK}"Enter the current OH snapshot version [clear field to exit]"${NC}; echo
    read -e -p "[Use backspace to modify, enter to accept] " -i "2.4.0" ohVersion
    if [ -z "${ohVersion}" ]; then
        exit
    fi

    if [[ "$bindings" = "Install Zigbee" || "$bindings" = "Install both" ]]; then
        echo; echo; echo; echo -e ${GREEN_DARK}"Enter the requested version of ZSmartSystems libraries [clear field to exit]"${NC}; echo
        read -e -p "[Use backspace to modify, enter to accept] " -i "1.0.14" zsmartVersion
        if [ -z "${zsmartVersion}" ]; then
            exit
        fi
    fi
    summary
}

summary()
{
    clear; echo; echo "     *****     SUMMARY     *****"; echo
    echo -e ${GREEN_DARK}"OH addons path: "${NC}${ohAddons}
    echo -e ${GREEN_DARK}"Current OH snapshot version: "${NC}${ohVersion}
    if [ "${bindings}" == "Install Zigbee" ] || [ "${bindings}" == "Install both" ]; then
        echo -e ${GREEN_DARK}"Requested version of ZSmartSytems libraries: "${NC}${zsmartVersion}
    fi
    echo; echo -e ${GREEN_DARK}"Is this correct?"
    echo -e ${GREEN_DARK}"NOTE: if you Exit, be mindful that the binding(s) are currently uninstalled."${NC}; echo
    
    select yn in "Yes" "No" "Exit"; do
        case $yn in
            "Yes" ) break;;
            "No" ) inputs; exit;;
            "Exit" ) exit;;
        esac
    done

    echo; echo -e ${BLUE_DARK}"Waiting for uninstall to complete..."${NC}
    count=0
    zigbeePass=false
    zwavePass=false
    while [[ ${zigbeePass} = false && ${zwavePass} = false ]]; do
        if [[ ${zigbeePass} = false && "${bindings}" != "Install Z-Wave" ]]; then
            zigbeeCheck=`/usr/bin/curl -s --connect-timeout 10 -m 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zigbee/config"`
            if [ -z "${zigbeeCheck}" ]; then
                zigbeePass=true
            elif [ ${count} -gt 12 ]; then
                echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than a minute to uninstall the Zigbee binding! ${BLINKING}!!!!!${NC}"; echo; echo
                exit
            fi
        else
            zigbeePass=true
        fi
        if [[ ${zwavePass} = false && "${bindings}" != "Install Zigbee" ]]; then
            zwaveCheck=`/usr/bin/curl -s --connect-timeout 10 -m 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zwave/config"`
            if [ -z "${zwaveCheck}" ]; then
                zwavePass=true
            elif [ ${count} -gt 12 ]; then
                echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than a minute to uninstall the Z-Wave binding! ${BLINKING}!!!!!${NC}"; echo; echo
                exit
            fi
        else
            zwavePass=true
        fi
        sleep 5
        ((count++))
    done

    echo; echo -e ${BLUE_DARK}"Backing up any old manual installs and downloading new jars..."${NC}
    current_time=$(date "+%Y%m%d%H%M%S")
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        #curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" "http://localhost:8080/rest/extensions/binding-zigbee/uninstall"
        cd ${ohAddons}
        mkdir -p ${ohAddons}/archive/zigbee
        mv -f *zigbee*.jar ${ohAddons}/archive/zigbee/
        cd ${ohAddons}/archive/zigbee
        rename .jar .${current_time}.old *zigbee*
        mkdir -p ${ohAddons}/archive/staging/zigbee
        cd ${ohAddons}/archive/staging/zigbee
        wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.cc2531-${ohVersion}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.cc2531/artifact/org.openhab.binding/org.openhab.binding.zigbee.cc2531/${ohVersion}-SNAPSHOT/org.openhab.binding.zigbee.cc2531-${ohVersion}-SNAPSHOT.jar
        wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.cc2531-${zsmartVersion}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.cc2531%2F${zsmartVersion}%2Fcom.zsmartsystems.zigbee.dongle.cc2531-${zsmartVersion}.jar
        wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.ember-${ohVersion}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.ember/artifact/org.openhab.binding/org.openhab.binding.zigbee.ember/${ohVersion}-SNAPSHOT/org.openhab.binding.zigbee.ember-${ohVersion}-SNAPSHOT.jar
        wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.ember-${zsmartVersion}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.ember%2F${zsmartVersion}%2Fcom.zsmartsystems.zigbee.dongle.ember-$zsmartVersion.jar
        wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.telegesis-${ohVersion}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.telegesis/artifact/org.openhab.binding/org.openhab.binding.zigbee.telegesis/${ohVersion}-SNAPSHOT/org.openhab.binding.zigbee.telegesis-${ohVersion}-SNAPSHOT.jar
        wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.telegesis-${zsmartVersion}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.telegesis%2F${zsmartVersion}%2Fcom.zsmartsystems.zigbee.dongle.telegesis-${zsmartVersion}.jar
        wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.xbee-${ohVersion}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.xbee/artifact/org.openhab.binding/org.openhab.binding.zigbee.xbee/${ohVersion}-SNAPSHOT/org.openhab.binding.zigbee.xbee-${ohVersion}-SNAPSHOT.jar
        wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.xbee-${zsmartVersion}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.xbee%2F${zsmartVersion}%2Fcom.zsmartsystems.zigbee.dongle.xbee-${zsmartVersion}.jar
        wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee-${zsmartVersion}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee%2F${zsmartVersion}%2Fcom.zsmartsystems.zigbee-${zsmartVersion}.jar
        wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee-${ohVersion}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee/artifact/org.openhab.binding/org.openhab.binding.zigbee/${ohVersion}-SNAPSHOT/org.openhab.binding.zigbee-${ohVersion}-SNAPSHOT.jar
    fi
    if [[ "${bindings}" = "Install Z-Wave" || "${bindings}" = "Install both" ]]; then
        #curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" "http://localhost:8080/rest/extensions/binding-zwave/uninstall"
        cd ${ohAddons}
        mkdir -p ${ohAddons}/archive/zwave
        mv -f *zwave*.jar ${ohAddons}/archive/zwave/
        cd ${ohAddons}/archive/zwave
        rename .jar .${current_time}.old *zwave*
        mkdir -p ${ohAddons}/archive/staging/zwave
        cd ${ohAddons}/archive/staging/zwave
        wget -q --no-use-server-timestamps -O org.openhab.binding.zwave-${ohVersion}-SNAPSHOT.jar http://www.cd-jackson.com/downloads/openhab2/org.openhab.binding.zwave-${ohVersion}-SNAPSHOT.jar
    fi

    echo; echo -e ${BLUE_DARK}"Changing owner and permissions of downloaded jars..."${NC}
    cd ${ohAddons}
    owner=$(stat -c '%U' ./)
    group=$(stat -c '%G' ./)
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        chown ${owner}:${group} ${ohAddons}/archive/staging/zigbee/*.jar
        chmod 644 ${ohAddons}/archive/staging/zigbee/*.jar
    fi
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        chown ${owner}:${group} ${ohAddons}/archive/staging/zwave/*.jar
        chmod 644 ${ohAddons}/archive/staging/zwave/*.jar
    fi
    
    echo; echo -e ${BLUE_DARK}"Startering bindings..."${NC}
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        mv -f ${ohAddons}/archive/staging/zigbee/*.jar ${ohAddons}/
    fi
    if [[ "${bindings}" = "Install Zigbee" || "${bindings}" = "Install both" ]]; then
        mv -f ${ohAddons}/archive/staging/zwave/*.jar ${ohAddons}/
    fi

    echo; echo -e ${BLUE_DARK}"Complete!"${NC}; echo; echo
}

get_addons_path()
{
    echo; echo; echo; echo -e ${GREEN_DARK}"Enter the full path to your addons folder [clear field to exit]"${NC}; echo
    read -e -p "[Use backspace to modify, enter to accept] " -i "/opt/openhab2/addons" ohAddons
    if [ -z "${ohAddons}" ]; then
        exit
    fi
    break
}

start