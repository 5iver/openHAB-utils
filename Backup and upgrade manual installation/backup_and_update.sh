#!/bin/sh

# stop openhab instance (here: systemd service)
#sudo systemctl stop openhab2.service

# prepare backup folder, replace by your desired destination
BACKUPDIRFULL="/home/archive/$(date +%Y%m%d_%H%M%S)_openhab2_full"
BACKUPDIR="/home/archive/$(date +%Y%m%d_%H%M%S)_openhab2"
UNZIPDIR="/opt/openhab2-backup/unzipDir"
mkdir -p $BACKUPDIRFULL
mkdir -p $BACKUPDIR
mkdir -p $UNZIPDIR
#rm -f /opt/openhab2/openhab-2.2.0-SNAPSHOT.zip

# move last zwave log to archive directory
current_time=$(date "+%Y%m%d%H%M%S")
mv /opt/openhab2/userdata/logs/zwave/zwave.log /home/archive/_zwavelogs/zwave.log.$current_time

# backup current installation with settings
cp -arv /opt/openhab2 "$BACKUPDIRFULL"

#find somedir -type f -exec md5sum {} \; | sort -k 2 | md5sum
backupDiff=$(diff -qrN /opt/openhab2 $BACKUPDIRFULL/openhab2)
#backupDirSize=$(du -sb $BACKUPDIRFULL/openhab2 | awk 'NF--')
#originalDirSize=$(du -sb /opt/openhab2 | awk 'NF--')
result="Full backup successful."
#if [ $backupDirSize -ne $originalDirSize ]; then
    #result="STOP! STOP! STOP! Copy NOT successful!!!!!"
#fi
if [ -n "$backupDiff" ]; then
    result="STOP! STOP! STOP! Copy NOT successful!!!!!"
fi
echo
echo
echo
echo
echo
#echo "$result original=$originalDirSize, backup=$backupDirSize"
echo "$result"
echo
#echo "Full backup complete. Compare sizes. Do you wish to continue?"
echo "Check to see if the last zwave.log got moved properly!"
echo "Full backup complete. Next step is to remove unneeded files. Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo
echo "Continuing................................"
echo

rm -rf /opt/openhab2/userdata/logs
rm -f /opt/openhab2/userdata/etc/all.policy
rm -f /opt/openhab2/userdata/etc/branding.properties
rm -f /opt/openhab2/userdata/etc/branding-ssh.properties
rm -f /opt/openhab2/userdata/etc/config.properties
rm -f /opt/openhab2/userdata/etc/custom.properties
rm -f /opt/openhab2/userdata/etc/version.properties
rm -f /opt/openhab2/userdata/etc/distribution.info
rm -f /opt/openhab2/userdata/etc/jre.properties
rm -f /opt/openhab2/userdata/etc/profile.cfg
rm -f /opt/openhab2/userdata/etc/startup.properties
rm -f /opt/openhab2/userdata/etc/org.apache.karaf*
rm -f /opt/openhab2/userdata/etc/org.ops4j.pax.url.mvn.cfg
rm -rf /opt/openhab2/userdata/cache
rm -rf /opt/openhab2/userdata/tmp
rm -rf /opt/openhab2/runtime
cp -arv /opt/openhab2/conf "$BACKUPDIR/conf"
cp -arv /opt/openhab2/userdata "$BACKUPDIR/userdata"
cp -arv /opt/openhab2/*.sh "$BACKUPDIR"

echo
echo
echo
echo
echo
echo "Unneeded files removed from backup directory. Next step is to copy in new OH version. Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo
echo "Continuing................................"
echo

# copy updated version without overwriting settings
unzip /opt/openhab2-backup/openhab-2.4.0-SNAPSHOT.zip -d "$UNZIPDIR"
cp -anrv "$UNZIPDIR/." /opt/openhab2/

echo
echo
echo
echo
echo
echo "Updated version copied. Do you wish to remove the unzipped files?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
echo
echo "Continuing................................"
echo
rm -rf "$UNZIPDIR"

# or just unzip without overwriting settings [UNTESTED]
#echo "Updating openHAB..."
#unzip -nq /opt/openhab2/openhab-2.1.0.zip -d /opt/openhab2/

# restart openhab instance
#sudo systemctl start openhab2.service
