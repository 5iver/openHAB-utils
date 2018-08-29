#!/usr/bin/env bash
GREY_RED='\033[0;37;41m'
GREEN_DARK='\033[0;32;40m'
BLUE_DARK='\033[1;34;40m'
BLACK_WHITE='\033[0;30;47m'
BLINKING='\033[5;37;41m'
NC='\033[0m' # Reset

clear
CURRENT_ACCOUNT=$(whoami)
if [[ "${CURRENT_ACCOUNT}" != "openhab" ]]; then
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} This script MUST be executed by the account that runs openHAB, typically \"openhab\" ${BLINKING}!!!!!${NC}"
    select choice in "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" "Exit"; do
        case $choice in
            "Continue (my openHAB account is \"${CURRENT_ACCOUNT}\")" ) break;;
            "Exit" ) exit; break;;
        esac
    done
fi

#echo; echo -e "${BLUE_DARK}Stopping service...${NC}"
# stop openhab instance (here: systemd service)
#sudo systemctl stop openhab2.service

echo; echo -e "${GREEN_DARK}Querying configuration parameters...${NC}"

# prepare backup folder, replace with your desired destinations
OPENHAB_DIR="/opt/openhab2"
BACKUP_DIR="/home/archive"
DOWNLOAD_DIR="/opt/openhab2-backup/downloads"

BACKUP_DIR_FULL="${BACKUP_DIR}/$(date +%Y%m%d_%H%M%S)_openhab2_full"
BUILD_NUMBER=$(curl -s --connect-timeout 10 --max-time 10 "https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/console" | grep -a "Build successfully deployed" | grep -aoP "\d{4}" | head -n1)
OH_VERSION=$(curl -s --connect-timeout 10 --max-time 10 "https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/console" | grep -a "Building openHAB Distribution" | head -n1 | grep -aoP "[0-9]+\.[0-9]+\.[0-9]+")
FILE_NAME="${DOWNLOAD_DIR}/${BUILD_NUMBER}/openhab-${OH_VERSION}-SNAPSHOT.zip"
UNZIP_DIR="${DOWNLOAD_DIR}/${BUILD_NUMBER}/UNZIP_DIR"

mkdir -p "${BACKUP_DIR_FULL}"
mkdir -p "${UNZIP_DIR}"
mkdir -p "${BACKUP_DIR}/_zwavelogs"

# download latest snapshot
echo; echo -e "${GREEN_DARK}Downloading latest jar...${NC}"
curl -s --connect-timeout 10 --max-time 60 -o "${FILE_NAME}" "https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${OH_VERSION}-SNAPSHOT.zip"

# move last zwave log to archive directory
if [ -n "${OPENHAB_DIR}/userdata/logs/zwave/zwave.log" ]; then
    current_time=$(date "+%Y%m%d%H%M%S")
    mv "${OPENHAB_DIR}/userdata/logs/zwave/zwave.log" "${BACKUP_DIR}/_zwavelogs/zwave.log.${current_time}"
fi

# backup current installation with settings
cp -arv "${OPENHAB_DIR}" "${BACKUP_DIR_FULL}"

#find somedir -type f -exec md5sum {} \; | sort -k 2 | md5sum
#BACKUP_DIR_SIZE=$(du -sb ${BACKUP_DIR_FULL}/openhab2 | awk 'NF--')
#ORIGINAL_DIR_SIZE=$(du -sb ${OPENHAB_DIR} | awk 'NF--')
BACKUP_DIFF=$(diff -qrN "${OPENHAB_DIR}" "${BACKUP_DIR_FULL}/openhab2")

#if [ $BACKUP_DIRSize -ne $originalDirSize ]; then
if [[ -n "${BACKUP_DIFF}" ]]; then
    echo; echo -e "${BLINKING}!!!!!${GREY_RED} STOP! STOP! STOP! Full backup NOT successful ${BLINKING}!!!!!${NC}"
else
    echo; echo -e "${BLUE_DARK}Full backup successful...${NC}"
fi
#echo "${RESULT} original=$originalDirSize, backup=$BACKUP_DIRSize"
echo; echo -e "${GREEN_DARK}Next step is to remove unneeded files. Do you wish to continue?${NC}"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo; echo -e "${BLUE_DARK}Continuing................................${NC}"

rm -rf ${OPENHAB_DIR}/userdata/logs
rm -f ${OPENHAB_DIR}/userdata/etc/all.policy
rm -f ${OPENHAB_DIR}/userdata/etc/branding.properties
rm -f ${OPENHAB_DIR}/userdata/etc/branding-ssh.properties
rm -f ${OPENHAB_DIR}/userdata/etc/config.properties
rm -f ${OPENHAB_DIR}/userdata/etc/custom.properties
rm -f ${OPENHAB_DIR}/userdata/etc/version.properties
rm -f ${OPENHAB_DIR}/userdata/etc/distribution.info
rm -f ${OPENHAB_DIR}/userdata/etc/jre.properties
rm -f ${OPENHAB_DIR}/userdata/etc/profile.cfg
rm -f ${OPENHAB_DIR}/userdata/etc/startup.properties
rm -f ${OPENHAB_DIR}/userdata/etc/org.apache.karaf*
rm -f ${OPENHAB_DIR}/userdata/etc/org.ops4j.pax.url.mvn.cfg
rm -rf ${OPENHAB_DIR}/userdata/cache
rm -rf ${OPENHAB_DIR}/userdata/tmp
rm -rf ${OPENHAB_DIR}/runtime

echo; echo -e "${GREEN_DARK}Unneeded files removed from backup directory. Next step is to download and copy in new OH version. Do you wish to continue?${NC}"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo; echo -e "${BLUE_DARK}Continuing................................${NC}"

# copy updated version without overwriting settings
unzip "${FILE_NAME}" -d "${UNZIP_DIR}"
cp -anrv "${UNZIP_DIR}/." "${OPENHAB_DIR}/"

echo; echo -e "${GREEN_DARK}Updated version copied. Do you wish to remove the unzipped files?${NC}"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo; echo -e "${BLUE_DARK}Continuing................................${NC}"
rm -rf "${UNZIP_DIR}"

# or just unzip without overwriting settings [UNTESTED]
#echo "Updating openHAB..."
#unzip -nq /opt/openhab2/openhab-2.1.0.zip -d /opt/openhab2/

#echo; echo -e "${BLUE_DARK}Stopping service...${NC}"
# restart openhab instance
#sudo systemctl start openhab2.service

echo; echo -e "${BLUE_DARK}Complete................................${NC}"; echo