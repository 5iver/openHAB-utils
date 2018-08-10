#!/bin/bash
for WORD; do
    case $WORD in
        --ACTION) #echo "split arg Option (with space)"
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ACTION=$2
                shift 2
                #echo "arg present"
                #echo "ACCOUNT=${ACCOUNT}, with space"
            else
                echo "ACTION argument specified, but left blank"
                exit
            fi;;
        --ACCOUNT) #echo "split arg Option (with space)"
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ACCOUNT=$2
                shift 2
                #echo "arg present"
                #echo "ACCOUNT=${ACCOUNT}, with space"
            else
                echo "ACCOUNT argument specified, but left blank"
                exit
            fi;;
        --OH_VERSION) #echo "split arg Option (with space)"
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                OH_VERSION=$2
                shift 2
                #echo "arg present"
                #echo "ACCOUNT=${ACCOUNT}, with space"
            else
                echo "OH_VERSION argument specified, but left blank"
                exit
            fi ;;
        --ZSMARTSYSTEMS_VERSION) #echo "split arg Option (with space)"
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZSMARTSYSTEMS_VERSION=$2
                shift 2
                #echo "arg present"
                #echo "ACCOUNT=${ACCOUNT}, with space"
            else
                echo "ZSMARTSYSTEMS_VERSION argument specified, but left blank"
                exit
            fi;;
        --*) #echo "Unrecognized Short Option"
            echo "Unrecognized argument: ${WORD}"
            exit ;;
        -*) #echo "Unrecognized Short Option"
            echo "Unrecognized argument: ${WORD}"
            exit #;;
        #*) #echo "Unrecognized Short Option"
            #echo "Unrecognized argument: ${WORD}"
            #exit
        ;;
    esac
done

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve SOURCE until the file is no longer a symlink
    ADDONS="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$ADDONS/$SOURCE" # if SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ADDONS="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"

GREY_RED='\033[0;37;41m'
GREEN_DARK='\033[0;32;40m'
BLUE_DARK='\033[1;34;40m'
BLACK_WHITE='\033[0;30;47m'
BLINKING='\033[5;37;41m'
NC='\033[0m' # Reset

