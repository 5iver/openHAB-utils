#!/usr/bin/env bash
GREY_RED='\033[0;37;41m'
GREEN_DARK='\033[0;32;40m'
BLUE_DARK='\033[1;34;40m'
BLACK_WHITE='\033[0;30;47m'
BLINKING='\033[5;37;41m'
NC='\033[0m' # Reset

introText() {
    echo; echo -e "${GREEN_DARK}This script is capable of downloading and manually installing the latest development or master branch builds of the Z-Wave and Zigbee bindings, and/or the openhab-transport-serial"
    echo "feature. The script must reside inside the addons folder and be executed on the machine running OH. Before a binding is installed, any previous versions will be"
    echo "uninstalled. Any manually installed versions will also be backed up by moving them to addons/archive. The installation of any binding will also include the installation"
    echo "of the opemnhab-transport-serial feature. After using this script, you can uninstall the bindings by deleting their jars from addons or you can use this script.${NC}"
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} If you have manually added the Zigbee or Z-Wave binding to your addons.cfg file, they must be removed from the file or the old version will reinstall ${BLINKING}!!!!!${NC}"
}
SILENT=false
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
                        ACTION="Install the openhab-transport-serial feature"
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
        --ZWAVE_BRANCH)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZWAVE_BRANCH=$2
                ZWAVE_BRANCH="${ZWAVE_BRANCH,,}"
                ZWAVE_BRANCH="${ZWAVE_BRANCH[@]^}"
                if [[ "${ZWAVE_BRANCH}" = "Development" || "${ZWAVE_BRANCH}" = "Master" ]]; then
                    shift 2
                    #echo "ZWAVE_BRANCH=${ZWAVE_BRANCH,,}"
                else
                    echo -e "${GREY_RED}ZWAVE_BRANCH argument specified with invalid value (${ZWAVE_BRANCH}). Accepted values: development, master.${NC}"
                    echo; exit
                fi
            else
                echo -e "${GREY_RED}ZWAVE_BRANCH argument specified without a value${NC}"
                echo; exit
            fi;;
        --ZIGBEE_BRANCH)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZIGBEE_BRANCH=$2
                ZIGBEE_BRANCH="${ZIGBEE_BRANCH,,}"
                ZIGBEE_BRANCH="${ZIGBEE_BRANCH[@]^}"
                if [[ "${ZIGBEE_BRANCH}" = "Development" || "${ZIGBEE_BRANCH}" = "Master" ]]; then
                    shift 2
                    #echo "ZIGBEE_BRANCH=${ZIGBEE_BRANCH,,}"
                else
                    echo -e "${GREY_RED}ZIGBEE_BRANCH argument specified with invalid value (${ZIGBEE_BRANCH}). Accepted values: development, master.${NC}"
                    echo; exit
                fi
            else
                echo -e "${GREY_RED}ZIGBEE_BRANCH argument specified without a value${NC}"
                echo; exit
            fi;;
        --ZSMARTSYSTEMS_VERSION)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                ZSMARTSYSTEMS_VERSION=$2
                shift 2
                #echo "ZSMARTSYSTEMS_VERSION=${ZSMARTSYSTEMS_VERSION}"
            else
                echo -e "${GREY_RED}ZSMARTSYSTEMS_VERSION argument specified without a value${NC}"
                echo; exit
            fi;;
        --KARAF_ACCOUNT)
            if [[ "${2:0:1}" != "-" && "${2:0:1}" != "" ]]; then
                KARAF_ACCOUNT=$2
                shift 2
                #echo "KARAF_ACCOUNT=${KARAF_ACCOUNT}"
            else
                echo -e "${GREY_RED}KARAF_ACCOUNT argument specified without a value${NC}"
                echo; exit
            fi;;
        --HELP)
            introText; echo
            echo -e "${BLUE_DARK}Usage: zzManualInstaller.sh [OPTION]...${NC}"; echo
            echo -e "${BLUE_DARK}If executed without the ACTION argument, menus will be displayed for each option${NC}"; echo
            echo -e "    --ACTION                  ${BLUE_DARK}Accepted values: zigbee, zwave, both. Specify which bindings to install/upgrade.${NC}"
            echo -e "    --ZWAVE_BRANCH            ${BLUE_DARK}Accepted values: development, master. Default: master. Specify the development or master branch for Z-Wave.${NC}"
            echo -e "    --ZIGBEE_BRANCH           ${BLUE_DARK}Accepted values: development, master. Default: master. Specify the development or master branch for Zigbee.${NC}"
            echo -e "    --ZSMARTSYSTEMS_VERSION   ${BLUE_DARK}Default: latest version, based on selected branch. Specify the version of the ZSmartSystems libraries.${NC}"
            echo -e "    --KARAF_ACCOUNT           ${BLUE_DARK}Default: ${NC}openhab${BLUE_DARK}. Specify an account for the Karaf SSH login.${NC}"
            echo -e "    --HELP                    ${BLUE_DARK}Display this help and exit${NC}"; echo
            echo; exit;;
        --*) echo -e "${GREY_RED}Unrecognized argument: ${WORD}${NC}"
            echo; exit;;
        -*) echo -e "${GREY_RED}Unrecognized argument: ${WORD}${NC}"
            echo; exit;;
    esac
