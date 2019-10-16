#!/usr/bin/env bash
SCRIPT_VERSION=1.2.2

GREY_RED='\033[0;37;41m'
GREEN_DARK='\033[0;32;40m'
BLUE_DARK='\033[1;34;40m'
BLACK_WHITE='\033[0;30;47m'
BLINKING='\033[5;37;41m'
NC='\033[0m' # Reset

SILENT=false
introText() {
    echo; echo "Script version: ${SCRIPT_VERSION}"
    echo; echo -e "${GREEN_DARK}This script is capable of downloading and manually installing the latest development or snapshot builds of the Z-Wave and Zigbee bindings, and/or the openhab-core-io-transport-serial"
    echo "feature. The script must reside inside the addons folder and be executed on the machine running OpenHAB. Before a binding is installed, any previous versions will be"
    echo "uninstalled. Any manually installed versions will also be backed up by moving them to /addons/archive. The installation of any binding will also include the installation"
    echo -e "of the openhab-core-io-transport-serial feature. After using this script, you can uninstall the bindings by deleting their jars from addons, or you can use this script.${NC}"
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, they must be removed from the file or the old version will reinstall ${BLINKING}!!!!!${NC}"
}
for WORD; do
    ARGUMENT=${WORD^^}
    case $ARGUMENT in
        --ACTION)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ACTION=$2
                if [[ "${ACTION,,}" = "zigbee" || "${ACTION,,}" = "zwave" || "${ACTION,,}" = "both" || "${ACTION,,}" = "transport" ]]; then
                    SILENT=true
                    if [[ "${ACTION,,}" = "zigbee" ]]; then
                        ACTION="Install or upgrade Zigbee binding"
                    elif [[ "${ACTION,,}" = "zwave" ]]; then
                        ACTION="Install or upgrade Z-Wave binding"
                    elif [[ "${ACTION,,}" = "both" ]]; then
                        ACTION="Install or upgrade both bindings"
                    elif [[ "${ACTION,,}" = "transport" ]]; then
                        ACTION="Install the openhab-core-io-transport-serial feature"
                    fi
                    shift 2
                    #echo "ACTION=${ACTION}"
                else
                    echo -e "${GREY_RED}ACTION argument specified with invalid value (${ACTION}). Accepted values: zigbee, zwave, both, transport${NC}"
                    echo; exit
                fi
            else
                echo -e "${GREY_RED}ACTION argument specified without a value${NC}"
                echo; exit
            fi;;
        --ZWAVE_VERSION)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZWAVE_VERSION=$2
                ZWAVE_VERSION="${ZWAVE_VERSION,,}"# lower case
                ZWAVE_VERSION="${ZWAVE_VERSION[@]^}"# title case
                if [[ "${ZWAVE_VERSION}" = "Development" || "${ZWAVE_VERSION}" = "Snapshot" ]]; then
                    if [[ "${ZWAVE_VERSION}" = "Snapshot" ]]; then
                        ZWAVE_VERSION="OpenHAB snapshot"
                    fi
                    shift 2
                    #echo "ZWAVE_VERSION=${ZWAVE_VERSION,,}"
                else
                    echo -e "${GREY_RED}ZWAVE_VERSION argument specified with invalid value (${ZWAVE_VERSION}). Accepted values: development, master.${NC}"
                    echo; exit
                fi
            else
                echo -e "${GREY_RED}ZWAVE_VERSION argument specified without a value${NC}"
                echo; exit
            fi;;
        --ZIGBEE_VERSION)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZIGBEE_VERSION=$2
                ZIGBEE_VERSION="${ZIGBEE_VERSION,,}"# lower case
                ZIGBEE_VERSION="${ZIGBEE_VERSION[@]^}"# title case
                if [[ "${ZIGBEE_VERSION}" = "Snapshot" || "${ZIGBEE_VERSION}" = "Release" || "${ZIGBEE_VERSION}" = "Prerelease" ]]; then
                    if [[ "${ZIGBEE_VERSION}" = "Snapshot" ]]; then
                        ZIGBEE_VERSION="OpenHAB baseline (included in OpenHAB snapshot)"
                    elif [[ "${ZIGBEE_VERSION}" = "Release" ]]; then
                        ZIGBEE_VERSION="ZigBee Library release (pre-OpenHAB snapshot)"
                    elif [[ "${ZIGBEE_VERSION}" = "Prerelease" ]]; then
                        ZIGBEE_VERSION="ZigBee Library snapshot (still in development)"
                    fi
                    shift 2
                    #echo "ZIGBEE_VERSION=${ZIGBEE_VERSION,,}"
                else
                    echo -e "${GREY_RED}ZIGBEE_VERSION argument specified with invalid value (${ZIGBEE_VERSION}). Accepted values: snapshot, release, prerelease.${NC}"
                    echo; exit
                fi
            else
                echo -e "${GREY_RED}ZIGBEE_VERSION argument specified without a value${NC}"
                echo; exit
            fi;;
        --LIBRARY_VERSION)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                LIBRARY_VERSION=$2
                shift 2
                #echo "LIBRARY_VERSION=${LIBRARY_VERSION}"
            else
                echo -e "${GREY_RED}LIBRARY_VERSION argument specified without a value${NC}"
                echo; exit
            fi;;
        --HELP)
            introText; echo
            echo -e "${BLUE_DARK}Usage: zzManualInstaller.sh [OPTION]...${NC}"; echo
            echo -e "${BLUE_DARK}If executed without the ACTION argument, menus will be displayed for each option${NC}"; echo
            echo -e "    --ACTION             ${BLUE_DARK}Accepted values: zigbee, zwave, both. Specify which bindings to install/upgrade.${NC}"
            echo -e "    --ZWAVE_VERSION      ${BLUE_DARK}Accepted values: snapshot, development. Default: snapshot. Specify the snapshot or development Z-Wave version.${NC}"
            echo -e "    --ZIGBEE_VERSION     ${BLUE_DARK}Accepted values: snapshot, release, prerelease. Default: snapshot. Specify the snapshot, release, or prerelease Zigbee library version.${NC}"
            echo -e "    --LIBRARY_VERSION    ${BLUE_DARK}Default: latest version, based on choice of ZIGBEE_VERSION. Specify the version of the Zigbee libraries.${NC}"
            echo -e "    --HELP               ${BLUE_DARK}Display this help and exit${NC}"; echo
            echo; exit;;
        --*) echo -e "${GREY_RED}Unrecognized argument: ${WORD}${NC}"
            echo; exit;;
        -*) echo -e "${GREY_RED}Unrecognized argument: ${WORD}${NC}"
            echo; exit;;
    esac