installUninstall() {
    if [[ !("${ACTION}" =~ "transport") ]]; then
        echo; echo -e ${BLUE_DARK}"Waiting for the uninstallation of previous versions to complete..."${NC}
        COUNT=0
        ZIGBEE_UNINSTALLED=false
        ZWAVE_UNINSTALLED=false
        while [[ ${ZIGBEE_UNINSTALLED} = false && ${ZWAVE_UNINSTALLED} = false ]]; do
            if [[ ${ZIGBEE_UNINSTALLED} = false && !("${ACTION}" =~ "Z-Wave") ]]; then
                ZIGBEE_CHECK=`/usr/bin/curl -s --connect-timeout 10 -m 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zigbee/config"`
                if [[ "${ZIGBEE_CHECK}" = "{}" || -z "${ZIGBEE_CHECK}" ]]; then
                    ZIGBEE_UNINSTALLED=true
                elif [ ${COUNT} -gt 24 ]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than a minute to uninstall the Zigbee binding, so exiting! ${BLINKING}!!!!!${NC}"; echo; echo
                    exit
                else
                    echo -e "Debug: Zigbee wait count: ${COUNT}, ZIGBEE_CHECK=${ZIGBEE_CHECK}"
                fi
            else
                ZIGBEE_UNINSTALLED=true
            fi
            if [[ ${ZWAVE_UNINSTALLED} = false && !("${ACTION}" =~ "Zigbee") ]]; then
                ZWAVE_CHECK=`/usr/bin/curl -s --connect-timeout 10 -m 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zwave/config"`
                if [[ "${ZWAVE_CHECK}" = "{}" || -z "${ZWAVE_CHECK}" ]]; then
                    ZWAVE_UNINSTALLED=true
                elif [ ${COUNT} -gt 24 ]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than a minute to uninstall the Z-Wave binding, so exiting! ${BLINKING}!!!!!${NC}"; echo; echo
                    exit
                else
                    echo -e "Debug: Zwave wait count: ${COUNT}, ZWAVE_CHECK=${ZWAVE_CHECK}"
                fi
            else
                ZWAVE_UNINSTALLED=true
            fi
            sleep 5
            ((COUNT++))
        done

        echo; echo -e ${BLUE_DARK}"Backing up any old manual installs and downloading new jars..."${NC}
        current_time=$(date "+%Y%m%d%H%M%S")
        if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
            #curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" "http://localhost:8080/rest/extensions/binding-zigbee/uninstall"
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zigbee
            if [ 0 -lt $(ls *zigbee*.jar 2>/dev/null | wc -w) ]; then
                mv -f *zigbee*.jar ${ADDONS}/archive/zigbee/
            fi
            cd ${ADDONS}/archive/zigbee
            rename .jar .${current_time}.old *zigbee*
            if [[ "${ACTION}" =~ "Install" ]]; then
                mkdir -p ${ADDONS}/archive/staging/zigbee
                cd ${ADDONS}/archive/staging/zigbee
                wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.cc2531-${OH_VERSION}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.cc2531/artifact/org.openhab.binding/org.openhab.binding.zigbee.cc2531/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.cc2531-${OH_VERSION}-SNAPSHOT.jar
                wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.cc2531-${ZSMARTSYSTEMS_VERSION}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.cc2531%2F${ZSMARTSYSTEMS_VERSION}%2Fcom.zsmartsystems.zigbee.dongle.cc2531-${ZSMARTSYSTEMS_VERSION}.jar
                wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.ember-${OH_VERSION}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.ember/artifact/org.openhab.binding/org.openhab.binding.zigbee.ember/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.ember-${OH_VERSION}-SNAPSHOT.jar
                wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.ember-${ZSMARTSYSTEMS_VERSION}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.ember%2F${ZSMARTSYSTEMS_VERSION}%2Fcom.zsmartsystems.zigbee.dongle.ember-$ZSMARTSYSTEMS_VERSION.jar
                wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.telegesis-${OH_VERSION}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.telegesis/artifact/org.openhab.binding/org.openhab.binding.zigbee.telegesis/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.telegesis-${OH_VERSION}-SNAPSHOT.jar
                wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.telegesis-${ZSMARTSYSTEMS_VERSION}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.telegesis%2F${ZSMARTSYSTEMS_VERSION}%2Fcom.zsmartsystems.zigbee.dongle.telegesis-${ZSMARTSYSTEMS_VERSION}.jar
                wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee.xbee-${OH_VERSION}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.xbee/artifact/org.openhab.binding/org.openhab.binding.zigbee.xbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.xbee-${OH_VERSION}-SNAPSHOT.jar
                wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee.dongle.xbee-${ZSMARTSYSTEMS_VERSION}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee.dongle.xbee%2F${ZSMARTSYSTEMS_VERSION}%2Fcom.zsmartsystems.zigbee.dongle.xbee-${ZSMARTSYSTEMS_VERSION}.jar
                wget -q --no-use-server-timestamps -O com.zsmartsystems.zigbee-${ZSMARTSYSTEMS_VERSION}.jar https://bintray.com/zsmartsystems/com.zsmartsystems/download_file?file_path=com%2Fzsmartsystems%2Fzigbee%2Fcom.zsmartsystems.zigbee%2F${ZSMARTSYSTEMS_VERSION}%2Fcom.zsmartsystems.zigbee-${ZSMARTSYSTEMS_VERSION}.jar
                wget -q --no-use-server-timestamps -O org.openhab.binding.zigbee-${OH_VERSION}-SNAPSHOT.jar https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee/artifact/org.openhab.binding/org.openhab.binding.zigbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee-${OH_VERSION}-SNAPSHOT.jar
            fi
        fi
        if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
            #curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" "http://localhost:8080/rest/extensions/binding-zwave/uninstall"
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zwave
            if [ 0 -lt $(ls *zwave*.jar 2>/dev/null | wc -w) ]; then
                mv -f *zwave*.jar ${ADDONS}/archive/zwave/
            fi
            cd ${ADDONS}/archive/zwave
            rename .jar .${current_time}.old *zwave*
            if [[ "${ACTION}" =~ "Install" ]]; then
                mkdir -p ${ADDONS}/archive/staging/zwave
                cd ${ADDONS}/archive/staging/zwave
                wget -q --no-use-server-timestamps -O org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar http://www.cd-jackson.com/downloads/openhab2/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar
            fi
        fi
        #if [[ "${ACTION}" = "Install development Zigbee" || "${ACTION}" = "Install development Z-Wave" || "${ACTION}" = "Install both" ]]; then
        #    echo; echo -e ${BLUE_DARK}"Changing owner and permissions of downloaded jars..."${NC}
        #    cd ${ADDONS}
        #    owner=$(stat -c '%U' ./)
        #    group=$(stat -c '%G' ./)
        #fi
        #if [[ "${ACTION}" = "Install development Zigbee" || "${ACTION}" = "Install both" ]]; then
        #    chown ${owner}:${group} ${ADDONS}/archive/staging/zigbee/*.jar
        #    chmod 644 ${ADDONS}/archive/staging/zigbee/*.jar
        #fi
        #if [[ "${ACTION}" = "Install development Zigbee" || "${ACTION}" = "Install both" ]]; then
        #    chown ${owner}:${group} ${ADDONS}/archive/staging/zwave/*.jar
        #    chmod 644 ${ADDONS}/archive/staging/zwave/*.jar
        #fi
        if [[ "${ACTION}" =~ "Install" ]]; then
            echo; echo -e ${BLUE_DARK}"Starting bindings..."${NC}
            if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
                mv -f ${ADDONS}/archive/staging/zigbee/*.jar ${ADDONS}/
            fi
            if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
                mv -f ${ADDONS}/archive/staging/zwave/*.jar ${ADDONS}/
            fi
        fi
    fi
    echo; echo -e ${BLUE_DARK}"Complete!"${NC}; echo; echo; exit
}

changeOHAccount() {
    echo; echo; echo -e ${GREEN_DARK}"Enter the modified Karaf account name (case sensitive)"${NC}; echo
    read -e -p "[Use backspace to modify, enter to accept] " ACCOUNT
    if [ -z "${ACCOUNT}" ]; then
        exit
    fi
    break
}

karaf() {
    KARAF_FUNCTION=""
    if [ -z "${ACCOUNT}" ]; then
        echo; echo; echo -e ${GREEN_DARK}"This script will connect to Karaf via SSH to uninstall duplicate bindings and/or install openhab-serial-transport. If you have changed the default Karaf"
                            echo -e "SSH username, choose 'Change Account'. You will be prompted for the password when the script establishes the SSH session, unless the Karaf SSH server's public"
                            echo -e "key has already been added to the OH account's list of known hosts. The first time the script is run, if it is the first time establishing an SSH session to Karaf"
                            echo -e "from your OH server, you will be prompted with a warning that it is being permanently added to known hosts. The default account:password is ${NC}openhab${GREEN_DARK}:${NC}habopen${GREEN_DARK}."${NC}; echo
        select yn in "Continue" "Change Account" "Exit"; do
            case $yn in
                "Continue" ) ACCOUNT="openhab"; break;;
                "Change Account" ) changeOHAccount; break;;
                "Exit" ) exit;;
            esac
        done
    fi
    if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
        KARAF_FUNCTION="
        bundle:uninstall com.zsmartsystems.zigbee;
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
        KARAF_FUNCTION="${KARAF_FUNCTION} bundle:uninstall org.openhab.binding.zwave;"
    fi
    if [[ "${ACTION}" =~ "Install" ]]; then
        KARAF_FUNCTION="${KARAF_FUNCTION} feature:install openhab-transport-serial;"
    fi
    KARAF_FUNCTION="${KARAF_FUNCTION} logout"
    #echo $KARAF_FUNCTION
    if [[ "${ACTION}" =~ "transport" ]]; then
        echo; echo -e ${BLUE_DARK}"Installing openhab-serial-transport..."${NC}
    elif [[ "${ACTION}" =~ "Install" ]]; then
        echo; echo -e ${BLUE_DARK}"Uninstalling binding(s) and installing openhab-serial-transport..."${NC}
    else
        echo; echo -e ${BLUE_DARK}"Uninstalling binding(s)..."${NC}
    fi
    ssh -p 8101 -o StrictHostKeyChecking=no -l ${ACCOUNT} localhost ${KARAF_FUNCTION}
    installUninstall
}

summary() {
    clear; echo; echo; echo -e "     ${BLACK_WHITE}*****     SUMMARY     *****${NC}     "; echo
    echo -e ${GREEN_DARK}"Addons path: "${NC}${ADDONS}
    echo -e ${GREEN_DARK}"Current OH snapshot version: "${NC}${OH_VERSION}
    if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
        echo -e ${GREEN_DARK}"ZSmartSystems library version: "${NC}${ZSMARTSYSTEMS_VERSION}
    fi
    echo; echo -e ${GREEN_DARK}"Is this correct?"${NC}; echo
    select yn in "Yes" "No" "Exit"; do
        case $yn in
            "Yes" ) break;;
            "No" ) versions; break;;
            "Exit" ) exit;;
        esac
    done
    karaf
}

versions() {
    echo; echo; echo -e ${GREEN_DARK}"Enter the current OH snapshot version [clear field to exit]"${NC}; echo
    read -e -p "[Use backspace to modify, enter to accept] " -i "2.4.0" OH_VERSION
    if [ -z "${OH_VERSION}" ]; then
        exit
    fi

    if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
        echo; echo; echo -e ${GREEN_DARK}"Enter the requested version of ZSmartSystems libraries [clear field to exit]"${NC}; echo
        read -e -p "[Use backspace to modify, enter to accept] " -i "1.0.14" ZSMARTSYSTEMS_VERSION
        if [ -z "${ZSMARTSYSTEMS_VERSION}" ]; then
            exit
        fi
    fi
    summary
}

menu() {
    clear
    if [[ -n "${OH_VERSION}" || -n "${ZSMARTSYSTEMS_VERSION}" || -n "${ACTION}" || -n "${ACCOUNT}" ]]; then
        echo; echo -e ${BLUE_DARK}"Script started with arguments, but one or more were missing or invalid"${NC}; echo
    fi
    CURRENT_ACCOUNT=$(whoami)
    if [ "${CURRENT_ACCOUNT}" != "root" ] && [ "${CURRENT_ACCOUNT}" != "openhab" ] && [ "${CURRENT_ACCOUNT}" != "openhabian" ]; then
    #if [ "${CURRENT_ACCOUNT}" != "root" ]; then
        #echo; echo; echo; echo; echo; echo -e ${DARK_RED}"This script must be run under the root, openhab or openhabian account!"; echo -e ${NC}; exit
        echo; echo; echo; echo -e "${BLINKING}!!!!!${GREY_RED} This script MUST be run under the account that runs openHAB! Typically root, openhab or openhabian. ${BLINKING}!!!!!${NC}"; echo; echo
        select yn in "Continue (this is my openHAB account)" "Exit"; do
            case $yn in
                "Continue (${CURRENT_ACCOUNT} is my openHAB account)" ) break;;
                "Exit" ) exit;;
            esac
        done
    fi

    echo; echo; echo -e ${GREEN_DARK}"This script is capable of downloading and manually installing the latest development Zwave and Zigbee bindings, which are not yet available in"
                                echo "the snapshot builds. The script must reside inside the addons folder and be executed on the machine running OH. Before installing the development"
                                echo "version of a binding, any versions installed through PaperUI or Habmin will be uninstalled. Any manually installed versions will be backed up by moving"
                                echo "them to /addons/archive. The installation of any binding will include the installation of the serial transport and the uninstallation of any previous"
                                echo "version of the binding. After installing the development version of the bindings, you can uninstall them by deleting their jars from /addons."
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, Exit and remove them from the file or the old version will reinstall! ${BLINKING}!!!!!${NC}"
    echo; echo -e ${GREEN_DARK}"What would you like to do?"${NC}
    select ACTION in "Install or upgrade development Zigbee" "Install or upgrade development Z-Wave" "Install or upgrade both" "Install serial transport" "Backup and uninstall development Zigbee" "Backup and uninstall development Z-Wave" "Backup and uninstall both" "Exit"; do
        case $ACTION in
            "Install or upgrade development Zigbee" ) versions; break;;
            "Install or upgrade development Z-Wave" ) versions; break;;
            "Install or upgrade both" ) versions; break;;
            "Install serial transport" ) karaf; break;;
            "Backup and uninstall development Zigbee" ) karaf; break;;
            "Backup and uninstall development Z-Wave" ) karaf; break;;
            "Backup and uninstall both" ) karaf; break;;
            "Exit" ) exit;;
        esac
    done
}

# validate arguments
if [ "${ACTION,,}" = "zigbee" ]; then
    ACTION="Install or upgrade development Zigbee"
elif [ "${ACTION,,}" = "zwave" ]; then
    ACTION="Install or upgrade development Z-Wave"
elif [ "${ACTION,,}" = "both" ]; then
    ACTION="Install or upgrade both"
fi

if [[ -n "${OH_VERSION}" && ("${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both") ]]; then
    PARAMETERS_OK=true
    message="Initiating changes using the following parameters:"
    if [[ -n "${ACCOUNT}" ]]; then
        message="${message} ACCOUNT=${ACCOUNT},"
    fi
    message="${message} OH_VERSION=${OH_VERSION},"
    if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
        message="${message} ZSMARTSYSTEMS_VERION=${ZSMARTSYSTEMS_VERSION}"
    fi
    echo; echo -e ${BLUE_DARK}"${message}"${NC}
    karaf
else
    PARAMETERS_OK=false
    menu
fi