done

SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do # resolve SOURCE until the file is no longer a symlink
    ADDONS="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$ADDONS/$SOURCE" # if SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ADDONS="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"

installUninstall() {
    if [[ !("${ACTION}" =~ "transport") ]]; then
        echo; echo -e ${BLUE_DARK}"Waiting for the uninstallation of previous versions to complete..."${NC}
        COUNT=0
        ZIGBEE_UNINSTALLED=false
        ZWAVE_UNINSTALLED=false
        while [[ ${ZIGBEE_UNINSTALLED} = false && ${ZWAVE_UNINSTALLED} = false ]]; do
            if [[ ${ZIGBEE_UNINSTALLED} = false && "${ACTION}" =~ "Zigbee" ]]; then
                ZIGBEE_CHECK=$(curl -s --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zigbee/config")
                if [[ -z "${ZIGBEE_CHECK}" ]]; then #"${ZIGBEE_CHECK}" = "{}" || 
                    ZIGBEE_UNINSTALLED=true
                elif [[ ${COUNT} -gt 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to uninstall the Zigbee binding, so exiting ${BLINKING}!!!!!${NC}"; echo; echo
                    exit
                #else
                #    echo "Debug: Zigbee wait count: ${COUNT}, ZIGBEE_CHECK=${ZIGBEE_CHECK}"
                fi
            else
                ZIGBEE_UNINSTALLED=true
            fi
            if [[ ${ZWAVE_UNINSTALLED} = false && "${ACTION}" =~ "Z-Wave" ]]; then
                ZWAVE_CHECK=$(curl -s --connect-timeout 10 --max-time 10 -X GET --header "Accept: application/json" "http://localhost:8080/rest/bindings/zwave/config")
                if [[ -z "${ZWAVE_CHECK}" ]]; then #"${ZWAVE_CHECK}" = "{}" || 
                    ZWAVE_UNINSTALLED=true
                elif [[ ${COUNT} -gt 24 ]]; then
                    echo; echo -e "${BLINKING}!!!!!${GREY_RED} It has taken more than two minutes to uninstall the Z-Wave binding, so exiting ${BLINKING}!!!!!${NC}"; echo; echo
                    exit
                #else
                #    echo "Debug: Z-Wave wait count: ${COUNT}, ZWAVE_CHECK=${ZWAVE_CHECK}"
                fi
            else
                ZWAVE_UNINSTALLED=true
            fi
            sleep 5
            ((COUNT++))
        done
        current_time=$(date "+%Y%m%d%H%M%S")
        if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
            echo; echo -e ${BLUE_DARK}"Backing up any old manual installs of Zigbee..."${NC}
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zigbee
            if [[ 0 -lt $(ls *zigbee*.jar 2>/dev/null | wc -w) ]]; then
                mv -f *zigbee*.jar ${ADDONS}/archive/zigbee/
            fi
            cd ${ADDONS}/archive/zigbee
            rename .jar .${current_time}.old *zigbee*
            if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
                echo; echo -e ${BLUE_DARK}"Downloading new Zigbee jars..."${NC}
                mkdir -p ${ADDONS}/archive/staging/zigbee
                cd ${ADDONS}/archive/staging/zigbee

                curl -s --connect-timeout 10 --max-time 60 -O -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee-${ZSMARTSYSTEMS_VERSION}.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.xbee/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.xbee-${ZSMARTSYSTEMS_VERSION}.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.ember/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.ember-${ZSMARTSYSTEMS_VERSION}.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.telegesis/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.telegesis-${ZSMARTSYSTEMS_VERSION}.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://dl.bintray.com/zsmartsystems/com.zsmartsystems/com/zsmartsystems/zigbee/com.zsmartsystems.zigbee.dongle.cc2531/${ZSMARTSYSTEMS_VERSION}/com.zsmartsystems.zigbee.dongle.cc2531-${ZSMARTSYSTEMS_VERSION}.jar"

                curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.cc2531/artifact/org.openhab.binding/org.openhab.binding.zigbee.cc2531/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.cc2531-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.ember/artifact/org.openhab.binding/org.openhab.binding.zigbee.ember/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.ember-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.telegesis/artifact/org.openhab.binding/org.openhab.binding.zigbee.telegesis/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.telegesis-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee.xbee/artifact/org.openhab.binding/org.openhab.binding.zigbee.xbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee.xbee-${OH_VERSION}-SNAPSHOT.jar"
                curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zigbee/artifact/org.openhab.binding/org.openhab.binding.zigbee/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zigbee-${OH_VERSION}-SNAPSHOT.jar"
            fi
        fi
        if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
            echo; echo -e ${BLUE_DARK}"Backing up any old manual installs of Z-Wave..."${NC}
            cd ${ADDONS}
            mkdir -p ${ADDONS}/archive/zwave
            if [[ 0 -lt $(ls *zwave*.jar 2>/dev/null | wc -w) ]]; then
                mv -f *zwave*.jar ${ADDONS}/archive/zwave/
            fi
            cd ${ADDONS}/archive/zwave
            rename .jar .${current_time}.old *zwave*
            if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
                echo; echo -e ${BLUE_DARK}"Downloading new Z-Wave jar..."${NC}
                mkdir -p ${ADDONS}/archive/staging/zwave
                cd ${ADDONS}/archive/staging/zwave
                if [[ "${ZWAVE_BRANCH}" = "Development" ]]; then
                    curl -s --connect-timeout 10 --max-time 60 -O -L "http://www.cd-jackson.com/downloads/openhab2/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar"
                else
                    curl -s --connect-timeout 10 --max-time 60 -O -L "https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding%24org.openhab.binding.zwave/artifact/org.openhab.binding/org.openhab.binding.zwave/${OH_VERSION}-SNAPSHOT/org.openhab.binding.zwave-${OH_VERSION}-SNAPSHOT.jar"
                fi
            fi
        fi
        if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
            echo; echo -e ${BLUE_DARK}"Starting bindings..."${NC}
            if [[ "${ACTION}" =~ "Zigbee" || "${ACTION}" =~ "both" ]]; then
                mv -f ${ADDONS}/archive/staging/zigbee/*.jar ${ADDONS}/
            fi
            if [[ "${ACTION}" =~ "Z-Wave" || "${ACTION}" =~ "both" ]]; then
                mv -f ${ADDONS}/archive/staging/zwave/*.jar ${ADDONS}/
            fi
        fi
    fi
    echo; echo -e ${BLUE_DARK}"Complete!"${NC}; echo
    if [[ "${ACTION}" =~ "Install or upgrade Z-Wave" || "${ACTION}" =~ "Install or upgrade both" ]]; then
        echo -e ${GREEN_DARK}"You've installed, upgraded, or downgraded the Z-Wave binding. For first time installs or downgrades of the development binding, it is required that all of your Z-Wave"
        echo -e "Things (except for the controller) be deleted and rediscovered. This does not mean excluding the devices. This is a requirement due to changes in how the Things are"
        echo -e "defined. This is also recommended when the developemnt Z-Wave binding is upgraded, in order to update the Thing definitions with the frequent changes that are made.${NC}"; echo
    fi
    exit
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
        KARAF_FUNCTION="${KARAF_FUNCTION} bundle:uninstall org.openhab.binding.zwave;"
    fi
    if [[ "${ACTION}" =~ "nstall" ]]; then
        KARAF_FUNCTION="${KARAF_FUNCTION} feature:install openhab-transport-serial;"
    fi
    KARAF_FUNCTION="${KARAF_FUNCTION} logout;"
    #echo $KARAF_FUNCTION
    if [[ "${ACTION}" =~ "transport" ]]; then
        echo; echo -e ${BLUE_DARK}"Installing openhab-serial-transport..."${NC}
    elif [[ "${ACTION}" =~ "Install" ]]; then
        echo; echo -e ${BLUE_DARK}"Uninstalling binding(s) and installing openhab-serial-transport..."${NC}
    else
        echo; echo -e ${BLUE_DARK}"Uninstalling binding(s)..."${NC}
    fi
    echo; echo -e ${GREEN_DARK}"Reminder... the default Karaf SSH session password is${NC} habopen"
    #ssh -p 8101 -o StrictHostKeyChecking=no -l ${KARAF_ACCOUNT} localhost ${KARAF_FUNCTION}
    ssh -p 8101 -l ${KARAF_ACCOUNT} localhost ${KARAF_FUNCTION}
    if [[ !("${ACTION}" =~ "transport") ]]; then
        echo -e ${GREEN_DARK}"An error here is normal, if one of the selected bindings was not previously installed...${NC}"
    fi
    installUninstall
}

summary() {
    if [[ ${SILENT} = false ]]; then
        clear; 
    fi
    echo; echo -e "     ${BLACK_WHITE}*****     SUMMARY     *****${NC}     "; echo
    echo -e "${GREEN_DARK}Addons path:${NC} ${ADDONS}"
    echo -e "${GREEN_DARK}OH account:${NC} ${CURRENT_ACCOUNT}"
    echo -e "${GREEN_DARK}Karaf account:${NC} ${KARAF_ACCOUNT}"
    echo -e "${GREEN_DARK}Requested action:${NC} ${ACTION}"
    if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
        echo -e "${GREEN_DARK}Current OH snapshot version:${NC} ${OH_VERSION}"
    fi
    if [[ ${ACTION} = "Install or upgrade Z-Wave binding" || ${ACTION} = "Install or upgrade both bindings" ]]; then
        echo -e "${GREEN_DARK}Requested branch for Z-Wave:${NC} ${ZWAVE_BRANCH}"
    fi
    if [[ ${ACTION} = "Install or upgrade Zigbee binding" || ${ACTION} = "Install or upgrade both bindings" ]]; then
        echo -e "${GREEN_DARK}Requested branch for Zigbee:${NC} ${ZIGBEE_BRANCH}"
        if [[ ${ZIGBEE_BRANCH} = "Master" ]]; then
            echo -e "${GREEN_DARK}Requested ZSmartSystems library version:${NC} ${ZSMARTSYSTEMS_VERSION}"
        else
            echo -e "${GREEN_DARK}Included ZSmartSystems library version:${NC} ${ZSMARTSYSTEMS_VERSION}"
        fi
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
            echo; echo; echo -e "${GREEN_DARK}From which branch would you like the Z-Wave binding downloaded from? Snapshots are in Master.${NC}"
            select ZWAVE_BRANCH in "Development" "Master" "Exit"; do
                case $ZWAVE_BRANCH in
                    "Development" ) break;;
                    "Master" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi
    elif [[ -z "${ZWAVE_BRANCH}" ]]; then # not specified as an argument
        ZWAVE_BRANCH="Master"
    fi

    if [[ ${SILENT} = false ]]; then
        if [[ "${ACTION}" = "Install or upgrade Zigbee binding" || "${ACTION}" = "Install or upgrade both bindings" ]]; then
            echo; echo; echo -e "${GREEN_DARK}From which branch would you like the Zigbee binding downloaded from? Snapshots are in Master.${NC}"
            select ZIGBEE_BRANCH in "Development" "Master" "Exit"; do
                case $ZIGBEE_BRANCH in
                    "Development" ) break;;
                    "Master" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi
    elif [[ -z "${ZIGBEE_BRANCH}" ]]; then # not specified as an argument
        ZIGBEE_BRANCH="Master"
    fi

    if [[ "${ACTION}" =~ "Install or upgrade" ]]; then
        #OH_VERSION=$(wget -nv -q -O- 'https://openhab.ci.cloudbees.com/job/openHAB2-Bundles/lastSuccessfulBuild/org.openhab.binding$org.openhab.binding.zigbee/console' | grep -a "Building ZigBee Binding" | grep -aoP "[0-9].*[0-9]")
        OH_VERSION=$(curl -s --connect-timeout 10 --max-time 10 "https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/console" | grep -a "Building openHAB Distribution" | head -n1 | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")

    fi

    if [[ -z "${ZSMARTSYSTEMS_VERSION}" && ("${ACTION}" = "Install or upgrade Zigbee binding" || "${ACTION}" = "Install or upgrade both bindings") ]]; then
        if [[ "${ZIGBEE_BRANCH}" = "Master" ]]; then
            ZSMARTSYSTEMS_VERSION=$(curl -s --connect-timeout 10 --max-time 10 'https://raw.githubusercontent.com/openhab/openhab-distro/master/features/addons/src/main/feature/feature.xml' | grep -a "com.zsmartsystems.zigbee.dongle.ember" | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")
        else
            #ZSMARTSYSTEMS_VERSION=$(wget -nv -q -O- 'https://bintray.com/zsmartsystems/com.zsmartsystems/zigbee/_latestVersion' | grep -oP "[0-9].*[0-9]$")
            ZSMARTSYSTEMS_VERSION=$(curl -Ls --connect-timeout 10 --max-time 10 -o /dev/null -w %{url_effective} 'https://bintray.com/zsmartsystems/com.zsmartsystems/zigbee/_latestVersion' | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")
        fi
        if [[ ${SILENT} = false && "${ZIGBEE_BRANCH}" = "Development" ]]; then
            echo; echo; echo -e "${GREEN_DARK}Note: the development Zigbee libraries may not yet be compatible with the current openHAB Zigbee binding"
            echo -e "or bridges. Enter the requested version of the development ZSmartSystems libraries [clear field to exit]${NC}"
            read -e -p "[Use backspace to modify, enter to accept. The latest development version is ${ZSMARTSYSTEMS_VERSION}.] " -i "${ZSMARTSYSTEMS_VERSION}" ZSMARTSYSTEMS_VERSION
            if [[ -z "${ZSMARTSYSTEMS_VERSION}" ]]; then
                exit
            fi
        fi
    fi
    summary
}

changeKarafAccount() {
    echo; echo -e "${GREEN_DARK}Enter the modified Karaf account name [clear field to exit]${NC}"
    read -e -p "[Use backspace to modify, enter to accept] " KARAF_ACCOUNT
    if [[ -z "${KARAF_ACCOUNT}" ]]; then
        exit
    fi
}

menu() {
    if [[ -z "${KARAF_ACCOUNT}" ]]; then
        KARAF_ACCOUNT="openhab"
    fi
    CURRENT_ACCOUNT=$(whoami)
    if [[ ${SILENT} = false ]]; then
        clear
        if [[ "${CURRENT_ACCOUNT}" != "openhab" ]]; then
            echo; echo -e "${BLINKING}!!!!!${GREY_RED} This script MUST be executed by the account that runs openHAB, typically \"openhab\" ${BLINKING}!!!!!${NC}"
            select choice in "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" "Exit"; do
                case $choice in
                    "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" ) break;;
                    "Exit" ) exit; break;;
                esac
            done
        fi

        introText
        echo; echo -e "${GREEN_DARK}What would you like to do?${NC}"
        select ACTION in "Install or upgrade Zigbee binding" "Install or upgrade Z-Wave binding" "Install or upgrade both bindings" "Install the openhab-transport-serial feature" "Uninstall Zigbee binding" "Uninstall Z-Wave binding" "Uninstall both bindings" "Exit"; do
            case $ACTION in
                "Install or upgrade Zigbee binding" ) break;;
                "Install or upgrade Z-Wave binding" ) break;;
                "Install or upgrade both bindings" ) break;;
                "Install the openhab-transport-serial feature" ) break;;
                "Uninstall Zigbee binding" ) break;;
                "Uninstall Z-Wave binding" ) break;;
                "Uninstall both bindings" ) break;;
                "Exit" ) echo; exit;;
            esac
        done

        echo; echo; echo -e ${GREEN_DARK}"This script will connect to the Karaf console via SSH to uninstall duplicate bindings and/or install openhab-serial-transport. If you have changed the default Karaf"
        echo -e "SSH username, choose 'Change Account'. You will be prompted for the password when the script establishes the SSH session, unless the Karaf SSH server's public"
        echo -e "key has already been added to the OH account's list of known hosts. The first time the script is run, if it is the first time establishing an SSH session to Karaf"
        echo -e "from your OH server, you will be prompted with a warning that it is being permanently added to known hosts. The default account:password is${NC} openhab:habopen"
        select choice in "Continue (my Karaf account is \"${KARAF_ACCOUNT}\")" "Select another account" "Exit"; do
            case $choice in
                "Continue (my Karaf account is \"${KARAF_ACCOUNT}\")" ) break;;
                "Select another account" ) changeKarafAccount; break;;
                "Exit" ) echo; exit;;
            esac
        done
    fi
    versions
}

menu