done

SOURCE=${BASH_SOURCE[0]}
while [[ -h ${SOURCE} ]]; do # resolve SOURCE until the file is no longer a symlink
    ADDONS=$( cd -P $( dirname ${SOURCE} ) >/dev/null 2>&1 && pwd )
    SOURCE=$( readlink ${SOURCE} )
    [[ ${SOURCE} != /* ]] && SOURCE=${ADDONS}/${SOURCE} # if SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ADDONS=$( cd -P $( dirname ${SOURCE} ) >/dev/null 2>&1 && pwd )
#echo "DEBUG: ${ADDONS}"

if [ ! -f ../runtime/bin/client ]; then
    echo -e "${GREY_RED}This script must be copied to the \$OPENHAB_HOME/addons directory before running it${NC}"
    echo; exit
fi

install() {
    if [[ !("${ACTION}" =~ "transport") ]]; then
        if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
            if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
                echo; echo -e ${BLUE_DARK}"Installing unmanaged Zigbee binding..."${NC}
                mv -f ${ADDONS}/archive/staging/zigbee/*.jar ${ADDONS}/
            fi
            if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
                echo; echo -e ${BLUE_DARK}"Installing unmanaged Z-Wave binding..."${NC}
                mv -f ${ADDONS}/archive/staging/zwave/*.jar ${ADDONS}/
            fi
        fi
        COUNT=0
        while [[ ${ZIGBEE_UNINSTALLED} = true || ${ZWAVE_UNINSTALLED} = true ]]; do
            if [[ ${ZIGBEE_UNINSTALLED} = true && ("${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both") && "${ACTION}" =~ "Install" ]]; then
                ZIGBEE_CHECK=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zigbee/config")
                if [[ "${ZIGBEE_CHECK}" = "200" ]]; then
                    if [[ "${ACTION}" =~ "both" ]]; then
                        offset="3"
                    else
                        offset="1"
                    fi
                    echo -ne "\033[${offset}A\033[38C done.\033[${offset}B\033[44D"
                    ZIGBEE_UNINSTALLED=false
                #elif [[ ${COUNT} -lt 24 ]]; then
                    #echo "DEBUG: Z-Wave ${ZIGBEE_CHECK}"
                elif [[ ${COUNT} -eq 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to install the Zigbee binding, so exiting ${BLINKING}!!!!!${NC}"; echo
                    exit
                #else
                    #echo "DEBUG: Zigbee wait count: ${COUNT}, ZIGBEE_CHECK=${ZIGBEE_CHECK}"
                fi
            else
                ZIGBEE_UNINSTALLED=false
            fi
            if [[ ${ZWAVE_UNINSTALLED} = true && ("${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both") && "${ACTION}" =~ "Install" ]]; then
                ZWAVE_CHECK=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zwave/config")
                if [[ "${ZWAVE_CHECK}" = "200" ]]; then
                    echo -ne "\033[1A\033[38C done.\033[1B\033[44D"
                    ZWAVE_UNINSTALLED=false
                #elif [[ ${COUNT} -lt 24 ]]; then
                    #echo "DEBUG: Z-Wave ${ZWAVE_CHECK}"
                elif [[ ${COUNT} -eq 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to install the Z-Wave binding, so exiting ${BLINKING}!!!!!${NC}"; echo
                    exit
                #else
                    #echo "DEBUG: Z-Wave wait count: ${COUNT}, ZWAVE_CHECK=${ZWAVE_CHECK}"
                fi
            else
                ZWAVE_UNINSTALLED=false
            fi
            if [[ ${ZIGBEE_UNINSTALLED} = true || ${ZWAVE_UNINSTALLED} = true ]]; then
                sleep 5
                ((COUNT++))
            fi
        done
    fi
    echo; echo -e ${BLUE_DARK}"Complete!"${NC}; echo
    if [[ "${ACTION}" =~ "Install or upgrade Z-Wave" || "${ACTION}" =~ "Install or upgrade both" ]]; then
        echo -e ${GREEN_DARK}"You have installed, upgraded, or downgraded the Z-Wave binding. For first time installations or downgrades to the snapshot or development binding, it is"
                     echo -e "required that all of your Z-Wave Things (except for the controller) be deleted and rediscovered. This does not mean excluding the devices. This is a requirement"
                     echo -e "due to changes in how the Things are defined. This is also recommended when the Z-Wave binding is upgraded, in order to update the Thing definitions for installed devices.${NC}"; echo
    fi
    if [[ "${ACTION}" =~ "Install or upgrade Zigbee" || "${ACTION}" =~ "Install or upgrade both" ]]; then
        echo -e ${GREEN_DARK}"You have installed, upgraded, or downgraded the Zigbee binding. If the binding does not start, you may need to restart openHAB.${NC}"; echo
    fi
    exit
}

download() {
    if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
        if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
            if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
                echo; echo -ne ${BLUE_DARK}"Downloading new Zigbee jars..."${NC}
                mkdir -p ${ADDONS}/archive/staging/zigbee
                cd ${ADDONS}/archive/staging/zigbee

                if [[ "${ZIGBEE_VERSION}" =~ "ZigBee Library snapshot (still in development)" ]]; then
                    FILE_NAME_VERSION1=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.cc2531/${LIBRARY_VERSION}-SNAPSHOT/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.[0-9]+-[0-9]+")
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.cc2531.jar" -L "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.cc2531/${LIBRARY_VERSION}-SNAPSHOT/com.zsmartsystems.zigbee.dongle.cc2531-${FILE_NAME_VERSION1}.jar"
                    FILE_NAME_VERSION2=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.ember/${LIBRARY_VERSION}-SNAPSHOT/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.[0-9]+-[0-9]+")
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.ember.jar" -L "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.ember/${LIBRARY_VERSION}-SNAPSHOT/com.zsmartsystems.zigbee.dongle.ember-${FILE_NAME_VERSION2}.jar"
                    FILE_NAME_VERSION3=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.telegesis/${LIBRARY_VERSION}-SNAPSHOT/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.[0-9]+-[0-9]+")
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.telegesis.jar" -L "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.telegesis/${LIBRARY_VERSION}-SNAPSHOT/com.zsmartsystems.zigbee.dongle.telegesis-${FILE_NAME_VERSION3}.jar"
                    FILE_NAME_VERSION4=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.xbee/${LIBRARY_VERSION}-SNAPSHOT/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.[0-9]+-[0-9]+")
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.xbee.jar" -L "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.xbee/${LIBRARY_VERSION}-SNAPSHOT/com.zsmartsystems.zigbee.dongle.xbee-${FILE_NAME_VERSION4}.jar"
                    FILE_NAME_VERSION5=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee/${LIBRARY_VERSION}-SNAPSHOT/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.[0-9]+-[0-9]+")
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.jar" -L "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee/${LIBRARY_VERSION}-SNAPSHOT/com.zsmartsystems.zigbee-${FILE_NAME_VERSION5}.jar"
                else
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.cc2531.jar" -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.cc2531/${LIBRARY_VERSION}/com.zsmartsystems.zigbee.dongle.cc2531-${LIBRARY_VERSION}.jar"
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.ember.jar" -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.ember/${LIBRARY_VERSION}/com.zsmartsystems.zigbee.dongle.ember-${LIBRARY_VERSION}.jar"
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.telegesis.jar" -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.telegesis/${LIBRARY_VERSION}/com.zsmartsystems.zigbee.dongle.telegesis-${LIBRARY_VERSION}.jar"
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.dongle.xbee.jar" -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.xbee/${LIBRARY_VERSION}/com.zsmartsystems.zigbee.dongle.xbee-${LIBRARY_VERSION}.jar"
                    curl -s --connect-timeout 10 --max-time 60 -o "com.zsmartsystems.zigbee.jar" -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee/${LIBRARY_VERSION}/com.zsmartsystems.zigbee-${LIBRARY_VERSION}.jar"
                fi
                curl -s --connect-timeout 10 --max-time 60 -o "org.openhab.binding.zigbee.cc2531.jar" -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zigbee/org.openhab.binding.zigbee.cc2531/target/org.openhab.binding.zigbee.cc2531-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -o "org.openhab.binding.zigbee.ember.jar" -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zigbee/org.openhab.binding.zigbee.ember/target/org.openhab.binding.zigbee.ember-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -o "org.openhab.binding.zigbee.telegesis.jar" -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zigbee/org.openhab.binding.zigbee.telegesis/target/org.openhab.binding.zigbee.telegesis-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -o "org.openhab.binding.zigbee.xbee.jar" -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zigbee/org.openhab.binding.zigbee.xbee/target/org.openhab.binding.zigbee.xbee-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -o "org.openhab.binding.zigbee.jar" -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zigbee/org.openhab.binding.zigbee/target/org.openhab.binding.zigbee-${OH_VERSION}-SNAPSHOT.jar"
                echo " done."
            fi
        fi
        if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
            echo; echo -ne ${BLUE_DARK}"Downloading new Z-Wave jar..."${NC}
            mkdir -p ${ADDONS}/archive/staging/zwave
            cd ${ADDONS}/archive/staging/zwave
            if [[ "${ZWAVE_VERSION}" = "Development" ]]; then
                curl -s --connect-timeout 10 --max-time 60 -O -L "http://www.cd-jackson.com/downloads/openhab2/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar"
            else
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/artifact/bindings/org.openhab.binding.zwave/target/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar"
            fi
            echo " done."
        fi
        curl -s --connect-timeout 10 --max-time 60 -O -L "http://central.maven.org/maven2/org/apache/servicemix/bundles/org.apache.servicemix.bundles.xstream/1.4.7_1/org.apache.servicemix.bundles.xstream-1.4.7_1.jar"
    fi
    install
}

uninstall() {
    if [[ !("${ACTION}" =~ "transport") ]]; then
        current_time=$(date "+%Y%m%d%H%M%S")
        if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
            echo; echo -e ${BLUE_DARK}"Backing up and uninstalling any unmanaged installs of Zigbee..."${NC}
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zigbee
            if [[ 0 -lt $(ls *zigbee*.jar 2>/dev/null | wc -w) ]]; then
                for file in *zigbee*.jar; do
                    mv -f "${file}" "${ADDONS}/archive/zigbee/${file%.jar}.${current_time}.old"
                done
            fi
        fi
        if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
            echo; echo -e ${BLUE_DARK}"Backing up and uninstalling any unmanaged installs of Z-Wave..."${NC}
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zwave
            if [[ 0 -lt $(ls *zwave*.jar 2>/dev/null | wc -w) ]]; then
                for file in *zwave*.jar; do
                    mv -f "${file}" "${ADDONS}/archive/zwave/${file%.jar}.${current_time}.old"
                done
            fi
        fi
        COUNT=0
        ZIGBEE_UNINSTALLED=false
        ZWAVE_UNINSTALLED=false
        while [[ ${ZIGBEE_UNINSTALLED} = false || ${ZWAVE_UNINSTALLED} = false ]]; do
            if [[ ${ZIGBEE_UNINSTALLED} = false && ("${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both") ]]; then
                ZIGBEE_CHECK=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zigbee/config")
                if [[ "${ZIGBEE_CHECK}" = "404" ]]; then
                    if [[ "${ACTION}" =~ "both" ]]; then
                        offset="3"
                    else
                        offset="1"
                    fi
                    echo -ne "\033[${offset}A\033[63C done.\033[${offset}B\033[69D"
                    ZIGBEE_UNINSTALLED=true
                #elif [[ ${COUNT} -lt 24 ]]; then
                    #echo "DEBUG: Zigbee ${ZIGBEE_CHECK}"
                elif [[ ${COUNT} -eq 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to uninstall the Zigbee binding, so exiting ${BLINKING}!!!!!${NC}"; echo
                    exit
                #else
                    #echo "DEBUG: Zigbee wait count: ${COUNT}, ZIGBEE_CHECK=${ZIGBEE_CHECK}"
                fi
            else
                ZIGBEE_UNINSTALLED=true
            fi
            if [[ ${ZWAVE_UNINSTALLED} = false && ("${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both") ]]; then
                ZWAVE_CHECK=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zwave/config")
                if [[ "${ZWAVE_CHECK}" = "404" ]]; then
                    echo -ne "\033[1A\033[63C done.\033[1B\033[69D"
                    ZWAVE_UNINSTALLED=true
                #elif [[ ${COUNT} -lt 24 ]]; then
                    #echo "DEBUG: Z-Wave ${ZWAVE_CHECK}"
                elif [[ ${COUNT} -eq 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to uninstall the Z-Wave binding, so exiting ${BLINKING}!!!!!${NC}"; echo
                    exit
                #else
                    #echo "DEBUG: Z-Wave wait count: ${COUNT}, ZWAVE_CHECK=${ZWAVE_CHECK}"
                fi
            else
                ZWAVE_UNINSTALLED=true
            fi
            if [[ ${ZIGBEE_UNINSTALLED} = false || ${ZWAVE_UNINSTALLED} = false ]]; then
                sleep 5
                ((COUNT++))
            fi
        done
        if [[ "${ACTION}" =~ "Uninstall" ]]; then
            echo; echo -e ${GREEN_DARK}"If the xstream jar is no longer required by any of your other manually installed bindings, you can remove it"${NC}
        fi
    fi
    download
}

karaf() {
    KARAF_FUNCTION=""
    if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
        KARAF_FUNCTION="bundle:uninstall com.zsmartsystems.zigbee;
                        bundle:uninstall com.zsmartsystems.zigbee.dongle.cc2531;
                        bundle:uninstall com.zsmartsystems.zigbee.dongle.ember;
                        bundle:uninstall com.zsmartsystems.zigbee.dongle.telegesis;
                        bundle:uninstall com.zsmartsystems.zigbee.dongle.xbee;
                        bundle:uninstall org.openhab.binding.zigbee;
                        bundle:uninstall org.openhab.binding.zigbee.cc2531;
                        bundle:uninstall org.openhab.binding.zigbee.ember;
                        bundle:uninstall org.openhab.binding.zigbee.telegesis;
                        bundle:uninstall org.openhab.binding.zigbee.xbee;"
    fi
    if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
        KARAF_FUNCTION="${KARAF_FUNCTION}
            bundle:uninstall org.openhab.binding.zwave;"
    fi
    if [[ "${ACTION}" =~ "Install" ]]; then
        KARAF_FUNCTION="${KARAF_FUNCTION}
            feature:install openhab-transport-serial;"
    fi
    #echo "DEBUG: ${KARAF_FUNCTION}"
    if [[ "${ACTION}" =~ "transport" ]]; then
        echo; echo -e ${BLUE_DARK}"Installing serial transport..."${NC}
    elif [[ "${ACTION}" =~ "Install" ]]; then
        echo; echo -e ${BLUE_DARK}"Uninstalling any managed binding(s) and installing serial transport..."${NC}
    else
        echo; echo -e ${BLUE_DARK}"Uninstalling any managed binding(s)..."${NC}
    fi
    #ssh -p 8101 -o StrictHostKeyChecking=no -l ${KARAF_ACCOUNT} localhost ${KARAF_FUNCTION}
    # invoke the client command since we are running on localhost
    cd ${ADDONS}
    if [[ -f "/usr/bin/openhab-cli" ]]; then
        /usr/bin/openhab-cli console ${KARAF_FUNCTION} --
    else
        ../runtime/bin/client ${KARAF_FUNCTION} --
    fi
    if [[ !("${ACTION}" =~ "transport") ]]; then
        echo -e ${GREEN_DARK}"... a 'No matching bundles' error mesage is normal, if a binding had not been previously installed.${NC}"
    fi
    uninstall
}

summary() {
    if [[ ${SILENT} = false ]]; then
        clear;
    fi
    echo; echo -e "     ${BLACK_WHITE}*****     SUMMARY     *****${NC}     "; echo
    echo -e "${GREEN_DARK}Addons path:${NC} ${ADDONS}"
    echo -e "${GREEN_DARK}OpenHAB account:${NC} ${CURRENT_ACCOUNT}"
    echo -e "${GREEN_DARK}Requested action:${NC} ${ACTION}"
    if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
        echo -e "${GREEN_DARK}Current OpenHAB snapshot version:${NC} ${OH_VERSION}"
    fi
    if [[ ${ACTION} = "Install or upgrade Z-Wave binding" || ${ACTION} = "Install or upgrade both bindings" ]]; then
        echo -e "${GREEN_DARK}Requested Z-Wave version:${NC} ${ZWAVE_VERSION}"
    fi
    if [[ ${ACTION} = "Install or upgrade Zigbee binding" || ${ACTION} = "Install or upgrade both bindings" ]]; then
        echo -e "${GREEN_DARK}Requested Zigbee version:${NC} ${ZIGBEE_VERSION}"
        echo -e "${GREEN_DARK}Requested Zigbee library version:${NC} ${LIBRARY_VERSION}"
    fi
    if [[ ${SILENT} = false ]]; then
        echo; echo -e "${GREEN_DARK}Is this correct?"${NC}
        select choice in "Yes, start now" "No, take me back to the first menu" "Exit"; do
            case $choice in
                "Yes, start now" ) break;;
                "No, take me back to the first menu" ) menu; break;;
                "Exit" ) exit; break;;
            esac
        done
    fi
    karaf
}

versions() {
    if [[ ${SILENT} = false ]]; then
        if [[ "${ACTION}" = "Install or upgrade Z-Wave binding" || "${ACTION}" = "Install or upgrade both bindings" ]]; then
            echo; echo; echo -e "Z-Wave binding: ${GREEN_DARK}Would you like to download the OpenHAB snapshot or development version?${NC}"
                        echo -e "${BLINKING}!!!!!${GREY_RED} DO NOT select 'Development' unless Chris has specifically instructed you to do so ${BLINKING}!!!!!${NC}"
            select ZWAVE_VERSION in "OpenHAB snapshot" "Development" "Exit"; do
                case $ZWAVE_VERSION in
                    "OpenHAB snapshot" ) break;;
                    "Development" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi
    elif [[ -z "${ZWAVE_VERSION}" ]]; then # not specified as an argument
        ZWAVE_VERSION="OpenHAB snapshot"
    fi

    if [[ ${SILENT} = false ]]; then
        if [[ "${ACTION}" = "Install or upgrade Zigbee binding" || "${ACTION}" = "Install or upgrade both bindings" ]]; then
            echo; echo; echo -e "Zigbee binding: ${GREEN_DARK}The OpenHAB snapshot binding will be downloaded, but Which libraries would you like to use?${NC}"
                        echo -e "${BLINKING}!!!!!${GREY_RED} DO NOT select 'ZigBee Library snapshot' unless Chris has specifically instructed you to do so ${BLINKING}!!!!!${NC}"
            select ZIGBEE_VERSION in "OpenHAB baseline (included in OpenHAB snapshot)" "ZigBee Library release (pre-OpenHAB snapshot)" "ZigBee Library snapshot (still in development)" "Exit"; do
                case $ZIGBEE_VERSION in
                    "OpenHAB baseline (included in OpenHAB snapshot)" ) break;;
                    "ZigBee Library release (pre-OpenHAB snapshot)" ) break;;
                    "ZigBee Library snapshot (still in development)" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi
    elif [[ -z "${ZIGBEE_VERSION}" ]]; then # not specified as an argument
        ZIGBEE_VERSION="OpenHAB baseline (included in OpenHAB snapshot)"
    fi

    if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
        #OH_VERSION=$(wget -nv -q -O- "https://ci.openhab.org/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding$org.openhab.binding.zigbee/console" | grep -a "Building ZigBee Binding" | grep -aoP "[0-9].*[0-9]")
        OH_VERSION=$(curl -s --connect-timeout 10 --max-time 10 "https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/console" | grep -a "Building openHAB" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+")

    fi

    if [[ -z "${LIBRARY_VERSION}" && ("${ACTION}" = "Install or upgrade Zigbee binding" || "${ACTION}" = "Install or upgrade both bindings") ]]; then
        if [[ "${ZIGBEE_VERSION}" = "OpenHAB baseline (included in OpenHAB snapshot)" ]]; then
            LIBRARY_VERSION=$(curl -s --connect-timeout 10 --max-time 10 "https://raw.githubusercontent.com/openhab/openhab-distro/master/features/addons/src/main/feature/feature.xml" | grep -a "com.zsmartsystems.zigbee.dongle.ember" | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")
        elif [[ "${ZIGBEE_VERSION}" = "ZigBee Library release (pre-OpenHAB snapshot)" ]]; then
            #LIBRARY_VERSION=$(wget -nv -q -O- "https://bintray.com/zsmartsystems/com.zsmartsystems/zigbee/_latestVersion" | grep -oP "[0-9].*[0-9]$")
            LIBRARY_VERSION=$(curl -Ls --connect-timeout 10 --max-time 10 -o /dev/null -w %{url_effective} "https://bintray.com/zsmartsystems/com.zsmartsystems/zigbee/_latestVersion" | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")
        else
            LIBRARY_VERSION=$(curl -s --connect-timeout 10 --max-time 10 "https://oss.jfrog.org/artifactory/oss-snapshot-local/com/zsmartsystems/zigbee/maven-metadata.xml" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+")
        fi
        if [[ ${SILENT} = false && "${ZIGBEE_VERSION}" != "OpenHAB baseline (included in OpenHAB snapshot)" ]]; then
            echo; echo; echo -e "${GREEN_DARK}Note: the pre-OpenHAB snapshot Zigbee libraries may not yet be compatible with the current openHAB snapshot Zigbee binding"
                        echo -e "or bridges. Enter the requested version of the Zigbee libraries [clear field to exit]${NC}"
            read -e -p "[Use backspace to modify, enter to accept. The latest version is ${LIBRARY_VERSION}.] " -i "${LIBRARY_VERSION}" LIBRARY_VERSION
            if [[ -z "${LIBRARY_VERSION}" ]]; then
                exit
            fi
        fi
    fi
    summary
}

addonsCfgCheck() {
    if [[ ${SILENT} = false ]]; then
        if [[ "${ACTION}" =~ "Uninstall" || "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" || "${ACTION}" =~ "Z-Wave" ]]; then
            APTGET="/etc/openhab2/services/addons.cfg"
            MANUAL="../conf/services/addons.cfg"
            if [[ -f ${APTGET} ]]; then
                ADDONSCFG=${APTGET}
            elif [[ -f ${MANUAL} ]]; then
                ADDONSCFG=${MANUAL}
            fi
            if [[ -n ${ADDONSCFG} ]]; then
                binding=`grep "^binding" ${ADDONSCFG}`
                if [[ "${binding}" =~ "zwave" && ("${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both") ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} You must remove the Z-Wave binding from the 'binding' line in ${ADDONSCFG} ${BLINKING}!!!!!${NC}"; echo
                    exit
                elif [[ "${binding}" =~ "zigbee" && ("${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both") ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} You must remove the Zigbee binding from the 'binding' line in ${ADDONSCFG} ${BLINKING}!!!!!${NC}"; echo
                    exit
                fi
            fi
        fi
    fi
    versions
}

menu() {
    CURRENT_ACCOUNT=$(whoami)
    if [[ ${SILENT} = false ]]; then
        clear
        if [[ "${CURRENT_ACCOUNT}" != "openhab" ]]; then
            echo; echo -e "${BLINKING}!!!!!${GREY_RED} This script MUST be executed by the account that runs openHAB, typically 'openhab' ${BLINKING}!!!!!${NC}"
            select choice in "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" "Exit"; do
                case $choice in
                    "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi

        introText
        echo; echo -e "${GREEN_DARK}What would you like to do?${NC}"
        select ACTION in "Install or upgrade Zigbee binding" "Install or upgrade Z-Wave binding" "Install or upgrade both bindings" "Install serial transport" "Uninstall Zigbee binding" "Uninstall Z-Wave binding" "Uninstall both bindings" "Exit"; do
            case $ACTION in
                "Install or upgrade Zigbee binding" ) break;;
                "Install or upgrade Z-Wave binding" ) break;;
                "Install or upgrade both bindings" ) break;;
                "Install serial transport" ) break;;
                "Uninstall Zigbee binding" ) break;;
                "Uninstall Z-Wave binding" ) break;;
                "Uninstall both bindings" ) break;;
                "Exit" ) echo; exit;;
            esac
        done

    fi
    addonsCfgCheck
}

updateScript() {
    mkdir -p ${ADDONS}/archive/openhab-utils
    cd ${ADDONS}/archive/openhab-utils
    curl -s --connect-timeout 10 --max-time 60 -o ${1}.zip -L "https://github.com/openhab-5iver/openHAB-utils/archive/${1}.zip"
    unzip -p ${ADDONS}/archive/openhab-utils/$1.zip "openHAB-utils-${1}/Zigbee and Z-Wave manual install/addons/zzManualInstaller.sh" > ${ADDONS}/zzManualInstaller.sh
    cd ${ADDONS}
    exec "${ADDONS}/zzManualInstaller.sh"
}

versionCheck() {
    if [[ ${SILENT} = false ]]; then
        CURRENT_RELEASE=$(curl -s --connect-timeout 10 --max-time 10 "https://github.com/openhab-5iver/openHAB-utils/releases/latest" | grep -aoP -m1 "[0-9]+\.[0-9]+\.[0-9]+")
        if [[ -z ${CURRENT_RELEASE} || "${SCRIPT_VERSION}" = "${CURRENT_RELEASE}" ]]; then
            menu
        else
            clear;
            echo; echo "Script version:  ${SCRIPT_VERSION}"
            echo "Current release: ${CURRENT_RELEASE}"
            echo; echo -e "${BLINKING}!!!!!${GREY_RED} There is a newer version of the script available ${BLINKING}!!!!!${NC}"
            select choice in "Upgrade script" "Do not upgrade script" "Exit"; do
                case $choice in
                    "Upgrade script" ) updateScript ${CURRENT_RELEASE}; break;;
                    "Do not upgrade script" ) menu;;
                    "Exit" ) exit; break;;
                esac
            done
        fi
    else
        menu
    fi
}

versionCheck
